import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

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

class _DiscountScreenState extends State<DiscountScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _isProcessing = false;
  
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
  
  void _acceptOffer() async {
    setState(() {
      _isProcessing = true;
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      widget.controller.completePurchase();
      widget.onAccept();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Cannot be dismissed
      child: Container(
        decoration: const BoxDecoration(
          gradient: OnboardingTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Attention grabber
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  OnboardingTheme.errorRed,
                                  OnboardingTheme.warningAmber,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              '⚡ WAIT! EXCLUSIVE OFFER ⚡',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'Special Discount',
                          style: OnboardingTheme.headingTextStyle(fontSize: 40),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'Don\'t miss this one-time offer!',
                          style: OnboardingTheme.subheadingStyle,
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Discount card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                OnboardingTheme.errorRed.withOpacity(0.3),
                                OnboardingTheme.accentIndigo.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: OnboardingTheme.errorRed,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Original price crossed out
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '\$9.99',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.5),
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: OnboardingTheme.errorRed,
                                      decorationThickness: 3,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Discount badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.errorRed,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '50% OFF',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // New price
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '\$',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: OnboardingTheme.healthGreen,
                                    ),
                                  ),
                                  const Text(
                                    '4.99',
                                    style: TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      '/month',
                                      style: OnboardingTheme.bodyStyle.copyWith(
                                        fontSize: 18,
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
                                  'PLUS 7 days FREE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: OnboardingTheme.healthGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Urgency message
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: OnboardingTheme.warningAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: OnboardingTheme.warningAmber.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                color: OnboardingTheme.warningAmber,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Limited Time Only',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This offer expires when you leave this page',
                                      style: OnboardingTheme.bodyStyle.copyWith(
                                        fontSize: 14,
                                        color: OnboardingTheme.warningAmber,
                                      ),
                                    ),
                                  ],
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Everything Included',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _BenefitRow(text: 'Unlimited symptom tracking'),
                              _BenefitRow(text: 'AI-powered insights'),
                              _BenefitRow(text: '24/7 health assistant'),
                              _BenefitRow(text: 'Cloud backup & sync'),
                              _BenefitRow(text: 'Priority support'),
                              _BenefitRow(text: 'Cancel anytime'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Savings calculation
                        Container(
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
                              const Text(
                                'You Save \$60/year',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'That\'s like getting 6 months free!',
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
                
                if (_isProcessing) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      OnboardingTheme.accentIndigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Processing your discount...',
                    style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                  ),
                ] else ...[
                  // Accept button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _acceptOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OnboardingTheme.healthGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.all(
                          OnboardingTheme.healthGreen,
                        ),
                      ),
                      child: const Text(
                        'Claim 50% Discount',
                        style: TextStyle(
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
                      'No thanks, continue with regular price',
                      style: OnboardingTheme.bodyStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
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
