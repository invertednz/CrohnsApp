import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:gut_md/core/environment.dart';
import 'package:gut_md/core/firebase_backend.dart';
import 'package:gut_md/core/mock_backend.dart';
import 'package:gut_md/firebase_options.dart';
import 'package:gut_md/services/ai_chat_service.dart';

/// Signed-in user, independent of the backend implementation.
class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });
}

abstract class UnifiedAuthService {
  AppUser? get currentUser;
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  });
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AppUser?> signInWithGoogle();
  Future<AppUser?> signInWithApple();

  /// Start without an account; data is kept under an anonymous user id.
  Future<AppUser?> signInAsGuest();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

/// Tracking entries are stored per `type` (daily, diet, meal, symptoms,
/// supplements, medications). Within a type an entry is keyed by
/// `data['entry_id']` when present, otherwise by `data['date']`. Saving merges
/// fields into an existing entry, so different screens can each contribute
/// fields to the same day's record.
abstract class UnifiedTrackingService {
  Future<void> trackEvent({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  });
  Future<Map<String, dynamic>?> getTrackingData({
    required String userId,
    required String date,
    required String type,
  });
  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    required String type,
    int limit = 30,
  });
}

abstract class UnifiedInsightsService {
  Future<Map<String, dynamic>?> getUserInsights(String userId);
  Future<void> generateInsights(String userId);
}

abstract class UnifiedChatService {
  Future<String> sendMessage(String userId, String message);

  /// Messages oldest first as `{text, isUser, timestamp}`.
  Future<List<Map<String, dynamic>>> getChatHistory(String userId);
}

class UnifiedBackendService {
  final UnifiedAuthService auth;
  final UnifiedTrackingService tracking;
  final UnifiedInsightsService insights;
  final UnifiedChatService chat;
  final bool isMock;

  const UnifiedBackendService({
    required this.auth,
    required this.tracking,
    required this.insights,
    required this.chat,
    required this.isMock,
  });
}

/// Tracking types the chat assistant and insights read from.
const insightTrackingTypes = ['daily', 'symptoms', 'supplements', 'medications', 'diet', 'meal', 'log'];

/// Loads the recent history used as AI context, plus the onboarding answers
/// (`profile`, saved by OnboardingProfileStore) when the user has them.
Future<Map<String, List<Map<String, dynamic>>>> loadRecentHistory(
  UnifiedTrackingService tracking,
  String userId,
) async {
  final results = await Future.wait([
    ...insightTrackingTypes.map(
      (type) => tracking.getTrackingHistory(userId: userId, type: type, limit: 30),
    ),
    tracking
        .getTrackingData(userId: userId, date: 'onboarding', type: 'profile')
        .then((p) => p == null ? <Map<String, dynamic>>[] : [p]),
  ]);
  return {
    for (var i = 0; i < insightTrackingTypes.length; i++)
      insightTrackingTypes[i]: results[i],
    'profile': results.last,
  };
}

/// The most recently saved diet entry that holds the user's food lists.
/// Triggers and safe foods are edited as global lists, so the newest save
/// wins regardless of which day it was saved on.
Map<String, dynamic>? _latestFoodLists(List<Map<String, dynamic>> diet) {
  Map<String, dynamic>? best;
  String bestStamp = '';
  for (final entry in diet) {
    if (entry['food_triggers'] == null && entry['safe_foods'] == null) continue;
    final stamp = '${entry['updated_at'] ?? entry['recorded_at'] ?? entry['date'] ?? ''}';
    if (best == null || stamp.compareTo(bestStamp) > 0) {
      best = entry;
      bestStamp = stamp;
    }
  }
  return best;
}

/// Builds the health context for the AI assistant from tracked history.
UserHealthContext buildHealthContext(
  Map<String, List<Map<String, dynamic>>> history,
  List<Map<String, dynamic>> chatHistory,
) {
  final diet = history['diet'] ?? const [];
  final meals = history['meal'] ?? const [];
  final foodLists = _latestFoodLists(diet);
  final profile = history['profile'] ?? const [];
  return UserHealthContext(
    profile: profile.isEmpty ? null : profile.first,
    recentDailyTracking: (history['daily'] ?? const []).take(14).toList(),
    recentSymptoms: (history['symptoms'] ?? const []).take(14).toList(),
    recentSupplements: (history['supplements'] ?? const []).take(7).toList(),
    recentMedications: (history['medications'] ?? const []).take(7).toList(),
    recentLogs: (history['log'] ?? const []).take(7).toList(),
    recentDiet: [
      ...diet.take(7),
      for (final m in meals.take(10))
        {
          'date': m['date'],
          'meals': [
            {'name': 'Meal ${m['time'] ?? ''}'.trim(), 'foods': m['foods'] ?? const []},
          ],
        },
    ],
    foodTriggers: List<String>.from(foodLists?['food_triggers'] ?? const []),
    safeFoods: List<String>.from(foodLists?['safe_foods'] ?? const []),
    chatHistory: chatHistory.map(ChatMessage.fromJson).toList(),
  );
}

/// Owns the single backend instance: Firebase in production, the in-memory
/// mock when built with `USE_MOCK_DATA=true` or when Firebase cannot start.
class BackendServiceProvider {
  static UnifiedBackendService? _instance;
  static Future<void>? _initializing;

  static bool get isInitialized => _instance != null;
  static bool get isMock => _instance?.isMock ?? Environment.useMockData;

  static UnifiedBackendService get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('BackendService not initialized. Await BackendServiceProvider.initialize() first.');
    }
    return instance;
  }

  /// Safe to call repeatedly; concurrent callers share one initialisation.
  static Future<void> initialize() => _initializing ??= _initialize();

  static Future<void> _initialize() async {
    if (Environment.useMockData) {
      debugPrint('BackendServiceProvider: Using offline mock backend');
      _instance = MockBackend.create();
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      _instance = await FirebaseBackend.create();
      debugPrint('BackendServiceProvider: Firebase backend ready');
    } catch (error, stackTrace) {
      debugPrint('BackendServiceProvider: Firebase unavailable, using offline mock: $error');
      debugPrintStack(stackTrace: stackTrace);
      _instance = MockBackend.create();
    }
  }
}
