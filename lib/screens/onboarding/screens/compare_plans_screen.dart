import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';

/// Features every plan includes; all of them exist in the app today.
const List<String> _coreFeatures = [
  'Unlimited symptom tracking',
  'Diet, supplement & medication logging',
  'AI summaries of your patterns',
  'AI health assistant chat',
  'Meal photo analysis',
  'Cloud backup & sync',
];

class ComparePlansScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onSelectPlan;
  final VoidCallback onBack;
  final VoidCallback onNoThanks;

  const ComparePlansScreen({
    Key? key,
    required this.controller,
    required this.onSelectPlan,
    required this.onBack,
    required this.onNoThanks,
  }) : super(key: key);

  @override
  State<ComparePlansScreen> createState() => _ComparePlansScreenState();
}

class _ComparePlansScreenState extends State<ComparePlansScreen> {
  static const List<SubscriptionPlan> _plans = [
    SubscriptionPlan.annual,
    SubscriptionPlan.monthly,
    SubscriptionPlan.payItForward,
  ];

  late SubscriptionPlan _selectedPlan;

  @override
  void initState() {
    super.initState();
    final current = widget.controller.selectedPlan;
    _selectedPlan =
        _plans.contains(current) ? current : SubscriptionPlan.annual;
  }

  void _select(SubscriptionPlan plan) {
    setState(() => _selectedPlan = plan);
  }

  void _continue() {
    widget.controller.selectPlan(_selectedPlan);
    widget.onSelectPlan();
  }

  String? _badge(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.annual:
        return 'Save ${SubscriptionPlan.annualSavingsPercent}%';
      case SubscriptionPlan.payItForward:
        return 'Help Others';
      default:
        return null;
    }
  }

  String _description(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.annual:
        return 'Best value for long-term tracking';
      case SubscriptionPlan.monthly:
        return 'Flexible month-to-month billing';
      case SubscriptionPlan.payItForward:
        final extra = (SubscriptionPlan.payItForward.price -
                SubscriptionPlan.annual.price)
            .toStringAsFixed(0);
        return 'Annual plus \$$extra a year to help keep GutMD affordable for others';
      case SubscriptionPlan.discountedAnnual:
        return '';
    }
  }

  List<String> _features(SubscriptionPlan plan) {
    if (plan == SubscriptionPlan.payItForward) {
      return const ['Everything in Annual', ..._coreFeatures];
    }
    return _coreFeatures;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: widget.onBack,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: const Text(
                          'Compare Plans',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      for (final plan in _plans) ...[
                        _PlanCard(
                          title: plan.displayName,
                          price: plan.priceLabel,
                          period: plan.period,
                          savings: _badge(plan),
                          savingsColor: plan == SubscriptionPlan.payItForward
                              ? OnboardingTheme.ctaGreen
                              : null,
                          description: _description(plan),
                          features: _features(plan),
                          isSelected: _selectedPlan == plan,
                          isRecommended: plan == SubscriptionPlan.annual,
                          onTap: () => _select(plan),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 8),

                      // Trial terms
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: OnboardingTheme.lightIndigo,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'All plans start with a $kTrialDays-day free trial. '
                                'No payment today, and you are never charged automatically. Cancel anytime.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OnboardingTheme.ctaGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Continue with ${_selectedPlan.displayName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.onNoThanks,
                      child: const Text(
                        'No thanks',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? savings;
  final Color? savingsColor;
  final String description;
  final List<String> features;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.savings,
    this.savingsColor,
    required this.description,
    required this.features,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? OnboardingTheme.accentIndigo
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: OnboardingTheme.accentIndigo.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Selection indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? OnboardingTheme.accentIndigo
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? OnboardingTheme.accentIndigo
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? OnboardingTheme.accentIndigo
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (savings != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (savingsColor ?? const Color(0xFFB45309))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        savings!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: savingsColor ?? const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  if (isRecommended && savings == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: OnboardingTheme.accentIndigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: OnboardingTheme.accentIndigo,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),

              if (isSelected) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Features
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: OnboardingTheme.ctaGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
