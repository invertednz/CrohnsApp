import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/screens/onboarding/onboarding_controller.dart';
import 'package:gut_md/screens/onboarding/onboarding_data.dart';
import 'package:gut_md/screens/onboarding/screens/diet_flags_screen.dart';
import 'package:gut_md/screens/onboarding/screens/lifestyle_screen.dart';
import 'package:gut_md/screens/onboarding/screens/medications_screen.dart';
import 'package:gut_md/screens/onboarding/screens/supplements_screen.dart';
import 'package:gut_md/screens/onboarding/screens/symptoms_screen.dart';
import 'package:gut_md/screens/onboarding/screens/thank_you_screen.dart';

/// Pumps [screen] on a tall phone-width surface and lets the staggered
/// entrance animations (delayed timers) finish.
Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1170, 7200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).first;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await settle(tester);
}

Future<void> tapSemantics(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await settle(tester);
}

Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
  final target = find.byTooltip(tooltip);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await settle(tester);
}

Future<void> enterCustom(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

ElevatedButton addButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Add'));
}

/// The semantics node a card title belongs to (the card's checkbox node).
SemanticsNode cardNode(WidgetTester tester, String title) {
  return tester.getSemantics(find.text(title).first);
}

void main() {
  group('DietFlagsScreen', () {
    testWidgets('Back button is labelled and calls onBack', (tester) async {
      var back = 0;
      await pumpScreen(
        tester,
        DietFlagsScreen(controller: OnboardingController(), onNext: () {}, onBack: () => back++),
      );
      await tapTooltip(tester, 'Back');
      expect(back, 1);
    });

    testWidgets('trigger cards are checkboxes that toggle the controller data', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        DietFlagsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );

      expect(cardNode(tester, 'Dairy'), isSemantics(hasCheckedState: true, isChecked: false));
      await tapText(tester, 'Dairy');
      expect(controller.data.dietFlags, ['Dairy']);
      expect(cardNode(tester, 'Dairy'), isSemantics(hasCheckedState: true, isChecked: true));

      await tapText(tester, 'Dairy');
      expect(controller.data.dietFlags, isEmpty);
      handle.dispose();
    });

    testWidgets('Add is disabled until something is typed', (tester) async {
      await pumpScreen(
        tester,
        DietFlagsScreen(controller: OnboardingController(), onNext: () {}, onBack: () {}),
      );
      expect(addButton(tester).onPressed, isNull);
      await enterCustom(tester, '   ');
      expect(addButton(tester).onPressed, isNull);
      await enterCustom(tester, 'Tomatoes');
      expect(addButton(tester).onPressed, isNotNull);
    });

    testWidgets('custom items can be added once and removed by name', (tester) async {
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        DietFlagsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      await enterCustom(tester, '  Tomatoes ');
      await tapText(tester, 'Add');
      expect(controller.data.dietFlags, ['Tomatoes']);
      expect(find.text('Your Custom Items'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

      await enterCustom(tester, 'tomatoes');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(controller.data.dietFlags, ['Tomatoes']);

      await tapTooltip(tester, 'Remove Tomatoes');
      expect(controller.data.dietFlags, isEmpty);
      expect(find.text('Your Custom Items'), findsNothing);
    });

    testWidgets('typing a listed trigger selects its card instead of duplicating it', (tester) async {
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        DietFlagsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      await enterCustom(tester, 'dairy');
      await tapText(tester, 'Add');
      expect(controller.data.dietFlags, ['Dairy']);
      expect(find.text('Your Custom Items'), findsNothing);
    });

    testWidgets('does not promise a settings screen that does not exist', (tester) async {
      await pumpScreen(
        tester,
        DietFlagsScreen(controller: OnboardingController(), onNext: () {}, onBack: () {}),
      );
      expect(find.textContaining('settings'), findsNothing);
      expect(find.textContaining('Diet tracker'), findsOneWidget);
    });
  });

  group('SupplementsScreen', () {
    testWidgets('adding a supplement reveals labelled AM/PM toggles that keep it selected',
        (tester) async {
      final handle = tester.ensureSemantics();
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        SupplementsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );

      await tapText(tester, 'Vitamin D');
      expect(controller.data.supplements.map((s) => s.name), ['Vitamin D']);
      expect(cardNode(tester, 'Vitamin D'), isSemantics(isChecked: true));

      await tapSemantics(tester, 'Take Vitamin D in the AM');
      expect(controller.data.supplements.single.takesAM, isTrue);
      expect(controller.data.supplements.single.takesPM, isFalse);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Take Vitamin D in the AM')),
        isSemantics(hasCheckedState: true, isChecked: true),
      );

      await tapSemantics(tester, 'Take Vitamin D in the PM');
      await tapSemantics(tester, 'Take Vitamin D in the AM');
      final entry = controller.data.supplements.single;
      expect(entry.takesAM, isFalse);
      expect(entry.takesPM, isTrue);

      await tapText(tester, 'Vitamin D');
      expect(controller.data.supplements, isEmpty);
      expect(find.bySemanticsLabel('Take Vitamin D in the AM'), findsNothing);
      handle.dispose();
    });

    testWidgets('custom supplements can be added, timed and removed', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        SupplementsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      expect(addButton(tester).onPressed, isNull);
      await enterCustom(tester, 'Turmeric');
      await tapText(tester, 'Add');
      expect(find.text('Your Custom Supplements'), findsOneWidget);
      await tapSemantics(tester, 'Take Turmeric in the PM');
      expect(controller.data.supplements.single.takesPM, isTrue);

      await enterCustom(tester, 'probiotics');
      await tapText(tester, 'Add');
      expect(controller.data.supplements.map((s) => s.name), ['Turmeric', 'Probiotics']);

      await tapTooltip(tester, 'Remove Turmeric');
      expect(controller.data.supplements.map((s) => s.name), ['Probiotics']);
      handle.dispose();
    });

    testWidgets('does not make unsupported health claims', (tester) async {
      await pumpScreen(
        tester,
        SupplementsScreen(controller: OnboardingController(), onNext: () {}, onBack: () {}),
      );
      expect(find.textContaining('Anti-inflammatory'), findsNothing);
      expect(find.textContaining('Gut health and digestive support'), findsNothing);
    });
  });

  group('LifestyleScreen', () {
    testWidgets('factors toggle, custom factors add on Enter and remove by name', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        LifestyleScreen(controller: controller, onNext: () {}, onBack: () {}),
      );

      await tapText(tester, 'Poor Sleep');
      expect(controller.data.lifestyle, ['Poor Sleep']);
      expect(cardNode(tester, 'Less than 7 hours per night'), isSemantics(isChecked: true));

      expect(addButton(tester).onPressed, isNull);
      await enterCustom(tester, 'Travel');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(controller.data.lifestyle, ['Poor Sleep', 'Travel']);
      expect(find.text('Selected Factors'), findsOneWidget);

      await enterCustom(tester, 'high stress');
      await tapText(tester, 'Add');
      expect(controller.data.lifestyle, ['Poor Sleep', 'Travel', 'High Stress']);

      await tapTooltip(tester, 'Remove Travel');
      await tapTooltip(tester, 'Remove Poor Sleep');
      expect(controller.data.lifestyle, ['High Stress']);
      handle.dispose();
    });
  });

  group('MedicationsScreen', () {
    Future<OnboardingController> pumpWith(WidgetTester tester, List<GutCondition> conditions) async {
      final controller = OnboardingController();
      controller.data.conditions = conditions;
      await pumpScreen(
        tester,
        MedicationsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      return controller;
    }

    testWidgets("Crohn's shows the IBD list only", (tester) async {
      await pumpWith(tester, [GutCondition.crohns]);
      expect(find.text('Common IBD Medications'), findsOneWidget);
      expect(find.text('Ustekinumab'), findsOneWidget);
      expect(find.text('Common IBS Medications'), findsNothing);
      expect(find.text('Common Reflux (GERD) Medications'), findsNothing);
    });

    testWidgets('IBS and GERD show their own lists instead of IBD drugs', (tester) async {
      await pumpWith(tester, [GutCondition.ibs, GutCondition.gerd]);
      expect(find.text('Common IBD Medications'), findsNothing);
      expect(find.text('Common IBS Medications'), findsOneWidget);
      expect(find.text('Common Reflux (GERD) Medications'), findsOneWidget);
      expect(find.text('Loperamide'), findsOneWidget);
      expect(find.text('Omeprazole'), findsOneWidget);
    });

    testWidgets('unsure users see every list', (tester) async {
      await pumpWith(tester, [GutCondition.notSure]);
      expect(find.text('Common IBD Medications'), findsOneWidget);
      expect(find.text('Common IBS Medications'), findsOneWidget);
      expect(find.text('Common Reflux (GERD) Medications'), findsOneWidget);
    });

    testWidgets('cards toggle, brand names map to the listed medication', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = await pumpWith(tester, [GutCondition.crohns]);

      await tapText(tester, 'Mesalamine');
      expect(controller.data.medications, ['Mesalamine']);
      expect(cardNode(tester, 'Mesalamine'), isSemantics(isChecked: true));

      await enterCustom(tester, 'humira');
      await tapText(tester, 'Add');
      expect(controller.data.medications, ['Mesalamine', 'Adalimumab']);
      expect(find.text('Your Custom Medications'), findsNothing);
      handle.dispose();
    });

    testWidgets('custom medications can be added and removed', (tester) async {
      final controller = await pumpWith(tester, [GutCondition.crohns]);
      await enterCustom(tester, 'Cholestyramine');
      await tapText(tester, 'Add');
      expect(find.text('Your Custom Medications'), findsOneWidget);
      expect(controller.data.medications, ['Cholestyramine']);

      await tapTooltip(tester, 'Remove Cholestyramine');
      expect(controller.data.medications, isEmpty);
    });

    testWidgets('international names and biosimilars map to the listed generic', (tester) async {
      final controller = await pumpWith(tester, [GutCondition.ulcerativeColitis]);
      await enterCustom(tester, 'Mesalazine');
      await tapText(tester, 'Add');
      await enterCustom(tester, 'amgevita');
      await tapText(tester, 'Add');
      expect(controller.data.medications, ['Mesalamine', 'Adalimumab']);
      expect(find.text('Your Custom Medications'), findsNothing);
    });

    testWidgets('a picked medication stays visible after the condition changes', (tester) async {
      final controller = OnboardingController();
      controller.data.conditions = [GutCondition.crohns];
      controller.data.medications.add('Loperamide');
      await pumpScreen(
        tester,
        MedicationsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      expect(find.text('Loperamide'), findsOneWidget);
      expect(find.byTooltip('Remove Loperamide'), findsOneWidget);
    });
  });

  group('CurrentSymptomsScreen', () {
    testWidgets('severity options are labelled radios that do not deselect the symptom',
        (tester) async {
      final handle = tester.ensureSemantics();
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        CurrentSymptomsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );

      await tapText(tester, 'Bloating');
      expect(controller.getSymptom('Bloating')?.severity, 'Moderate');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bloating severity: Moderate')),
        isSemantics(isInMutuallyExclusiveGroup: true, hasCheckedState: true, isChecked: true),
      );

      await tapSemantics(tester, 'Bloating severity: Severe');
      expect(controller.getSymptom('Bloating')?.severity, 'Severe');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bloating severity: Moderate')),
        isSemantics(isChecked: false),
      );
      expect(controller.hasSymptom('Bloating'), isTrue);
      handle.dispose();
    });

    testWidgets('blood in stool shows a contact-your-doctor notice', (tester) async {
      await pumpScreen(
        tester,
        CurrentSymptomsScreen(controller: OnboardingController(), onNext: () {}, onBack: () {}),
      );
      expect(find.textContaining('contact your doctor'), findsNothing);
      expect(find.textContaining('No symptoms right now?'), findsOneWidget);
      await tapText(tester, 'Blood in Stool');
      expect(find.textContaining('contact your doctor or care team'), findsOneWidget);
      expect(find.textContaining('No symptoms right now?'), findsNothing);
    });

    testWidgets('typed symptoms: listed names select the card, new ones become custom',
        (tester) async {
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        CurrentSymptomsScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      await enterCustom(tester, 'diarrhea');
      await tapText(tester, 'Add');
      expect(controller.data.currentSymptoms.single.name, 'Diarrhea');
      expect(controller.data.currentSymptoms.single.isCustom, isFalse);
      expect(find.text('Your Custom Symptoms'), findsNothing);

      await enterCustom(tester, 'Headache');
      await tapText(tester, 'Add');
      expect(find.text('Your Custom Symptoms'), findsOneWidget);
      expect(controller.getSymptom('Headache')?.isCustom, isTrue);
      await tapSemantics(tester, 'Headache severity: Mild');
      expect(controller.getSymptom('Headache')?.severity, 'Mild');

      await tapTooltip(tester, 'Remove Headache');
      expect(controller.hasSymptom('Headache'), isFalse);
    });
  });

  group('ThankYouScreen', () {
    testWidgets('has a labelled Back button, no fake review prompt, and Continue works',
        (tester) async {
      var next = 0;
      var back = 0;
      await pumpScreen(tester, ThankYouScreen(onNext: () => next++, onBack: () => back++));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Love the app?'), findsNothing);
      expect(find.text('Rate Now'), findsNothing);
      expect(find.textContaining('24/7'), findsNothing);

      await tapTooltip(tester, 'Back');
      await tapText(tester, 'Continue');
      expect(back, 1);
      expect(next, 1);
    });
  });
}
