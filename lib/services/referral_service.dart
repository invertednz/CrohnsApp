import 'dart:math';
import 'package:flutter/material.dart';
import '../models/referral.dart';

class ReferralService extends ChangeNotifier {
  Referral? _referral;
  bool _isLoading = false;

  Referral? get referral => _referral;
  bool get isLoading => _isLoading;
  bool get hasReferral => _referral != null;

  // Generate unique 8-character alphanumeric code (avoiding confusing chars)
  String generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No O,0,I,1
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Create new referral for user
  Future<void> createReferral(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final code = generateReferralCode();
      _referral = Referral(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        referralCode: code,
        createdAt: DateTime.now(),
      );

      // TODO: Save to database (Supabase/Firebase)
      await _saveToDatabase(_referral!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Load referral from database
  Future<void> loadReferral(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Load from database
      final data = await _loadFromDatabase(userId);
      if (data != null) {
        _referral = Referral.fromJson(data);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Record successful referral
  Future<void> recordSuccessfulReferral(String referredUserId) async {
    if (_referral == null || _referral!.hasReachedCap) return;

    final newSuccessfulReferrals = _referral!.successfulReferrals + 1;
    final newEarnedRewards = (newSuccessfulReferrals * Referral.rewardPerReferral)
        .clamp(0, Referral.maxRewardCap)
        .toDouble();

    _referral = _referral!.copyWith(
      successfulReferrals: newSuccessfulReferrals,
      earnedRewards: newEarnedRewards,
      lastReferralAt: DateTime.now(),
      referredUserIds: [..._referral!.referredUserIds, referredUserId],
    );

    // TODO: Save to database
    await _saveToDatabase(_referral!);

    notifyListeners();
  }

  // Validate and apply referral code (for new user)
  Future<bool> applyReferralCode(String code, String newUserId) async {
    try {
      // TODO: Query database for referral code
      final referrerData = await _findReferralByCode(code);
      
      if (referrerData == null) return false;
      
      final referrer = Referral.fromJson(referrerData);
      
      if (referrer.hasReachedCap) return false;
      if (referrer.referredUserIds.contains(newUserId)) return false;

      // Record the successful referral for the referrer
      // This would be called from backend after new user completes payment
      return true;
    } catch (e) {
      return false;
    }
  }

  // Reset rewards at renewal (called annually)
  Future<void> resetRewards() async {
    if (_referral == null) return;

    _referral = _referral!.copyWith(
      successfulReferrals: 0,
      earnedRewards: 0.0,
      referredUserIds: [],
    );

    await _saveToDatabase(_referral!);
    notifyListeners();
  }

  // Database placeholder methods (implement with actual DB)
  Future<void> _saveToDatabase(Referral referral) async {
    // TODO: Implement with Supabase/Firebase
    // Example: await supabase.from('referrals').upsert(referral.toJson());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<Map<String, dynamic>?> _loadFromDatabase(String userId) async {
    // TODO: Implement with Supabase/Firebase
    // Example: final response = await supabase
    //   .from('referrals')
    //   .select()
    //   .eq('userId', userId)
    //   .single();
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  Future<Map<String, dynamic>?> _findReferralByCode(String code) async {
    // TODO: Implement with Supabase/Firebase
    // Example: final response = await supabase
    //   .from('referrals')
    //   .select()
    //   .eq('referralCode', code)
    //   .single();
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }
}
