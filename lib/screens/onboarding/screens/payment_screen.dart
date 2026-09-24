import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';

/// Confirms the chosen plan and starts the free trial. The app has no payment
/// processing, so no payment details are collected and nothing is charged.
class PaymentScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const PaymentScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const List<SubscriptionPlan> _plans = [
    SubscriptionPlan.annual,
    SubscriptionPlan.monthly,
    SubscriptionPlan.payItForward,
  ];

  late SubscriptionPlan _selectedPlan;
  bool _showAllPlans = false;

  @override
  void initState() {
    super.initState();
    // Keep whatever was picked on Compare Plans.
    final current = widget.controller.selectedPlan;
    _selectedPlan =
        _plans.contains(current) ? current : SubscriptionPlan.annual;
  }

  void _select(SubscriptionPlan plan) {
    setState(() => _selectedPlan = plan);
    widget.controller.selectPlan(plan);
  }

  void _startTrial() {
    widget.controller.selectPlan(_selectedPlan);
    widget.controller.startTrial();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    // System back is handled by OnboardingFlow.
    return Container(
      decoration: const BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header with close button
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        Semantics(
                          header: true,
                          child: Text(
                            'Unlock Your Full Health Journey',
                            style:
                                OnboardingTheme.headingTextStyle(fontSize: 32),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Start your $kTrialDays-day free trial today',
                          style: OnboardingTheme.subheadingStyle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        _showAllPlans
                            ? _buildAllPlansView()
                            : _buildSelectedPlanView(),

                        const SizedBox(height: 32),

                        // Benefits section
                        _buildBenefitsSection(),

                        const SizedBox(height: 32),

                        // Primary CTA Button
                        _buildPrimaryCTA(),

                        const SizedBox(height: 12),

                        Text(
                          'Then ${_selectedPlan.priceLabel}${_selectedPlan.period} if you choose to continue. '
                          'No payment is taken today.',
                          style:
                              OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Terms
                        Text(
                          'No payment details are collected and you are never charged automatically. '
                          'By continuing, you agree to our Terms of Service and Privacy Policy.',
                          style: OnboardingTheme.bodyStyle.copyWith(
                            fontSize: 12,
                            color: OnboardingTheme.indigoGlow.withOpacity(0.85),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPlanView() {
    return Column(
      children: [
        _buildPlanCard(_selectedPlan),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _showAllPlans = true;
            });
          },
          child: const Text(
            'Change plan',
            style: TextStyle(
              fontSize: 16,
              color: OnboardingTheme.lightIndigo,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllPlansView() {
    return Column(
      children: [
        // Comparison Header
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick the option that works best for you',
          style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        for (final plan in _plans) ...[
          _buildPlanCard(plan),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.monthly:
        return _buildMonthlyPlanCard();
      case SubscriptionPlan.payItForward:
        return _buildPayItForwardCard();
      case SubscriptionPlan.annual:
      case SubscriptionPlan.discountedAnnual:
        return _buildAnnualPlanCard();
    }
  }

  Widget _selectable({
    required SubscriptionPlan plan,
    required Widget child,
  }) {
    return Semantics(
      button: true,
      selected: _selectedPlan == plan,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: () => _select(plan),
        child: child,
      ),
    );
  }

  Widget _buildAnnualPlanCard() {
    const plan = SubscriptionPlan.annual;
    final isSelected = _selectedPlan == plan;
    final perMonth = (plan.price / 12).toStringAsFixed(2);
    return _selectable(
      plan: plan,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              OnboardingTheme.accentIndigo,
              OnboardingTheme.accentIndigo.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.healthGreen
                : OnboardingTheme.lightIndigo.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: OnboardingTheme.healthGreen
                  .withOpacity(isSelected ? 0.4 : 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Best Value Badge
            _buildBadge(
              label:
                  'BEST VALUE - SAVE ${SubscriptionPlan.annualSavingsPercent}%',
              color: OnboardingTheme.ctaGreen,
            ),
            const SizedBox(height: 20),
            const Text(
              'Annual Plan',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildPrice(plan),
            const SizedBox(height: 8),
            Text(
              '${plan.priceLabel} for the whole year (about \$$perMonth a month)',
              textAlign: TextAlign.center,
              style: OnboardingTheme.bodyStyle.copyWith(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            _buildTrialPill(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.savings, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Save \$${SubscriptionPlan.annualSavings.toStringAsFixed(2)} a year vs monthly',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildHighlightBullet('One payment a year instead of twelve'),
            _buildHighlightBullet('Cancel anytime'),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPlanCard() {
    const plan = SubscriptionPlan.monthly;
    final isSelected = _selectedPlan == plan;
    return _selectable(
      plan: plan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.healthGreen
                : OnboardingTheme.lightIndigo.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Monthly Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildPrice(plan, fontSize: 48),
            const SizedBox(height: 8),
            Text(
              'Flexible month-to-month billing',
              style: OnboardingTheme.bodyStyle.copyWith(
                fontSize: 13,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 12),
            _buildTrialPill(),
          ],
        ),
      ),
    );
  }

  Widget _buildPayItForwardCard() {
    const plan = SubscriptionPlan.payItForward;
    final isSelected = _selectedPlan == plan;
    final extra =
        (plan.price - SubscriptionPlan.annual.price).toStringAsFixed(0);
    return _selectable(
      plan: plan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.healthGreen
                : OnboardingTheme.lightIndigo.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite,
                    color: OnboardingTheme.lightIndigo, size: 20),
                SizedBox(width: 6),
                Text(
                  'PAY IT FORWARD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: OnboardingTheme.lightIndigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Annual + Help Others',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildPrice(plan, fontSize: 48),
            const SizedBox(height: 8),
            Text(
              'Everything in Annual, plus \$$extra a year to help keep GutMD affordable for others',
              textAlign: TextAlign.center,
              style: OnboardingTheme.bodyStyle.copyWith(
                fontSize: 13,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 12),
            _buildTrialPill(),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OnboardingTheme.accentIndigo.withOpacity(0.3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars,
                color: OnboardingTheme.healthGreen,
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Everything Included',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _BenefitRow(text: 'Unlimited symptom tracking'),
          _BenefitRow(text: 'Diet, supplement & medication logging'),
          _BenefitRow(text: 'AI summaries of your patterns'),
          _BenefitRow(text: 'AI health assistant chat'),
          _BenefitRow(text: 'Meal photo analysis'),
          _BenefitRow(text: 'Secure cloud backup'),
          _BenefitRow(text: 'Cancel anytime, no commitment'),
        ],
      ),
    );
  }

  Widget _buildPrimaryCTA() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _startTrial,
        style: ElevatedButton.styleFrom(
          backgroundColor: OnboardingTheme.ctaGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Start $kTrialDays-day free trial',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPrice(SubscriptionPlan plan, {double fontSize = 56}) {
    return Semantics(
      label:
          '${plan.priceLabel} ${plan.period == '/year' ? 'per year' : 'per month'}',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              plan.priceLabel,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text(
                plan.period,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '$kTrialDays-Day Free Trial',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHighlightBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: OnboardingTheme.healthGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
