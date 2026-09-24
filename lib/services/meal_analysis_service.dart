import 'package:firebase_ai/firebase_ai.dart' show Schema;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/core/environment.dart';
import 'package:gut_md/services/gemini_client.dart';

class MealAnalysisResult {
  final List<String> foods;
  final String description;
  final Map<String, dynamic>? nutritionEstimate;
  final List<String>? potentialTriggers;

  /// AI estimate (1 = likely to aggravate, 10 = very gentle) of how easy the
  /// meal is on a sensitive gut. Null when the meal was not scored.
  final int? digestibilityScore;
  final String? digestibilityRationale;

  /// `gemini` for a real analysis, `sample` for the offline test build's
  /// fixed analysis.
  final String source;
  final DateTime timestamp;

  MealAnalysisResult({
    required this.foods,
    required this.description,
    this.nutritionEstimate,
    this.potentialTriggers,
    this.digestibilityScore,
    this.digestibilityRationale,
    this.source = 'gemini',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'foods': foods,
    'description': description,
    'nutrition_estimate': nutritionEstimate,
    'potential_triggers': potentialTriggers,
    'digestibility_score': digestibilityScore,
    'digestibility_rationale': digestibilityRationale,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) {
    final foods = List<String>.from(json['foods'] ?? []);
    final score = json['digestibility_score'];
    final rationale = json['digestibility_rationale'];
    return MealAnalysisResult(
      foods: foods,
      description: json['description'] ?? '',
      nutritionEstimate: json['nutrition_estimate'] == null
          ? null
          : Map<String, dynamic>.from(json['nutrition_estimate']),
      potentialTriggers: json['potential_triggers'] != null
          ? List<String>.from(json['potential_triggers'])
          : null,
      // A score only makes sense for a photo that actually shows food.
      digestibilityScore:
          score is num && foods.isNotEmpty ? score.round().clamp(1, 10) : null,
      digestibilityRationale:
          score is num && foods.isNotEmpty && rationale is String && rationale.trim().isNotEmpty
              ? rationale.trim()
              : null,
      source: json['source'] as String? ?? 'gemini',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class MealAnalysisService {
  static final Schema _schema = Schema.object(properties: {
    'foods': Schema.array(
      items: Schema.string(),
      description: 'Foods and ingredients visible in the photo',
    ),
    'description': Schema.string(description: 'One-sentence meal description'),
    'nutrition_estimate': Schema.object(properties: {
      'calories': Schema.integer(),
      'protein_g': Schema.integer(),
      'carbs_g': Schema.integer(),
      'fat_g': Schema.integer(),
      'fiber_g': Schema.integer(),
    }),
    'potential_triggers': Schema.array(
      items: Schema.string(),
      description:
          'Likely IBD/IBS digestive triggers, e.g. "Broccoli (high fiber)"',
    ),
    'digestibility_score': Schema.integer(
      nullable: true,
      minimum: 1,
      maximum: 10,
      description: 'How gentle the meal is likely to be on a sensitive or '
          'inflamed gut: 10 = very gentle, 1 = very likely to aggravate. '
          'Null if the photo is not food.',
    ),
    'digestibility_rationale': Schema.string(
      nullable: true,
      description: 'One short sentence explaining the score',
    ),
  });

  static const String _prompt =
      'You are a dietitian assistant for people with Crohn\'s disease, '
      'ulcerative colitis and IBS. Identify the foods in this meal photo, '
      'describe the meal in one sentence, estimate its nutrition, and list '
      'any ingredients that commonly trigger IBD/IBS symptoms (high insoluble '
      'fiber, dairy/lactose, gluten, spicy, fried/high-fat, alcohol, caffeine, '
      'artificial sweeteners, high-FODMAP). Give a general digestibility '
      'estimate with a one-sentence reason. If it is not food, return empty '
      'lists and a null score.';

  /// Analyze a meal photo with Gemini vision.
  ///
  /// Throws when the analysis cannot be performed so the UI can ask the user
  /// to describe the meal instead of showing a made-up result.
  static Future<MealAnalysisResult> analyzeMealPhoto(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    // Only the explicit offline test build gets the fixed sample analysis; a
    // real user whose backend fell back to offline mode must never be shown
    // an analysis that did not look at their photo.
    if (Environment.useMockData) {
      return _offlineAnalysis();
    }
    if (!GeminiClient.isAvailable) {
      throw StateError('Meal analysis is unavailable offline');
    }

    final json = await GeminiClient.json(
      prompt: _prompt,
      schema: _schema,
      imageBytes: imageBytes,
      imageMimeType: mimeType,
    );
    return MealAnalysisResult.fromJson({...json, 'source': 'gemini'});
  }

  /// Deterministic analysis for the offline test build (`USE_MOCK_DATA=true`).
  /// It is labelled as a sample and carries no digestibility score.
  static MealAnalysisResult _offlineAnalysis() {
    return MealAnalysisResult(
      foods: ['Grilled chicken', 'White rice', 'Steamed vegetables'],
      description: 'A balanced meal with lean protein, simple carbs, and vegetables',
      nutritionEstimate: {
        'calories': 450,
        'protein_g': 35,
        'carbs_g': 45,
        'fat_g': 12,
        'fiber_g': 4,
      },
      potentialTriggers: ['Broccoli (high fiber)', 'Possible seasoning'],
      source: 'sample',
    );
  }

  /// Persist an analysed meal as a tracking entry.
  static Future<void> saveMealData({
    required MealAnalysisResult analysis,
    required DateTime date,
  }) async {
    final backend = BackendServiceProvider.instance;
    final userId = backend.auth.currentUser?.id ?? '';

    await backend.tracking.trackEvent(
      userId: userId,
      type: 'meal',
      data: {
        'entry_id': DateFormat('yyyy-MM-dd_HHmmss_SSS').format(analysis.timestamp),
        'date': DateFormat('yyyy-MM-dd').format(date),
        'time': DateFormat('HH:mm').format(analysis.timestamp),
        'foods': analysis.foods,
        'description': analysis.description,
        'nutrition': analysis.nutritionEstimate,
        'potential_triggers': analysis.potentialTriggers,
        'digestibility_score': analysis.digestibilityScore,
        'digestibility_rationale': analysis.digestibilityRationale,
      },
    );
    debugPrint('MealAnalysisService: Meal data saved');
  }
}
