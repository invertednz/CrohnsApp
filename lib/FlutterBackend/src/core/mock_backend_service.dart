import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:gut_md/services/ai_chat_service.dart';

/// Mock user class that mirrors Supabase User
class MockUser {
  final String id;
  final String email;
  final String? displayName;
  final Map<String, dynamic>? userMetadata;
  final DateTime createdAt;

  MockUser({
    required this.id,
    required this.email,
    this.displayName,
    this.userMetadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Mock implementation of BackendService for development/testing
class MockBackendService {
  MockUser? _currentUser;
  
  MockBackendService._();
  
  static Future<MockBackendService> initialize() async {
    debugPrint('MockBackendService: Initialized');
    return MockBackendService._();
  }
  
  MockAuthService get auth => MockAuthService(this);
  MockTrackingService get tracking => MockTrackingService(this);
  MockInsightsService get insights => MockInsightsService(this);
  MockChatService get chat => MockChatService(this);
}

class MockAuthService {
  final MockBackendService _service;
  
  MockAuthService(this._service);
  
  MockUser? get currentUser => _service._currentUser;
  
  Future<MockUser?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (email.isNotEmpty && password.length >= 6) {
      _service._currentUser = MockUser(
        id: 'mock_user_${email.hashCode}',
        email: email,
        displayName: userData?['name'] ?? email.split('@').first,
        userMetadata: userData,
      );
      debugPrint('MockAuthService: User signed up: ${_service._currentUser?.email}');
      return _service._currentUser;
    }
    
    throw Exception('Invalid email or password (min 6 characters)');
  }

  Future<MockUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Accept any valid-looking credentials for mock
    if (email.isNotEmpty && password.isNotEmpty) {
      _service._currentUser = MockUser(
        id: 'mock_user_${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
      );
      debugPrint('MockAuthService: User signed in: ${_service._currentUser?.email}');
      return _service._currentUser;
    }
    
    throw Exception('Invalid credentials');
  }

  Future<MockUser?> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Auto-login with mock Google account
    _service._currentUser = MockUser(
      id: 'mock_google_user_12345',
      email: 'mockuser@gmail.com',
      displayName: 'Mock Google User',
      userMetadata: {'provider': 'google'},
    );
    debugPrint('MockAuthService: Google sign-in successful');
    return _service._currentUser;
  }

  Future<MockUser?> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Auto-login with mock Apple account
    _service._currentUser = MockUser(
      id: 'mock_apple_user_67890',
      email: 'mockuser@privaterelay.appleid.com',
      displayName: 'Mock Apple User',
      userMetadata: {'provider': 'apple'},
    );
    debugPrint('MockAuthService: Apple sign-in successful');
    return _service._currentUser;
  }
  
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _service._currentUser = null;
    debugPrint('MockAuthService: User signed out');
  }
  
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('MockAuthService: Password reset email sent to $email');
  }
}

class MockTrackingService {
  final MockBackendService _service;
  final Map<String, Map<String, dynamic>> _trackingData = {};
  
  MockTrackingService(this._service);
  
  Future<void> trackEvent({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final key = '$userId-$type-${data['date'] ?? DateTime.now().toIso8601String()}';
    _trackingData[key] = {'type': type, ...data};
    debugPrint('MockTrackingService: Tracked $type for $userId');
  }
  
  Future<Map<String, dynamic>?> getTrackingData({
    required String userId,
    required String date,
    required String type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final key = '$userId-$type-$date';
    return _trackingData[key];
  }
  
  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    required String type,
    int limit = 30,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final results = _trackingData.entries
        .where((e) => e.key.startsWith('$userId-$type-'))
        .map((e) => e.value)
        .toList();
    // Sort by date descending
    results.sort((a, b) {
      final dateA = a['date'] ?? '';
      final dateB = b['date'] ?? '';
      return dateB.compareTo(dateA);
    });
    return results.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getAllTrackingHistory({
    required String userId,
    int limit = 30,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final results = _trackingData.entries
        .where((e) => e.key.startsWith(userId))
        .map((e) => e.value)
        .toList();
    results.sort((a, b) {
      final dateA = a['date'] ?? '';
      final dateB = b['date'] ?? '';
      return dateB.compareTo(dateA);
    });
    return results.take(limit).toList();
  }
}

class MockInsightsService {
  final MockBackendService _service;
  
  MockInsightsService(this._service);
  
  Future<Map<String, dynamic>> getInsights({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'symptomTrends': [
        {'day': 'Mon', 'severity': 2},
        {'day': 'Tue', 'severity': 3},
        {'day': 'Wed', 'severity': 2},
        {'day': 'Thu', 'severity': 4},
        {'day': 'Fri', 'severity': 3},
      ],
      'topTriggers': ['Dairy', 'Stress', 'Lack of Sleep'],
      'recommendations': [
        'Consider keeping a food diary',
        'Try stress-reduction techniques',
        'Maintain consistent sleep schedule',
      ],
    };
  }
}

class MockChatService {
  final MockBackendService _service;
  final Map<String, List<Map<String, dynamic>>> _chatHistory = {};
  late final AIChatService _aiChatService;
  
  MockChatService(this._service) {
    _aiChatService = AIChatService.fromEnvironment();
  }
  
  Future<String> sendMessage({
    required String userId,
    required String message,
  }) async {
    // Initialize chat history for user if not exists
    _chatHistory[userId] ??= [];
    
    // Save user message to history
    _chatHistory[userId]!.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': message,
      'isUser': true,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Gather user health context
    final context = await _buildUserContext(userId);
    
    // Generate AI response
    final response = await _aiChatService.generateResponse(
      userMessage: message,
      context: context,
    );
    
    // Save assistant response to history
    _chatHistory[userId]!.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': response,
      'isUser': false,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return response;
  }
  
  Future<UserHealthContext> _buildUserContext(String userId) async {
    final tracking = _service.tracking;
    
    // Get recent tracking data
    final dailyTracking = await tracking.getTrackingHistory(
      userId: userId,
      type: 'daily',
      limit: 14,
    );
    
    final symptoms = await tracking.getTrackingHistory(
      userId: userId,
      type: 'symptoms',
      limit: 14,
    );
    
    final supplements = await tracking.getTrackingHistory(
      userId: userId,
      type: 'supplements',
      limit: 7,
    );
    
    final diet = await tracking.getTrackingHistory(
      userId: userId,
      type: 'diet',
      limit: 7,
    );
    
    // Extract food triggers and safe foods from diet data
    List<String> foodTriggers = [];
    List<String> safeFoods = [];
    if (diet.isNotEmpty) {
      foodTriggers = List<String>.from(diet.first['food_triggers'] ?? []);
      safeFoods = List<String>.from(diet.first['safe_foods'] ?? []);
    }
    
    // Convert chat history to ChatMessage objects
    final chatMessages = (_chatHistory[userId] ?? [])
        .map((m) => ChatMessage.fromJson(m))
        .toList();
    
    return UserHealthContext(
      recentDailyTracking: dailyTracking,
      recentSymptoms: symptoms,
      recentSupplements: supplements,
      recentDiet: diet,
      foodTriggers: foodTriggers,
      safeFoods: safeFoods,
      chatHistory: chatMessages,
    );
  }
  
  Future<List<Map<String, dynamic>>> getChatHistory({
    required String userId,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final history = _chatHistory[userId] ?? [];
    return history.take(limit).toList();
  }
  
  Future<void> clearChatHistory(String userId) async {
    _chatHistory[userId] = [];
  }
}
