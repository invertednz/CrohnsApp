import '../core/supabase_client.dart';
import '../models/user_model.dart';

/// Service for managing user profiles
class ProfileService {
  final SupabaseClient _supabaseClient;
  final String _tableName = 'profiles';
  
  /// Constructor that takes a Supabase client
  ProfileService(this._supabaseClient);
  
  /// Get a user's profile
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _supabaseClient.db
          .from(_tableName)
          .select()
          .eq('id', userId)
          .single()
          .execute();
      
      if (response.data == null) {
        return null;
      }
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }
  
  /// Create or update a user's profile
  Future<bool> upsertProfile(String userId, Map<String, dynamic> data) async {
    try {
      // Ensure the ID is set
      data['id'] = userId;
      data['updated_at'] = DateTime.now().toIso8601String();
      
      // Check if the profile exists
      final existing = await getProfile(userId);
      
      if (existing == null) {
        // Create a new profile
        data['created_at'] = DateTime.now().toIso8601String();
        await _supabaseClient.db
            .from(_tableName)
            .insert(data)
            .execute();
      } else {
        // Update the existing profile
        await _supabaseClient.db
            .from(_tableName)
            .update(data)
            .eq('id', userId)
            .execute();
      }
      
      return true;
    } catch (e) {
      print('Error upserting profile: $e');
      return false;
    }
  }
  
  /// Update specific fields in a user's profile
  Future<bool> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabaseClient.db
          .from(_tableName)
          .update(data)
          .eq('id', userId)
          .execute();
      
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
  
  /// Get a stream of profile changes for a user
  Stream<Map<String, dynamic>?> watchProfile(String userId) {
    return _supabaseClient.db
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) {
            return null;
          }
          return data.first as Map<String, dynamic>;
        });
  }
}