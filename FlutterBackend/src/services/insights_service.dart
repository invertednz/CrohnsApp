import '../core/supabase_client.dart';
import '../models/user_model.dart';

/// Service for generating and retrieving insights for users
class InsightsService {
  final SupabaseClient _supabaseClient;
  final String _tableName = 'user_insights';
  
  /// Constructor that takes a Supabase client
  InsightsService(this._supabaseClient);
  
  /// Generate insights for a user based on their tracking data
  Future<bool> generateInsights(String userId) async {
    try {
      // This would call an external AI service or a Supabase Edge Function
      // that processes the user's data and generates insights
      final response = await _supabaseClient.db.rpc('generate_user_insights', params: {
        'p_user_id': userId,
      }).execute();
      
      if (response.error != null) {
        print('Error generating insights: ${response.error!.message}');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error generating insights: $e');
      return false;
    }
  }
  
  /// Get all insights for a user
  Future<List<Map<String, dynamic>>> getInsights(String userId, {
    int limit = 50,
    int offset = 0,
    String? category,
  }) async {
    try {
      var query = _supabaseClient.db
          .from(_tableName)
          .select()
          .eq('user_id', userId);
      
      if (category != null) {
        query = query.eq('category', category);
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
      print('Error getting insights: $e');
      return [];
    }
  }
  
  /// Get a specific insight by ID
  Future<Map<String, dynamic>?> getInsight(String insightId) async {
    try {
      final response = await _supabaseClient.db
          .from(_tableName)
          .select()
          .eq('id', insightId)
          .single()
          .execute();
      
      if (response.data == null) {
        return null;
      }
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting insight: $e');
      return null;
    }
  }
  
  /// Mark an insight as read
  Future<bool> markInsightAsRead(String insightId) async {
    try {
      await _supabaseClient.db
          .from(_tableName)
          .update({
            'read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', insightId)
          .execute();
      
      return true;
    } catch (e) {
      print('Error marking insight as read: $e');
      return false;
    }
  }
  
  /// Get the latest insights for a user
  Future<List<Map<String, dynamic>>> getLatestInsights(String userId, {
    int limit = 5,
  }) async {
    return getInsights(userId, limit: limit);
  }
  
  /// Check if a user has new insights
  Future<bool> hasNewInsights(String userId) async {
    try {
      final response = await _supabaseClient.db
          .from(_tableName)
          .select('count', { count: 'exact' })
          .eq('user_id', userId)
          .eq('read', false)
          .execute();
      
      if (response.count == null) {
        return false;
      }
      
      return response.count > 0;
    } catch (e) {
      print('Error checking for new insights: $e');
      return false;
    }
  }
  
  /// Schedule weekly insight generation for all users
  /// This would typically be called by a cron job or scheduled function
  static Future<bool> scheduleWeeklyInsights(SupabaseClient client) async {
    try {
      // This would call a Supabase Edge Function or other scheduled job
      final response = await client.db.rpc('schedule_weekly_insights').execute();
      
      if (response.error != null) {
        print('Error scheduling insights: ${response.error!.message}');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error scheduling insights: $e');
      return false;
    }
  }
}