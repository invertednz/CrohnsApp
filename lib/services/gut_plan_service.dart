import 'package:firebase_ai/firebase_ai.dart' show Schema;
import 'package:flutter/foundation.dart';

import 'package:gut_md/screens/onboarding/onboarding_data.dart';
import 'package:gut_md/services/gemini_client.dart';

/// One focus area in the user's plan, e.g. "Find your trigger foods".
class PlanFocus {
  final String title;
  final String detail;
  const PlanFocus(this.title, this.detail);

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};
  factory PlanFocus.fromJson(Map<String, dynamic> json) =>
      PlanFocus('${json['title'] ?? ''}', '${json['detail'] ?? ''}');
}

/// A personalised 14-day starter plan built from the onboarding answers.
class GutPlan {
  final String headline;
  final List<PlanFocus> focusAreas;
  final String firstExperiment;
  final List<String> dailyRoutine;
  final String encouragement;
  final String source; // gemini | local

  const GutPlan({
    required this.headline,
    required this.focusAreas,
    required this.firstExperiment,
    required this.dailyRoutine,
    required this.encouragement,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'focus_areas': focusAreas.map((f) => f.toJson()).toList(),
        'first_experiment': firstExperiment,
        'daily_routine': dailyRoutine,
        'encouragement': encouragement,
        'source': source,
      };

  factory GutPlan.fromJson(Map<String, dynamic> json, {String? source}) => GutPlan(
        headline: '${json['headline'] ?? 'Your 14-day GutMD plan'}',
        focusAreas: (json['focus_areas'] as List? ?? const [])
            .map((f) => PlanFocus.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList(),
        firstExperiment: '${json['first_experiment'] ?? ''}',
        dailyRoutine: (json['daily_routine'] as List? ?? const []).map((e) => '$e').toList(),
        encouragement: '${json['encouragement'] ?? ''}',
        source: source ?? '${json['source'] ?? 'local'}',
      );
}

/// Generates the plan shown at the end of onboarding.
class GutPlanService {
  GutPlanService._();

  static final Schema _schema = Schema.object(properties: {
    'headline': Schema.string(description: 'Short, warm plan title, max 8 words'),
    'focus_areas': Schema.array(
      items: Schema.object(properties: {
        'title': Schema.string(description: 'Max 5 words'),
        'detail': Schema.string(description: 'One practical sentence'),
      }),
      description: 'Exactly 3 focus areas',
    ),
    'first_experiment': Schema.string(
      description: 'One concrete, safe 5-day experiment to start with, one sentence',
    ),
    'daily_routine': Schema.array(
      items: Schema.string(),
      description: '3-4 short daily habits, each starting with a time of day',
    ),
    'encouragement': Schema.string(description: 'One supportive sentence'),
  });

  static Future<GutPlan> generate(OnboardingData data) async {
    if (GeminiClient.isAvailable) {
      try {
        final json = await GeminiClient.json(
          systemInstruction:
              'You write short, practical starter plans for a gut-health tracking app used by '
              'people with Crohn\'s, ulcerative colitis, IBS and related conditions. The plan is '
              'about tracking habits and gentle self-experiments. Never diagnose, never suggest '
              'stopping or changing prescribed medication, and recommend a clinician for severe '
              'or worsening symptoms. Keep every string concise.',
          prompt: 'Onboarding answers (JSON): ${_answers(data)}',
          schema: _schema,
        );
        final plan = GutPlan.fromJson(json, source: 'gemini');
        if (plan.focusAreas.isNotEmpty && plan.dailyRoutine.isNotEmpty) return plan;
      } catch (e) {
        debugPrint('GutPlanService: Gemini failed, using local plan: $e');
      }
    }
    return localPlan(data);
  }

  static Map<String, dynamic> _answers(OnboardingData data) => {
        'conditions': data.conditions.map((c) => c.displayName).toList(),
        'goal': data.goal,
        'diet_flags': data.dietFlags,
        'current_symptoms': data.currentSymptoms.map((s) => '${s.name} (${s.severity})').toList(),
        'supplements': data.supplements.map((s) => s.name).toList(),
        'medications_count': data.medications.length,
        'lifestyle': data.lifestyle,
        'reminder_times': data.notificationTimes,
      };

  static PlanFocus _goalFocus(String? goal) {
    switch (goal) {
      case 'identify_triggers':
        return const PlanFocus(
          'Find your trigger foods',
          'Log every meal (a photo is enough) so GutMD can link foods to how you feel.',
        );
      case 'improve_diet':
        return const PlanFocus(
          'Build your safe-food list',
          'Mark meals that sit well so you always have go-to options on tough days.',
        );
      case 'better_understanding':
        return const PlanFocus(
          'Learn your patterns',
          'A 20-second daily check-in is enough for weekly trend insights.',
        );
      case 'overall_wellness':
        return const PlanFocus(
          'Balance the basics',
          'Track sleep, stress and food together; they often move as a set.',
        );
      default:
        return const PlanFocus(
          'Calm your symptoms',
          'Rate how you feel each day so you can spot what helps and what hurts.',
        );
    }
  }

  /// Deterministic plan from the answers (offline mode and Gemini fallback).
  static GutPlan localPlan(OnboardingData data) {
    final conditions = data.conditions.map((c) => c.displayName).toList();
    final conditionText = conditions.isEmpty ? 'your gut' : conditions.first;
    final symptoms = data.currentSymptoms.map((s) => s.name).toList();
    final severe = data.currentSymptoms.any((s) => s.severity == 'Severe');

    final focus = <PlanFocus>[
      _goalFocus(data.goal),
      PlanFocus(
        symptoms.isEmpty ? 'Track your baseline' : 'Watch your ${symptoms.first.toLowerCase()}',
        symptoms.isEmpty
            ? 'Note bowel movements and comfort daily to set your personal baseline.'
            : 'Log it with a 1-5 severity so changes show up week to week.',
      ),
      data.supplements.isNotEmpty || data.medications.isNotEmpty
          ? const PlanFocus(
              'Stay consistent',
              'Tick off your supplements and meds so you can see whether they help.',
            )
          : const PlanFocus(
              'Rest and hydrate',
              'Steady fluids and regular sleep make it easier to read your gut signals.',
            ),
    ];

    final dietFlag = data.dietFlags.isEmpty ? null : data.dietFlags.first;
    final experiment = dietFlag != null
        ? 'For 5 days, log every meal and note how you feel 2-3 hours later, paying attention to ${dietFlag.toLowerCase()}.'
        : 'For 5 days, log every meal and note how you feel 2-3 hours later.';

    final morning = data.notificationTimes.isNotEmpty ? data.notificationTimes.first : 'Morning';
    final routine = <String>[
      '$morning: 20-second check-in: how do you feel?',
      'Meals: snap a photo or type what you ate',
      if (data.supplements.isNotEmpty || data.medications.isNotEmpty)
        'With meals: tick off supplements and meds',
      'Evening: log bowel movements and any symptoms',
    ];

    return GutPlan(
      headline: 'Your 14-day plan for $conditionText',
      focusAreas: focus,
      firstExperiment: experiment,
      dailyRoutine: routine,
      encouragement: severe
          ? 'You noted severe symptoms, so please keep your care team in the loop. GutMD will help you bring them clear notes.'
          : 'Small daily check-ins add up, and every one makes your insights sharper.',
      source: 'local',
    );
  }
}
