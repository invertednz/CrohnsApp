import 'supabase_client.dart';

/// Abstract base class for all services
/// This provides common functionality and ensures consistent implementation
abstract class BaseService {
  final SupabaseClient _supabaseClient;
  
  /// Constructor that takes a Supabase client
  BaseService(this._supabaseClient);
  
  /// Get the Supabase client
  SupabaseClient get supabaseClient => _supabaseClient;
}