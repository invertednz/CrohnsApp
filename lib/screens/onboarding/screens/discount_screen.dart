import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';

/// Shown when someone leaves the paywall without picking a plan: a lower
/// first-year price, still starting with the free trial. Nothing is charged.
class DiscountScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onAccept;
  final VoidCallback onComplete;

  const DiscountScreen({
    Key? key,
    required this.controller,
    required this.onAccept,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  static const SubscriptionPlan _offer = SubscriptionPlan.discountedAnnual;
  static const SubscriptionPlan _regular = SubscriptionPlan.annual;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _acceptOffer() {
    widget.controller.selectPlan(_offer);
    widget.controller.startTrial();
    widget.onAccept();
  }

  @override
  Widget build(BuildContext context) {
    final saving = (_regular.price - _offer.price).toStringAsFixed(0);
    final trialEnds =
        DateFormat('MMMM d').format(widget.controller.trialEndDate);
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
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Attention grabber
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  OnboardingTheme.ctaGreen,
                                  OnboardingTheme.accentIndigo,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'NEW MEMBER OFFER',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Semantics(
                          header: true,
                          child: Text(
                            'Your first year for ${_offer.priceLabel}',
                            style:
                                OnboardingTheme.headingTextStyle(fontSize: 34),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Not ready for the full price? Get a year of GutMD for '
                          '${_offer.priceLabel} instead of ${_regular.priceLabel}. '
                          'You still start with a $kTrialDays-day free trial.',
                          style: OnboardingTheme.subheadingStyle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Discount card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                OnboardingTheme.accentIndigo.withOpacity(0.35),
                                OnboardingTheme.healthGreen.withOpacity(0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: OnboardingTheme.healthGreen,
                              width: 2.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Original price crossed out
                              Semantics(
                                label:
                                    'Regular price ${_regular.priceLabel} a year',
                                excludeSemantics: true,
                                child: Text(
                                  _regular.priceLabel,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.6),
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor:
                                        OnboardingTheme.lightIndigo,
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // New price
                              Semantics(
                                label:
                                    'Offer price ${_offer.priceLabel} for your first year',
                                excludeSemantics: true,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '\$',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _offer.price.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontSize: 72,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 18),
                                      child: Text(
                                        _offer.period,
                                        style:
                                            OnboardingTheme.bodyStyle.copyWith(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'First year only, then ${_regular.priceLabel}/year',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Benefits
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: OnboardingTheme.cardDecoration(),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Everything You Unlock',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                              _BenefitRow(
                                  text:
                                      'Symptom, food, supplement & medication tracking'),
                              _BenefitRow(
                                  text:
                                      'AI summaries of your patterns and possible triggers'),
                              _BenefitRow(
                                  text:
                                      'AI health assistant for everyday questions'),
                              _BenefitRow(
                                  text: 'Cloud backup & sync across devices'),
                              _BenefitRow(text: 'Cancel anytime'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Savings calculation
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: OnboardingTheme.accentGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.savings,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Save \$$saving on your first year',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No payment today. Your free trial runs until $trialEnds '
                                'and you are never charged automatically.',
                                textAlign: TextAlign.center,
                                style: OnboardingTheme.bodyStyle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _acceptOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OnboardingTheme.ctaGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Claim offer – ${_offer.priceLabel}/year',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Decline button
                TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'No thanks – continue without the offer',
                    style: OnboardingTheme.bodyStyle.copyWith(
                      fontSize: 14,
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
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: OnboardingTheme.healthGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
