import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// A wrapper around the Supabase client to provide a consistent interface
/// for all services and handle common operations
class SupabaseClient {
  final supabase.GotrueClient _auth;
  final supabase.SupabaseClient _db;
  
  /// Constructor that takes the Supabase client
  SupabaseClient(this._auth, this._db);
  
  /// Get the Supabase auth client
  supabase.GotrueClient get auth => _auth;
  
  /// Get the Supabase database client
  supabase.SupabaseClient get db => _db;
  
  /// Initialize Supabase with the provided URL and key
  static Future<SupabaseClient> initialize({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    await supabase.Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    
    final client = supabase.Supabase.instance;
    return SupabaseClient(client.client.auth, client.client);
  }
  
  /// Get the current user ID
  String? get currentUserId => _auth.currentUser?.id;
  
  /// Get the current user
  supabase.User? get currentUser => _auth.currentUser;
  
  /// Check if a user is signed in
  bool get isSignedIn => _auth.currentUser != null;
  
  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  /// Listen for auth state changes
  Stream<supabase.AuthState> get onAuthStateChange => _auth.onAuthStateChange;
  
  /// Get a stream of the current user
  Stream<supabase.User?> get onUserChange => _auth.onAuthStateChange.map((state) => state.session?.user);
}