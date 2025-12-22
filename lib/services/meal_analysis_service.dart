import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gut_md/core/environment.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:intl/intl.dart';

class MealAnalysisResult {
  final List<String> foods;
  final String description;
  final Map<String, dynamic>? nutritionEstimate;
  final List<String>? potentialTriggers;
  final DateTime timestamp;

  MealAnalysisResult({
    required this.foods,
    required this.description,
    this.nutritionEstimate,
    this.potentialTriggers,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'foods': foods,
    'description': description,
    'nutrition_estimate': nutritionEstimate,
    'potential_triggers': potentialTriggers,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MealAnalysisResult(
      foods: List<String>.from(json['foods'] ?? []),
      description: json['description'] ?? '',
      nutritionEstimate: json['nutrition_estimate'],
      potentialTriggers: json['potential_triggers'] != null 
          ? List<String>.from(json['potential_triggers']) 
          : null,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}

class MealAnalysisService {
  static const String _geminiEndpoint = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Analyze a meal photo using Gemini Vision API
  static Future<MealAnalysisResult> analyzeMealPhoto(File imageFile) async {
    final isMock = BackendServiceProvider.isMock;
    
    if (isMock) {
      return _getMockAnalysis();
    }
    
    return _analyzeWithGemini(imageFile);
  }

  /// Analyze meal with Gemini Vision API
  static Future<MealAnalysisResult> _analyzeWithGemini(File imageFile) async {
    final apiKey = Environment.geminiApiKey;
    
    if (apiKey.isEmpty || apiKey == 'your_gemini_api_key') {
      debugPrint('MealAnalysisService: No Gemini API key configured, using mock');
      return _getMockAnalysis();
    }

    try {
      // Read and encode image as base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Determine mime type
      final extension = imageFile.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'webp') mimeType = 'image/webp';

      final response = await http.post(
        Uri.parse('$_geminiEndpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''Analyze this meal photo and provide:
1. A list of foods/ingredients you can identify
2. A brief description of the meal
3. Estimated nutritional information (calories, protein, carbs, fat)
4. Any potential digestive triggers for someone with IBD/IBS (e.g., high fiber, dairy, gluten, spicy, fried)

Respond ONLY with valid JSON in this exact format:
{
  "foods": ["food1", "food2", "food3"],
  "description": "Brief meal description",
  "nutrition_estimate": {
    "calories": 500,
    "protein_g": 20,
    "carbs_g": 50,
    "fat_g": 15
  },
  "potential_triggers": ["trigger1", "trigger2"]
}'''
                },
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        
        // Extract JSON from response (handle markdown code blocks)
        String jsonStr = text;
        if (text.contains('```json')) {
          jsonStr = text.split('```json')[1].split('```')[0].trim();
        } else if (text.contains('```')) {
          jsonStr = text.split('```')[1].split('```')[0].trim();
        }
        
        final parsed = jsonDecode(jsonStr);
        return MealAnalysisResult.fromJson(parsed);
      } else {
        debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
        return _getMockAnalysis();
      }
    } catch (e) {
      debugPrint('MealAnalysisService error: $e');
      return _getMockAnalysis();
    }
  }

  /// Mock analysis for testing
  static MealAnalysisResult _getMockAnalysis() {
    return MealAnalysisResult(
      foods: ['Grilled chicken', 'White rice', 'Steamed vegetables'],
      description: 'A balanced meal with lean protein, simple carbs, and vegetables',
      nutritionEstimate: {
        'calories': 450,
        'protein_g': 35,
        'carbs_g': 45,
        'fat_g': 12,
      },
      potentialTriggers: ['Broccoli (high fiber)', 'Possible seasoning'],
    );
  }

  /// Save meal data to tracking service
  static Future<void> saveMealData({
    required MealAnalysisResult analysis,
    required DateTime date,
    String? imagePath,
  }) async {
    final isMock = BackendServiceProvider.isMock;
    
    if (isMock) {
      debugPrint('MealAnalysisService: Mock mode - meal saved locally');
      return;
    }

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      final userId = BackendServiceProvider.instance.auth.currentUser?.id ?? '';
      
      await trackingService.trackEvent(
        userId: userId,
        type: 'meal',
        data: {
          'date': DateFormat('yyyy-MM-dd').format(date),
          'time': DateFormat('HH:mm').format(analysis.timestamp),
          'foods': analysis.foods,
          'description': analysis.description,
          'nutrition': analysis.nutritionEstimate,
          'potential_triggers': analysis.potentialTriggers,
          'image_path': imagePath,
        },
      );
      
      debugPrint('MealAnalysisService: Meal data saved successfully');
    } catch (e) {
      debugPrint('MealAnalysisService: Error saving meal data: $e');
      rethrow;
    }
  }
}
