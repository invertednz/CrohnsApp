import 'supabase_client.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/user_settings_service.dart';
import '../services/tracking_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/insights_service.dart';
import '../services/chat_service.dart';
import '../services/referral_service.dart';

/// Interface for creating app-specific service implementations
/// Each app will provide its own implementation of this factory
abstract class ServiceFactory {
  /// Create an authentication service
  AuthService createAuthService(SupabaseClient supabaseClient);
  
  /// Create a profile service
  ProfileService createProfileService(SupabaseClient supabaseClient);
  
  /// Create a user settings service
  UserSettingsService createUserSettingsService(SupabaseClient supabaseClient);
  
  /// Create a tracking service
  TrackingService createTrackingService(SupabaseClient supabaseClient);
  
  /// Create a storage service
  StorageService createStorageService(SupabaseClient supabaseClient);
  
  /// Create a notification service
  NotificationService createNotificationService(SupabaseClient supabaseClient);
  
  /// Create an insights service
  InsightsService createInsightsService(SupabaseClient supabaseClient);
  
  /// Create a chat service
  ChatService createChatService(SupabaseClient supabaseClient);
  
  /// Create a referral service
  ReferralService createReferralService(SupabaseClient supabaseClient);
}