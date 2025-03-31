import 'service_factory.dart';
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

/// Default implementation of the service factory
/// Creates the standard service implementations
class DefaultServiceFactory implements ServiceFactory {
  @override
  AuthService createAuthService(SupabaseClient supabaseClient) {
    return AuthService(supabaseClient);
  }
  
  @override
  ProfileService createProfileService(SupabaseClient supabaseClient) {
    return ProfileService(supabaseClient);
  }
  
  @override
  UserSettingsService createUserSettingsService(SupabaseClient supabaseClient) {
    return UserSettingsService(supabaseClient);
  }
  
  @override
  TrackingService createTrackingService(SupabaseClient supabaseClient) {
    return TrackingService(supabaseClient);
  }
  
  @override
  StorageService createStorageService(SupabaseClient supabaseClient) {
    return StorageService(supabaseClient);
  }
  
  @override
  NotificationService createNotificationService(SupabaseClient supabaseClient) {
    return NotificationService(supabaseClient);
  }
  
  @override
  InsightsService createInsightsService(SupabaseClient supabaseClient) {
    return InsightsService(supabaseClient);
  }
  
  @override
  ChatService createChatService(SupabaseClient supabaseClient) {
    return ChatService(supabaseClient);
  }
  
  @override
  ReferralService createReferralService(SupabaseClient supabaseClient) {
    return ReferralService(supabaseClient);
  }
}