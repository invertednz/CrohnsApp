import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/core/mock_backend.dart';
import 'package:gut_md/services/ai_chat_service.dart';
import 'package:gut_md/services/insights_generator.dart';
import 'package:gut_md/services/meal_analysis_service.dart';

void main() {
  group('MockBackend tracking', () {
    test('stores entries per type and date, and updates in place', () async {
      final backend = MockBackend.create();
      final user = await backend.auth.signInAsGuest();
      final uid = user!.id;

      await backend.tracking.trackEvent(userId: uid, type: 'daily', data: {'date': '2026-09-20', 'feeling': 1});
      await backend.tracking.trackEvent(userId: uid, type: 'daily', data: {'date': '2026-09-21', 'feeling': 3});
      await backend.tracking.trackEvent(userId: uid, type: 'daily', data: {'date': '2026-09-21', 'feeling': 4});

      final day = await backend.tracking.getTrackingData(userId: uid, date: '2026-09-21', type: 'daily');
      expect(day?['feeling'], 4);

      final history = await backend.tracking.getTrackingHistory(userId: uid, type: 'daily');
      expect(history.map((e) => e['date']), ['2026-09-21', '2026-09-20']);
    });

    test('meal entries with entry_id do not overwrite each other on the same day', () async {
      final backend = MockBackend.create();
      const uid = 'u1';
      await backend.tracking.trackEvent(userId: uid, type: 'meal', data: {'entry_id': 'a', 'date': '2026-09-21', 'foods': ['Rice']});
      await backend.tracking.trackEvent(userId: uid, type: 'meal', data: {'entry_id': 'b', 'date': '2026-09-21', 'foods': ['Eggs']});
      final meals = await backend.tracking.getTrackingHistory(userId: uid, type: 'meal');
      expect(meals, hasLength(2));
    });
  });

  group('MockBackend auth', () {
    test('sign-up keeps the guest id so guest data carries over', () async {
      final backend = MockBackend.create();
      final guest = await backend.auth.signInAsGuest();
      final account = await backend.auth.signUpWithEmail(email: 'sam@example.com', password: 'secret1', userData: {'name': 'Sam'});
      expect(account!.id, guest!.id);
      expect(account.displayName, 'Sam');
      expect(account.isAnonymous, isFalse);
    });

    test('rejects short passwords', () async {
      final backend = MockBackend.create();
      expect(
        () => backend.auth.signUpWithEmail(email: 'sam@example.com', password: '123'),
        throwsException,
      );
    });

    test('sign out clears the current user', () async {
      final backend = MockBackend.create();
      await backend.auth.signInWithEmail(email: 'a@b.co', password: 'x');
      await backend.auth.signOut();
      expect(backend.auth.currentUser, isNull);
    });
  });

  group('Chat assistant (offline)', () {
    test('replies using the user\'s tracked data and keeps history', () async {
      final backend = MockBackend.create();
      const uid = 'u1';
      await backend.tracking.trackEvent(userId: uid, type: 'diet', data: {
        'date': '2026-09-21',
        'meals': [],
        'food_triggers': ['Dairy'],
        'safe_foods': ['Rice'],
      });

      final reply = await backend.chat.sendMessage(uid, 'What food should I eat?');
      expect(reply, contains('Rice'));
      expect(reply, contains('Dairy'));

      final history = await backend.chat.getChatHistory(uid);
      expect(history, hasLength(2));
      expect(history.first['isUser'], isTrue);
      expect(history.last['isUser'], isFalse);
    });

    test('AIChatService falls back without Firebase', () async {
      final reply = await const AIChatService().generateResponse(
        userMessage: 'I feel stressed',
        context: UserHealthContext(),
      );
      expect(reply, contains('Stress'));
    });
  });

  group('InsightsGenerator.localInsights', () {
    test('returns the shape the Insights screen renders', () {
      final insights = InsightsGenerator.localInsights({});
      expect(insights['health_summary'], isA<Map>());
      expect(insights['food_triggers'], isA<List>());
      expect(insights['beneficial_foods'], isA<List>());
      expect(insights['supplement_effectiveness'], isA<List>());
      expect(insights['recommendations'], isNotEmpty);
      expect(insights['source'], 'local');
    });

    test('links foods eaten on bad days to triggers and scores the user', () {
      final insights = InsightsGenerator.localInsights({
        'daily': [
          {'date': '2026-09-21', 'feeling': 0, 'pain_level': 7},
          {'date': '2026-09-20', 'feeling': 4, 'pain_level': 1},
        ],
        'diet': [
          {
            'date': '2026-09-21',
            'meals': [
              {'name': 'Lunch', 'foods': ['Pizza']},
            ],
          },
          {
            'date': '2026-09-20',
            'meals': [
              {'name': 'Lunch', 'foods': ['Rice']},
            ],
          },
        ],
      });
      final triggers = (insights['food_triggers'] as List).map((t) => t['food']);
      final good = (insights['beneficial_foods'] as List).map((t) => t['food']);
      expect(triggers, contains('Pizza'));
      expect(good, contains('Rice'));
      final score = (insights['health_summary'] as Map)['score'] as int;
      expect(score, inInclusiveRange(1, 100));
    });
  });

  group('buildHealthContext', () {
    test('folds analysed meals into the diet context', () {
      final context = buildHealthContext({
        'meal': [
          {'date': '2026-09-21', 'time': '12:30', 'foods': ['Salmon', 'Rice']},
        ],
      }, const []);
      expect(context.buildContextSummary(), contains('Salmon, Rice'));
    });
  });

  test('MealAnalysisResult parses Gemini JSON', () {
    final result = MealAnalysisResult.fromJson({
      'foods': ['Toast'],
      'description': 'Plain toast',
      'nutrition_estimate': {'calories': 120},
      'potential_triggers': ['Gluten'],
    });
    expect(result.foods, ['Toast']);
    expect(result.nutritionEstimate?['calories'], 120);
    expect(result.potentialTriggers, ['Gluten']);
  });
}
