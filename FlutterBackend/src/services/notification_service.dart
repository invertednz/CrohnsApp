import '../core/supabase_client.dart';
import '../models/user_model.dart';

/// Service for handling notifications
class NotificationService {
  final SupabaseClient _supabaseClient;
  final String _tableName = 'notifications';
  
  /// Constructor that takes a Supabase client
  NotificationService(this._supabaseClient);
  
  /// Create a notification for a user
  Future<bool> createNotification(String userId, {
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> data = const {},
    DateTime? scheduledFor,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      
      await _supabaseClient.db.from(_tableName).insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'read': false,
        'created_at': timestamp,
        'scheduled_for': scheduledFor?.toIso8601String() ?? timestamp,
      }).execute();
      
      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }
  
  /// Get all notifications for a user
  Future<List<Map<String, dynamic>>> getNotifications(String userId, {
    bool onlyUnread = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabaseClient.db
          .from(_tableName)
          .select()
          .eq('user_id', userId);
      
      if (onlyUnread) {
        query = query.eq('read', false);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1)
          .execute();
      
      if (response.data == null) {
        return [];
      }
      
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }
  
  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabaseClient.db
          .from(_tableName)
          .update({
            'read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .execute();
      
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }
  
  /// Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _supabaseClient.db
          .from(_tableName)
          .update({
            'read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('read', false)
          .execute();
      
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
  
  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabaseClient.db
          .from(_tableName)
          .delete()
          .eq('id', notificationId)
          .execute();
      
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
  
  /// Get a stream of new notifications for a user
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _supabaseClient.db
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data.cast<Map<String, dynamic>>();
        });
  }
  
  /// Create a tracking reminder notification
  Future<bool> createTrackingReminder(String userId, String trackingType) async {
    return createNotification(
      userId,
      title: 'Tracking Reminder',
      body: 'Don\'t forget to track your $trackingType today!',
      type: 'tracking_reminder',
      data: {
        'tracking_type': trackingType,
      },
    );
  }
  
  /// Create an insights notification
  Future<bool> createInsightsNotification(String userId, String insightTitle) async {
    return createNotification(
      userId,
      title: 'New Insight Available',
      body: 'Check out your new insight: $insightTitle',
      type: 'new_insight',
      data: {
        'insight_title': insightTitle,
      },
    );
  }
}