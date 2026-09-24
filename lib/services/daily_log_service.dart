import 'package:firebase_ai/firebase_ai.dart' show Schema;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:gut_md/services/gemini_client.dart';
import 'package:gut_md/services/meal_analysis_service.dart';

/// How a daily log entry was analysed.
class LogAnalysis {
  LogAnalysis._();

  /// Structured by Gemini from the user's text or meal photo.
  static const String gemini = 'gemini';

  /// Gemini was unavailable: only a keyword check against commonly reported
  /// IBD/IBS triggers and symptom words was done. No score is given.
  static const String keywords = 'keywords';

  /// Deterministic meal-photo analysis of the offline test build.
  static const String sample = 'sample';
}

/// One entry in the Home screen's "Daily Logs": something the user ate, did
/// or felt, typed as free text or captured as a meal photo.
///
/// Entries are stored per day as tracking type `log`:
/// `{date: yyyy-MM-dd, entries: [DailyLogEntry.toJson(), ...]}`.
class DailyLogEntry {
  final String id;

  /// Time of day the entry was logged, `HH:mm` (24h).
  final String time;

  /// What the user typed, or the description of a meal photo.
  final String text;

  /// `text` or `photo`.
  final String source;

  /// meal | drink | symptom | bowel_movement | activity | mood | medication | note
  final String category;
  final List<String> foods;

  /// `{name: String, severity: int 1-5 or null}`.
  final List<Map<String, dynamic>> symptoms;
  final String? mood;
  final List<String> potentialTriggers;

  /// AI estimate (1 = likely to aggravate, 10 = very gentle) of how easy the
  /// foods are on a sensitive gut. Null when not scored.
  final int? digestibilityScore;
  final String? digestibilityRationale;

  /// One of [LogAnalysis].
  final String analysis;

  const DailyLogEntry({
    required this.id,
    required this.time,
    required this.text,
    this.source = 'text',
    this.category = 'note',
    this.foods = const [],
    this.symptoms = const [],
    this.mood,
    this.potentialTriggers = const [],
    this.digestibilityScore,
    this.digestibilityRationale,
    this.analysis = LogAnalysis.keywords,
  });

  bool get isPhoto => source == 'photo';

  Map<String, dynamic> toJson() => {
        'entry_id': id,
        'time': time,
        'text': text,
        'source': source,
        'category': category,
        'foods': foods,
        'symptoms': symptoms,
        'mood': mood,
        'potential_triggers': potentialTriggers,
        'digestibility_score': digestibilityScore,
        'digestibility_rationale': digestibilityRationale,
        'analysis': analysis,
      };

  factory DailyLogEntry.fromJson(Map<String, dynamic> json) {
    return DailyLogEntry(
      id: '${json['entry_id'] ?? ''}',
      time: '${json['time'] ?? ''}',
      text: '${json['text'] ?? ''}',
      source: '${json['source'] ?? 'text'}',
      category: '${json['category'] ?? 'note'}',
      foods: _strings(json['foods']),
      symptoms: _symptoms(json['symptoms']),
      mood: _optionalString(json['mood']),
      potentialTriggers: _strings(json['potential_triggers']),
      digestibilityScore: _score(json['digestibility_score']),
      digestibilityRationale: _optionalString(json['digestibility_rationale']),
      analysis: '${json['analysis'] ?? LogAnalysis.keywords}',
    );
  }

  /// The meal this entry describes, for the `meal` history the AI reads.
  MealAnalysisResult toMealAnalysis(DateTime loggedAt) => MealAnalysisResult(
        foods: foods,
        description: text,
        potentialTriggers: potentialTriggers,
        digestibilityScore: digestibilityScore,
        digestibilityRationale: digestibilityRationale,
        source: analysis == LogAnalysis.gemini ? 'gemini' : 'sample',
        timestamp: loggedAt,
      );
}

/// Turns free text and meal photos into [DailyLogEntry]s.
///
/// Uses Gemini (Firebase AI Logic) when available. Without it, it falls back
/// to an honest keyword check: it flags commonly reported trigger foods and
/// symptom words the text mentions, and does not make up a score.
class DailyLogAnalyzer {
  DailyLogAnalyzer._();

  static const List<String> categories = [
    'meal',
    'drink',
    'symptom',
    'bowel_movement',
    'activity',
    'mood',
    'medication',
    'note',
  ];

  static final Schema _schema = Schema.object(properties: {
    'category': Schema.enumString(
      enumValues: categories,
      description: 'What the entry is mainly about',
    ),
    'foods': Schema.array(
      items: Schema.string(),
      description: 'Foods and drinks the text says were consumed. Empty if none.',
    ),
    'symptoms': Schema.array(
      items: Schema.object(properties: {
        'name': Schema.string(description: 'Symptom, e.g. "Bloating"'),
        'severity': Schema.integer(
          nullable: true,
          minimum: 1,
          maximum: 5,
          description: '1 = very mild, 5 = severe; null if the text gives no hint',
        ),
      }),
      description: 'Symptoms the text says the user has. Empty if none.',
    ),
    'mood': Schema.string(
      nullable: true,
      description: 'Mood or stress level the text states, e.g. "stressed"; null if not stated',
    ),
    'potential_triggers': Schema.array(
      items: Schema.string(),
      description: 'Mentioned foods/drinks that commonly trigger IBD/IBS symptoms, '
          'with the reason, e.g. "Coffee (caffeine)"',
    ),
    'digestibility_score': Schema.integer(
      nullable: true,
      minimum: 1,
      maximum: 10,
      description: 'How gentle the foods/drinks are likely to be on a sensitive or '
          'inflamed gut: 10 = very gentle, 1 = very likely to aggravate. '
          'Null when no food or drink is mentioned.',
    ),
    'digestibility_rationale': Schema.string(
      nullable: true,
      description: 'One short sentence explaining the score; null when not scored',
    ),
  });

  static const String _systemInstruction =
      'You turn short diary entries from people with Crohn\'s disease, ulcerative '
      'colitis or IBS into structured data. Only extract what the text actually '
      'says: never invent foods, symptoms or moods, and respect negations '
      '("no pain" is not a symptom). The digestibility score is a general '
      'estimate, not medical advice.';

  /// Analyse a free-text entry, preferring Gemini.
  static Future<DailyLogEntry> analyzeText(String text, {DateTime? now}) async {
    final loggedAt = now ?? DateTime.now();
    if (GeminiClient.isAvailable) {
      try {
        final json = await GeminiClient.json(
          systemInstruction: _systemInstruction,
          prompt: 'Diary entry: """$text"""',
          schema: _schema,
        );
        return fromGeminiJson(text, json, now: loggedAt);
      } catch (e) {
        debugPrint('DailyLogAnalyzer: Gemini unavailable, using keyword check: $e');
      }
    }
    return keywordAnalysis(text, now: loggedAt);
  }

  /// Builds an entry from Gemini's structured output, discarding anything
  /// out of range and any score given without food.
  @visibleForTesting
  static DailyLogEntry fromGeminiJson(
    String text,
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final loggedAt = now ?? DateTime.now();
    final foods = _strings(json['foods']);
    final category = categories.contains(json['category']) ? json['category'] as String : 'note';
    final score = foods.isEmpty ? null : _score(json['digestibility_score']);
    return DailyLogEntry(
      id: newEntryId(loggedAt),
      time: DateFormat('HH:mm').format(loggedAt),
      text: text,
      category: category,
      foods: foods,
      symptoms: _symptoms(json['symptoms']),
      mood: _optionalString(json['mood']),
      potentialTriggers: _strings(json['potential_triggers']),
      digestibilityScore: score,
      digestibilityRationale: score == null ? null : _optionalString(json['digestibility_rationale']),
      analysis: LogAnalysis.gemini,
    );
  }

  /// Log entry for an analysed meal photo.
  static DailyLogEntry fromMealPhoto(MealAnalysisResult meal, {DateTime? now}) {
    final loggedAt = now ?? DateTime.now();
    return DailyLogEntry(
      id: newEntryId(loggedAt),
      time: DateFormat('HH:mm').format(loggedAt),
      text: meal.description.trim().isEmpty ? 'Meal photo' : meal.description.trim(),
      source: 'photo',
      category: 'meal',
      foods: meal.foods,
      potentialTriggers: meal.potentialTriggers ?? const [],
      digestibilityScore: meal.digestibilityScore,
      digestibilityRationale: meal.digestibilityRationale,
      analysis: meal.source == 'gemini' ? LogAnalysis.gemini : LogAnalysis.sample,
    );
  }

  static String newEntryId(DateTime at) =>
      'log_${DateFormat('yyyyMMdd_HHmmss').format(at)}_${at.microsecondsSinceEpoch % 1000000}';

  /// Commonly reported IBD/IBS food triggers (keyword -> reason). Keywords are
  /// matched as whole words, with an optional plural.
  static const Map<String, String> _triggerKeywords = {
    'coffee': 'caffeine',
    'espresso': 'caffeine',
    'latte': 'caffeine',
    'cappuccino': 'caffeine',
    'energy drink': 'caffeine',
    'beer': 'alcohol',
    'wine': 'alcohol',
    'vodka': 'alcohol',
    'whisky': 'alcohol',
    'whiskey': 'alcohol',
    'cocktail': 'alcohol',
    'alcohol': 'alcohol',
    'milk': 'dairy/lactose',
    'cheese': 'dairy/lactose',
    'ice cream': 'dairy/lactose',
    'cream': 'dairy/lactose',
    'yogurt': 'dairy/lactose',
    'yoghurt': 'dairy/lactose',
    'milkshake': 'dairy/lactose',
    'spicy': 'spicy food',
    'chili': 'spicy food',
    'chilli': 'spicy food',
    'curry': 'spicy food',
    'hot sauce': 'spicy food',
    'jalapeno': 'spicy food',
    'fried': 'fried/high-fat',
    'fries': 'fried/high-fat',
    'burger': 'high-fat',
    'pizza': 'high-fat, dairy',
    'bacon': 'high-fat',
    'sausage': 'high-fat',
    'soda': 'carbonated',
    'cola': 'carbonated',
    'fizzy': 'carbonated',
    'sparkling': 'carbonated',
    'sweetener': 'artificial sweetener',
    'sugar-free': 'artificial sweetener',
    'sorbitol': 'artificial sweetener',
    'xylitol': 'artificial sweetener',
    'bean': 'high-FODMAP',
    'lentil': 'high-FODMAP',
    'chickpea': 'high-FODMAP',
    'onion': 'high-FODMAP',
    'garlic': 'high-FODMAP',
    'cauliflower': 'high-FODMAP',
    'broccoli': 'high fibre',
    'cabbage': 'high fibre',
    'nut': 'insoluble fibre',
    'seed': 'insoluble fibre',
    'popcorn': 'insoluble fibre',
    'corn': 'insoluble fibre',
  };

  /// Symptom word patterns (regex source) -> symptom name.
  static const Map<String, String> _symptomPatterns = {
    r'joint pains?': 'Joint pain',
    r'(?:stomach|tummy|belly) ?aches?': 'Abdominal pain',
    r'(?:stomach|tummy|belly|abdominal) pains?': 'Abdominal pain',
    r'cramp\w*': 'Cramping',
    r'bloat\w*': 'Bloating',
    r'gas|gassy|flatulen\w*': 'Gas',
    r'diarrh\w*|loose stools?': 'Diarrhea',
    r'constipat\w*': 'Constipation',
    r'nause\w*': 'Nausea',
    r'vomit\w*|threw up|throwing up': 'Vomiting',
    r'tired|fatigue\w*|exhausted': 'Fatigue',
    r'urgency': 'Urgency',
    r'heartburn|reflux': 'Heartburn/reflux',
    r'headaches?': 'Headache',
    r'pains?|painful': 'Pain',
  };

  static const Set<String> _negations = {'no', 'not', 'without', 'never', 'zero'};

  /// Variants of trigger words that are not the trigger, checked first so
  /// "oat milk" is not flagged as dairy.
  static const List<String> _nonTriggerPhrases = [
    'almond milk',
    'oat milk',
    'soy milk',
    'soya milk',
    'rice milk',
    'coconut milk',
    'lactose-free milk',
    'lactose free milk',
    'dairy-free cheese',
    'vegan cheese',
    'lactose-free yogurt',
    'lactose-free yoghurt',
  ];

  /// Offline analysis: flags trigger foods and symptom words mentioned in the
  /// text. It does not extract a food list or score the entry.
  static DailyLogEntry keywordAnalysis(String text, {DateTime? now}) {
    final loggedAt = now ?? DateTime.now();
    var remaining = ' ${text.toLowerCase()} ';

    final symptoms = <String>[];
    for (final pattern in _symptomPatterns.entries) {
      final result = _consume(remaining, pattern.key);
      remaining = result.remaining;
      if (result.matched && !symptoms.contains(pattern.value)) {
        symptoms.add(pattern.value);
      }
    }

    for (final phrase in _nonTriggerPhrases) {
      remaining = _consume(remaining, RegExp.escape(phrase)).remaining;
    }

    final triggers = <String>[];
    final keywords = _triggerKeywords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final keyword in keywords) {
      final result = _consume(remaining, '${RegExp.escape(keyword)}(?:e?s)?');
      remaining = result.remaining;
      if (result.matched) {
        triggers.add('${_capitalize(keyword)} (${_triggerKeywords[keyword]})');
      }
    }

    final category = triggers.isNotEmpty
        ? 'meal'
        : symptoms.isNotEmpty
            ? 'symptom'
            : 'note';
    return DailyLogEntry(
      id: newEntryId(loggedAt),
      time: DateFormat('HH:mm').format(loggedAt),
      text: text,
      category: category,
      symptoms: [
        for (final name in symptoms) {'name': name, 'severity': null},
      ],
      potentialTriggers: triggers,
      analysis: LogAnalysis.keywords,
    );
  }

  /// Finds un-negated whole-word matches of [pattern] and blanks them out so
  /// shorter patterns do not match the same words again.
  static _Consumed _consume(String text, String pattern) {
    final regex = RegExp('\\b(?:$pattern)\\b');
    var matched = false;
    final remaining = text.replaceAllMapped(regex, (m) {
      if (!_isNegated(text.substring(0, m.start))) matched = true;
      return ' ' * (m.end - m.start);
    });
    return _Consumed(matched, remaining);
  }

  static bool _isNegated(String before) {
    final words = before
        .replaceAll('’', "'")
        .split(RegExp(r"[^a-z']+"))
        .where((w) => w.isNotEmpty)
        .toList();
    final recent = words.length > 3 ? words.sublist(words.length - 3) : words;
    return recent.any((w) => _negations.contains(w) || w.endsWith("n't"));
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Consumed {
  final bool matched;
  final String remaining;
  const _Consumed(this.matched, this.remaining);
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  final seen = <String>{};
  return [
    for (final item in value)
      if (item != null && '$item'.trim().isNotEmpty && seen.add('$item'.trim().toLowerCase()))
        '$item'.trim(),
  ];
}

List<Map<String, dynamic>> _symptoms(Object? value) {
  if (value is! List) return const [];
  final result = <Map<String, dynamic>>[];
  for (final item in value) {
    if (item is! Map) continue;
    final name = '${item['name'] ?? ''}'.trim();
    if (name.isEmpty) continue;
    final severity = item['severity'];
    result.add({
      'name': name,
      'severity': severity is num ? severity.round().clamp(1, 5) : null,
    });
  }
  return result;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  final s = '$value'.trim();
  return s.isEmpty || s.toLowerCase() == 'null' ? null : s;
}

int? _score(Object? value) => value is num ? value.round().clamp(1, 10) : null;
