import '../core/supabase_client.dart';
import '../models/user_model.dart';

/// Service for managing user referrals
class ReferralService {
  final SupabaseClient _supabaseClient;
  final String _referralsTable = 'referrals';
  final String _referralCodesTable = 'referral_codes';
  
  /// Constructor that takes a Supabase client
  ReferralService(this._supabaseClient);
  
  /// Generate a unique referral code for a user
  /// If a code already exists, return the existing code
  Future<String?> generateReferralCode(String userId) async {
    try {
      // Check if user already has a referral code
      final existingCode = await getReferralCode(userId);
      if (existingCode != null) {
        return existingCode;
      }
      
      // Generate a new unique code (alphanumeric, 8 characters)
      final code = _generateUniqueCode();
      
      // Store the code in the database
      await _supabaseClient.db.from(_referralCodesTable).insert({
        'user_id': userId,
        'code': code,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      }).execute();
      
      return code;
    } catch (e) {
      print('Error generating referral code: $e');
      return null;
    }
  }
  
  /// Get a user's referral code
  Future<String?> getReferralCode(String userId) async {
    try {
      final response = await _supabaseClient.db
          .from(_referralCodesTable)
          .select('code')
          .eq('user_id', userId)
          .eq('is_active', true)
          .single()
          .execute();
      
      if (response.data == null) {
        return null;
      }
      
      return response.data['code'] as String;
    } catch (e) {
      print('Error getting referral code: $e');
      return null;
    }
  }
  
  /// Track a referral when a new user signs up using a referral code
  Future<bool> trackReferral(String referralCode, String newUserId) async {
    try {
      // Find the referrer user ID from the code
      final response = await _supabaseClient.db
          .from(_referralCodesTable)
          .select('user_id')
          .eq('code', referralCode)
          .eq('is_active', true)
          .single()
          .execute();
      
      if (response.data == null) {
        return false; // Invalid or inactive referral code
      }
      
      final referrerId = response.data['user_id'] as String;
      
      // Record the referral relationship
      await _supabaseClient.db.from(_referralsTable).insert({
        'referrer_id': referrerId,
        'referred_id': newUserId,
        'referral_code': referralCode,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending', // Initial status, can be updated later
      }).execute();
      
      return true;
    } catch (e) {
      print('Error tracking referral: $e');
      return false;
    }
  }
  
  /// Get users referred by a specific user
  Future<List<Map<String, dynamic>>> getReferredUsers(String userId) async {
    try {
      final response = await _supabaseClient.db
          .from(_referralsTable)
          .select('referred_id, created_at, status')
          .eq('referrer_id', userId)
          .order('created_at', ascending: false)
          .execute();
      
      if (response.data == null) {
        return [];
      }
      
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting referred users: $e');
      return [];
    }
  }
  
  /// Get the user who referred the current user
  Future<String?> getReferrerUserId(String userId) async {
    try {
      final response = await _supabaseClient.db
          .from(_referralsTable)
          .select('referrer_id')
          .eq('referred_id', userId)
          .single()
          .execute();
      
      if (response.data == null) {
        return null;
      }
      
      return response.data['referrer_id'] as String;
    } catch (e) {
      print('Error getting referrer: $e');
      return null;
    }
  }
  
  /// Update the status of a referral (e.g., from 'pending' to 'completed')
  Future<bool> updateReferralStatus(String referrerId, String referredId, String status) async {
    try {
      await _supabaseClient.db
          .from(_referralsTable)
          .update({'status': status})
          .eq('referrer_id', referrerId)
          .eq('referred_id', referredId)
          .execute();
      
      return true;
    } catch (e) {
      print('Error updating referral status: $e');
      return false;
    }
  }
  
  /// Get referral statistics for a user
  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      // This assumes you have a stored procedure or function in Supabase
      // that can calculate referral statistics
      final response = await _supabaseClient.db.rpc('get_referral_stats', params: {
        'p_user_id': userId,
      }).execute();
      
      if (response.data == null) {
        // Return default stats if no data
        return {
          'total_referrals': 0,
          'pending_referrals': 0,
          'completed_referrals': 0,
        };
      }
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting referral stats: $e');
      return {
        'total_referrals': 0,
        'pending_referrals': 0,
        'completed_referrals': 0,
      };
    }
  }
  
  /// Generate a unique alphanumeric code
  String _generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final code = List.generate(8, (index) {
      final randomIndex = (random.codeUnitAt(index % random.length) + index) % chars.length;
      return chars[randomIndex];
    }).join();
    
    return code;
  }
}