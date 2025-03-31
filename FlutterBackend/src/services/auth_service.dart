import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/user_model.dart';

/// Service for handling authentication operations
class AuthService {
  final SupabaseClient _supabaseClient;
  bool _devMode = false;
  
  /// Constructor that takes a Supabase client
  AuthService(this._supabaseClient);
  
  /// Set development mode
  void setDevMode(bool enabled) {
    _devMode = enabled;
  }
  
  /// Check if development mode is enabled
  bool isDevMode() {
    return _devMode;
  }
  
  /// Sign in with email and password
  /// Only available in development mode unless explicitly allowed
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      // Check if dev mode is enabled
      if (!_devMode) {
        print('Email/password authentication is only available in development mode');
        return null;
      }
      
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        return null;
      }
      
      return UserModel.fromSupabaseUser(response.user!);
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }
  
  /// Sign up with email and password
  /// Only available in development mode unless explicitly allowed
  Future<UserModel?> signUpWithEmail(String email, String password) async {
    try {
      // Check if dev mode is enabled
      if (!_devMode) {
        print('Email/password authentication is only available in development mode');
        return null;
      }
      
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        return null;
      }
      
      return UserModel.fromSupabaseUser(response.user!);
    } catch (e) {
      print('Error signing up with email: $e');
      return null;
    }
  }
  
  /// Sign in with Apple
  Future<UserModel?> signInWithApple() async {
    try {
      final response = await _supabaseClient.auth.signInWithOAuth(
        provider: OAuthProvider.apple,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      // OAuth sign-in is a bit different as it redirects to a web page
      // We need to wait for the auth state to change
      if (!response.isSuccess) {
        return null;
      }
      
      // Wait for auth state to change and get the user
      final user = await _waitForUser();
      if (user == null) {
        return null;
      }
      
      return UserModel.fromSupabaseUser(user);
    } catch (e) {
      print('Error signing in with Apple: $e');
      return null;
    }
  }
  
  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final response = await _supabaseClient.auth.signInWithOAuth(
        provider: OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      // OAuth sign-in is a bit different as it redirects to a web page
      // We need to wait for the auth state to change
      if (!response.isSuccess) {
        return null;
      }
      
      // Wait for auth state to change and get the user
      final user = await _waitForUser();
      if (user == null) {
        return null;
      }
      
      return UserModel.fromSupabaseUser(user);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }
  
  /// Wait for the user to be available after OAuth sign-in
  Future<supabase.User?> _waitForUser() async {
    // Wait for the auth state to change
    final completer = Completer<supabase.User?>();
    final subscription = _supabaseClient.auth.onAuthStateChange.listen((data) {
      if (data.event == supabase.AuthChangeEvent.signedIn) {
        completer.complete(data.session?.user);
      }
    });
    
    // Set a timeout
    Future.delayed(const Duration(seconds: 60), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
    
    final user = await completer.future;
    subscription.cancel();
    return user;
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    await _supabaseClient.signOut();
  }
  
  /// Get the current user
  UserModel? getCurrentUser() {
    final user = _supabaseClient.currentUser;
    if (user == null) {
      return null;
    }
    
    return UserModel.fromSupabaseUser(user);
  }
  
  /// Check if a user is signed in
  bool isSignedIn() {
    return _supabaseClient.isSignedIn;
  }
  
  /// Get a stream of auth state changes
  Stream<UserModel?> get onUserChange {
    return _supabaseClient.onUserChange.map((user) {
      if (user == null) {
        return null;
      }
      
      return UserModel.fromSupabaseUser(user);
    });
  }
  
  /// Check if email/password authentication is available
  bool isEmailAuthAvailable() {
    return _devMode;
  }
}