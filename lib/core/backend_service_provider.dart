import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import the backend services and environment
import '../FlutterBackend/src/core/backend_service.dart';
import '../FlutterBackend/src/core/mock_backend_service.dart';
import '../core/environment.dart';

/// Unified auth interface for both mock and real services
abstract class UnifiedAuthService {
  dynamic get currentUser;
  Future<dynamic> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  });
  Future<dynamic> signInWithEmail({
    required String email,
    required String password,
  });
  Future<dynamic> signInWithGoogle();
  Future<dynamic> signInWithApple();
  Future<void> signOut();
}

/// Wrapper for real Supabase auth
class _RealAuthWrapper implements UnifiedAuthService {
  final AuthService _authService;
  _RealAuthWrapper(this._authService);
  
  @override
  dynamic get currentUser => _authService.currentUser;
  
  @override
  Future<dynamic> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) => _authService.signUpWithEmail(email: email, password: password, userData: userData);
  
  @override
  Future<dynamic> signInWithEmail({required String email, required String password}) =>
      _authService.signInWithEmail(email: email, password: password);
  
  @override
  Future<dynamic> signInWithGoogle() => _authService.signInWithGoogle();
  
  @override
  Future<dynamic> signInWithApple() => _authService.signInWithApple();
  
  @override
  Future<void> signOut() => _authService.signOut();
}

/// Wrapper for mock auth
class _MockAuthWrapper implements UnifiedAuthService {
  final MockAuthService _authService;
  _MockAuthWrapper(this._authService);
  
  @override
  dynamic get currentUser => _authService.currentUser;
  
  @override
  Future<dynamic> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) => _authService.signUpWithEmail(email: email, password: password, userData: userData);
  
  @override
  Future<dynamic> signInWithEmail({required String email, required String password}) =>
      _authService.signInWithEmail(email: email, password: password);
  
  @override
  Future<dynamic> signInWithGoogle() => _authService.signInWithGoogle();
  
  @override
  Future<dynamic> signInWithApple() => _authService.signInWithApple();
  
  @override
  Future<void> signOut() => _authService.signOut();
}

/// Unified tracking interface
abstract class UnifiedTrackingService {
  Future<void> trackEvent({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  });
  Future<Map<String, dynamic>?> getTrackingData({
    required String userId,
    required String date,
    required String type,
  });
  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    required String type,
    int limit = 30,
  });
}

/// Unified insights interface
abstract class UnifiedInsightsService {
  Future<Map<String, dynamic>?> getUserInsights(String userId);
  Future<void> generateInsights(String userId);
}

/// Unified chat interface
abstract class UnifiedChatService {
  Future<String> sendMessage(String userId, String message);
  Future<List<Map<String, dynamic>>> getChatHistory(String userId);
}

/// Wrapper for real tracking
class _RealTrackingWrapper implements UnifiedTrackingService {
  final TrackingService _service;
  _RealTrackingWrapper(this._service);
  
  @override
  Future<void> trackEvent({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) => _service.trackEvent(userId: userId, type: type, data: data);
  
  @override
  Future<Map<String, dynamic>?> getTrackingData({
    required String userId,
    required String date,
    required String type,
  }) => _service.getTrackingData(userId: userId, date: date, type: type);

  @override
  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    required String type,
    int limit = 30,
  }) => _service.getTrackingHistory(userId: userId, type: type, limit: limit);
}

/// Wrapper for mock tracking
class _MockTrackingWrapper implements UnifiedTrackingService {
  final MockTrackingService _service;
  _MockTrackingWrapper(this._service);
  
  @override
  Future<void> trackEvent({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) => _service.trackEvent(userId: userId, type: type, data: data);
  
  @override
  Future<Map<String, dynamic>?> getTrackingData({
    required String userId,
    required String date,
    required String type,
  }) => _service.getTrackingData(userId: userId, date: date, type: type);

  @override
  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    required String type,
    int limit = 30,
  }) => _service.getTrackingHistory(userId: userId, type: type, limit: limit);
}

/// Wrapper for real insights
class _RealInsightsWrapper implements UnifiedInsightsService {
  final InsightsService _service;
  _RealInsightsWrapper(this._service);
  
  @override
  Future<Map<String, dynamic>?> getUserInsights(String userId) =>
      _service.getUserInsights(userId);
  
  @override
  Future<void> generateInsights(String userId) =>
      _service.generateInsights(userId);
}

/// Wrapper for mock insights
class _MockInsightsWrapper implements UnifiedInsightsService {
  final MockInsightsService _service;
  _MockInsightsWrapper(this._service);
  
  @override
  Future<Map<String, dynamic>?> getUserInsights(String userId) =>
      _service.getInsights(userId: userId);
  
  @override
  Future<void> generateInsights(String userId) async {
    // Mock implementation - no-op
  }
}

/// Wrapper for real chat
class _RealChatWrapper implements UnifiedChatService {
  final ChatService _service;
  _RealChatWrapper(this._service);
  
  @override
  Future<String> sendMessage(String userId, String message) =>
      _service.sendMessage(userId, message);
  
  @override
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) =>
      _service.getChatHistory(userId);
}

/// Wrapper for mock chat
class _MockChatWrapper implements UnifiedChatService {
  final MockChatService _service;
  _MockChatWrapper(this._service);
  
  @override
  Future<String> sendMessage(String userId, String message) =>
      _service.sendMessage(userId: userId, message: message);
  
  @override
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) =>
      _service.getChatHistory(userId: userId);
}

/// Unified backend service that works with both mock and real implementations
class UnifiedBackendService {
  final UnifiedAuthService auth;
  final UnifiedTrackingService tracking;
  final UnifiedInsightsService insights;
  final UnifiedChatService chat;
  final bool isMock;
  
  UnifiedBackendService._({
    required this.auth,
    required this.tracking,
    required this.insights,
    required this.chat,
    required this.isMock,
  });
  
  static Future<UnifiedBackendService> initializeMock() async {
    final mockService = await MockBackendService.initialize();
    return UnifiedBackendService._(
      auth: _MockAuthWrapper(mockService.auth),
      tracking: _MockTrackingWrapper(mockService.tracking),
      insights: _MockInsightsWrapper(mockService.insights),
      chat: _MockChatWrapper(mockService.chat),
      isMock: true,
    );
  }
  
  static Future<UnifiedBackendService> initializeReal({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    final realService = await BackendService.initialize(
      supabaseUrl: supabaseUrl,
      supabaseKey: supabaseKey,
    );
    return UnifiedBackendService._(
      auth: _RealAuthWrapper(realService.auth),
      tracking: _RealTrackingWrapper(realService.tracking),
      insights: _RealInsightsWrapper(realService.insights),
      chat: _RealChatWrapper(realService.chat),
      isMock: false,
    );
  }
}

/// A provider class that manages the initialization and access to the BackendService
class BackendServiceProvider {
  static UnifiedBackendService? _instance;
  static const _secureStorage = FlutterSecureStorage();
  static const _supabaseUrlKey = 'supabase_url';
  static const _supabaseAnonKey = 'supabase_anon_key';
  
  /// Check if using mock mode
  static bool get isMock => _instance?.isMock ?? false;
  
  /// Get the BackendService instance
  static UnifiedBackendService get instance {
    if (_instance == null) {
      throw Exception('BackendService not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the BackendService with Supabase credentials or mock mode
  static Future<void> initialize() async {
    if (_instance != null) return;
    
    // Initialize environment configuration
    await Environment.initialize();
    
    // Check if we should use mock mode
    final useMockData = Environment.useMockData;
    
    if (useMockData) {
      debugPrint('BackendServiceProvider: Using MOCK mode');
      _instance = await UnifiedBackendService.initializeMock();
      debugPrint('BackendServiceProvider: Mock service initialized successfully');
      return;
    }
    
    // Real mode - use Supabase
    debugPrint('BackendServiceProvider: Using REAL Supabase mode');
    
    // Get Supabase credentials from environment
    String supabaseUrl = Environment.supabaseUrl;
    String supabaseKey = Environment.supabaseAnonKey;
    
    try {
      // Try to get stored credentials
      final storedUrl = await _secureStorage.read(key: _supabaseUrlKey);
      final storedKey = await _secureStorage.read(key: _supabaseAnonKey);
      
      if (storedUrl != null && storedKey != null) {
        supabaseUrl = storedUrl;
        supabaseKey = storedKey;
      }
    } catch (e) {
      debugPrint('Error reading Supabase credentials from secure storage: $e');
    }
    
    // Initialize the real BackendService
    _instance = await UnifiedBackendService.initializeReal(
      supabaseUrl: supabaseUrl,
      supabaseKey: supabaseKey,
    );
    
    debugPrint('BackendServiceProvider: Supabase initialized successfully');
  }
  
  /// Store Supabase credentials in secure storage
  static Future<void> storeCredentials(String url, String key) async {
    try {
      await _secureStorage.write(key: _supabaseUrlKey, value: url);
      await _secureStorage.write(key: _supabaseAnonKey, value: key);
      debugPrint('Supabase credentials stored successfully');
    } catch (e) {
      debugPrint('Error storing Supabase credentials: $e');
    }
  }
  
  /// Clear stored Supabase credentials
  static Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _supabaseUrlKey);
      await _secureStorage.delete(key: _supabaseAnonKey);
      debugPrint('Supabase credentials cleared successfully');
    } catch (e) {
      debugPrint('Error clearing Supabase credentials: $e');
    }
  }
}