import '../core/supabase_client.dart';
import '../models/user_model.dart';

/// Service for tracking user activity and metrics
class TrackingService {
  final SupabaseClient _supabaseClient;
  final String _tableName = 'user_tracking';
  
  /// Constructor that takes a Supabase client
  TrackingService(this._supabaseClient);
  
  /// Track an event for a user
  Future<bool> trackEvent(String userId, String eventType, Map<String, dynamic> data) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      
      await _supabaseClient.db.from(_tableName).insert({
        'user_id': userId,
        'event_type': eventType,
        'data': data,
        'timestamp': timestamp,
        'created_at': timestamp,
      }).execute();
      
      return true;
    } catch (e) {
      print('Error tracking event: $e');
      return false;
    }
  }
  
  /// Get tracking data for a user within a date range
  Future<List<Map<String, dynamic>>> getTrackingData(
      String userId, String eventType, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabaseClient.db
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('event_type', eventType)
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false)
          .execute();
      
      if (response.data == null) {
        return [];
      }
      
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting tracking data: $e');
      return [];
    }
  }
  
  /// Get tracking data for a user for a specific day
  Future<List<Map<String, dynamic>>> getTrackingDataForDay(
      String userId, String eventType, DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    
    return getTrackingData(userId, eventType, startOfDay, endOfDay);
  }
  
  /// Check if a user has tracked an event for a specific day
  Future<bool> hasTrackedForDay(String userId, String eventType, DateTime day) async {
    final data = await getTrackingDataForDay(userId, eventType, day);
    return data.isNotEmpty;
  }
  
  /// Get tracking summary for a user within a date range
  Future<Map<String, dynamic>> getTrackingSummary(
      String userId, String eventType, DateTime startDate, DateTime endDate) async {
    try {
      // This assumes you have a stored procedure or function in Supabase
      // that can calculate summaries
      final response = await _supabaseClient.db.rpc('get_tracking_summary', params: {
        'p_user_id': userId,
        'p_event_type': eventType,
        'p_start_date': startDate.toIso8601String(),
        'p_end_date': endDate.toIso8601String(),
      }).execute();
      
      if (response.data == null) {
        return {};
      }
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting tracking summary: $e');
      return {};
    }
  }
  
  /// Delete tracking data for a user
  Future<bool> deleteTrackingData(String userId, String eventType, DateTime? before) async {
    try {
      var query = _supabaseClient.db
          .from(_tableName)
          .delete()
          .eq('user_id', userId);
      
      if (eventType.isNotEmpty) {
        query = query.eq('event_type', eventType);
      }
      
      if (before != null) {
        query = query.lte('timestamp', before.toIso8601String());
      }
      
      await query.execute();
      return true;
    } catch (e) {
      print('Error deleting tracking data: $e');
      return false;
    }
  }
}