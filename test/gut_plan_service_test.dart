import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/screens/onboarding/onboarding_data.dart';
import 'package:gut_md/services/gut_plan_service.dart';

void main() {
  group('GutPlanService.localPlan', () {
    test('personalises headline, focus and experiment from answers', () {
      final data = OnboardingData()
        ..conditions = [GutCondition.crohns]
        ..goal = 'identify_triggers'
        ..dietFlags = ['Dairy']
        ..currentSymptoms = [SymptomEntry(name: 'Bloating')]
        ..supplements = [SupplementEntry(name: 'Vitamin D')];

      final plan = GutPlanService.localPlan(data);

      expect(plan.headline, contains("Crohn's Disease"));
      expect(plan.focusAreas, hasLength(3));
      expect(plan.focusAreas.first.title, 'Find your trigger foods');
      expect(plan.focusAreas[1].title, 'Watch your bloating');
      expect(plan.focusAreas[2].title, 'Stay consistent');
      expect(plan.firstExperiment, contains('dairy'));
      expect(plan.dailyRoutine, contains('With meals: tick off supplements and meds'));
      expect(plan.source, 'local');
    });

    test('works with no answers and flags severe symptoms for a clinician', () {
      final empty = GutPlanService.localPlan(OnboardingData());
      expect(empty.headline, contains('your gut'));
      expect(empty.focusAreas, hasLength(3));

      final severe = GutPlanService.localPlan(
        OnboardingData()..currentSymptoms = [SymptomEntry(name: 'Pain', severity: 'Severe')],
      );
      expect(severe.encouragement, contains('care team'));
    });

    test('round-trips through JSON', () {
      final plan = GutPlanService.localPlan(OnboardingData()..goal = 'improve_diet');
      final copy = GutPlan.fromJson(plan.toJson());
      expect(copy.headline, plan.headline);
      expect(copy.focusAreas.map((f) => f.title), plan.focusAreas.map((f) => f.title));
      expect(copy.dailyRoutine, plan.dailyRoutine);
    });
  });
}
