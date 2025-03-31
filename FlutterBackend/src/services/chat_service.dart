import '../core/supabase_client.dart';
import '../models/user_model.dart';

/// Service for handling AI chat functionality
class ChatService {
  final SupabaseClient _supabaseClient;
  final String _chatTableName = 'chat_conversations';
  final String _messageTableName = 'chat_messages';
  
  /// Constructor that takes a Supabase client
  ChatService(this._supabaseClient);
  
  /// Create a new chat conversation
  Future<String?> createConversation(String userId, {String? title}) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final conversationTitle = title ?? 'Conversation ${timestamp}';
      
      final response = await _supabaseClient.db.from(_chatTableName).insert({
        'user_id': userId,
        'title': conversationTitle,
        'created_at': timestamp,
        'updated_at': timestamp,
      }).select('id').single().execute();
      
      if (response.data == null) {
        return null;
      }
      
      return response.data['id'] as String;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }
  
  /// Get all conversations for a user
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final response = await _supabaseClient.db
          .from(_chatTableName)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .execute();
      
      if (response.data == null) {
        return [];
      }
      
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }
  
  /// Get a specific conversation
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      final response = await _supabaseClient.db
          .from(_chatTableName)
          .select()
          .eq('id', conversationId)
          .single()
          .execute();
      
      if (response.data == null) {
        return null;
      }
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting conversation: $e');
      return null;
    }
  }
  
  /// Delete a conversation and all its messages
  Future<bool> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      await _supabaseClient.db
          .from(_messageTableName)
          .delete()
          .eq('conversation_id', conversationId)
          .execute();
      
      // Delete the conversation
      await _supabaseClient.db
          .from(_chatTableName)
          .delete()
          .eq('id', conversationId)
          .execute();
      
      return true;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }
  
  /// Send a message in a conversation
  Future<Map<String, dynamic>?> sendMessage(String conversationId, String userId, String content) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      
      // Insert the user message
      final userMessageResponse = await _supabaseClient.db.from(_messageTableName).insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'content': content,
        'is_user': true,
        'created_at': timestamp,
      }).select().single().execute();
      
      if (userMessageResponse.data == null) {
        return null;
      }
      
      // Update the conversation's updated_at timestamp
      await _supabaseClient.db
          .from(_chatTableName)
          .update({'updated_at': timestamp})
          .eq('id', conversationId)
          .execute();
      
      // Get the conversation history to provide context for the AI
      final history = await getConversationMessages(conversationId);
      
      // Call the AI service to generate a response
      final aiResponse = await _generateAIResponse(userId, conversationId, content, history);
      
      return aiResponse;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }
  
  /// Generate an AI response based on user message and conversation history
  Future<Map<String, dynamic>?> _generateAIResponse(String userId, String conversationId, String userMessage, List<Map<String, dynamic>> history) async {
    try {
      // This would call an external AI service or a Supabase Edge Function
      // that processes the user's message and generates a response
      final timestamp = DateTime.now().toIso8601String();
      
      // Get user data to provide context for the AI
      final userData = await _getUserContextData(userId);
      
      // Call the AI service (this is a placeholder for the actual implementation)
      final response = await _supabaseClient.db.rpc('generate_ai_response', params: {
        'p_user_id': userId,
        'p_conversation_id': conversationId,
        'p_user_message': userMessage,
        'p_history': history,
        'p_user_data': userData,
      }).execute();
      
      if (response.data == null) {
        // Fallback response if the AI service fails
        final fallbackResponse = await _supabaseClient.db.from(_messageTableName).insert({
          'conversation_id': conversationId,
          'user_id': userId,
          'content': 'I\'m sorry, I\'m having trouble processing your request right now. Please try again later.',
          'is_user': false,
          'created_at': timestamp,
        }).select().single().execute();
        
        return fallbackResponse.data as Map<String, dynamic>;
      }
      
      // Insert the AI response into the database
      final aiMessageResponse = await _supabaseClient.db.from(_messageTableName).insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'content': response.data['response'],
        'is_user': false,
        'created_at': timestamp,
      }).select().single().execute();
      
      return aiMessageResponse.data as Map<String, dynamic>;
    } catch (e) {
      print('Error generating AI response: $e');
      return null;
    }
  }
  
  /// Get messages in a conversation
  Future<List<Map<String, dynamic>>> getConversationMessages(String conversationId) async {
    try {
      final response = await _supabaseClient.db
          .from(_messageTableName)
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .execute();
      
      if (response.data == null) {
        return [];
      }
      
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting conversation messages: $e');
      return [];
    }
  }
  
  /// Get user context data for AI personalization
  Future<Map<String, dynamic>> _getUserContextData(String userId) async {
    try {
      // Get user profile
      final profileResponse = await _supabaseClient.db
          .from('profiles')
          .select()
          .eq('id', userId)
          .single()
          .execute();
      
      // Get user settings
      final settingsResponse = await _supabaseClient.db
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .execute();
      
      // Get recent tracking data
      final trackingResponse = await _supabaseClient.db
          .from('user_tracking')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(50)
          .execute();
      
      // Combine all data into a context object
      final contextData = {
        'profile': profileResponse.data ?? {},
        'settings': settingsResponse.data ?? [],
        'tracking': trackingResponse.data ?? [],
      };
      
      return contextData;
    } catch (e) {
      print('Error getting user context data: $e');
      return {};
    }
  }
  
  /// Get a stream of new messages in a conversation
  Stream<List<Map<String, dynamic>>> watchConversationMessages(String conversationId) {
    return _supabaseClient.db
        .from(_messageTableName)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) {
          return data.cast<Map<String, dynamic>>();
        });
  }
}