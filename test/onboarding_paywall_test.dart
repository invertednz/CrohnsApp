import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/mock_backend.dart';
import 'package:gut_md/models/referral.dart';
import 'package:gut_md/screens/onboarding/onboarding_controller.dart';
import 'package:gut_md/screens/onboarding/onboarding_data.dart';
import 'package:gut_md/screens/onboarding/screens/compare_plans_screen.dart';
import 'package:gut_md/screens/onboarding/screens/discount_screen.dart';
import 'package:gut_md/screens/onboarding/screens/payment_screen.dart';
import 'package:gut_md/screens/onboarding/screens/referral_share_screen.dart';
import 'package:gut_md/services/referral_service.dart';

Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
}

void main() {
  group('SubscriptionPlan', () {
    test('prices and savings are consistent', () {
      expect(SubscriptionPlan.annual.priceLabel, r'$49');
      expect(SubscriptionPlan.monthly.priceLabel, r'$9.99');
      expect(SubscriptionPlan.discountedAnnual.priceLabel, r'$29');
      // 12 x $9.99 = $119.88; annual saves $70.88 (59%).
      expect(SubscriptionPlan.annualSavings, closeTo(70.88, 0.001));
      expect(SubscriptionPlan.annualSavingsPercent, 59);
    });

    test('fromId falls back to annual for unknown ids', () {
      expect(SubscriptionPlan.fromId('monthly'), SubscriptionPlan.monthly);
      expect(SubscriptionPlan.fromId('gifted_annual'), SubscriptionPlan.annual);
      expect(SubscriptionPlan.fromId(null), SubscriptionPlan.annual);
    });
  });

  group('OnboardingController paywall state', () {
    test('selectPlan records the plan without marking anything paid', () {
      final c = OnboardingController();
      c.selectPlan(SubscriptionPlan.payItForward);
      expect(c.data.selectedPlan, 'pay_it_forward');
      expect(c.data.planPrice, 59);
      expect(c.data.isPayItForward, isTrue);
      expect(c.data.hasPaid, isFalse);

      c.selectPlan(SubscriptionPlan.monthly);
      expect(c.data.isPayItForward, isFalse, reason: 'switching plans clears Pay It Forward');
      expect(c.selectedPlan, SubscriptionPlan.monthly);
    });

    test('startTrial starts a $kTrialDays-day trial once', () {
      final c = OnboardingController();
      final start = DateTime(2026, 9, 24, 10);
      c.startTrial(now: start);
      expect(c.data.isOnTrial, isTrue);
      expect(c.data.hasPaid, isFalse);
      expect(c.data.trialEndDate, start.add(const Duration(days: kTrialDays)));

      c.startTrial(now: start.add(const Duration(days: 3)));
      expect(c.data.trialStartDate, start, reason: 'restarting keeps the original dates');
    });

    test('completeOnboarding shares the answers through AppState', () {
      final c = OnboardingController();
      c.addMedication('Ustekinumab');
      c.addSupplement(SupplementEntry(name: 'Slippery Elm', takesAM: true));
      c.completeOnboarding();
      expect(c.data.hasCompletedOnboarding, isTrue);
      expect(AppState().userMedications, contains('Ustekinumab'));
      expect(AppState().userSupplements.map((s) => s.name), contains('Slippery Elm'));
    });
  });

  group('OnboardingData JSON', () {
    test('round-trips answers, trial and plan', () {
      final data = OnboardingData()
        ..goal = 'identify_triggers'
        ..conditions = [GutCondition.crohns, GutCondition.ibs]
        ..medications = ['Mesalamine']
        ..supplements = [SupplementEntry(name: 'Vitamin D', takesPM: true)]
        ..currentSymptoms = [SymptomEntry(name: 'Bloating', severity: 'Mild')]
        ..isOnTrial = true
        ..trialEndDate = DateTime(2026, 10, 1)
        ..selectedPlan = 'monthly'
        ..planPrice = 9.99;
      final restored = OnboardingData.fromJson(data.toJson());
      expect(restored.goal, 'identify_triggers');
      expect(restored.conditions, [GutCondition.crohns, GutCondition.ibs]);
      expect(restored.medications, ['Mesalamine']);
      expect(restored.supplements.single.takesPM, isTrue);
      expect(restored.currentSymptoms.single.severity, 'Mild');
      expect(restored.trialEndDate, DateTime(2026, 10, 1));
      expect(restored.selectedPlan, 'monthly');
      expect(restored.planPrice, 9.99);
    });

    test('tolerates missing and malformed fields', () {
      final restored = OnboardingData.fromJson({'trialEndDate': 'not a date', 'supplements': ['x']});
      expect(restored.trialEndDate, isNull);
      expect(restored.supplements, isEmpty);
      expect(restored.planPrice, SubscriptionPlan.annual.price);
    });
  });

  group('OnboardingProfileStore', () {
    test('saves answers as a profile entry and restores them', () async {
      final backend = MockBackend.create();
      final data = OnboardingData()
        ..conditions = [GutCondition.ulcerativeColitis]
        ..medications = ['Vedolizumab']
        ..dietFlags = ['Dairy'];

      final saved = await OnboardingProfileStore.save(data, userId: 'u1', tracking: backend.tracking);
      expect(saved, isTrue);

      final entry = await backend.tracking.getTrackingData(
        userId: 'u1',
        date: OnboardingProfileStore.entryId,
        type: OnboardingProfileStore.trackingType,
      );
      expect(entry?['medications'], ['Vedolizumab']);
      expect(entry?['condition_display'], 'Ulcerative Colitis');
      expect(entry?['date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

      final restored = await OnboardingProfileStore.restore('u1', tracking: backend.tracking);
      expect(restored?.dietFlags, ['Dairy']);
      expect(AppState().userMedications, ['Vedolizumab']);
    });

    test('does nothing without a signed-in user', () async {
      final backend = MockBackend.create();
      expect(await OnboardingProfileStore.save(OnboardingData(), tracking: backend.tracking), isFalse);
      expect(await OnboardingProfileStore.restore('nobody', tracking: backend.tracking), isNull);
    });
  });

  group('ReferralService', () {
    final codePattern = RegExp('^[${ReferralService.codeAlphabet}]{${ReferralService.codeLength}}\$');

    test('generates codes without confusable characters', () {
      final service = ReferralService(tracking: MockBackend.create().tracking);
      for (var i = 0; i < 50; i++) {
        expect(service.generateReferralCode(), matches(codePattern));
      }
    });

    test('keeps a signed-out code pending, then saves it on sign-up', () async {
      final tracking = MockBackend.create().tracking;
      final service = ReferralService(tracking: tracking);

      final pending = await service.loadOrCreate(null);
      expect(service.isSaved, isFalse);
      expect(service.isLoading, isFalse);

      expect(await service.saveForUser('new_user'), isTrue);
      expect(service.isSaved, isTrue);
      expect(service.referral?.userId, 'new_user');

      final reloaded = ReferralService(tracking: tracking);
      final loaded = await reloaded.loadOrCreate('new_user');
      expect(loaded.referralCode, pending.referralCode, reason: 'the same code is loaded back');
    });

    test('an account keeps its existing code', () async {
      final tracking = MockBackend.create().tracking;
      final first = await ReferralService(tracking: tracking).loadOrCreate('u2');

      final other = ReferralService(tracking: tracking);
      await other.loadOrCreate(null);
      await other.saveForUser('u2');
      expect(other.referral?.referralCode, first.referralCode);
    });

    test('Referral.fromJson reads stored tracking entries', () {
      final referral = Referral.fromJson({
        'referralCode': 'ABCD2345',
        'userId': 'u3',
        'createdAt': '2026-09-24T10:00:00.000',
        'successfulReferrals': 2,
        'earnedRewards': 20,
        'type': 'referral',
      });
      expect(referral.id, 'ABCD2345');
      expect(referral.earnedRewards, 20.0);
      expect(referral.remainingReferralSlots, 3);
    });
  });

  group('Paywall screens', () {
    testWidgets('payment screen starts the trial without collecting payment', (tester) async {
      final controller = OnboardingController()..selectPlan(SubscriptionPlan.monthly);
      var next = 0, closed = 0;
      await _pumpScreen(
        tester,
        PaymentScreen(
          controller: controller,
          onNext: () => next++,
          onBack: () {},
          onClose: () => closed++,
        ),
      );

      expect(find.textContaining('Credit Card'), findsNothing);
      expect(find.textContaining('Processing'), findsNothing);
      expect(find.text('Monthly Plan'), findsOneWidget, reason: 'keeps the plan chosen on Compare Plans');

      await tester.tap(find.byTooltip('Close'));
      expect(closed, 1);

      await tester.ensureVisible(find.text('Start $kTrialDays-day free trial'));
      await tester.tap(find.text('Start $kTrialDays-day free trial'));
      await tester.pump();
      expect(next, 1);
      expect(controller.data.isOnTrial, isTrue);
      expect(controller.data.hasPaid, isFalse);
      expect(controller.data.selectedPlan, 'monthly');
    });

    testWidgets('compare plans records the chosen plan on continue', (tester) async {
      final controller = OnboardingController();
      var selected = 0, noThanks = 0;
      await _pumpScreen(
        tester,
        ComparePlansScreen(
          controller: controller,
          onSelectPlan: () => selected++,
          onBack: () {},
          onNoThanks: () => noThanks++,
        ),
      );
      expect(find.text('Save ${SubscriptionPlan.annualSavingsPercent}%'), findsOneWidget);

      await tester.ensureVisible(find.text('Monthly'));
      await tester.tap(find.text('Monthly'));
      await tester.pump();
      expect(find.text('Continue with Monthly'), findsOneWidget);
      await tester.tap(find.text('Continue with Monthly'));
      await tester.pump();
      expect(selected, 1);
      expect(controller.selectedPlan, SubscriptionPlan.monthly);

      await tester.tap(find.text('No thanks'));
      await tester.pump();
      expect(noThanks, 1);
    });

    testWidgets('discount offer is honest and does not fake a purchase', (tester) async {
      final controller = OnboardingController();
      var accepted = 0;
      await _pumpScreen(
        tester,
        DiscountScreen(controller: controller, onAccept: () => accepted++, onComplete: () {}),
      );
      expect(find.textContaining('sponsored'), findsNothing);
      expect(find.text(r'Your first year for $29'), findsOneWidget);

      await tester.tap(find.text(r'Claim offer – $29/year'));
      await tester.pump();
      expect(accepted, 1, reason: 'no fake processing delay');
      expect(controller.data.selectedPlan, SubscriptionPlan.discountedAnnual.id);
      expect(controller.data.isOnTrial, isTrue);
      expect(controller.data.hasPaid, isFalse);
    });

    testWidgets('referral screen creates a code and copies the invite when sharing is unavailable',
        (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      // No share sheet on this device (like most desktop browsers).
      const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, (call) async {
        throw PlatformException(code: 'unavailable', message: 'No share sheet');
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, null));

      final service = ReferralService(tracking: MockBackend.create().tracking);
      await _pumpScreen(tester, ReferralShareScreen(referralService: service, onComplete: () {}));
      await tester.pumpAndSettle();

      final code = service.referral!.referralCode;
      expect(find.text(code), findsOneWidget);
      expect(find.text('Your code is saved to your account when you sign up.'), findsOneWidget);

      await tester.ensureVisible(find.text('Share Your Code'));
      await tester.tap(find.text('Share Your Code'));
      await tester.pumpAndSettle();
      expect(clipboard, contains(code));
      expect(find.textContaining('Invite message copied'), findsOneWidget);
    });
  });
}
