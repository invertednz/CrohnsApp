import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/screens/diet/diet_screen.dart';
import 'package:gut_md/screens/insights/insights_screen.dart';
import 'package:gut_md/screens/tracking/tracking_screen.dart';
import 'package:gut_md/services/insights_generator.dart';

String _day(int offset) =>
    DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: offset)));

/// Pumps a launcher with an "Open" button that pushes [screen], so back
/// navigation has somewhere to return to.
Future<void> _open(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open'));
  await _settle(tester);
}

/// Lets the mock backend's simulated latency elapse.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pumpAndSettle();
}

/// Runs real (non-fake) async work such as the mock backend's delays.
Future<T> _real<T>(WidgetTester tester, Future<T> Function() fn) async =>
    (await tester.runAsync(fn)) as T;

Future<String> _signIn(WidgetTester tester, String email) => _real(tester, () async {
      final user = await BackendServiceProvider.instance.auth
          .signInWithEmail(email: email, password: 'password123');
      return user!.id;
    });

Future<void> _track(WidgetTester tester, String uid, String type, Map<String, dynamic> data) =>
    _real(tester, () => BackendServiceProvider.instance.tracking.trackEvent(userId: uid, type: type, data: data));

Future<Map<String, dynamic>?> _read(WidgetTester tester, String uid, String date, String type) =>
    _real(tester, () => BackendServiceProvider.instance.tracking.getTrackingData(userId: uid, date: date, type: type));

final _dialogAddMeal = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(ElevatedButton, 'Add Meal'),
);

void main() {
  setUpAll(() async {
    await BackendServiceProvider.initialize();
  });

  setUp(() => AppState().setSelectedDate(DateTime.now()));

  group('InsightsGenerator.localInsights', () {
    test('with no data it has no score and no trend instead of made-up values', () {
      final insights = InsightsGenerator.localInsights({});
      final summary = insights['health_summary'] as Map;
      expect(summary['score'], isNull);
      expect(summary['trend'], 'unknown');
      expect(insights['data_points'], 0);
      expect(insights['supplement_effectiveness'], isEmpty);
    });

    test('links a bad-day food to triggers and a good-day food to good days, with evidence', () {
      final insights = InsightsGenerator.localInsights({
        'daily': [
          {'date': '2026-09-21', 'feeling': 0, 'pain_level': 8},
          {'date': '2026-09-20', 'feeling': 4, 'pain_level': 1},
        ],
        'diet': [
          {
            'date': '2026-09-21',
            'meals': [
              {'name': 'Dinner', 'foods': ['Pizza', 'Rice']},
            ],
          },
          {
            'date': '2026-09-20',
            'meals': [
              {'name': 'Lunch', 'foods': ['Salmon', 'rice']},
            ],
          },
        ],
      });
      final triggers = insights['food_triggers'] as List;
      final good = insights['beneficial_foods'] as List;
      expect(triggers.map((t) => t['food']), ['Pizza']);
      expect(triggers.first['note'], 'Eaten on 1 of 1 tough day and 0 of 1 good day');
      // Rice was eaten on both days (case-insensitive), so it is neither.
      expect(good.map((t) => t['food']), ['Salmon']);
      final recs = (insights['recommendations'] as List).map((r) => r['description']).join(' ');
      expect(recs, contains('Pizza was eaten on 1 of your 1 tough day'));
    });

    test('ignores daily entries without a feeling rating', () {
      final insights = InsightsGenerator.localInsights({
        'daily': [
          {'date': '2026-09-21', 'bowel_movements': 2},
        ],
      });
      expect((insights['health_summary'] as Map)['score'], isNull);
      expect(insights['data_points'], 1);
    });

    test('uses only the most recently saved trigger list', () {
      final insights = InsightsGenerator.localInsights({
        'diet': [
          {'date': '2026-09-21', 'food_triggers': ['Dairy'], 'recorded_at': '2026-09-21T08:00:00'},
          {'date': '2026-09-20', 'food_triggers': ['Coffee'], 'recorded_at': '2026-09-22T08:00:00'},
        ],
      });
      final triggers = insights['food_triggers'] as List;
      expect(triggers.map((t) => t['food']), ['Coffee']);
      expect(triggers.first['note'], 'You marked this as a trigger');
    });

    test('supplement numbers come from rated days, never a fixed guess', () {
      final insights = InsightsGenerator.localInsights({
        'daily': [
          {'date': '2026-09-21', 'feeling': 4},
          {'date': '2026-09-20', 'feeling': 1},
        ],
        'supplements': [
          {
            'date': '2026-09-21',
            'supplements': [
              {'name': 'Vitamin D', 'taken': true},
              {'name': 'Iron', 'taken': false},
            ],
          },
          {
            'date': '2026-09-20',
            'supplements': [
              {'name': 'Vitamin D', 'taken': true},
            ],
          },
          {
            'date': '2026-09-19',
            'supplements': [
              {'name': 'Zinc', 'taken': true},
            ],
          },
        ],
      });
      final supps = {
        for (final s in insights['supplement_effectiveness'] as List) s['name']: s,
      };
      expect(supps.keys, containsAll(['Vitamin D', 'Zinc']));
      expect(supps.containsKey('Iron'), isFalse);
      expect(supps['Vitamin D']['effectiveness'], 0.5);
      expect(supps['Vitamin D']['note'], 'Taken on 2 rated days; you felt good on 1.');
      expect(supps['Zinc']['effectiveness'], isNull);
    });

    test('needs three older rated days before reporting a trend', () {
      Map<String, dynamic> day(int i, int feeling) =>
          {'date': '2026-09-${(30 - i).toString().padLeft(2, '0')}', 'feeling': feeling};
      final improving = InsightsGenerator.localInsights({
        'daily': [for (var i = 0; i < 7; i++) day(i, 4), for (var i = 7; i < 10; i++) day(i, 1)],
      });
      expect((improving['health_summary'] as Map)['trend'], 'improving');
      final short = InsightsGenerator.localInsights({
        'daily': [for (var i = 0; i < 8; i++) day(i, 4)],
      });
      expect((short['health_summary'] as Map)['trend'], 'unknown');
    });

    test('normalize clamps model output into the screen contract', () {
      final normalized = InsightsGenerator.normalize({
        'health_summary': {'score': 180, 'trend': 'amazing', 'description': 'Hi'},
        'food_triggers': [
          {'food': 'Milk', 'correlation': 3},
          {'food': '', 'correlation': 0.5},
        ],
        'recommendations': [
          {'title': 'Rest', 'description': 'Sleep', 'category': 'unknown'},
        ],
      });
      expect((normalized['health_summary'] as Map)['score'], 100);
      expect((normalized['health_summary'] as Map)['trend'], 'unknown');
      expect(normalized['food_triggers'], [
        {'food': 'Milk', 'correlation': 1.0, 'note': null},
      ]);
      expect(normalized['beneficial_foods'], isEmpty);
      expect((normalized['recommendations'] as List).first['category'], 'general');
    });
  });

  group('TrackingScreen', () {
    testWidgets('requires a feeling, then saves every field to the daily entry', (tester) async {
      final handle = tester.ensureSemantics();
      final uid = await _signIn(tester, 'tracker@example.com');
      await _open(tester, const TrackingScreen());

      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Previous day'), findsOneWidget);
      // The slider itself is announced with its title and value.
      expect(find.bySemanticsLabel('Pain level'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Pain level')).getSemanticsData().value, '0 out of 10');
      expect(find.bySemanticsLabel('Energy level'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await _settle(tester);
      expect(find.text('Choose how you\'re feeling to save this day'), findsOneWidget);
      expect(
        await _read(tester, uid, _day(0), 'daily'),
        isNull,
      );

      await tester.tap(find.bySemanticsLabel('Bad'));
      await tester.tap(find.byTooltip('Increase bowel movements'));
      await tester.tap(find.byTooltip('Increase bowel movements'));
      await tester.pump();
      await tester.drag(find.byType(Slider).first, const Offset(600, 0));
      await tester.drag(find.byType(Slider).last, const Offset(-600, 0));
      await tester.pump();
      expect(find.text('10/10'), findsOneWidget);
      expect(find.text('0/10'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'Ate pizza');
      await tester.enterText(find.byType(TextField).at(2), 'Cramping after dinner');
      await tester.tap(find.text('Save'));
      await _settle(tester);

      expect(find.text('Saved your entry for today'), findsOneWidget);
      final saved = await _read(tester, uid, _day(0), 'daily');
      expect(saved, containsPair('feeling', 1));
      expect(saved, containsPair('bowel_movements', 2));
      expect(saved, containsPair('pain_level', 10));
      expect(saved, containsPair('energy_level', 0));
      expect(saved, containsPair('feel_bad_factors', 'Ate pizza'));
      expect(saved, containsPair('notes', 'Cramping after dinner'));
      handle.dispose();
    });

    testWidgets('reloads the saved entry and marks the chosen feeling as selected', (tester) async {
      final handle = tester.ensureSemantics();
      final uid = await _signIn(tester, 'reload@example.com');
      await _track(tester, uid, 'daily', {
        'date': _day(0),
        'feeling': 4,
        'bowel_movements': 3,
        'pain_level': 2,
        'energy_level': 8,
        'notes': 'Good walk',
      });
      await _open(tester, const TrackingScreen());

      expect(tester.getSemantics(find.bySemanticsLabel('Great')), isSemantics(isSelected: true, isButton: true, hasSelectedState: true, hasTapAction: true, label: 'Great'));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2/10'), findsOneWidget);
      expect(find.text('8/10'), findsOneWidget);
      expect(find.text('Good walk'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('asks before discarding unsaved changes on back', (tester) async {
      await _signIn(tester, 'discard@example.com');
      await _open(tester, const TrackingScreen());

      await tester.tap(find.text('Okay'));
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Save your changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('moves between days and cannot go past today', (tester) async {
      final uid = await _signIn(tester, 'dates@example.com');
      await _track(tester, uid, 'daily', {'date': _day(-1), 'feeling': 0, 'notes': 'Rough day'},
      );
      await _open(tester, const TrackingScreen());

      final next = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right));
      expect(next.onPressed, isNull);
      await tester.tap(find.byTooltip('Previous day'));
      await _settle(tester);
      expect(find.text(DateFormat('EEEE, MMM d').format(DateTime.now().subtract(const Duration(days: 1)))), findsOneWidget);
      expect(find.text('Rough day'), findsOneWidget);
      await tester.tap(find.byTooltip('Next day'));
      await _settle(tester);
      expect(find.textContaining('Today, '), findsOneWidget);
      expect(find.text('Rough day'), findsNothing);
    });
  });

  group('DietScreen', () {
    testWidgets('validates and adds a meal with typed and common foods, then saves', (tester) async {
      final uid = await _signIn(tester, 'diet@example.com');
      await _open(tester, const DietScreen());
      expect(find.text('No meals logged for this day'), findsOneWidget);

      await tester.tap(find.text('Add Meal'));
      await tester.pumpAndSettle();
      await tester.tap(_dialogAddMeal);
      await tester.pump();
      expect(find.text('Enter a meal name'), findsOneWidget);
      expect(find.text('Add at least one food'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Lunch'));
      await tester.tap(find.widgetWithText(FilterChip, 'Rice'));
      await tester.enterText(find.widgetWithText(TextField, 'Add a food'), 'Pizza');
      await tester.tap(_dialogAddMeal);
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Rice'), findsOneWidget);

      await tester.tap(find.text('Save diet log'));
      await _settle(tester);
      final saved = await _read(tester, uid, _day(0), 'diet');
      final meals = saved!['meals'] as List;
      expect(meals.single['name'], 'Lunch');
      expect(meals.single['foods'], ['Rice', 'Pizza']);
    });

    testWidgets('triggers and safe foods are exclusive, persist and carry across days', (tester) async {
      final uid = await _signIn(tester, 'tags@example.com');
      await _open(tester, const DietScreen());

      await tester.tap(find.text('Add safe food'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Milk'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add trigger'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();
      expect(find.text('Type a food or pick one below'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Food name'), 'Milk');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Milk moved to food triggers'), findsOneWidget);
      expect(find.text('No safe foods yet. Add foods you tolerate well.'), findsOneWidget);

      await tester.tap(find.text('Save diet log'));
      await _settle(tester);
      final saved = await _read(tester, uid, _day(0), 'diet');
      expect(saved!['food_triggers'], ['Milk']);
      expect(saved['safe_foods'], isEmpty);

      await tester.tap(find.byTooltip('Previous day'));
      await _settle(tester);
      expect(find.text('No meals logged for this day'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.byTooltip('Remove Milk from triggers'), findsOneWidget);
    });

    testWidgets('removing a meal and leaving asks to save', (tester) async {
      final uid = await _signIn(tester, 'remove@example.com');
      await _track(tester, uid, 'diet', {
        'date': _day(0),
        'meals': [
          {'name': 'Breakfast', 'time': '08:00', 'foods': ['Eggs']},
        ],
      });
      await _open(tester, const DietScreen());
      expect(find.text('Breakfast'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove Breakfast'));
      await tester.pump();
      expect(find.text('Breakfast'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await _settle(tester);
      expect(find.text('Open'), findsOneWidget);
      final saved = await _read(tester, uid, _day(0), 'diet');
      expect(saved!['meals'], isEmpty);
    });
  });

  group('InsightsScreen', () {
    testWidgets('shows a getting-started state when nothing is tracked', (tester) async {
      await _signIn(tester, 'empty-insights@example.com');
      await _open(tester, const InsightsScreen());
      expect(find.text('No insights yet'), findsOneWidget);
      expect(find.text('Log how you feel'), findsOneWidget);
      expect(find.text('Log meals'), findsOneWidget);
      expect(find.byTooltip('Refresh insights'), findsOneWidget);
    });

    testWidgets('refreshed insights reflect a bad-day food and a good-day food', (tester) async {
      final uid = await _signIn(tester, 'insights@example.com');
      await _track(tester, uid, 'daily', {'date': _day(-1), 'feeling': 0, 'pain_level': 8});
      await _track(tester, uid, 'diet', {
        'date': _day(-1),
        'meals': [
          {'name': 'Dinner', 'time': '', 'foods': ['Chili']},
        ],
      });
      await _track(tester, uid, 'daily', {'date': _day(0), 'feeling': 4, 'pain_level': 1});
      await _track(tester, uid, 'diet', {
        'date': _day(0),
        'meals': [
          {'name': 'Lunch', 'time': '', 'foods': ['Oatmeal']},
        ],
      });
      await _open(tester, const InsightsScreen());
      await tester.tap(find.byTooltip('Refresh insights'));
      await _settle(tester);

      expect(find.text('Insights refreshed'), findsOneWidget);
      expect(find.text('Chili'), findsOneWidget);
      expect(find.text('Oatmeal'), findsOneWidget);
      expect(find.text('Eaten on 1 of 1 tough day and 0 of 1 good day'), findsOneWidget);
      expect(find.text('Calculated on your device from your logs', findRichText: false), findsNothing);
      expect(find.textContaining('Calculated on your device from your logs'), findsOneWidget);
      expect(find.text('Trend: not enough data yet'), findsOneWidget);
    });
  });
}
