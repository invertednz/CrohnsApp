import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/screens/medications/medications_screen.dart';
import 'package:gut_md/screens/onboarding/onboarding_data.dart';
import 'package:gut_md/screens/supplements/supplements_screen.dart';
import 'package:gut_md/screens/symptoms/symptoms_screen.dart';

var _userCount = 0;

String _day(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
DateTime get _today => DateTime.now();
DateTime get _yesterday => DateTime(_today.year, _today.month, _today.day - 1);

/// The square-glyph test font makes the shared CalendarBar's day labels
/// ("Yesterday") wider than their 56px cells; that widget is covered by its
/// own tests, so only its overflow reports are ignored here.
void _ignoreCalendarOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    if (text.contains('overflowed') && text.contains('calendar_bar.dart')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  _ignoreCalendarOverflow();
  tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: Scaffold(body: screen)));
  await _settle(tester);
}

/// Mock backend latency is 250ms and spinners never settle, so pump explicitly.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _tapLabel(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label);
  expect(target, findsOneWidget, reason: 'semantics label "$label"');
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  final target = find.byTooltip(tooltip);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _enterHint(WidgetTester tester, String hint, String value) async {
  final target = find.widgetWithText(TextField, hint);
  await tester.ensureVisible(target);
  await tester.enterText(target, value);
  await tester.pump();
}

Future<Map<String, dynamic>?> _stored(WidgetTester tester, String type, String key) async {
  final userId = BackendServiceProvider.instance.auth.currentUser!.id;
  final data = await tester.runAsync(() => BackendServiceProvider.instance.tracking
      .getTrackingData(userId: userId, date: key, type: type));
  return data;
}

Future<void> _selectDate(WidgetTester tester, DateTime date) async {
  AppState().setSelectedDate(date);
  await _settle(tester);
}

/// Replaces the current screen with an empty one and back, like switching tabs.
Future<void> _remount(WidgetTester tester, Widget Function() screen) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
  await tester.pump();
  await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: Scaffold(body: screen())));
  await _settle(tester);
}

void _expectChecked(WidgetTester tester, String label, bool checked) {
  expect(
    tester.getSemantics(find.bySemanticsLabel(label)),
    isSemantics(label: label, hasCheckedState: true, isChecked: checked, hasTapAction: true),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await BackendServiceProvider.initialize();
  });

  setUp(() async {
    _userCount++;
    await BackendServiceProvider.instance.auth
        .signInWithEmail(email: 'tabs$_userCount-${DateTime.now().microsecondsSinceEpoch}@example.com', password: 'secret1');
    AppState().setOnboardingData(OnboardingData());
    AppState().setSelectedDate(DateTime.now());
  });

  group('SymptomsScreen', () {
    testWidgets('adds a symptom, logs it with a 1-5 severity and saves the day', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester, const SymptomsScreen());

      expect(find.text('Nothing logged for today yet'), findsOneWidget);
      expect(find.textContaining("You're not tracking any symptoms yet"), findsOneWidget);

      await _tapLabel(tester, 'Add Nausea');
      expect(find.bySemanticsLabel('Add Nausea'), findsNothing);
      _expectChecked(tester, 'Nausea', false);
      final list = await _stored(tester, 'tracked_lists', 'symptoms');
      expect((list!['items'] as List).map((i) => i['name']), ['Nausea']);

      await _tapLabel(tester, 'Nausea');
      _expectChecked(tester, 'Nausea', true);
      expect(find.text('Severity: Moderate (3/5)'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Nausea severity 3 of 5, Moderate')),
        isSemantics(isInMutuallyExclusiveGroup: true, hasCheckedState: true, isChecked: true),
      );
      expect(find.text('Logged for today: 1 symptom'), findsOneWidget);

      await _tapLabel(tester, 'Nausea severity 5 of 5, Very severe');
      expect(find.text('Severity: Very severe (5/5)'), findsOneWidget);
      var day = await _stored(tester, 'symptoms', _day(_today));
      expect(day!['active_symptoms'], [
        {'name': 'Nausea', 'severity': 5},
      ]);

      await _tapLabel(tester, 'Nausea');
      _expectChecked(tester, 'Nausea', false);
      expect(find.text('Logged for today: no symptoms'), findsOneWidget);
      day = await _stored(tester, 'symptoms', _day(_today));
      expect(day!['active_symptoms'], isEmpty);
      semantics.dispose();
    });

    testWidgets('keeps each day separate and reloads after the tab is rebuilt', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester, const SymptomsScreen());
      await _tapLabel(tester, 'Add Nausea');
      await _tapLabel(tester, 'Add Fatigue');
      await _tapLabel(tester, 'Nausea');
      await _tapLabel(tester, 'Nausea severity 4 of 5, Severe');

      await _selectDate(tester, _yesterday);
      expect(find.text('Nothing logged for yesterday yet'), findsOneWidget);
      _expectChecked(tester, 'Nausea', false);
      await _tapLabel(tester, 'Fatigue');

      await _selectDate(tester, _today);
      _expectChecked(tester, 'Nausea', true);
      _expectChecked(tester, 'Fatigue', false);
      expect(find.text('Severity: Severe (4/5)'), findsOneWidget);

      await _remount(tester, () => const SymptomsScreen());
      _expectChecked(tester, 'Nausea', true);
      _expectChecked(tester, 'Fatigue', false);
      await _selectDate(tester, _yesterday);
      _expectChecked(tester, 'Fatigue', true);
      _expectChecked(tester, 'Nausea', false);
      semantics.dispose();
    });

    testWidgets('validates custom symptoms and removes symptoms from the list', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester, const SymptomsScreen());

      await _tapText(tester, 'Add');
      expect(find.text('Enter a symptom name to add it.'), findsOneWidget);

      await _enterHint(tester, 'Add custom symptom', 'Brain fog');
      expect(find.text('Enter a symptom name to add it.'), findsNothing);
      await _tapText(tester, 'Add');
      expect(find.text('Custom symptom'), findsOneWidget);
      expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Add custom symptom')).controller!.text, isEmpty);
      _expectChecked(tester, 'Brain fog', false);

      await _enterHint(tester, 'Add custom symptom', 'brain FOG');
      await _tapText(tester, 'Add');
      expect(find.text('Brain fog is already in your list.'), findsOneWidget);

      // Typing a suggestion's name adds that suggestion.
      await _enterHint(tester, 'Add custom symptom', 'bloating');
      await _tapText(tester, 'Add');
      expect(find.bySemanticsLabel('Add Bloating'), findsNothing);
      _expectChecked(tester, 'Bloating', false);

      // Buttons the E2E suite finds by accessible name.
      for (final label in ['Add', 'Had All', 'Had None', 'Add Gas']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(label: label, isButton: true, hasTapAction: true),
          reason: label,
        );
      }
      expect(
        tester.getSemantics(find.byTooltip('Remove Brain fog')),
        isSemantics(tooltip: 'Remove Brain fog', isButton: true, hasTapAction: true),
      );

      await _tapLabel(tester, 'Brain fog');
      await _tapTooltip(tester, 'Remove Brain fog');
      expect(find.text('Brain fog'), findsNothing);
      await _tapTooltip(tester, 'Remove Bloating');
      expect(find.bySemanticsLabel('Add Bloating'), findsOneWidget);

      final list = await _stored(tester, 'tracked_lists', 'symptoms');
      expect(list!['items'], isEmpty);
      final day = await _stored(tester, 'symptoms', _day(_today));
      expect(day!['active_symptoms'], isEmpty);
      semantics.dispose();
    });

    testWidgets('Had All and Had None log every tracked symptom or none', (tester) async {
      await _pumpScreen(tester, const SymptomsScreen());
      await _tapText(tester, 'Had None');
      expect(find.text('Logged for today: no symptoms'), findsOneWidget);

      await _tapLabel(tester, 'Add Gas');
      await _tapLabel(tester, 'Add Fever');
      await _tapText(tester, 'Had All');
      expect(find.text('Logged for today: 2 symptoms'), findsOneWidget);
      final day = await _stored(tester, 'symptoms', _day(_today));
      expect((day!['active_symptoms'] as List).map((s) => s['name']), ['Gas', 'Fever']);

      await _tapText(tester, 'Had None');
      expect(find.text('Logged for today: no symptoms'), findsOneWidget);
    });

    testWidgets('starts from the onboarding symptoms and their usual severity', (tester) async {
      final semantics = tester.ensureSemantics();
      AppState().setOnboardingData(OnboardingData()
        ..currentSymptoms = [
          SymptomEntry(name: 'Fatigue', severity: 'Severe'),
          SymptomEntry(name: 'Night sweats', severity: 'Mild', isCustom: true),
        ]);
      await _pumpScreen(tester, const SymptomsScreen());
      _expectChecked(tester, 'Fatigue', false);
      _expectChecked(tester, 'Night sweats', false);

      await _tapLabel(tester, 'Fatigue');
      expect(find.text('Severity: Severe (4/5)'), findsOneWidget);
      final list = await _stored(tester, 'tracked_lists', 'symptoms');
      expect((list!['items'] as List).map((i) => i['name']), ['Fatigue', 'Night sweats']);
      semantics.dispose();
    });
  });

  group('SupplementsScreenMain', () {
    testWidgets('adds a supplement with a dosage, marks it taken with a time and saves the day', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester, const SupplementsScreenMain());
      expect(find.text('Nothing logged for today yet'), findsOneWidget);

      await _enterHint(tester, 'Add custom supplement', 'Turmeric');
      await _enterHint(tester, 'Dosage (optional)', '500 mg');
      await _tapText(tester, 'Add');
      expect(find.text('500 mg · Custom supplement'), findsOneWidget);
      for (final hint in ['Add custom supplement', 'Dosage (optional)']) {
        expect(tester.widget<TextField>(find.widgetWithText(TextField, hint)).controller!.text, isEmpty);
      }
      _expectChecked(tester, 'Turmeric', false);

      await _tapLabel(tester, 'Turmeric');
      _expectChecked(tester, 'Turmeric', true);
      expect(find.text('Logged for today: 1 of 1 taken'), findsOneWidget);
      _expectChecked(tester, 'Turmeric taken AM', false);
      await _tapLabel(tester, 'Turmeric taken AM');
      _expectChecked(tester, 'Turmeric taken AM', true);

      final day = await _stored(tester, 'supplements', _day(_today));
      expect(day!['supplements'], [
        {'name': 'Turmeric', 'dosage': '500 mg', 'time': 'AM', 'taken': true},
      ]);

      await _remount(tester, () => const SupplementsScreenMain());
      _expectChecked(tester, 'Turmeric', true);
      _expectChecked(tester, 'Turmeric taken AM', true);
      _expectChecked(tester, 'Turmeric taken PM', false);
      semantics.dispose();
    });

    testWidgets('Mark All Taken, Clear All and per-day separation', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester, const SupplementsScreenMain());
      await _tapLabel(tester, 'Add Vitamin D');
      await _tapLabel(tester, 'Add Iron');
      await _tapText(tester, 'Mark All Taken');
      expect(find.text('Logged for today: 2 of 2 taken'), findsOneWidget);

      await _selectDate(tester, _yesterday);
      expect(find.text('Nothing logged for yesterday yet'), findsOneWidget);
      _expectChecked(tester, 'Vitamin D', false);
      await _tapLabel(tester, 'Iron');

      await _selectDate(tester, _today);
      _expectChecked(tester, 'Vitamin D', true);
      await _tapText(tester, 'Clear All');
      expect(find.text('Logged for today: 0 of 2 taken'), findsOneWidget);
      final today = await _stored(tester, 'supplements', _day(_today));
      expect((today!['supplements'] as List).every((s) => s['taken'] == false), isTrue);
      final yesterday = await _stored(tester, 'supplements', _day(_yesterday));
      expect(
        (yesterday!['supplements'] as List).map((s) => '${s['name']}:${s['taken']}'),
        ['Vitamin D:false', 'Iron:true'],
      );
      semantics.dispose();
    });

    testWidgets('edits a dosage, validates names and removes supplements', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester, const SupplementsScreenMain());
      await _tapLabel(tester, 'Add Vitamin D');

      await _tapTooltip(tester, 'Edit dosage for Vitamin D');
      expect(find.text('Vitamin D dosage'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Dosage'), '1000 IU');
      await _tapText(tester, 'Cancel');
      expect(find.textContaining('1000 IU'), findsNothing);

      await _tapTooltip(tester, 'Edit dosage for Vitamin D');
      await tester.enterText(find.widgetWithText(TextField, 'Dosage'), '1000 IU');
      await _tapText(tester, 'Save');
      expect(find.text('1000 IU · Fat-soluble vitamin (D3 or D2)'), findsOneWidget);
      final list = await _stored(tester, 'tracked_lists', 'supplements');
      expect(list!['items'], [
        {'name': 'Vitamin D', 'dosage': '1000 IU', 'am': false, 'pm': false},
      ]);

      await _tapText(tester, 'Add');
      expect(find.text('Enter a supplement name to add it.'), findsOneWidget);
      await _enterHint(tester, 'Add custom supplement', 'vitamin d');
      await _tapText(tester, 'Add');
      expect(find.text('Vitamin D is already in your list.'), findsOneWidget);

      await _tapTooltip(tester, 'Remove Vitamin D');
      expect(find.bySemanticsLabel('Add Vitamin D'), findsOneWidget);
      expect(find.textContaining("You haven't added any supplements yet"), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('starts from onboarding supplements with their usual time of day', (tester) async {
      final semantics = tester.ensureSemantics();
      AppState().setOnboardingData(OnboardingData()
        ..supplements = [SupplementEntry(name: 'Probiotics', takesPM: true)]);
      await _pumpScreen(tester, const SupplementsScreenMain());
      _expectChecked(tester, 'Probiotics', false);
      await _tapLabel(tester, 'Probiotics');
      _expectChecked(tester, 'Probiotics taken PM', true);
      _expectChecked(tester, 'Probiotics taken AM', false);
      final day = await _stored(tester, 'supplements', _day(_today));
      expect(day!['supplements'], [
        {'name': 'Probiotics', 'dosage': '', 'time': 'PM', 'taken': true},
      ]);
      semantics.dispose();
    });
  });

  group('MedicationsScreenMain', () {
    testWidgets('adds medications, logs doses and reloads them', (tester) async {
      final semantics = tester.ensureSemantics();
      AppState().setOnboardingData(OnboardingData()..medications = ['Mesalamine']);
      await _pumpScreen(tester, const MedicationsScreenMain());
      expect(find.text('Always consult your doctor before making medication changes'), findsOneWidget);
      _expectChecked(tester, 'Mesalamine', false);
      expect(find.bySemanticsLabel('Add Mesalamine'), findsNothing);

      await _enterHint(tester, 'Add custom medication', 'Ustekinumab');
      await _enterHint(tester, 'Dosage (optional)', '90 mg');
      await _tapText(tester, 'Add');
      await _tapLabel(tester, 'Mesalamine');
      await _tapLabel(tester, 'Mesalamine taken AM');
      await _tapLabel(tester, 'Mesalamine taken PM');
      expect(find.text('Logged for today: 1 of 2 taken'), findsOneWidget);

      final day = await _stored(tester, 'medications', _day(_today));
      expect(day!['medications'], [
        {'name': 'Mesalamine', 'dosage': '', 'time': 'AM, PM', 'taken': true},
        {'name': 'Ustekinumab', 'dosage': '90 mg', 'time': '', 'taken': false},
      ]);

      await _remount(tester, () => const MedicationsScreenMain());
      _expectChecked(tester, 'Mesalamine', true);
      _expectChecked(tester, 'Mesalamine taken PM', true);
      _expectChecked(tester, 'Ustekinumab', false);
      expect(find.text('90 mg · Custom medication'), findsOneWidget);
      semantics.dispose();
    });
  });
}
