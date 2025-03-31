import 'package:supabase_flutter/supabase_flutter.dart';

class BackendService {
  final SupabaseClient _supabaseClient;
  
  BackendService._(this._supabaseClient);
  
  static Future<BackendService> initialize({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    
    return BackendService._(Supabase.instance.client);
  }
  
  AuthService get auth => AuthService(_supabaseClient);
  TrackingService get tracking => TrackingService(_supabaseClient);
  InsightsService get insights => InsightsService(_supabaseClient);
  ChatService get chat => ChatService(_supabaseClient);
}

class AuthService {
  final SupabaseClient _supabaseClient;
  
  AuthService(this._supabaseClient);
  
  User? get currentUser => _supabaseClient.auth.currentUser;
  
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
    
    return response.user;
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    return response.user;
  }

  Future<User?> signInWithGoogle() async {
    final response = await _supabaseClient.auth.signInWithOAuth(
      Provider.google,
      redirectTo: 'io.supabase.crohnscompanion://login-callback',
    );
    
    return _supabaseClient.auth.currentUser;
  }

  Future<User?> signInWithApple() async {
    final response = await _supabaseClient.auth.signInWithOAuth(
      Provider.apple,
      redirectTo: 'io.supabase.crohnscompanion://login-callback',
    );
    
    return _supabaseClient.auth.currentUser;
  }
}

class TrackingService {
  final SupabaseClient _supabaseClient;
  
  TrackingService(this._supabaseClient);
  
  Future<Map<String, dynamic>?> getTrackingData({
    required String userId,
    required String date,
    required String type,
  }) async {
    final response = await _supabaseClient
        .from('tracking_data')
        .select()
        .eq('user_id', userId)
        .eq('date', date)
        .eq('type', type)
        .single();
    
    return response as Map<String, dynamic>?;
  }

  Future<void> trackEvent({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _supabaseClient
        .from('tracking_data')
        .upsert({
          'user_id': userId,
          'type': type,
          'data': data,
          'date': data['date'],
          'recorded_at': DateTime.now().toIso8601String(),
        });
  }
  
  Future<void> trackSymptoms({
    required String userId,
    required Map<String, dynamic> symptoms,
  }) async {
    await _supabaseClient
        .from('symptoms')
        .insert({
          'user_id': userId,
          'symptoms': symptoms,
          'recorded_at': DateTime.now().toIso8601String(),
        });
  }
  
  Future<List<Map<String, dynamic>>> getSymptoms(String userId) async {
    final response = await _supabaseClient
        .from('symptoms')
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
}

class InsightsService {
  final SupabaseClient _supabaseClient;
  
  InsightsService(this._supabaseClient);
  
  Future<Map<String, dynamic>?> getUserInsights(String userId) async {
    final response = await _supabaseClient
        .from('insights')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .single();
    
    return response as Map<String, dynamic>?;
  }

  Future<void> generateInsights(String userId) async {
    // Get user's tracking data
    final trackingData = await _supabaseClient
        .from('tracking_data')
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false)
        .limit(30);

    // Get user's symptoms
    final symptoms = await _supabaseClient
        .from('symptoms')
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false)
        .limit(30);

    // Generate insights based on tracking data and symptoms
    final insights = {
      'user_id': userId,
      'tracking_summary': trackingData,
      'symptoms_summary': symptoms,
      'generated_at': DateTime.now().toIso8601String(),
    };

    // Save the generated insights
    await _supabaseClient
        .from('insights')
        .insert(insights);
  }
}

class ChatService {
  final SupabaseClient _supabaseClient;
  
  ChatService(this._supabaseClient);
  
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    final response = await _supabaseClient
        .from('chat_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<void> saveMessage({
    required String userId,
    required String message,
    required String role,
  }) async {
    await _supabaseClient
        .from('chat_history')
        .insert({
          'user_id': userId,
          'message': message,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
        });
  }

  Future<String> sendMessage(String userId, String message) async {
    // Save user message
    await saveMessage(
      userId: userId,
      message: message,
      role: 'user',
    );

    // TODO: Implement AI response generation
    final aiResponse = "I understand you're asking about: $message. I'm here to help with your Crohn's related questions.";

    // Save AI response
    await saveMessage(
      userId: userId,
      message: aiResponse,
      role: 'assistant',
    );

    return aiResponse;
  }
}