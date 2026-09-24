import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/services/ai_chat_service.dart';
import 'package:gut_md/services/insights_generator.dart';

/// In-memory backend for the offline demo/E2E build (`USE_MOCK_DATA=true`)
/// and as a fallback when Firebase cannot start. Data lives for the session.
class MockBackend {
  MockBackend._();

  static UnifiedBackendService create() {
    final auth = _MockAuthService();
    final tracking = _MockTrackingService();
    return UnifiedBackendService(
      auth: auth,
      tracking: tracking,
      insights: _MockInsightsService(tracking),
      chat: _MockChatService(tracking),
      isMock: true,
    );
  }
}

const _latency = Duration(milliseconds: 250);

/// Copies stored data in and out so callers can never mutate the store,
/// matching Firestore's value semantics.
Map<String, dynamic> _copy(Map<String, dynamic> data) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(data)) as Map);

class _MockAuthService implements UnifiedAuthService {
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    await Future.delayed(_latency);
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Enter a valid email and a password of at least 6 characters');
    }
    final guest = _user?.isAnonymous == true ? _user : null;
    _user = AppUser(
      // Upgrading a guest keeps its id so anything logged as a guest carries over.
      id: guest?.id ?? 'mock_user_${email.hashCode}',
      email: email,
      displayName: (userData?['name'] as String?) ?? email.split('@').first,
    );
    return _user;
  }

  @override
  Future<AppUser?> signInWithEmail({required String email, required String password}) async {
    await Future.delayed(_latency);
    if (!email.contains('@') || password.isEmpty) {
      throw Exception('Invalid email or password');
    }
    _user = AppUser(id: 'mock_user_${email.hashCode}', email: email, displayName: email.split('@').first);
    return _user;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    await Future.delayed(_latency);
    final guest = _user?.isAnonymous == true ? _user : null;
    _user = AppUser(id: guest?.id ?? 'mock_google_user', email: 'demo.user@gmail.com', displayName: 'Demo User');
    return _user;
  }

  @override
  Future<AppUser?> signInWithApple() async {
    await Future.delayed(_latency);
    final guest = _user?.isAnonymous == true ? _user : null;
    _user = AppUser(id: guest?.id ?? 'mock_apple_user', email: 'demo@privaterelay.appleid.com', displayName: 'Demo User');
    return _user;
  }

  @override
  Future<AppUser?> signInAsGuest() async {
    await Future.delayed(_latency);
    return _user ??= const AppUser(id: 'mock_guest', isAnonymous: true);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(_latency);
    if (!email.contains('@')) throw Exception('Enter a valid email address');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(_latency);
    _user = null;
  }
}

class _MockTrackingService implements UnifiedTrackingService {
  /// userId -> type -> entryId -> data
  final Map<String, Map<String, Map<String, Map<String, dynamic>>>> _store = {};

  Map<String, Map<String, dynamic>> _entries(String userId, String type) =>
      (_store[userId] ??= {})[type] ??= {};

  @override
  Future<void> trackEvent({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(_latency);
    final id = (data['entry_id'] ?? data['date'] ?? DateTime.now().toIso8601String()).toString();
    final now = DateTime.now().toIso8601String();
    _entries(userId, type)[id] = _copy({
      ...?_entries(userId, type)[id],
      ...data,
      'type': type,
      'recorded_at': now,
      'updated_at': now,
    });
    debugPrint('MockBackend: tracked $type/$id');
  }

  @override
  Future<Map<String, dynamic>?> getTrackingData({
    required String userId,
    required String date,
    required String type,
  }) async {
    await Future.delayed(_latency);
    final entry = _entries(userId, type)[date];
    return entry == null ? null : _copy(entry);
  }

  @override
  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    required String type,
    int limit = 30,
  }) async {
    final results = _entries(userId, type).values.map(_copy).toList()
      ..sort((a, b) => '${b['date'] ?? ''}'.compareTo('${a['date'] ?? ''}'));
    return results.take(limit).toList();
  }
}

class _MockInsightsService implements UnifiedInsightsService {
  final UnifiedTrackingService _tracking;
  final Map<String, Map<String, dynamic>> _latest = {};

  _MockInsightsService(this._tracking);

  @override
  Future<Map<String, dynamic>?> getUserInsights(String userId) async {
    if (!_latest.containsKey(userId)) await generateInsights(userId);
    return _latest[userId];
  }

  @override
  Future<void> generateInsights(String userId) async {
    await Future.delayed(_latency);
    final history = await loadRecentHistory(_tracking, userId);
    _latest[userId] = InsightsGenerator.localInsights(history);
  }
}

class _MockChatService implements UnifiedChatService {
  final UnifiedTrackingService _tracking;
  final Map<String, List<Map<String, dynamic>>> _history = {};
  final AIChatService _ai = const AIChatService();

  _MockChatService(this._tracking);

  @override
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    return List.of(_history[userId] ?? const []);
  }

  @override
  Future<String> sendMessage(String userId, String message) async {
    final messages = _history[userId] ??= [];
    final previous = List.of(messages);
    messages.add({'text': message, 'isUser': true, 'timestamp': DateTime.now().toIso8601String()});
    await Future.delayed(_latency);
    final history = await loadRecentHistory(_tracking, userId);
    final reply = await _ai.generateResponse(
      userMessage: message,
      context: buildHealthContext(history, previous),
    );
    messages.add({'text': reply, 'isUser': false, 'timestamp': DateTime.now().toIso8601String()});
    return reply;
  }
}
