import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/backend_service_provider.dart';
import '../models/referral.dart';

/// A user's referral code, stored as one `referral` tracking entry on their
/// own account.
///
/// Crediting the person who referred a new member has to happen on the
/// server: security rules only let a user read and write their own data, so
/// the app can never update someone else's referral record.
class ReferralService extends ChangeNotifier {
  static const String trackingType = 'referral';
  static const String entryId = 'referral_code';

  /// Characters used in codes (no O/0 or I/1, which are easy to confuse).
  static const String codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int codeLength = 8;

  final UnifiedTrackingService? _trackingOverride;
  final Random _random;

  ReferralService({UnifiedTrackingService? tracking, Random? random})
      : _trackingOverride = tracking,
        _random = random ?? Random.secure();

  UnifiedTrackingService get _tracking =>
      _trackingOverride ?? BackendServiceProvider.instance.tracking;

  Referral? _referral;
  bool _isLoading = false;
  bool _isSaved = false;

  Referral? get referral => _referral;
  bool get isLoading => _isLoading;
  bool get hasReferral => _referral != null;

  /// True once the code is stored on an account; false while it only exists
  /// on this device (created before the user signed up).
  bool get isSaved => _isSaved;

  /// Generates an 8-character code from [codeAlphabet].
  String generateReferralCode() {
    return List.generate(
      codeLength,
      (_) => codeAlphabet[_random.nextInt(codeAlphabet.length)],
    ).join();
  }

  /// Loads the user's existing code or creates one. With no [userId] (not
  /// signed up yet) the code is kept on this device until [saveForUser].
  Future<Referral> loadOrCreate(String? userId) async {
    _setLoading(true);
    try {
      if (userId != null) {
        final existing = await loadReferral(userId);
        if (existing != null) return existing;
      }
      return await createReferral(userId);
    } finally {
      _setLoading(false);
    }
  }

  /// Loads the code saved on [userId]'s account, or null if there is none.
  Future<Referral?> loadReferral(String userId) async {
    final data = await _tracking.getTrackingData(
      userId: userId,
      date: entryId,
      type: trackingType,
    );
    final code = data?['referralCode'];
    if (data == null || code is! String || code.isEmpty) return null;
    _referral = Referral.fromJson(data);
    _isSaved = true;
    notifyListeners();
    return _referral;
  }

  /// Creates a new code, saving it straight away when [userId] is known.
  Future<Referral> createReferral(String? userId) async {
    final now = DateTime.now();
    _referral = Referral(
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId ?? '',
      referralCode: generateReferralCode(),
      createdAt: now,
    );
    _isSaved = false;
    if (userId != null) {
      await _save(userId);
    }
    notifyListeners();
    return _referral!;
  }

  /// Stores a code created before sign-up on the new account. If the account
  /// already has a code, that one is kept and loaded instead. Returns true
  /// when the account has a saved code afterwards.
  Future<bool> saveForUser(String userId) async {
    final pending = _referral;
    if (pending == null) return false;
    if (_isSaved && pending.userId == userId) return true;
    final existing = await loadReferral(userId);
    if (existing != null) return true;
    _referral = pending;
    await _save(userId);
    notifyListeners();
    return true;
  }

  Future<void> _save(String userId) async {
    final referral = _referral!.copyWith(userId: userId);
    await _tracking.trackEvent(
      userId: userId,
      type: trackingType,
      data: {
        ...referral.toJson(),
        'entry_id': entryId,
        'date': DateFormat('yyyy-MM-dd').format(referral.createdAt),
      },
    );
    _referral = referral;
    _isSaved = true;
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
