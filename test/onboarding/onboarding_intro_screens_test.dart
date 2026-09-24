import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/screens/onboarding/onboarding_controller.dart';
import 'package:gut_md/screens/onboarding/onboarding_data.dart';
import 'package:gut_md/screens/onboarding/screens/app_usage_screen.dart';
import 'package:gut_md/screens/onboarding/screens/condition_screen.dart';
import 'package:gut_md/screens/onboarding/screens/expected_results_screen.dart';
import 'package:gut_md/screens/onboarding/screens/goal_screen.dart';
import 'package:gut_md/screens/onboarding/screens/notification_preferences_screen.dart';
import 'package:gut_md/screens/onboarding/screens/progress_graph_screen.dart';
import 'package:gut_md/screens/onboarding/screens/welcome_screen.dart';
import 'package:gut_md/screens/onboarding/widgets/staggered_animation.dart';

/// Pumps [screen] on a phone-sized surface and lets entrance animations finish.
Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
  await tester.pumpAndSettle();
}

/// The option card (a `Semantics(button: true)` wrapper) that contains [text].
Finder optionCard(String text) {
  return find
      .ancestor(
        of: find.text(text),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      )
      .first;
}

bool isOptionSelected(WidgetTester tester, String text) {
  final data = tester.getSemantics(optionCard(text)).getSemanticsData();
  return data.flagsCollection.isSelected == Tristate.isTrue;
}

/// Scrolls [text] into view inside its scroll view, then taps it.
Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pump();
}

ElevatedButton primaryButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(find.byType(ElevatedButton));
}

void main() {
  group('WelcomeScreen', () {
    testWidgets('shows honest value propositions instead of unverified stats', (tester) async {
      await pumpScreen(tester, WelcomeScreen(onNext: () {}, onLogin: () {}));

      expect(find.text('Clinically Validated'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('10k+'), findsNothing);
      expect(find.textContaining('★'), findsNothing);
      expect(find.textContaining('peer-reviewed'), findsNothing);
      expect(find.textContaining('proven'), findsNothing);

      expect(find.text("Made for Crohn's, colitis & IBS"), findsOneWidget);
      expect(find.text('Quick daily check-ins'), findsOneWidget);
      expect(find.text('Meal & trigger diary'), findsOneWidget);
      expect(find.text('AI pattern insights'), findsOneWidget);
      expect(find.text('Meds & supplements log'), findsOneWidget);
      expect(find.textContaining('does not diagnose or treat'), findsOneWidget);
    });

    testWidgets('Get Started and Log In invoke their callbacks', (tester) async {
      var next = 0;
      var login = 0;
      await pumpScreen(tester, WelcomeScreen(onNext: () => next++, onLogin: () => login++));

      await tester.tap(find.text('Get Started'));
      await tester.tap(find.text('Log In'));
      expect(next, 1);
      expect(login, 1);
    });
  });

  group('ConditionScreen', () {
    testWidgets('Back button has an accessible name and calls onBack', (tester) async {
      var back = 0;
      await pumpScreen(
        tester,
        ConditionScreen(controller: OnboardingController(), onNext: () {}, onBack: () => back++),
      );

      expect(find.byTooltip('Back'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      expect(back, 1);
    });

    testWidgets('Continue is disabled until a condition is selected', (tester) async {
      var next = 0;
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        ConditionScreen(controller: controller, onNext: () => next++, onBack: () {}),
      );

      expect(find.text('Select at least one condition'), findsOneWidget);
      expect(primaryButton(tester).onPressed, isNull);

      await tapText(tester, "Crohn's Disease");
      await tester.pump();
      expect(find.text('Continue'), findsOneWidget);
      expect(primaryButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Continue'));
      expect(next, 1);
      expect(controller.data.conditions, [GutCondition.crohns]);
      expect(controller.data.condition, GutCondition.crohns);
    });

    testWidgets('options expose selected state and support multi-select', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        ConditionScreen(controller: controller, onNext: () {}, onBack: () {}),
      );

      expect(isOptionSelected(tester, "Crohn's Disease"), isFalse);
      await tapText(tester, "Crohn's Disease");
      await tapText(tester, 'IBS');
      await tester.pump();
      expect(isOptionSelected(tester, "Crohn's Disease"), isTrue);
      expect(isOptionSelected(tester, 'IBS'), isTrue);
      expect(isOptionSelected(tester, 'GERD'), isFalse);

      // Toggle one off again.
      await tapText(tester, "Crohn's Disease");
      await tester.pump();
      expect(isOptionSelected(tester, "Crohn's Disease"), isFalse);
      expect(controller.data.conditions, [GutCondition.ibs]);
      handle.dispose();
    });

    testWidgets('selections are kept on the controller when navigating back and return', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        ConditionScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      await tapText(tester, 'Ulcerative Colitis');
      await tapText(tester, 'GERD');
      await tester.pump();

      // Leave the screen (e.g. Back) and come back with a fresh widget.
      await tester.pumpWidget(const SizedBox());
      await pumpScreen(
        tester,
        ConditionScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      expect(isOptionSelected(tester, 'Ulcerative Colitis'), isTrue);
      expect(isOptionSelected(tester, 'GERD'), isTrue);
      expect(find.text('Continue'), findsOneWidget);

      // Clearing every selection also clears the primary condition.
      await tapText(tester, 'Ulcerative Colitis');
      await tapText(tester, 'GERD');
      await tester.pump();
      expect(controller.data.conditions, isEmpty);
      expect(controller.data.condition, isNull);
      handle.dispose();
    });
  });

  group('GoalScreen', () {
    testWidgets('requires a goal, exposes selection and allows only one goal', (tester) async {
      final handle = tester.ensureSemantics();
      var next = 0;
      var back = 0;
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        GoalScreen(controller: controller, onNext: () => next++, onBack: () => back++),
      );

      expect(find.text('Select a goal to continue'), findsOneWidget);
      expect(primaryButton(tester).onPressed, isNull);

      await tapText(tester, 'Identify Triggers');
      await tester.pump();
      expect(controller.data.goal, 'identify_triggers');
      expect(isOptionSelected(tester, 'Identify Triggers'), isTrue);

      await tapText(tester, 'Overall Wellness');
      await tester.pump();
      expect(controller.data.goal, 'overall_wellness');
      expect(isOptionSelected(tester, 'Overall Wellness'), isTrue);
      expect(isOptionSelected(tester, 'Identify Triggers'), isFalse);

      await tester.tap(find.text('Continue'));
      await tester.tap(find.byTooltip('Back'));
      expect(next, 1);
      expect(back, 1);
      handle.dispose();
    });
  });

  group('ExpectedResultsScreen', () {
    testWidgets('describes what tracking helps with and carries a disclaimer', (tester) async {
      var back = 0;
      await pumpScreen(tester, ExpectedResultsScreen(onNext: () {}, onBack: () => back++));

      expect(find.text('What to Expect'), findsOneWidget);
      expect(find.text('Clearer Bowel Patterns'), findsOneWidget);
      expect(find.text('Possible Food Triggers'), findsOneWidget);
      expect(find.textContaining('not a treatment'), findsOneWidget);
      // No outcome promises.
      expect(find.text('Reduced Pain & Discomfort'), findsNothing);
      expect(find.text('Increased Energy Levels'), findsNothing);
      expect(find.textContaining('Real results'), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      expect(back, 1);
    });
  });

  group('ProgressGraphScreen', () {
    testWidgets('carousel arrows are named and step through all five slides', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, ProgressGraphScreen(onNext: () {}, onBack: () {}));

      expect(find.text('Illustration only, not a prediction of your results'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Illustrative chart')), findsOneWidget);
      expect(find.bySemanticsLabel('Slide 1 of 5'), findsOneWidget);
      expect(find.byTooltip('Previous slide'), findsNothing);

      const weeks = ['Week 1-2', 'Week 3-4', 'Week 5-8', 'Week 9+'];
      for (var i = 0; i < weeks.length; i++) {
        await tester.tap(find.byTooltip('Next slide'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Slide ${i + 2} of 5'), findsOneWidget);
        expect(find.text(weeks[i]), findsOneWidget);
      }
      expect(find.byTooltip('Next slide'), findsNothing);

      await tester.tap(find.byTooltip('Previous slide'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Slide 4 of 5'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AppUsageScreen', () {
    testWidgets('Next/Previous walk the four feature cards and Continue finishes', (tester) async {
      final handle = tester.ensureSemantics();
      var next = 0;
      await pumpScreen(tester, AppUsageScreen(onNext: () => next++, onBack: () {}));

      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.bySemanticsLabel('Feature 1 of 4'), findsOneWidget);
      expect(find.text('Previous'), findsNothing);

      for (final title in ['Smart Insights', 'Diet Management', 'AI Assistant']) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Feature 4 of 4'), findsOneWidget);
      expect(find.textContaining('does not replace medical advice'), findsOneWidget);

      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('Diet Management'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      expect(next, 1);
      handle.dispose();
    });

    testWidgets('fits a short phone screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(1125, 2001); // 375 x 667
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppUsageScreen(onNext: () {}, onBack: () {}))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('NotificationPreferencesScreen', () {
    testWidgets('Continue needs a time; several times can be chosen and kept', (tester) async {
      final handle = tester.ensureSemantics();
      var next = 0;
      final controller = OnboardingController();
      await pumpScreen(
        tester,
        NotificationPreferencesScreen(controller: controller, onNext: () => next++, onBack: () {}),
      );

      expect(find.text('Select at least one'), findsOneWidget);
      expect(primaryButton(tester).onPressed, isNull);
      expect(find.textContaining('in your profile'), findsNothing);

      await tapText(tester, 'Morning');
      await tester.pump();
      await tapText(tester, 'Evening');
      await tester.pump();
      expect(controller.data.notificationTimes, ['morning', 'evening']);
      expect(isOptionSelected(tester, 'Evening'), isTrue);

      await tester.tap(find.text('Continue'));
      expect(next, 1);

      // Returning to the screen keeps the choice.
      await tester.pumpWidget(const SizedBox());
      await pumpScreen(
        tester,
        NotificationPreferencesScreen(controller: controller, onNext: () {}, onBack: () {}),
      );
      expect(isOptionSelected(tester, 'Morning'), isTrue);
      expect(find.text('Continue'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Skip clears reminder times and moves on', (tester) async {
      var next = 0;
      final controller = OnboardingController()..toggleNotificationTime('midday');
      await pumpScreen(
        tester,
        NotificationPreferencesScreen(controller: controller, onNext: () => next++, onBack: () {}),
      );

      await tester.tap(find.text('Skip'));
      expect(next, 1);
      expect(controller.data.notificationTimes, isEmpty);
    });
  });

  group('StaggeredAnimation', () {
    testWidgets('shows content immediately when reduce motion is on', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: StaggeredAnimation(index: 5, child: Text('content')),
          ),
        ),
      );
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, 1.0);
    });

    testWidgets('animates in after its stagger delay', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: StaggeredAnimation(index: 3, child: Text('content')),
        ),
      );
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, 0.0);
      await tester.pump(const Duration(milliseconds: 299));
      expect(fade.opacity.value, 0.0);
      await tester.pumpAndSettle();
      expect(fade.opacity.value, 1.0);
    });

    testWidgets('leaves no pending timer when removed before it starts', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: StaggeredAnimation(index: 20, child: Text('content')),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      // The test binding fails the test if a Timer is still pending here.
    });
  });
}
