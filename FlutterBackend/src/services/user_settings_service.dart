import '../core/supabase_client.dart';
import '../models/user_model.dart';

/// Service for managing user settings and onboarding data
class UserSettingsService {
  final SupabaseClient _supabaseClient;
  final String _tableName = 'user_settings';
  
  /// Constructor that takes a Supabase client
  UserSettingsService(this._supabaseClient);

  /// Get all settings for a user
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final response = await _supabaseClient.db
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .execute();

      if (response.data == null || (response.data as List).isEmpty) {
        return {};
      }

      final settings = <String, dynamic>{};
      for (final row in response.data as List) {
        settings[row['key']] = row['value'];
      }
      return settings;
    } catch (e) {
      print('Error getting user settings: $e');
      return {};
    }
  }

  /// Get a specific setting for a user
  Future<dynamic> getSetting(String userId, String key) async {
    try {
      final response = await _supabaseClient.db
          .from(_tableName)
          .select('value')
          .eq('user_id', userId)
          .eq('key', key)
          .single()
          .execute();

      if (response.data == null) {
        return null;
      }
      return response.data['value'];
    } catch (e) {
      print('Error getting setting $key: $e');
      return null;
    }
  }

  /// Save a setting for a user
  Future<bool> saveSetting(String userId, String key, dynamic value) async {
    try {
      // Check if the setting already exists
      final existing = await _supabaseClient.db
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('key', key)
          .execute();

      if (existing.data != null && (existing.data as List).isNotEmpty) {
        // Update existing setting
        await _supabaseClient.db
            .from(_tableName)
            .update({
              'value': value,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('key', key)
            .execute();
      } else {
        // Insert new setting
        await _supabaseClient.db.from(_tableName).insert({
          'user_id': userId,
          'key': key,
          'value': value,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).execute();
      }
      return true;
    } catch (e) {
      print('Error saving setting $key: $e');
      return false;
    }
  }

  /// Save multiple settings for a user in a batch
  Future<bool> saveSettings(
      String userId, Map<String, dynamic> settings) async {
    try {
      // Use a transaction to ensure all settings are saved atomically
      await _supabaseClient.db.rpc('save_user_settings', params: {
        'p_user_id': userId,
        'p_settings': settings,
      }).execute();
      return true;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  /// Delete a setting for a user
  Future<bool> deleteSetting(String userId, String key) async {
    try {
      await _supabaseClient.db
          .from(_tableName)
          .delete()
          .eq('user_id', userId)
          .eq('key', key)
          .execute();
      return true;
    } catch (e) {
      print('Error deleting setting $key: $e');
      return false;
    }
  }

  /// Save onboarding data for a user
  Future<bool> saveOnboardingData(
      String userId, Map<String, dynamic> data) async {
    try {
      // Store onboarding data as a collection of settings
      return await saveSettings(userId, {
        'onboarding_completed': true,
        'onboarding_data': data,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving onboarding data: $e');
      return false;
    }
  }

  /// Get onboarding data for a user
  Future<Map<String, dynamic>> getOnboardingData(String userId) async {
    try {
      final settings = await getUserSettings(userId);
      if (!settings.containsKey('onboarding_data')) {
        return {};
      }
      return settings['onboarding_data'] as Map<String, dynamic>;
    } catch (e) {
      print('Error getting onboarding data: $e');
      return {};
    }
  }

  /// Check if a user has completed onboarding
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final completed = await getSetting(userId, 'onboarding_completed');
      return completed == true;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }