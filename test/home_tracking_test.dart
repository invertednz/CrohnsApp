import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/core/mock_backend.dart';
import 'package:gut_md/services/daily_log_service.dart';
import 'package:gut_md/services/home_tracking_service.dart';
import 'package:gut_md/services/meal_analysis_service.dart';

DailyLogEntry _entry(String id, String time, String text) =>
    DailyLogEntry(id: id, time: time, text: text);

void main() {
  group('HomeTrackingService', () {
    test('saves Home fields into the daily entry without dropping other screens\' fields', () async {
      final backend = MockBackend.create();
      final service = HomeTrackingService(tracking: backend.tracking, userId: 'u1');
      await backend.tracking.trackEvent(
        userId: 'u1',
        type: 'daily',
        data: {'date': '2026-09-24', 'pain_level': 3.0, 'notes': 'from tracking screen'},
      );

      await service.saveDaily('2026-09-24', {'feeling': 4});
      await service.saveDaily('2026-09-24', {'bowel_movements': 2, 'supplements_followed': true});

      final day = await service.loadDaily('2026-09-24');
      expect(day?['feeling'], 4);
      expect(day?['bowel_movements'], 2);
      expect(day?['supplements_followed'], isTrue);
      expect(day?['pain_level'], 3.0);
      expect(day?['notes'], 'from tracking screen');
      expect(await service.loadDaily('2026-09-23'), isNull);
    });

    test('data is kept per user', () async {
      final backend = MockBackend.create();
      final a = HomeTrackingService(tracking: backend.tracking, userId: 'a');
      final b = HomeTrackingService(tracking: backend.tracking, userId: 'b');
      await a.saveDaily('2026-09-24', {'feeling': 1});
      expect(await b.loadDaily('2026-09-24'), isNull);
    });

    test('log entries are stored per day, sorted by time, and never clobber each other', () async {
      final backend = MockBackend.create();
      final device1 = HomeTrackingService(tracking: backend.tracking, userId: 'u1');
      final device2 = HomeTrackingService(tracking: backend.tracking, userId: 'u1');

      await device1.addLog('2026-09-24', _entry('b', '12:30', 'Lunch'));
      await device2.addLog('2026-09-24', _entry('a', '08:00', 'Breakfast'));
      final saved = await device1.addLog('2026-09-23', _entry('c', '19:00', 'Dinner yesterday'));

      expect(saved.map((e) => e.text), ['Dinner yesterday']);
      final today = await device1.loadLogs('2026-09-24');
      expect(today.map((e) => e.text), ['Breakfast', 'Lunch']);

      final history = await device1.logHistory();
      expect(history.keys, containsAll(['2026-09-24', '2026-09-23']));
      expect(history['2026-09-24'], hasLength(2));
      expect(await device1.loadLogs('2026-09-22'), isEmpty);
    });

    test('log entries round-trip all analysed fields', () async {
      final backend = MockBackend.create();
      final service = HomeTrackingService(tracking: backend.tracking, userId: 'u1');
      const entry = DailyLogEntry(
        id: 'x',
        time: '09:15',
        text: 'Porridge and coffee',
        category: 'meal',
        foods: ['Porridge', 'Coffee'],
        symptoms: [
          {'name': 'Bloating', 'severity': 2},
        ],
        mood: 'calm',
        potentialTriggers: ['Coffee (caffeine)'],
        digestibilityScore: 6,
        digestibilityRationale: 'Oats are gentle but coffee can speed up the gut.',
        analysis: LogAnalysis.gemini,
      );
      await service.addLog('2026-09-24', entry);
      final loaded = (await service.loadLogs('2026-09-24')).single;
      expect(loaded.foods, ['Porridge', 'Coffee']);
      expect(loaded.symptoms.single['severity'], 2);
      expect(loaded.mood, 'calm');
      expect(loaded.digestibilityScore, 6);
      expect(loaded.analysis, LogAnalysis.gemini);
    });
  });

  group('HomeSummary', () {
    final today = DateTime(2026, 9, 24, 15, 30);

    test('a new user has no streak and no stats', () {
      final summary = HomeSummary.compute(daily: {}, logs: {}, today: today);
      expect(summary.streak, 0);
      expect(summary.daysTracked, 0);
      expect(summary.averageFeeling, isNull);
      expect(summary.hasAnyData, isFalse);
    });

    test('streak counts consecutive tracked days and survives an unlogged today', () {
      final daily = {
        '2026-09-23': {'date': '2026-09-23', 'feeling': 3},
        '2026-09-22': {'date': '2026-09-22', 'bowel_movements': 2},
        '2026-09-20': {'date': '2026-09-20', 'feeling': 1},
      };
      final summary = HomeSummary.compute(daily: daily, logs: {}, today: today);
      expect(summary.streak, 2);
      expect(summary.daysTracked, 3);
    });

    test('log entries count as tracking for the streak', () {
      final summary = HomeSummary.compute(
        daily: {'2026-09-23': {'date': '2026-09-23', 'feeling': 2}},
        logs: {'2026-09-24': [_entry('a', '08:00', 'Toast')]},
        today: today,
      );
      expect(summary.streak, 2);
    });

    test('a day with only zero bowel motions saved does not count as tracked', () {
      expect(HomeSummary.hasDailyData({'date': '2026-09-24', 'bowel_movements': 0}), isFalse);
      expect(HomeSummary.hasDailyData({'date': '2026-09-24', 'diet_followed': false}), isTrue);
    });

    test('average feeling includes "Terrible" (0) days', () {
      final summary = HomeSummary.compute(
        daily: {
          '2026-09-24': {'date': '2026-09-24', 'feeling': 0},
          '2026-09-23': {'date': '2026-09-23', 'feeling': 0},
        },
        logs: {},
        today: today,
      );
      expect(summary.averageFeeling, 0);
    });

    test('stats only use the last 30 days', () {
      final summary = HomeSummary.compute(
        daily: {
          '2026-09-24': {'date': '2026-09-24', 'feeling': 4, 'supplements_followed': true},
          '2026-09-10': {'date': '2026-09-10', 'feeling': 2, 'medications_followed': true},
          '2026-08-01': {'date': '2026-08-01', 'feeling': 0, 'diet_followed': true},
        },
        logs: {},
        today: today,
      );
      expect(summary.daysTracked, 2);
      expect(summary.averageFeeling, 3);
      expect(summary.supplementsDays, 1);
      expect(summary.medicationsDays, 1);
      expect(summary.dietDays, 0);
    });

    test('streak is capped at the loaded history', () {
      final daily = {
        for (var i = 0; i < 10; i++)
          HomeTrackingService.dateKey(DateTime(2026, 9, 24 - i)): {'feeling': 3},
      };
      final summary = HomeSummary.compute(daily: daily, logs: {}, today: today, maxStreakDays: 5);
      expect(summary.streak, 5);
      expect(summary.streakCapped, isTrue);
    });
  });

  group('DailyLogAnalyzer keyword fallback', () {
    test('flags common triggers but does not invent foods or a score', () {
      final entry = DailyLogAnalyzer.keywordAnalysis('Coffee and toast for breakfast');
      expect(entry.potentialTriggers, ['Coffee (caffeine)']);
      expect(entry.foods, isEmpty);
      expect(entry.digestibilityScore, isNull);
      expect(entry.analysis, LogAnalysis.keywords);
      expect(entry.category, 'meal');
      expect(entry.text, 'Coffee and toast for breakfast');
    });

    test('detects symptom words and respects negation', () {
      final entry = DailyLogAnalyzer.keywordAnalysis('Bloated and crampy after pizza, no nausea');
      expect(entry.symptoms.map((s) => s['name']), ['Cramping', 'Bloating']);
      expect(entry.potentialTriggers, ['Pizza (high-fat, dairy)']);

      final calm = DailyLogAnalyzer.keywordAnalysis("No pain today, didn't have coffee");
      expect(calm.symptoms, isEmpty);
      expect(calm.potentialTriggers, isEmpty);
      expect(calm.category, 'note');
    });

    test('does not flag dairy-free milk or partial words', () {
      final entry = DailyLogAnalyzer.keywordAnalysis('Oat milk latte, then painting and ginger tea');
      expect(entry.potentialTriggers, ['Latte (caffeine)']);
      expect(entry.symptoms, isEmpty);
    });

    test('analyzeText falls back to the keyword check without Gemini', () async {
      final entry = await DailyLogAnalyzer.analyzeText('Spicy curry for dinner');
      expect(entry.analysis, LogAnalysis.keywords);
      expect(entry.potentialTriggers, unorderedEquals(['Spicy (spicy food)', 'Curry (spicy food)']));
      expect(entry.digestibilityScore, isNull);
    });
  });

  group('DailyLogAnalyzer Gemini output', () {
    test('keeps structured fields and clamps out-of-range values', () {
      final entry = DailyLogAnalyzer.fromGeminiJson('Rice and banana, mild cramps', {
        'category': 'meal',
        'foods': ['White rice', 'Banana', 'banana'],
        'symptoms': [
          {'name': 'Cramps', 'severity': 9},
        ],
        'mood': '',
        'potential_triggers': [],
        'digestibility_score': 14,
        'digestibility_rationale': 'Low-fibre, gentle foods.',
      });
      expect(entry.foods, ['White rice', 'Banana']);
      expect(entry.symptoms.single['severity'], 5);
      expect(entry.mood, isNull);
      expect(entry.digestibilityScore, 10);
      expect(entry.analysis, LogAnalysis.gemini);
    });

    test('drops a score when no food was mentioned and unknown categories', () {
      final entry = DailyLogAnalyzer.fromGeminiJson('Went for a walk', {
        'category': 'exercise',
        'foods': [],
        'digestibility_score': 7,
        'digestibility_rationale': 'n/a',
      });
      expect(entry.digestibilityScore, isNull);
      expect(entry.digestibilityRationale, isNull);
      expect(entry.category, 'note');
    });

    test('photo entries carry the meal analysis and its source', () {
      final entry = DailyLogAnalyzer.fromMealPhoto(MealAnalysisResult(
        foods: ['Salmon'],
        description: 'Baked salmon',
        potentialTriggers: const [],
        digestibilityScore: 8,
        source: 'gemini',
      ));
      expect(entry.isPhoto, isTrue);
      expect(entry.text, 'Baked salmon');
      expect(entry.digestibilityScore, 8);
      expect(entry.analysis, LogAnalysis.gemini);
    });
  });

  group('MealAnalysisResult', () {
    test('parses the digestibility estimate', () {
      final result = MealAnalysisResult.fromJson({
        'foods': ['Toast'],
        'description': 'Plain toast',
        'digestibility_score': 8.4,
        'digestibility_rationale': ' Plain and low in fat. ',
      });
      expect(result.digestibilityScore, 8);
      expect(result.digestibilityRationale, 'Plain and low in fat.');
      expect(result.source, 'gemini');
    });

    test('ignores a score for a photo with no food', () {
      final result = MealAnalysisResult.fromJson({
        'foods': [],
        'description': 'A cat',
        'digestibility_score': 5,
      });
      expect(result.digestibilityScore, isNull);
    });
  });
}
