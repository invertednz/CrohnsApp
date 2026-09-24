import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/screens/chat/chat_screen.dart';
import 'package:gut_md/services/ai_chat_service.dart';
import 'package:gut_md/services/gemini_client.dart';

Future<String> ask(String message, [UserHealthContext? context]) {
  return const AIChatService().generateResponse(
    userMessage: message,
    context: context ?? UserHealthContext(),
  );
}

void main() {
  group('AIChatService offline replies', () {
    test('stress questions get stress guidance, not the symptom reply', () async {
      final reply = await ask('Can stress trigger digestive symptoms?');
      expect(reply, startsWith('Stress'));
    });

    test('food questions mention the user\'s triggers and safe foods', () async {
      final reply = await ask(
        'What foods should I avoid with my condition?',
        UserHealthContext(foodTriggers: ['Dairy', 'Spicy food'], safeFoods: ['Rice']),
      );
      expect(reply, contains('Dairy, Spicy food'));
      expect(reply, contains('Rice'));
    });

    test('food questions without data explain how to add triggers', () async {
      final reply = await ask('What should I eat?');
      expect(reply, contains("haven't marked any food triggers"));
    });

    test('"great" is not treated as a food question', () async {
      final reply = await ask('I feel great today');
      expect(reply, isNot(contains('food triggers')));
    });

    test('"yoghurt" is not treated as "hurt" (keywords match whole words)', () async {
      final reply = await ask('I had yoghurt and banana for breakfast');
      expect(reply, contains('Trigger foods differ'));
      expect(reply, isNot(contains('heat pad')));
    });

    test('red-flag symptoms get urgent-care advice', () async {
      final reply = await ask('There is blood in my stool');
      expect(reply, contains('urgent'));
      expect(reply, contains('doctor'));
    });

    test('self-harm mentions point to crisis support', () async {
      final reply = await ask('I want to end my life');
      expect(reply, contains('crisis line'));
    });

    test('medication questions use the medication log', () async {
      final reply = await ask(
        'Did I take my medication?',
        UserHealthContext(recentMedications: [
          {
            'date': '2026-09-21',
            'medications': [
              {'name': 'Mesalamine', 'dosage': '1g', 'time': 'Morning', 'taken': true},
              {'name': 'Budesonide', 'dosage': '9mg', 'time': 'Morning', 'taken': false},
            ],
          },
        ]),
      );
      expect(reply, contains('Mesalamine and Budesonide'));
      expect(reply, contains('Not marked as taken yet: Budesonide'));
    });

    test('feeling questions summarise the daily check-ins', () async {
      final reply = await ask(
        'How have I been feeling lately?',
        UserHealthContext(recentDailyTracking: [
          {'date': '2026-09-21', 'feeling': 4, 'pain_level': 2},
          {'date': '2026-09-20', 'feeling': 0, 'pain_level': 6.0},
        ]),
      );
      expect(reply, contains('"Great"'));
      expect(reply, contains('1 good'));
      expect(reply, contains('1 tough'));
      expect(reply, contains('4/10'));
    });

    test('pattern questions list foods eaten on tough days', () async {
      final reply = await ask(
        'What could be triggering my symptoms?',
        UserHealthContext(
          recentDailyTracking: [
            {'date': '2026-09-21', 'feeling': 0},
          ],
          recentDiet: [
            {
              'date': '2026-09-21',
              'meals': [
                {'name': 'Lunch', 'foods': ['Pizza']},
              ],
            },
          ],
        ),
      );
      expect(reply, contains('Foods logged on tough days: Pizza'));
    });
  });

  group('UserHealthContext.buildContextSummary', () {
    test('tolerates numeric doubles and list-valued free text', () {
      final summary = UserHealthContext(recentDailyTracking: [
        {
          'date': '2026-09-21',
          'feeling': 3.0,
          'pain_level': 2.5,
          'feel_good_factors': ['Walk', 'Sleep'],
          'medications_followed': true,
        },
      ]).buildContextSummary();
      expect(summary, contains('Feeling Good'));
      expect(summary, contains('pain 2.5/10'));
      expect(summary, contains('Helped: Walk, Sleep'));
      expect(summary, contains('took all medications: yes'));
    });

    test('says when nothing has been tracked', () {
      expect(UserHealthContext().buildContextSummary(), contains('not tracked any health data'));
    });
  });

  group('AIChatService helpers', () {
    test('toPlainText strips Markdown from Gemini replies', () {
      const markdown = '## Tips\n**Rest** and *hydrate*.\n* Eat small meals\n- Use `heat`';
      expect(
        AIChatService.toPlainText(markdown),
        'Tips\nRest and hydrate.\n• Eat small meals\n• Use heat',
      );
    });

    test('recentHistory starts with a user turn, ends with a model turn and merges repeats', () {
      final now = DateTime(2026, 9, 21);
      ChatMessage m(String text, bool isUser) =>
          ChatMessage(id: text, text: text, isUser: isUser, timestamp: now);
      final turns = const AIChatService().recentHistory([
        m('welcome', false),
        m('a', true),
        m('b', true),
        m('reply', false),
        m('unanswered', true),
      ], 'next');
      expect(turns.map((t) => t.isUser), [true, false]);
      expect(turns.first.text, 'a\n\nb');
    });

    test('thinking level is only requested for Gemini 3+ models', () {
      expect(GeminiClient.chatThinkingConfig('gemini-3.5-flash'), isNotNull);
      expect(GeminiClient.chatThinkingConfig('gemini-2.5-flash'), isNull);
      expect(GeminiClient.chatThinkingConfig('custom-model'), isNull);
    });
  });

  group('ChatScreen', () {
    setUpAll(() async {
      await BackendServiceProvider.initialize();
      await BackendServiceProvider.instance.auth.signInAsGuest();
    });

    Future<void> pumpChat(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const ChatScreen()));
      await tester.pump();
    }

    testWidgets('shows starter questions, disclaimer and labelled controls', (tester) async {
      await pumpChat(tester);
      expect(find.text('Start a conversation'), findsOneWidget);
      expect(find.text('Can stress trigger digestive symptoms?'), findsOneWidget);
      expect(find.textContaining('not medical advice'), findsOneWidget);
      expect(find.byTooltip('Send message'), findsOneWidget);
      expect(find.byTooltip('Reload conversation'), findsOneWidget);

      final send = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.send), matching: find.byType(IconButton)),
      );
      expect(send.onPressed, isNull, reason: 'send is disabled while the input is empty');
    });

    testWidgets('sends a message, shows typing indicator, then the reply', (tester) async {
      await pumpChat(tester);
      await tester.enterText(find.byType(TextField), 'Can stress trigger digestive symptoms?');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();

      expect(find.text('Can stress trigger digestive symptoms?'), findsOneWidget);
      expect(find.text('GutMD Assistant is typing…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('GutMD Assistant is typing…'), findsNothing);
      expect(find.textContaining('Stress is commonly linked'), findsOneWidget);
      expect(find.text('Start a conversation'), findsNothing);
    });

    testWidgets('history reloads when the screen is rebuilt', (tester) async {
      await pumpChat(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Stress is commonly linked'), findsOneWidget);
    });
  });
}
