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
  final OnboardingController _controller = OnboardingController();
  final ReferralService _referralService = ReferralService();
  bool _showDiscountScreen = false;
  bool _showReferralScreen = false;
  bool _showComparePlans = false;

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
    // User closed payment screen, show discount offer
    setState(() {
      _showDiscountScreen = true;
    });
  }

  void _handleDiscountAccept() {
    // User accepted discount, show referral screen
    setState(() {
      _showDiscountScreen = false;
      _showReferralScreen = true;
    });
  }

  void _handleDiscountDecline() {
    // User declined discount, complete onboarding
    _completeOnboarding();
  }
  
  void _handleReferralComplete() {
    // User completed referral flow, finish onboarding
    _completeOnboarding();
  }

  void _completeOnboarding() {
    _controller.completeOnboarding();
    final authService = BackendServiceProvider.instance.auth;
    final user = authService.currentUser;
    if (user != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SignUpScreen(
            shouldReturnToOnboarding: false,
          ),
        ),
        (route) => false,
      );
    }
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignInScreen(
          shouldReturnToOnboarding: false,
        ),
      ),
    );
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
    });
    _nextStep(); // Go to payment
  }

  @override
  Widget build(BuildContext context) {
    // Show compare plans screen if triggered
    if (_showComparePlans) {
      return ComparePlansScreen(
        controller: _controller,
        onSelectPlan: _selectPlanAndContinue,
        onBack: _hideComparePlansScreen,
      );
    }

    // Show referral screen if triggered
    if (_showReferralScreen) {
      return ReferralShareScreen(
        controller: _controller,
        referralService: _referralService,
        onComplete: _handleReferralComplete,
        donorName: _controller.data.giftDonorName ?? 'A Community Member',
      );
    }
    
    // Show discount screen if triggered
    if (_showDiscountScreen) {
      return DiscountScreen(
        controller: _controller,
        onAccept: _handleDiscountAccept,
        onComplete: _handleDiscountDecline,
      );
    }

    // Main onboarding flow
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildCurrentScreen(),
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
        return TrialOfferScreen(
          key: const ValueKey(13),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 14:
        return TimelineScreen(
          key: const ValueKey(14),
          controller: _controller,
          onNext: _nextStep,
          onBack: _previousStep,
          onComparePlans: _showComparePlansScreen,
        );
      case 15:
        return PaymentScreen(
          key: const ValueKey(15),
          controller: _controller,
          onNext: _completeOnboarding,
          onBack: _previousStep,
          onClose: _handlePaymentClose,
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
    _controller.dispose();
    super.dispose();
  }
}
