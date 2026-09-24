import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/screens/home/home_screen.dart';
import 'package:gut_md/services/home_tracking_service.dart';

/// Drives the real Home dashboard against the in-memory backend (Firebase is
/// unavailable in unit tests, so the provider falls back to it).
void main() {
  late String userId;
  var userCount = 0;

  setUpAll(() async {
    await BackendServiceProvider.initialize();
  });

  setUp(() async {
    AppState().reset();
    userCount++;
    final user = await BackendServiceProvider.instance.auth
        .signInWithEmail(email: 'home$userCount@test.dev', password: 'password1');
    userId = user!.id;
  });

  String todayKey() => HomeTrackingService.dateKey(DateTime.now());

  // Direct backend calls need real async: the mock backend's latency timers
  // do not advance inside testWidgets' fake clock.
  Future<Map<String, dynamic>?> saved(WidgetTester tester, String date, [String type = 'daily']) =>
      tester.runAsync<Map<String, dynamic>?>(() => BackendServiceProvider.instance.tracking
          .getTrackingData(userId: userId, date: date, type: type));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await settle(tester);
  }

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final finder = find.bySemanticsLabel(label);
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.tap(finder.first);
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.tap(finder.first);
    await settle(tester);
  }

  Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
    final finder = find.byTooltip(tooltip);
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.tap(finder.first);
    await settle(tester);
  }

  testWidgets('a new user sees an honest empty dashboard', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    expect(find.bySemanticsLabel('Current streak: 0 days'), findsOneWidget);
    expect(find.bySemanticsLabel('Streak: 0 days'), findsOneWidget);
    expect(find.bySemanticsLabel('Days tracked in the last 30 days: 0'), findsOneWidget);
    expect(find.bySemanticsLabel('Average feeling: no entries in the last 30 days'), findsOneWidget);
    expect(find.bySemanticsLabel('Bowel motions: 0'), findsOneWidget);
    expect(find.textContaining('No logs for this day yet'), findsOneWidget);
    for (final tooltip in ['Sign out', 'Add meal photo', 'Add log', 'Add bowel motion', 'Remove bowel motion']) {
      expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
    }
    semantics.dispose();
  });

  testWidgets('feeling is saved to the backend and kept across tab switches', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    await tapLabel(tester, 'Great');
    expect((await saved(tester, todayKey()))?['feeling'], 4);
    expect(tester.getSemantics(find.bySemanticsLabel('Great')), isSemantics(isChecked: true));
    expect(find.bySemanticsLabel('Current streak: 1 day'), findsOneWidget);
    expect(find.bySemanticsLabel('Average feeling, last 30 days: 5.0 out of 5 (Great)'), findsOneWidget);

    await tester.tap(find.text('Symptoms').last);
    await settle(tester);
    await tester.tap(find.text('Home').last);
    await settle(tester);
    expect(tester.getSemantics(find.bySemanticsLabel('Great')), isSemantics(isChecked: true));
    semantics.dispose();
  });

  testWidgets('bowel counter, supplements and diet choices persist; zero is the minimum', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    await tapTooltip(tester, 'Add bowel motion');
    await tapTooltip(tester, 'Add bowel motion');
    await tapTooltip(tester, 'Remove bowel motion');
    expect(find.bySemanticsLabel('Bowel motions: 1'), findsOneWidget);
    await tapTooltip(tester, 'Remove bowel motion');
    expect(find.bySemanticsLabel('Bowel motions: 0'), findsOneWidget);
    final remove = tester.widget<IconButton>(
      find.ancestor(of: find.byTooltip('Remove bowel motion'), matching: find.byType(IconButton)),
    );
    expect(remove.onPressed, isNull);

    await tapLabel(tester, 'Supplements: Had All');
    await tapLabel(tester, 'Diet: Different');
    final day = await saved(tester, todayKey());
    expect(day?['bowel_movements'], 0);
    expect(day?['supplements_followed'], isTrue);
    expect(day?['diet_followed'], isFalse);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Diet: Different')),
      isSemantics(isChecked: true),
    );
    semantics.dispose();
  });

  testWidgets('data is per day: switching the calendar date loads that day', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    await tapLabel(tester, 'Great');
    await tapText(tester, 'Yesterday');
    expect(tester.getSemantics(find.bySemanticsLabel('Great')), isSemantics(isChecked: false));

    await tapLabel(tester, 'Bad');
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect((await saved(tester, HomeTrackingService.dateKey(yesterday)))?['feeling'], 1);
    expect(find.bySemanticsLabel('Current streak: 2 days'), findsOneWidget);

    await tapText(tester, 'Today');
    expect(tester.getSemantics(find.bySemanticsLabel('Great')), isSemantics(isChecked: true));
    expect(tester.getSemantics(find.bySemanticsLabel('Bad')), isSemantics(isChecked: false));
    semantics.dispose();
  });

  testWidgets('free-text log is analysed without inventing a score and saved', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    await tapTooltip(tester, 'Add log');
    expect(find.text('Type what you ate, did or felt first.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Coffee and toast for breakfast');
    await tapTooltip(tester, 'Add log');

    expect(find.text('Coffee and toast for breakfast'), findsOneWidget);
    expect(find.text('Not scored'), findsOneWidget);
    expect(find.text('Possible triggers: Coffee (caffeine)'), findsOneWidget);
    expect(find.text('No AI analysis · common-trigger keyword check only'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

    final log = await saved(tester, todayKey(), 'log');
    expect((log?['entries'] as List).single['text'], 'Coffee and toast for breakfast');
    expect(find.bySemanticsLabel('Current streak: 1 day'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('saved data is reloaded when Home is rebuilt from the backend', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.runAsync(() => BackendServiceProvider.instance.tracking.trackEvent(
          userId: userId,
          type: 'daily',
          data: {'date': todayKey(), 'feeling': 2, 'bowel_movements': 3, 'medications_followed': true},
        ));
    await pumpHome(tester);

    expect(tester.getSemantics(find.bySemanticsLabel('Okay')), isSemantics(isChecked: true));
    expect(find.bySemanticsLabel('Bowel motions: 3'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Medications: Had All')),
      isSemantics(isChecked: true),
    );
    expect(find.bySemanticsLabel('Days tracked in the last 30 days: 1'), findsOneWidget);
    semantics.dispose();
  });
}
