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

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
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

  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    required String type,
    int limit = 30,
  }) async {
    final response = await _supabaseClient
        .from('tracking_data')
        .select()
        .eq('user_id', userId)
        .eq('type', type)
        .order('date', ascending: false)
        .limit(limit);
    
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
    try {
      final response = await _supabaseClient
          .from('chat_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return empty list if table doesn't exist or other error
      return [];
    }
  }
  
  Future<void> saveMessage({
    required String userId,
    required String message,
    required String role,
  }) async {
    try {
      await _supabaseClient
          .from('chat_history')
          .insert({
            'user_id': userId,
            'message': message,
            'role': role,
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Ignore save errors for now
    }
  }

  Future<String> sendMessage(String userId, String message) async {
    // Save user message
    await saveMessage(
      userId: userId,
      message: message,
      role: 'user',
    );

    // Get user health context for AI
    final trackingService = TrackingService(_supabaseClient);
    
    final dailyTracking = await trackingService.getTrackingHistory(
      userId: userId,
      type: 'daily',
      limit: 14,
    );
    
    final symptoms = await trackingService.getTrackingHistory(
      userId: userId,
      type: 'symptoms',
      limit: 14,
    );
    
    final supplements = await trackingService.getTrackingHistory(
      userId: userId,
      type: 'supplements',
      limit: 7,
    );
    
    final diet = await trackingService.getTrackingHistory(
      userId: userId,
      type: 'diet',
      limit: 7,
    );
    
    // Extract triggers and safe foods
    List<String> foodTriggers = [];
    List<String> safeFoods = [];
    if (diet.isNotEmpty) {
      foodTriggers = List<String>.from(diet.first['food_triggers'] ?? []);
      safeFoods = List<String>.from(diet.first['safe_foods'] ?? []);
    }
    
    // Get chat history for context
    final chatHistory = await getChatHistory(userId);
    
    // Import and use AIChatService
    final aiService = _createAIChatService();
    
    final context = _UserHealthContext(
      recentDailyTracking: dailyTracking,
      recentSymptoms: symptoms,
      recentSupplements: supplements,
      recentDiet: diet,
      foodTriggers: foodTriggers,
      safeFoods: safeFoods,
      chatHistory: chatHistory,
    );
    
    final aiResponse = await aiService.generateResponse(
      userMessage: message,
      context: context,
    );

    // Save AI response
    await saveMessage(
      userId: userId,
      message: aiResponse,
      role: 'assistant',
    );

    return aiResponse;
  }
  
  _AIChatService _createAIChatService() {
    return _AIChatService();
  }
}

class _UserHealthContext {
  final List<Map<String, dynamic>> recentDailyTracking;
  final List<Map<String, dynamic>> recentSymptoms;
  final List<Map<String, dynamic>> recentSupplements;
  final List<Map<String, dynamic>> recentDiet;
  final List<String> foodTriggers;
  final List<String> safeFoods;
  final List<Map<String, dynamic>> chatHistory;

  _UserHealthContext({
    this.recentDailyTracking = const [],
    this.recentSymptoms = const [],
    this.recentSupplements = const [],
    this.recentDiet = const [],
    this.foodTriggers = const [],
    this.safeFoods = const [],
    this.chatHistory = const [],
  });

  String buildContextSummary() {
    final buffer = StringBuffer();
    
    if (recentDailyTracking.isNotEmpty) {
      buffer.writeln('=== Recent Daily Tracking ===');
      for (final entry in recentDailyTracking.take(7)) {
        final feeling = _feelingToText(entry['feeling'] ?? 2);
        final date = entry['date'] ?? 'Unknown';
        buffer.writeln('- $date: Feeling $feeling');
      }
      buffer.writeln();
    }

    if (recentSymptoms.isNotEmpty) {
      buffer.writeln('=== Recent Symptoms ===');
      for (final entry in recentSymptoms.take(7)) {
        final symptoms = entry['active_symptoms'] as List? ?? [];
        if (symptoms.isNotEmpty) {
          final symptomNames = symptoms.map((s) => s['name']).join(', ');
          buffer.writeln('- ${entry['date']}: $symptomNames');
        }
      }
      buffer.writeln();
    }

    if (foodTriggers.isNotEmpty) {
      buffer.writeln('=== Food Triggers ===');
      buffer.writeln(foodTriggers.join(', '));
    }

    if (safeFoods.isNotEmpty) {
      buffer.writeln('=== Safe Foods ===');
      buffer.writeln(safeFoods.join(', '));
    }

    return buffer.toString();
  }

  String _feelingToText(int feeling) {
    switch (feeling) {
      case 0: return 'Very Bad';
      case 1: return 'Bad';
      case 2: return 'Okay';
      case 3: return 'Good';
      case 4: return 'Great';
      default: return 'Unknown';
    }
  }
}

class _AIChatService {
  Future<String> generateResponse({
    required String userMessage,
    required _UserHealthContext context,
  }) async {
    // Fallback response logic when no API key is available
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('symptom') || lowerMessage.contains('pain')) {
      if (context.recentSymptoms.isNotEmpty) {
        return "Based on your recent tracking, I can see you've been monitoring your symptoms. "
            "It's great that you're keeping track! Would you like tips on managing these symptoms?";
      }
      return "Tracking symptoms is important for managing Crohn's. Would you like tips on common symptom management?";
    }

    if (lowerMessage.contains('food') || lowerMessage.contains('eat') || lowerMessage.contains('diet')) {
      final safeFoodsText = context.safeFoods.isNotEmpty 
          ? "Your safe foods include: ${context.safeFoods.join(', ')}. " 
          : "";
      final triggersText = context.foodTriggers.isNotEmpty 
          ? "Watch out for your triggers: ${context.foodTriggers.join(', ')}. "
          : "";
      return "$safeFoodsText$triggersText"
          "Everyone's triggers are different, so your personal tracking is valuable!";
    }

    if (lowerMessage.contains('supplement') || lowerMessage.contains('vitamin')) {
      return "Common supplements for Crohn's include Vitamin D, B12, Iron, and probiotics. "
          "Always discuss with your healthcare provider before starting new supplements.";
    }

    return "I'm here to help you manage your Crohn's journey! "
        "${context.recentDailyTracking.isNotEmpty ? "I can see you've been tracking - great job! " : ""}"
        "Ask me about symptoms, diet, supplements, or patterns in your health data.";
  }
}