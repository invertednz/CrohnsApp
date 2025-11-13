import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

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
  bool _isProcessing = false;
  String _selectedPlan = 'annual';
  bool _showAllPlans = false;

  @override
  void initState() {
    super.initState();
    widget.controller.selectPlan(
      planId: 'annual',
      price: 49,
      isPayItForward: false,
    );
  }
  
  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      widget.controller.completePurchase();
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onClose();
        return false;
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: OnboardingTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header with close button
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
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
                        
                        Text(
                          'Unlock Your Full Health Journey',
                          style: OnboardingTheme.headingTextStyle(fontSize: 32),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'Start your 7-day free trial today',
                          style: OnboardingTheme.subheadingStyle,
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),

                        _showAllPlans ? _buildAllPlansView() : _buildAnnualPlanOnlyView(),

                        const SizedBox(height: 32),

                        // Benefits section
                        _buildBenefitsSection(),
                        
                        const SizedBox(height: 32),
                        
                        // Primary CTA Button
                        _buildPrimaryCTA(),
                        
                        const SizedBox(height: 24),
                        
                        // Payment methods (collapsed by default)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: OnboardingTheme.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Method',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PaymentOption(
                                icon: Icons.credit_card,
                                title: 'Credit Card',
                                subtitle: 'Visa, Mastercard, Amex',
                                onTap: _processPayment,
                              ),
                              const SizedBox(height: 12),
                              _PaymentOption(
                                icon: Icons.apple,
                                title: 'Apple Pay',
                                subtitle: 'Fast & secure',
                                onTap: _processPayment,
                              ),
                              const SizedBox(height: 12),
                              _PaymentOption(
                                icon: Icons.g_mobiledata,
                                title: 'Google Pay',
                                subtitle: 'Quick checkout',
                                onTap: _processPayment,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Terms
                        Text(
                          'By subscribing, you agree to our Terms of Service and Privacy Policy. Your subscription will auto-renew unless cancelled.',
                          style: OnboardingTheme.bodyStyle.copyWith(
                            fontSize: 12,
                            color: OnboardingTheme.lightIndigo.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_isProcessing) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      OnboardingTheme.accentIndigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Processing...',
                    style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnnualPlanOnlyView() {
    return Column(
      children: [
        _buildAnnualPlanCard(),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _showAllPlans = true;
            });
          },
          child: Text(
            'Compare Plans',
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
        Text(
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
        
        // Annual Plan (Most Prominent)
        _buildAnnualPlanCard(),
        const SizedBox(height: 16),
        
        // Monthly Plan
        _buildMonthlyPlanCard(),
        const SizedBox(height: 16),
        
        // Pay It Forward Plan
        _buildPayItForwardCard(),
      ],
    );
  }

  Widget _buildAnnualPlanCard() {
    final isSelected = _selectedPlan == 'annual';
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = 'annual';
          widget.controller.selectPlan(
            planId: 'annual',
            price: 49,
            isPayItForward: false,
          );
        });
      },
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
            color: isSelected ? OnboardingTheme.healthGreen : OnboardingTheme.lightIndigo.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: OnboardingTheme.healthGreen.withOpacity(isSelected ? 0.4 : 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Best Value Badge
            _buildBadge(
              label: '🏆 BEST VALUE - SAVE 45%',
              color: OnboardingTheme.healthGreen,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrice('\$', '49'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Only \$49 for the entire year (less than \$4.10/month)',
              style: OnboardingTheme.bodyStyle.copyWith(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            _buildTrialPill(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OnboardingTheme.healthGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings, color: OnboardingTheme.healthGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Save \$59 compared to monthly',
                    style: TextStyle(
                      color: OnboardingTheme.healthGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildHighlightBullet('Less than \$4.10 per month for unlimited support'),
            _buildHighlightBullet('Lock in lowest price - cancel anytime'),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPlanCard() {
    final isSelected = _selectedPlan == 'monthly';
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = 'monthly';
          widget.controller.selectPlan(
            planId: 'monthly',
            price: 9,
            isPayItForward: false,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? OnboardingTheme.healthGreen : OnboardingTheme.lightIndigo.withOpacity(0.3),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrice('\$', '9', fontSize: 48),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '/month',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Flexible month-to-month billing',
              style: OnboardingTheme.bodyStyle.copyWith(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
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
    final isSelected = _selectedPlan == 'pay_it_forward';
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = 'pay_it_forward';
          widget.controller.selectPlan(
            planId: 'pay_it_forward',
            price: 59,
            isPayItForward: true,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? OnboardingTheme.healthGreen : OnboardingTheme.lightIndigo.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: OnboardingTheme.lightIndigo, size: 20),
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
              'Sponsor Someone in Need',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrice('\$', '59', fontSize: 48),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '/year',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'We match your gift to help someone in need',
              textAlign: TextAlign.center,
              style: OnboardingTheme.bodyStyle.copyWith(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars,
                color: OnboardingTheme.healthGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Everything Included',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BenefitRow(text: 'Unlimited symptom tracking'),
          _BenefitRow(text: 'AI-powered health insights'),
          _BenefitRow(text: 'Personalized meal recommendations'),
          _BenefitRow(text: '24/7 AI health assistant'),
          _BenefitRow(text: 'Medication & supplement reminders'),
          _BenefitRow(text: 'Secure cloud backup'),
          _BenefitRow(text: 'Export health reports'),
          _BenefitRow(text: 'Cancel anytime, no commitment'),
        ],
      ),
    );
  }
  
  Widget _buildPrimaryCTA() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            OnboardingTheme.healthGreen,
            OnboardingTheme.healthGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: OnboardingTheme.healthGreen.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : _processPayment,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              _selectedPlan == 'annual'
                  ? 'Start Free Trial – Then \$49/year'
                  : _selectedPlan == 'monthly'
                      ? 'Start Free Trial – Then \$9/month'
                      : 'Sponsor a Member – \$59/year',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
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

  Widget _buildPrice(String symbol, String amount, {double fontSize = 56}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          symbol,
          style: TextStyle(
            fontSize: fontSize * 0.46,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
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
        '7-Day Free Trial',
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

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: OnboardingTheme.accentIndigo.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: OnboardingTheme.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: OnboardingTheme.bodyStyle.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: OnboardingTheme.lightIndigo,
              size: 16,
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: OnboardingTheme.healthGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
