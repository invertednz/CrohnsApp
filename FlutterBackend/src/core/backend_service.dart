import 'supabase_client.dart';
import 'service_factory.dart';
import 'default_service_factory.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/user_settings_service.dart';
import '../services/tracking_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/insights_service.dart';
import '../services/chat_service.dart';
import '../services/referral_service.dart';

/// A centralized service manager that provides access to all backend services
class BackendService {
  final SupabaseClient _supabaseClient;
  final ServiceFactory _serviceFactory;
  late final AuthService _authService;
  late final ProfileService _profileService;
  late final UserSettingsService _userSettingsService;
  late final TrackingService _trackingService;
  late final StorageService _storageService;
  late final NotificationService _notificationService;
  late final InsightsService _insightsService;
  late final ChatService _chatService;
  late final ReferralService _referralService;
  
  /// Constructor that initializes all services using the provided service factory
  BackendService(this._supabaseClient, {ServiceFactory? serviceFactory}) : 
      _serviceFactory = serviceFactory ?? DefaultServiceFactory() {
    _initializeServices();
  }
  
  /// Initialize all services using the service factory
  void _initializeServices() {
    _authService = _serviceFactory.createAuthService(_supabaseClient);
    _profileService = _serviceFactory.createProfileService(_supabaseClient);
    _userSettingsService = _serviceFactory.createUserSettingsService(_supabaseClient);
    _trackingService = _serviceFactory.createTrackingService(_supabaseClient);
    _storageService = _serviceFactory.createStorageService(_supabaseClient);
    _notificationService = _serviceFactory.createNotificationService(_supabaseClient);
    _insightsService = _serviceFactory.createInsightsService(_supabaseClient);
    _chatService = _serviceFactory.createChatService(_supabaseClient);
    _referralService = _serviceFactory.createReferralService(_supabaseClient);
  }
  
  /// Get the Supabase client
  SupabaseClient get supabaseClient => _supabaseClient;
  
  /// Get the authentication service
  AuthService get auth => _authService;
  
  /// Get the profile service
  ProfileService get profile => _profileService;
  
  /// Get the user settings service
  UserSettingsService get userSettings => _userSettingsService;
  
  /// Get the tracking service
  TrackingService get tracking => _trackingService;
  
  /// Get the storage service
  StorageService get storage => _storageService;
  
  /// Get the notification service
  NotificationService get notifications => _notificationService;
  
  /// Get the insights service
  InsightsService get insights => _insightsService;
  
  /// Get the chat service
  ChatService get chat => _chatService;
  
  /// Get the referral service
  ReferralService get referrals => _referralService;
  
  /// Initialize the backend service with Supabase credentials
  /// Optionally provide a custom service factory for app-specific implementations
  static Future<BackendService> initialize({
    required String supabaseUrl,
    required String supabaseKey,
    ServiceFactory? serviceFactory,
  }) async {
    final client = await SupabaseClient.initialize(
      supabaseUrl: supabaseUrl,
      supabaseKey: supabaseKey,
    );
    
    return BackendService(client, serviceFactory: serviceFactory);
  }
}