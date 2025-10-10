import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import the backend service and environment
import '../FlutterBackend/src/core/backend_service.dart';
import '../core/environment.dart';

/// A provider class that manages the initialization and access to the BackendService
class BackendServiceProvider {
  static BackendService? _instance;
  static const _secureStorage = FlutterSecureStorage();
  static const _supabaseUrlKey = 'supabase_url';
  static const _supabaseAnonKey = 'supabase_anon_key';
  
  /// Get the BackendService instance
  static BackendService get instance {
    if (_instance == null) {
      throw Exception('BackendService not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the BackendService with Supabase credentials
  static Future<void> initialize() async {
    if (_instance != null) return;
    
    // Initialize environment configuration
    await Environment.initialize();
    
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
    
    // Initialize the BackendService
    _instance = await BackendService.initialize(
      supabaseUrl: supabaseUrl,
      supabaseKey: supabaseKey,
    );
    
    debugPrint('BackendService initialized successfully');
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