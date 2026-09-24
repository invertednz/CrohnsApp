import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:gut_md/screens/home/home_screen.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/screens/auth/sign_in_screen.dart';
import 'package:gut_md/screens/auth/sign_up_screen.dart';
import 'onboarding_controller.dart';
import 'screens/welcome_screen.dart';
import 'screens/condition_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/expected_results_screen.dart';
import 'screens/progress_graph_screen.dart';
import 'screens/app_usage_screen.dart';
import 'screens/notification_preferences_screen.dart';
import 'screens/diet_flags_screen.dart';
import 'screens/supplements_screen.dart';
import 'screens/lifestyle_screen.dart';
import 'screens/medications_screen.dart';
import 'screens/symptoms_screen.dart';
import 'screens/thank_you_screen.dart';
import 'screens/trial_offer_screen.dart';
import 'screens/plan_building_screen.dart';
import 'screens/plan_reveal_screen.dart';
import 'screens/commitment_screen.dart';
import '../../services/gut_plan_service.dart';
import 'screens/timeline_screen.dart';
import 'screens/compare_plans_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/discount_screen.dart';
import 'screens/referral_share_screen.dart';
import '../../services/referral_service.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  GutPlan? _plan;
  final OnboardingController _controller = OnboardingController();
  final ReferralService _referralService = ReferralService();
  bool _showDiscountScreen = false;
  bool _showReferralScreen = false;
  bool _showComparePlans = false;
  bool _showPayment = false;

  /// Set once the user finished (or skipped to sign-up), so their answers
  /// belong on the account they are about to create.
  bool _answersCommitted = false;
  bool _profileSaved = false;

  void _nextStep() {
    setState(() {
      _controller.nextStep();
    });
  }

  void _previousStep() {
    setState(() {
      _controller.previousStep();
    });
  }

  void _handlePaymentClose() {
    // Leaving the paywall without a plan: offer the discount instead.
    setState(() {
      _showPayment = false;
      _showDiscountScreen = true;
    });
  }

  void _handlePaymentBack() {
    setState(() {
      _showPayment = false;
      _showComparePlans = true;
    });
  }

  void _handleDiscountAccept() {
    setState(() {
      _showDiscountScreen = false;
      _showReferralScreen = true;
    });
  }

  void _handleDiscountDecline() {
    _completeOnboarding();
  }
  
  void _handleReferralComplete() {
    _completeOnboarding();
  }

  AppUser? get _currentUser => BackendServiceProvider.isInitialized
      ? BackendServiceProvider.instance.auth.currentUser
      : null;

  void _commitAnswers() {
    _answersCommitted = true;
    _controller.completeOnboarding();
  }

  void _completeOnboarding() {
    _commitAnswers();
    if (_currentUser != null) {
      _saveToAccount();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _openSignUp();
    }
  }

  /// Sign-up sits on top of onboarding so its back button returns here.
  /// Once the account exists and sign-up opens Home, this flow is disposed
  /// and [dispose] saves the answers to the new account.
  void _openSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  /// Saves the onboarding answers and any referral code created before
  /// sign-up to the signed-in account (tracking types `profile`/`referral`).
  Future<void> _saveToAccount() async {
    final user = _currentUser;
    if (user == null || _profileSaved) return;
    _profileSaved = true;
    try {
      await OnboardingProfileStore.save(_controller.data, userId: user.id);
      await _referralService.saveForUser(user.id);
    } catch (error, stackTrace) {
      _profileSaved = false;
      developer.log(
        'Could not save onboarding answers to the account',
        name: 'OnboardingFlow',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// A returning user who logged in from the welcome screen: load the
  /// answers they gave when they first signed up.
  Future<void> _restoreFromAccount(String userId) async {
    try {
      await OnboardingProfileStore.restore(userId);
    } catch (error, stackTrace) {
      developer.log(
        'Could not load saved onboarding answers',
        name: 'OnboardingFlow',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  void _goToSignUp() {
    _controller.startTrial();
    _commitAnswers();
    _openSignUp();
  }

  void _showComparePlansScreen() {
    setState(() {
      _showComparePlans = true;
    });
  }

  void _hideComparePlansScreen() {
    setState(() {
      _showComparePlans = false;
    });
  }

  void _selectPlanAndContinue() {
    setState(() {
      _showComparePlans = false;
      _showPayment = true;
    });
  }

  void _handleNoThanks() {
    setState(() {
      _showComparePlans = false;
      _showDiscountScreen = true;
    });
  }

  /// System/browser back: step back through the flow instead of leaving it.
  void _handleSystemBack() {
    if (_showReferralScreen) {
      _handleReferralComplete();
    } else if (_showDiscountScreen) {
      _handleDiscountDecline();
    } else if (_showPayment) {
      _handlePaymentBack();
    } else if (_showComparePlans) {
      _hideComparePlansScreen();
    } else if (_controller.currentStep > 0) {
      _previousStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final atStart = _controller.currentStep == 0 &&
        !_showComparePlans &&
        !_showPayment &&
        !_showDiscountScreen &&
        !_showReferralScreen;
    return PopScope(
      canPop: atStart,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleSystemBack();
      },
      child: _buildOverlayOrStep(),
    );
  }

  Widget _buildOverlayOrStep() {
    if (_showReferralScreen) {
      return ReferralShareScreen(
        referralService: _referralService,
        onComplete: _handleReferralComplete,
      );
    }
    
    if (_showDiscountScreen) {
      return DiscountScreen(
        controller: _controller,
        onAccept: _handleDiscountAccept,
        onComplete: _handleDiscountDecline,
      );
    }

    if (_showPayment) {
      return PaymentScreen(
        controller: _controller,
        onNext: _completeOnboarding,
        onBack: _handlePaymentBack,
        onClose: _handlePaymentClose,
      );
    }

    if (_showComparePlans) {
      return ComparePlansScreen(
        controller: _controller,
        onSelectPlan: _selectPlanAndContinue,
        onBack: _hideComparePlansScreen,
        onNoThanks: _handleNoThanks,
      );
    }

    // Main onboarding flow, with a progress bar across the personal quiz.
    final step = _controller.currentStep;
    final inQuiz = step >= 1 && step <= OnboardingController.lastQuizStep;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentScreen(),
          ),
        ),
        if (inQuiz)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 24,
            right: 24,
            child: _QuizProgressBar(value: step / OnboardingController.lastQuizStep),
          ),
      ],
    );
  }

  Widget _buildCurrentScreen() {
    switch (_controller.currentStep) {
      case 0:
        return WelcomeScreen(
          key: const ValueKey(0),
          onNext: _nextStep,
          onLogin: _goToLogin,
        );
      case 1:
        return ConditionScreen(
          key: const ValueKey(1),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 2:
        return GoalScreen(
          key: const ValueKey(2),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 3:
        return ExpectedResultsScreen(
          key: const ValueKey(3),
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 4:
        return ProgressGraphScreen(
          key: const ValueKey(4),
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 5:
        return AppUsageScreen(
          key: const ValueKey(5),
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 6:
        return NotificationPreferencesScreen(
          key: const ValueKey(6),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 7:
        return DietFlagsScreen(
          key: const ValueKey(7),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 8:
        return SupplementsScreen(
          key: const ValueKey(8),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 9:
        return LifestyleScreen(
          key: const ValueKey(9),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 10:
        return MedicationsScreen(
          key: const ValueKey(10),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 11:
        return CurrentSymptomsScreen(
          key: const ValueKey(11),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 12:
        return ThankYouScreen(
          key: const ValueKey(12),
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 13:
        return PlanBuildingScreen(
          key: const ValueKey(13),
          controller: _controller,
          onComplete: (plan) {
            _plan = plan;
            _controller.data.plan = plan.toJson();
            _nextStep();
          },
        );
      case 14:
        final plan = _plan;
        if (plan == null) {
          // The plan lives in memory; rebuild it if the user came back here.
          return PlanBuildingScreen(
            key: const ValueKey('rebuild-plan'),
            controller: _controller,
            onComplete: (plan) => setState(() {
              _plan = plan;
              _controller.data.plan = plan.toJson();
            }),
          );
        }
        return PlanRevealScreen(
          key: const ValueKey(14),
          plan: plan,
          onNext: _nextStep,
        );
      case 15:
        return CommitmentScreen(
          key: const ValueKey(15),
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 16:
        return TrialOfferScreen(
          key: const ValueKey(16),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 17:
        return TimelineScreen(
          key: const ValueKey(17),
          controller: _controller,
          onNext: _goToSignUp,
          onBack: _previousStep,
          onComparePlans: _showComparePlansScreen,
        );
      default:
        return WelcomeScreen(
          key: const ValueKey(0),
          onNext: _nextStep,
          onLogin: _goToLogin,
        );
    }
  }

  @override
  void dispose() {
    // Leaving onboarding for Home. If an account now exists, finished answers
    // go to it; a returning user who logged in gets their saved answers back.
    final user = _currentUser;
    if (user != null) {
      if (_answersCommitted) {
        _saveToAccount();
      } else {
        _restoreFromAccount(user.id);
      }
    }
    _controller.dispose();
    super.dispose();
  }
}

/// Thin animated bar showing how far through the personal quiz the user is.
class _QuizProgressBar extends StatelessWidget {
  final double value;
  const _QuizProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Semantics(
      label: 'Onboarding progress $percent percent',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
          ),
        ),
      ),
    );
  }
}
