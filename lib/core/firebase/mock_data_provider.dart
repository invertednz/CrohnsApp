import 'package:flutter/foundation.dart';

import 'data_provider.dart';

/// Mock implementation of DataProvider for testing and development
class MockDataProvider implements DataProvider {
  // In-memory storage for mock data
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, List<Map<String, dynamic>>> _healthData = {};
  final Map<String, Map<String, dynamic>> _notificationPreferences = {};
  String? _currentUserId;

  @override
  Future<void> initialize() async {
    debugPrint('MockDataProvider: Initialized with mock data');
    
    // Seed some default mock data
    _currentUserId = 'mock_user_123';
    _users[_currentUserId!] = {
      'name': 'Test User',
      'email': 'test@example.com',
      'age': 30,
      'diagnosedYear': 2020,
    };

    _healthData[_currentUserId!] = [
      {
        'id': 'entry_1',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'symptomSeverity': 3,
        'notes': 'Mild discomfort after lunch',
        'meals': ['Salad', 'Chicken'],
      },
      {
        'id': 'entry_2',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'symptomSeverity': 5,
        'notes': 'Moderate pain, took medication',
        'meals': ['Pasta', 'Bread'],
      },
    ];

    _notificationPreferences[_currentUserId!] = {
      'morningReminder': true,
      'morningTime': '09:00',
      'eveningReminder': true,
      'eveningTime': '21:00',
      'medicationReminders': true,
      'symptomTracking': true,
    };
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate network delay
    return _users[userId];
  }

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _users[userId] = {..._users[userId] ?? {}, ...data};
    debugPrint('MockDataProvider: Updated user profile for $userId');
  }

  @override
  Future<List<Map<String, dynamic>>> getHealthData(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final data = _healthData[userId] ?? [];
    
    if (startDate == null && endDate == null) {
      return List.from(data);
    }

    return data.where((entry) {
      final date = entry['date'] as DateTime;
      if (startDate != null && date.isBefore(startDate)) return false;
      if (endDate != null && date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> saveHealthData(String userId, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _healthData[userId] ??= [];
    _healthData[userId]!.add({
      ...data,
      'id': 'mock_entry_${DateTime.now().millisecondsSinceEpoch}',
    });
    debugPrint('MockDataProvider: Saved health data for $userId');
  }

  @override
  Future<Map<String, dynamic>?> getNotificationPreferences(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _notificationPreferences[userId];
  }

  @override
  Future<void> updateNotificationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notificationPreferences[userId] = {
      ..._notificationPreferences[userId] ?? {},
      ...preferences,
    };
    debugPrint('MockDataProvider: Updated notification preferences for $userId');
  }

  @override
  Future<String?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock authentication - accept any credentials for testing
    if (email.isNotEmpty && password.isNotEmpty) {
      _currentUserId = 'mock_user_${email.hashCode}';
      debugPrint('MockDataProvider: User signed in with ID $_currentUserId');
      return _currentUserId;
    }
    
    return null;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUserId = null;
    debugPrint('MockDataProvider: User signed out');
  }

  @override
  String? getCurrentUserId() {
    return _currentUserId;
  }

  @override
  bool isAuthenticated() {
    return _currentUserId != null;
  }
}
