import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gut_md/core/environment.dart';

/// Model for a chat message
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    text: json['text'] ?? json['message'] ?? '',
    isUser: json['isUser'] ?? json['role'] == 'user',
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
  );
}

/// User health context for AI chat
class UserHealthContext {
  final List<Map<String, dynamic>> recentDailyTracking;
  final List<Map<String, dynamic>> recentSymptoms;
  final List<Map<String, dynamic>> recentSupplements;
  final List<Map<String, dynamic>> recentDiet;
  final List<String> foodTriggers;
  final List<String> safeFoods;
  final List<ChatMessage> chatHistory;

  UserHealthContext({
    this.recentDailyTracking = const [],
    this.recentSymptoms = const [],
    this.recentSupplements = const [],
    this.recentDiet = const [],
    this.foodTriggers = const [],
    this.safeFoods = const [],
    this.chatHistory = const [],
  });

  /// Build a summary string of the user's health context for the AI
  String buildContextSummary() {
    final buffer = StringBuffer();
    
    // Recent feelings and wellness
    if (recentDailyTracking.isNotEmpty) {
      buffer.writeln('=== Recent Daily Tracking (last 7 days) ===');
      for (final entry in recentDailyTracking.take(7)) {
        final feeling = _feelingToText(entry['feeling'] ?? 2);
        final date = entry['date'] ?? 'Unknown date';
        final painLevel = entry['pain_level'] ?? 0;
        final energyLevel = entry['energy_level'] ?? 5;
        final bowelMovements = entry['bowel_movements'] ?? 0;
        buffer.writeln('- $date: Feeling $feeling, Pain level: $painLevel/10, Energy: $energyLevel/10, Bowel movements: $bowelMovements');
      }
      buffer.writeln();
    }

    // Recent symptoms
    if (recentSymptoms.isNotEmpty) {
      buffer.writeln('=== Recent Symptoms ===');
      for (final entry in recentSymptoms.take(7)) {
        final date = entry['date'] ?? 'Unknown date';
        final symptoms = entry['active_symptoms'] as List? ?? [];
        if (symptoms.isNotEmpty) {
          final symptomNames = symptoms.map((s) => '${s['name']} (severity: ${s['severity']}/5)').join(', ');
          buffer.writeln('- $date: $symptomNames');
        }
      }
      buffer.writeln();
    }

    // Recent supplements
    if (recentSupplements.isNotEmpty) {
      buffer.writeln('=== Current Supplements ===');
      final latestSupplements = recentSupplements.first['supplements'] as List? ?? [];
      for (final supp in latestSupplements) {
        final taken = supp['taken'] == true ? '✓ taken' : 'not taken';
        buffer.writeln('- ${supp['name']} ${supp['dosage'] ?? ''} (${supp['time']}) - $taken');
      }
      buffer.writeln();
    }

    // Diet information
    if (recentDiet.isNotEmpty) {
      buffer.writeln('=== Recent Meals ===');
      for (final entry in recentDiet.take(3)) {
        final date = entry['date'] ?? 'Unknown date';
        final meals = entry['meals'] as List? ?? [];
        for (final meal in meals) {
          final foods = (meal['foods'] as List?)?.join(', ') ?? '';
          buffer.writeln('- $date ${meal['name']}: $foods');
        }
      }
      buffer.writeln();
    }

    // Food triggers and safe foods
    if (foodTriggers.isNotEmpty) {
      buffer.writeln('=== Known Food Triggers ===');
      buffer.writeln(foodTriggers.join(', '));
      buffer.writeln();
    }

    if (safeFoods.isNotEmpty) {
      buffer.writeln('=== Safe Foods ===');
      buffer.writeln(safeFoods.join(', '));
      buffer.writeln();
    }

    // Analyze patterns - what made them feel good/bad
    buffer.writeln(_analyzePatterns());

    return buffer.toString();
  }

  String _feelingToText(int feeling) {
    switch (feeling) {
      case 0: return 'Very Bad 😞';
      case 1: return 'Bad 😐';
      case 2: return 'Okay 🙂';
      case 3: return 'Good 😊';
      case 4: return 'Great 🤗';
      default: return 'Unknown';
    }
  }

  String _analyzePatterns() {
    final buffer = StringBuffer();
    buffer.writeln('=== Pattern Analysis ===');

    // Find good days and what was eaten/done
    final goodDays = recentDailyTracking.where((d) => (d['feeling'] ?? 2) >= 3).toList();
    final badDays = recentDailyTracking.where((d) => (d['feeling'] ?? 2) <= 1).toList();

    if (goodDays.isNotEmpty) {
      buffer.writeln('Good days (feeling good/great): ${goodDays.length} in recent history');
      // Show user-reported factors that made them feel good
      for (final goodDay in goodDays.take(3)) {
        final date = goodDay['date'];
        final feelGoodFactors = goodDay['feel_good_factors'] ?? '';
        if (feelGoodFactors.isNotEmpty) {
          buffer.writeln('  - On $date: User reported feeling good because: $feelGoodFactors');
        }
        // Also correlate with diet
        final dietOnDay = recentDiet.where((d) => d['date'] == date).toList();
        if (dietOnDay.isNotEmpty) {
          final meals = dietOnDay.first['meals'] as List? ?? [];
          final allFoods = meals.expand((m) => (m['foods'] as List?) ?? []).toList();
          if (allFoods.isNotEmpty) {
            buffer.writeln('    Foods eaten: ${allFoods.join(', ')}');
          }
        }
      }
    }

    if (badDays.isNotEmpty) {
      buffer.writeln('Bad days (feeling bad/very bad): ${badDays.length} in recent history');
      for (final badDay in badDays.take(3)) {
        final date = badDay['date'];
        final feelBadFactors = badDay['feel_bad_factors'] ?? '';
        if (feelBadFactors.isNotEmpty) {
          buffer.writeln('  - On $date: User reported feeling bad because: $feelBadFactors');
        }
        // Correlate with diet and symptoms
        final dietOnDay = recentDiet.where((d) => d['date'] == date).toList();
        final symptomsOnDay = recentSymptoms.where((s) => s['date'] == date).toList();
        
        if (dietOnDay.isNotEmpty) {
          final meals = dietOnDay.first['meals'] as List? ?? [];
          final allFoods = meals.expand((m) => (m['foods'] as List?) ?? []).toList();
          if (allFoods.isNotEmpty) {
            buffer.writeln('    Foods eaten: ${allFoods.join(', ')}');
          }
        }
        if (symptomsOnDay.isNotEmpty) {
          final symptoms = symptomsOnDay.first['active_symptoms'] as List? ?? [];
          if (symptoms.isNotEmpty) {
            buffer.writeln('    Symptoms: ${symptoms.map((s) => s['name']).join(', ')}');
          }
        }
      }
    }

    // Collect all reported feel-good and feel-bad factors
    final allFeelGoodFactors = recentDailyTracking
        .where((d) => (d['feel_good_factors'] ?? '').isNotEmpty)
        .map((d) => d['feel_good_factors'] as String)
        .toList();
    final allFeelBadFactors = recentDailyTracking
        .where((d) => (d['feel_bad_factors'] ?? '').isNotEmpty)
        .map((d) => d['feel_bad_factors'] as String)
        .toList();

    if (allFeelGoodFactors.isNotEmpty) {
      buffer.writeln('\n=== User-Reported Feel Good Factors ===');
      buffer.writeln(allFeelGoodFactors.join('; '));
    }

    if (allFeelBadFactors.isNotEmpty) {
      buffer.writeln('\n=== User-Reported Feel Bad Factors ===');
      buffer.writeln(allFeelBadFactors.join('; '));
    }

    return buffer.toString();
  }
}

/// AI Chat Service for generating intelligent responses
class AIChatService {
  final String apiKey;
  final String model;
  final String endpoint;

  AIChatService({
    required this.apiKey,
    required this.model,
    required this.endpoint,
  });

  factory AIChatService.fromEnvironment() {
    return AIChatService(
      apiKey: Environment.llmApiKey,
      model: Environment.llmModel.isNotEmpty ? Environment.llmModel : 'gpt-4o-mini',
      endpoint: Environment.llmEndpoint.isNotEmpty 
          ? Environment.llmEndpoint 
          : 'https://api.openai.com/v1/chat/completions',
    );
  }

  /// Generate a response using the AI model with user health context
  Future<String> generateResponse({
    required String userMessage,
    required UserHealthContext context,
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('AIChatService: No API key configured, using fallback response');
      return _generateFallbackResponse(userMessage, context);
    }

    try {
      final systemPrompt = _buildSystemPrompt(context);
      final messages = _buildMessages(systemPrompt, context.chatHistory, userMessage);

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content;
      } else {
        debugPrint('AIChatService: API error ${response.statusCode}: ${response.body}');
        return _generateFallbackResponse(userMessage, context);
      }
    } catch (e) {
      debugPrint('AIChatService: Error generating response: $e');
      return _generateFallbackResponse(userMessage, context);
    }
  }

  String _buildSystemPrompt(UserHealthContext context) {
    return '''You are a caring and knowledgeable health assistant for a Crohn's disease management app called "Crohn's Companion". Your role is to:

1. Help users understand their symptoms and patterns
2. Provide personalized advice based on their tracked health data
3. Suggest foods that might be safe or should be avoided based on their history
4. Offer emotional support and encouragement
5. Help identify correlations between diet, supplements, and how they feel

IMPORTANT GUIDELINES:
- Always be empathetic and supportive
- Never provide specific medical diagnoses or replace professional medical advice
- Encourage users to consult their healthcare provider for medical decisions
- Use the user's tracked data to provide personalized insights
- When discussing patterns, reference specific data from their history
- Be encouraging about their tracking efforts
- If they're having a bad day, be supportive and help them identify potential triggers

USER'S HEALTH DATA:
${context.buildContextSummary()}

Remember to reference their specific data when relevant to make responses personalized and helpful.''';
  }

  List<Map<String, String>> _buildMessages(
    String systemPrompt,
    List<ChatMessage> chatHistory,
    String userMessage,
  ) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Add recent chat history (last 10 messages for context)
    for (final msg in chatHistory.take(10)) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    // Add current user message
    messages.add({'role': 'user', 'content': userMessage});

    return messages;
  }

  /// Fallback response when API is not available
  String _generateFallbackResponse(String userMessage, UserHealthContext context) {
    final lowerMessage = userMessage.toLowerCase();
    
    // Analyze recent data for personalized responses
    final recentFeeling = context.recentDailyTracking.isNotEmpty 
        ? context.recentDailyTracking.first['feeling'] ?? 2 
        : 2;
    final hasGoodDays = context.recentDailyTracking.any((d) => (d['feeling'] ?? 2) >= 3);
    final hasBadDays = context.recentDailyTracking.any((d) => (d['feeling'] ?? 2) <= 1);

    // Symptom-related questions
    if (lowerMessage.contains('symptom') || lowerMessage.contains('pain') || lowerMessage.contains('hurt')) {
      if (context.recentSymptoms.isNotEmpty) {
        final recentSymptomsList = context.recentSymptoms.take(3).expand((s) {
          final symptoms = s['active_symptoms'] as List? ?? [];
          return symptoms.map((sym) => sym['name']);
        }).toSet().toList();
        
        if (recentSymptomsList.isNotEmpty) {
          return "I see you've been tracking symptoms like ${recentSymptomsList.join(', ')} recently. "
              "It's important to monitor these patterns. Have you noticed if any particular foods or activities "
              "tend to trigger these symptoms? Your food trigger list shows: ${context.foodTriggers.isNotEmpty ? context.foodTriggers.join(', ') : 'no triggers identified yet'}. "
              "Keep tracking to help identify patterns!";
        }
      }
      return "I understand you're experiencing symptoms. Tracking them consistently helps identify patterns. "
          "Would you like tips on managing common Crohn's symptoms, or help identifying potential triggers?";
    }

    // Diet-related questions
    if (lowerMessage.contains('eat') || lowerMessage.contains('food') || lowerMessage.contains('diet') || lowerMessage.contains('meal')) {
      final safeFoodsText = context.safeFoods.isNotEmpty 
          ? "Based on your tracking, your safe foods include: ${context.safeFoods.join(', ')}. " 
          : "";
      final triggersText = context.foodTriggers.isNotEmpty 
          ? "You've identified these as triggers to avoid: ${context.foodTriggers.join(', ')}. "
          : "";
      
      return "${safeFoodsText}${triggersText}"
          "Everyone with Crohn's has different trigger foods, so your personal tracking is valuable. "
          "Generally, easily digestible foods like white rice, bananas, and lean proteins are often well-tolerated. "
          "Would you like to discuss specific foods or meal ideas?";
    }

    // Supplement/medication questions
    if (lowerMessage.contains('supplement') || lowerMessage.contains('vitamin') || lowerMessage.contains('medication')) {
      if (context.recentSupplements.isNotEmpty) {
        final supplements = context.recentSupplements.first['supplements'] as List? ?? [];
        final suppNames = supplements.map((s) => s['name']).toList();
        if (suppNames.isNotEmpty) {
          return "I see you're currently tracking: ${suppNames.join(', ')}. "
              "Consistency with supplements is key! Common supplements for Crohn's include Vitamin D, B12, Iron, and probiotics. "
              "Always discuss any new supplements with your healthcare provider as they can interact with medications.";
        }
      }
      return "Supplements like Vitamin D, B12, Iron, and probiotics are commonly recommended for Crohn's patients, "
          "but it's important to discuss with your doctor before starting any new supplements. "
          "Would you like to track your supplements in the app?";
    }

    // Feeling-related questions
    if (lowerMessage.contains('feel') || lowerMessage.contains('today') || lowerMessage.contains('how am i')) {
      if (recentFeeling >= 3) {
        return "I'm glad to see you've been feeling ${recentFeeling >= 4 ? 'great' : 'good'} recently! 🎉 "
            "Keep up what you're doing. Looking at your data, your consistent tracking is really helping build a picture of what works for you.";
      } else if (recentFeeling <= 1) {
        return "I'm sorry you haven't been feeling well lately. 💙 Looking at your recent data, "
            "let's see if we can identify any patterns. ${hasBadDays ? "You've had some tough days recently." : ""} "
            "Remember to stay hydrated and rest when you need to. Would you like to talk about what might be contributing to how you're feeling?";
      }
    }

    // Pattern/insight questions
    if (lowerMessage.contains('pattern') || lowerMessage.contains('trigger') || lowerMessage.contains('why') || lowerMessage.contains('insight')) {
      final goodDays = context.recentDailyTracking.where((d) => (d['feeling'] ?? 2) >= 3).length;
      final badDays = context.recentDailyTracking.where((d) => (d['feeling'] ?? 2) <= 1).length;
      
      return "Based on your recent tracking, you've had $goodDays good days and $badDays challenging days. "
          "${context.foodTriggers.isNotEmpty ? 'Your identified triggers (${context.foodTriggers.join(', ')}) are important to watch. ' : ''}"
          "The more consistently you track, the better we can identify patterns together. "
          "Try to note what you eat on both good and bad days to find correlations!";
    }

    // Stress-related
    if (lowerMessage.contains('stress') || lowerMessage.contains('anxious') || lowerMessage.contains('worried')) {
      return "Stress can definitely impact Crohn's symptoms. Many people find that stress management techniques like "
          "deep breathing, gentle exercise, meditation, or getting enough sleep can help. "
          "Your feelings are valid, and managing a chronic condition is challenging. "
          "Would you like some specific stress-management techniques that have helped others with Crohn's?";
    }

    // Default personalized response
    return "Thanks for reaching out! I'm here to help you manage your Crohn's journey. "
        "${context.recentDailyTracking.isNotEmpty ? "I can see you've been tracking your health, which is great! " : "Start tracking your symptoms, diet, and how you feel to get personalized insights. "}"
        "You can ask me about:\n"
        "• Your symptoms and patterns\n"
        "• Diet recommendations based on your tracked triggers\n"
        "• Supplement information\n"
        "• Stress management tips\n"
        "• Understanding your health data\n\n"
        "What would you like to know more about?";
  }
}
