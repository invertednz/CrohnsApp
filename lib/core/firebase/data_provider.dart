/// Abstract interface for data access
/// Implementations can provide real Firebase data or mock data
abstract class DataProvider {
  /// Initialize the data provider
  Future<void> initialize();

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId);

  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data);

  /// Get health tracking data
  Future<List<Map<String, dynamic>>> getHealthData(String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Save health tracking entry
  Future<void> saveHealthData(String userId, Map<String, dynamic> data);

  /// Get notification preferences
  Future<Map<String, dynamic>?> getNotificationPreferences(String userId);

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );

  /// Sign in user
  Future<String?> signIn(String email, String password);

  /// Sign out current user
  Future<void> signOut();

  /// Get current user ID
  String? getCurrentUserId();

  /// Check if user is authenticated
  bool isAuthenticated();
}
