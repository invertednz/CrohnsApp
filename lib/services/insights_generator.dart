import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' show Schema;
import 'package:flutter/foundation.dart';

import 'package:gut_md/services/gemini_client.dart';

/// Builds the insights document shown on the Insights screen from a user's
/// tracked history.
///
/// Shape:
/// {
///   health_summary: {score: int 0-100 | null, trend: improving|stable|worsening|unknown, description},
///   food_triggers: [{food, correlation: 0-1, note}],
///   beneficial_foods: [{food, impact: 0-1, note}],
///   supplement_effectiveness: [{name, effectiveness: 0-1 | null, note}],
///   recommendations: [{title, description, category: diet|lifestyle|supplements|medical|general}],
///   data_points: int, generated_at, source: gemini|local
/// }
///
/// Every number is derived from the user's own logs; when there is not enough
/// data the score is null and the trend is `unknown` rather than a guess.
class InsightsGenerator {
  InsightsGenerator._();

  static const _trends = ['improving', 'stable', 'worsening', 'unknown'];
  static const _categories = ['diet', 'lifestyle', 'supplements', 'medical', 'general'];

  static final Schema _schema = Schema.object(properties: {
    'health_summary': Schema.object(properties: {
      'score': Schema.integer(
        description: 'Wellbeing 0-100 from logged feeling and pain; null when nothing about feeling is logged',
        nullable: true,
      ),
      'trend': Schema.enumString(enumValues: _trends),
      'description': Schema.string(description: 'Two supportive sentences referencing the data'),
    }),
    'food_triggers': Schema.array(
      items: Schema.object(properties: {
        'food': Schema.string(),
        'correlation': Schema.number(description: '0-1 strength of link to bad days'),
        'note': Schema.string(description: 'The evidence from the logs, e.g. "Eaten on 3 of 4 tough days"'),
      }),
    ),
    'beneficial_foods': Schema.array(
      items: Schema.object(properties: {
        'food': Schema.string(),
        'impact': Schema.number(description: '0-1 strength of link to good days'),
        'note': Schema.string(description: 'The evidence from the logs'),
      }),
    ),
    'supplement_effectiveness': Schema.array(
      items: Schema.object(properties: {
        'name': Schema.string(),
        'effectiveness': Schema.number(
          description: '0-1 share of logged days taken that were good days; null without data',
          nullable: true,
        ),
        'note': Schema.string(description: 'The evidence from the logs'),
      }),
    ),
    'recommendations': Schema.array(
      items: Schema.object(properties: {
        'title': Schema.string(),
        'description': Schema.string(),
        'category': Schema.enumString(enumValues: _categories),
      }),
    ),
  });

  /// Generate insights with Gemini, falling back to on-device statistics.
  ///
  /// Gemini is only asked when there is something to analyse; it receives the
  /// on-device statistics alongside the raw logs so its numbers stay grounded.
  static Future<Map<String, dynamic>> generate(
    Map<String, List<Map<String, dynamic>>> history,
  ) async {
    final local = localInsights(history);
    final dataPoints = local['data_points'] as int;
    if (dataPoints > 0 && GeminiClient.isAvailable) {
      try {
        final result = await GeminiClient.json(
          systemInstruction:
              'You analyse symptom, diet, supplement and wellbeing logs for people '
              'with Crohn\'s disease, UC or IBS. Feeling is 0 (terrible) to 4 (great); '
              'pain and energy are 0-10. Only claim correlations the data supports and '
              'explain the evidence in each "note" (for example "Eaten on 3 of 4 tough days"). '
              'With little data, say so, use trend "unknown", and focus on what to track next. '
              'Never diagnose, never invent numbers, and suggest discussing medication or '
              'diet changes with the care team.',
          prompt: 'On-device statistics (JSON):\n${jsonEncode(local)}\n\n'
              'Tracked history (JSON, newest first):\n${jsonEncode(history)}',
          schema: _schema,
        );
        return {
          ...normalize(result),
          'data_points': dataPoints,
          'generated_at': DateTime.now().toIso8601String(),
          'source': 'gemini',
        };
      } catch (e) {
        debugPrint('InsightsGenerator: Gemini failed, using local analysis: $e');
      }
    }
    return local;
  }

  /// Coerces a model response into the shape the Insights screen expects:
  /// values clamped to their ranges, unknown enums replaced, lists guaranteed.
  @visibleForTesting
  static Map<String, dynamic> normalize(Map<String, dynamic> raw) {
    double? unit(Object? v) => v is num ? v.toDouble().clamp(0.0, 1.0) : null;
    List<Map<String, dynamic>> items(Object? list) => list is List
        ? list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
        : <Map<String, dynamic>>[];

    final summary = raw['health_summary'] is Map
        ? Map<String, dynamic>.from(raw['health_summary'] as Map)
        : <String, dynamic>{};
    final score = summary['score'];
    final trend = summary['trend'];

    return {
      'health_summary': {
        'score': score is num ? score.round().clamp(0, 100) : null,
        'trend': _trends.contains(trend) ? trend : 'unknown',
        'description': '${summary['description'] ?? ''}',
      },
      'food_triggers': [
        for (final t in items(raw['food_triggers']))
          if ('${t['food'] ?? ''}'.trim().isNotEmpty)
            {'food': '${t['food']}', 'correlation': unit(t['correlation']) ?? 0.0, 'note': t['note']},
      ],
      'beneficial_foods': [
        for (final f in items(raw['beneficial_foods']))
          if ('${f['food'] ?? ''}'.trim().isNotEmpty)
            {'food': '${f['food']}', 'impact': unit(f['impact']) ?? 0.0, 'note': f['note']},
      ],
      'supplement_effectiveness': [
        for (final s in items(raw['supplement_effectiveness']))
          if ('${s['name'] ?? ''}'.trim().isNotEmpty)
            {'name': '${s['name']}', 'effectiveness': unit(s['effectiveness']), 'note': s['note']},
      ],
      'recommendations': [
        for (final r in items(raw['recommendations']))
          if ('${r['title'] ?? ''}'.trim().isNotEmpty)
            {
              'title': '${r['title']}',
              'description': '${r['description'] ?? ''}',
              'category': _categories.contains(r['category']) ? r['category'] : 'general',
            },
      ],
    };
  }

  /// Deterministic insights computed from the tracked data on-device.
  static Map<String, dynamic> localInsights(
    Map<String, List<Map<String, dynamic>>> history,
  ) {
    final daily = history['daily'] ?? const <Map<String, dynamic>>[];
    final diet = history['diet'] ?? const <Map<String, dynamic>>[];
    final meals = history['meal'] ?? const <Map<String, dynamic>>[];
    final supplements = history['supplements'] ?? const <Map<String, dynamic>>[];
    final symptoms = history['symptoms'] ?? const <Map<String, dynamic>>[];
    final dataPoints =
        daily.length + diet.length + meals.length + supplements.length + symptoms.length;

    // Only days where the user actually rated how they felt count as good/tough.
    int? feelingOf(Map<String, dynamic> d) {
      final v = d['feeling'];
      return v is num ? v.toInt().clamp(0, 4) : null;
    }

    final rated = daily.where((d) => feelingOf(d) != null).toList();
    final feelingByDate = {for (final d in rated) '${d['date']}': feelingOf(d)!};
    final badDates = {for (final e in feelingByDate.entries) if (e.value <= 1) e.key};
    final goodDates = {for (final e in feelingByDate.entries) if (e.value >= 3) e.key};

    // Foods eaten per day, matched case-insensitively (first spelling is shown).
    final foodNames = <String, String>{};
    String foodKey(Object? food) {
      final name = '$food'.trim();
      final key = name.toLowerCase();
      foodNames.putIfAbsent(key, () => name);
      return key;
    }

    final foodsByDate = <String, Set<String>>{};
    void addFoods(Object? date, Object? foods) {
      if (date == null || foods is! List) return;
      final day = foodsByDate.putIfAbsent('$date', () => <String>{});
      for (final food in foods) {
        if ('$food'.trim().isNotEmpty) day.add(foodKey(food));
      }
    }

    for (final d in diet) {
      for (final meal in (d['meals'] as List? ?? const [])) {
        if (meal is Map) addFoods(d['date'], meal['foods']);
      }
    }
    for (final m in meals) {
      addFoods(m['date'], m['foods']);
    }

    Map<String, int> countOn(Set<String> dates) {
      final counts = <String, int>{};
      for (final date in dates) {
        for (final food in foodsByDate[date] ?? const <String>{}) {
          counts[food] = (counts[food] ?? 0) + 1;
        }
      }
      return counts;
    }

    final badCounts = countOn(badDates);
    final goodCounts = countOn(goodDates);
    double share(int? n, int total) => total == 0 ? 0 : (n ?? 0) / total;
    String days(int n, String kind) => '$n $kind day${n == 1 ? '' : 's'}';
    String evidence(String food) {
      final parts = <String>[
        if (badDates.isNotEmpty) '${badCounts[food] ?? 0} of ${days(badDates.length, 'tough')}',
        if (goodDates.isNotEmpty) '${goodCounts[food] ?? 0} of ${days(goodDates.length, 'good')}',
      ];
      return 'Eaten on ${parts.join(' and ')}';
    }

    // The trigger / safe-food lists the user saved most recently.
    Map<String, dynamic>? flaggedSource;
    for (final d in diet) {
      if (!d.containsKey('food_triggers') && !d.containsKey('safe_foods')) continue;
      if (flaggedSource == null ||
          '${d['recorded_at'] ?? ''}'.compareTo('${flaggedSource['recorded_at'] ?? ''}') > 0) {
        flaggedSource = d;
      }
    }
    final flaggedTriggers = [
      for (final t in (flaggedSource?['food_triggers'] as List? ?? const [])) foodKey(t),
    ];
    final flaggedSafe = [
      for (final s in (flaggedSource?['safe_foods'] as List? ?? const [])) foodKey(s),
    ];

    List<Map<String, dynamic>> ranked({
      required Map<String, int> towards,
      required Set<String> towardsDates,
      required Map<String, int> away,
      required Set<String> awayDates,
      required List<String> flagged,
      required List<String> excluded,
      required String scoreKey,
      required String flaggedNote,
    }) {
      final scores = <String, double>{};
      for (final food in towards.keys) {
        final score = share(towards[food], towardsDates.length) - share(away[food], awayDates.length);
        if (score > 0 && !excluded.contains(food)) scores[food] = score;
      }
      final entries = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final result = <Map<String, dynamic>>[
        for (final e in entries.take(5))
          {
            'food': foodNames[e.key],
            scoreKey: double.parse(e.value.toStringAsFixed(2)),
            'note': flagged.contains(e.key) ? '$flaggedNote · ${evidence(e.key)}' : evidence(e.key),
          },
      ];
      for (final food in flagged) {
        if (result.any((r) => '${r['food']}'.toLowerCase() == food)) continue;
        final seen = foodsByDate.values.any((foods) => foods.contains(food));
        result.add({
          'food': foodNames[food],
          scoreKey: double.parse((scores[food] ?? 0).toStringAsFixed(2)),
          'note': seen && (badDates.isNotEmpty || goodDates.isNotEmpty)
              ? '$flaggedNote · ${evidence(food)}'
              : flaggedNote,
        });
      }
      return result;
    }

    final triggers = ranked(
      towards: badCounts,
      towardsDates: badDates,
      away: goodCounts,
      awayDates: goodDates,
      flagged: flaggedTriggers,
      excluded: flaggedSafe,
      scoreKey: 'correlation',
      flaggedNote: 'You marked this as a trigger',
    );
    final beneficial = ranked(
      towards: goodCounts,
      towardsDates: goodDates,
      away: badCounts,
      awayDates: badDates,
      flagged: flaggedSafe,
      excluded: flaggedTriggers,
      scoreKey: 'impact',
      flaggedNote: 'You marked this as a safe food',
    );

    // Wellbeing score and trend from the most recent rated days.
    final recent = rated.take(7).toList();
    final older = rated.skip(7).take(7).toList();
    double avgFeeling(List<Map<String, dynamic>> list) =>
        list.map((d) => feelingOf(d)!).reduce((a, b) => a + b) / list.length;
    double? average(Iterable<Object?> values) {
      final nums = values.whereType<num>().map((n) => n.toDouble()).toList();
      return nums.isEmpty ? null : nums.reduce((a, b) => a + b) / nums.length;
    }

    var trend = 'unknown';
    if (recent.length >= 3 && older.length >= 3) {
      final change = avgFeeling(recent) - avgFeeling(older);
      trend = change > 0.3
          ? 'improving'
          : change < -0.3
              ? 'worsening'
              : 'stable';
    }
    final avgPain = average(recent.map((d) => d['pain_level']));
    final avgBowel = average(daily.take(7).map((d) => d['bowel_movements']));
    final int? score = recent.isEmpty
        ? null
        : avgPain == null
            ? (avgFeeling(recent) / 4 * 100).round().clamp(0, 100)
            : ((avgFeeling(recent) / 4) * 70 + (1 - avgPain / 10) * 30).round().clamp(0, 100);

    final okayDays = rated.length - goodDates.length - badDates.length;
    final String description;
    if (rated.isEmpty) {
      description = dataPoints == 0
          ? 'Start logging how you feel to see your wellbeing score and patterns.'
          : 'Rate how you feel each day to see your wellbeing score and trend.';
    } else {
      description = 'Based on ${rated.length} rated day${rated.length == 1 ? '' : 's'}: '
          '${goodDates.length} good, $okayDays okay and ${badDates.length} tough.'
          '${avgPain == null ? '' : ' Recent average pain: ${avgPain.toStringAsFixed(1)}/10.'}';
    }

    // Supplements: how often the days they were taken were good days.
    final suppNames = <String, String>{};
    final takenDates = <String, Set<String>>{};
    for (final entry in supplements) {
      for (final s in (entry['supplements'] as List? ?? const [])) {
        if (s is! Map || s['taken'] != true) continue;
        final name = '${s['name'] ?? ''}'.trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        suppNames.putIfAbsent(key, () => name);
        takenDates.putIfAbsent(key, () => <String>{}).add('${entry['date']}');
      }
    }
    final suppInsights = <Map<String, dynamic>>[];
    for (final e in takenDates.entries) {
      final ratedDays = e.value.where(feelingByDate.containsKey).toList();
      final good = ratedDays.where(goodDates.contains).length;
      suppInsights.add({
        'name': suppNames[e.key],
        'effectiveness': ratedDays.isEmpty ? null : double.parse((good / ratedDays.length).toStringAsFixed(2)),
        'note': ratedDays.isEmpty
            ? 'Taken on ${days(e.value.length, 'logged')}. Rate how you feel on those days to compare.'
            : 'Taken on ${days(ratedDays.length, 'rated')}; you felt good on $good.',
      });
    }

    // Strongest trigger backed by the logs (not just the user's own flag).
    String? topTrigger;
    for (final t in triggers) {
      if ((t['correlation'] as double) > 0) {
        topTrigger = '${t['food']}'.toLowerCase();
        break;
      }
    }
    final recommendations = <Map<String, dynamic>>[
      if (rated.length < 7)
        {
          'title': 'Build your baseline',
          'description': 'Log how you feel daily for a week so patterns can emerge. '
              'You have ${rated.length} rated day${rated.length == 1 ? '' : 's'} so far.',
          'category': 'general',
        },
      if (topTrigger != null)
        {
          'title': 'Test a possible trigger',
          'description': '${foodNames[topTrigger]} was eaten on ${badCounts[topTrigger] ?? 0} of '
              'your ${days(badDates.length, 'tough')}. Try leaving it out for a few days and note '
              'how you feel. Check with your care team or dietitian before cutting out whole food groups.',
          'category': 'diet',
        },
      if (avgPain != null && avgPain >= 5)
        {
          'title': 'Talk to your care team',
          'description': 'Your recent average pain is ${avgPain.toStringAsFixed(1)}/10. '
              'Consider sharing your log with your doctor.',
          'category': 'medical',
        },
      if (avgBowel != null && avgBowel > 3)
        {
          'title': 'Keep an eye on frequency',
          'description': 'You have averaged ${avgBowel.toStringAsFixed(1)} bowel movements a day recently. '
              'If that is more than usual for you, or you notice blood, let your care team know.',
          'category': 'medical',
        },
      {
        'title': 'Note sleep and stress',
        'description': 'Add sleep, stress and hydration to your daily notes so you can see '
            'whether they line up with your better and worse days.',
        'category': 'lifestyle',
      },
    ];

    return {
      'health_summary': {
        'score': score,
        'trend': trend,
        'description': description,
      },
      'food_triggers': triggers,
      'beneficial_foods': beneficial,
      'supplement_effectiveness': suppInsights,
      'recommendations': recommendations,
      'data_points': dataPoints,
      'generated_at': DateTime.now().toIso8601String(),
      'source': 'local',
    };
  }
}
