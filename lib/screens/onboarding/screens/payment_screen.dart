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
                          'Start Your Trial',
                          style: OnboardingTheme.neonTextStyle(fontSize: 32),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'Subscribe now and get 7 days free',
                          style: OnboardingTheme.subheadingStyle,
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Pricing card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: OnboardingTheme.cardDecoration(withGlow: true),
                          child: Column(
                            children: [
                              const Text(
                                'Premium Plan',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '\$',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: OnboardingTheme.lightIndigo,
                                    ),
                                  ),
                                  const Text(
                                    '9.99',
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      '/month',
                                      style: OnboardingTheme.bodyStyle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.healthGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'First 7 days FREE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: OnboardingTheme.healthGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Payment methods
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
                        
                        // Benefits reminder
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: OnboardingTheme.accentIndigo.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'What You Get',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _BenefitRow(text: 'Unlimited tracking'),
                              _BenefitRow(text: 'AI-powered insights'),
                              _BenefitRow(text: '24/7 health assistant'),
                              _BenefitRow(text: 'Cloud backup'),
                              _BenefitRow(text: 'Cancel anytime'),
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
