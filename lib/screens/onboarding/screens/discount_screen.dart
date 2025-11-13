import 'dart:math';

import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

const List<String> _donorNames = [
  'Olivia', 'Emma', 'Charlotte', 'Amelia', 'Ava', 'Sophia', 'Isabella', 'Mia',
  'Evelyn', 'Harper', 'Luna', 'Camila', 'Gianna', 'Abigail', 'Ella',
  'Elizabeth', 'Sofia', 'Emily', 'Scarlett', 'Victoria', 'Madison',
  'Eleanor', 'Grace', 'Chloe', 'Penelope', 'Riley', 'Zoey', 'Nora', 'Lily',
  'Aurora', 'Violet', 'Hazel', 'Ellie', 'Paisley', 'Audrey', 'Skylar',
  'Claire', 'Lucy', 'Anna', 'Stella', 'Natalie', 'Emilia', 'Zoe', 'Leah',
  'Savannah', 'Brooklyn', 'Bella', 'Aria', 'Isla', 'Addison', 'Willow',
  'Everly', 'Kinsley', 'Naomi', 'Eliana', 'Kennedy', 'Lillian', 'Elena',
  'Autumn', 'Piper', 'Ruby', 'Sadie', 'Sarah', 'Allison', 'Josephine', 'Cora',
  'Vivian', 'Madeline', 'Peyton', 'Julia', 'Raelynn', 'Athena', 'Maria',
  'Jasmine', 'Serenity', 'Adeline', 'Caroline', 'Hadley', 'Brielle', 'Sloane',
  'Brynlee', 'Morgan', 'Ivy', 'Eden', 'Margot', 'Camille', 'Lainey', 'Mila',
  'Liam', 'Noah', 'Oliver', 'Elijah', 'James', 'William', 'Benjamin', 'Lucas',
  'Henry', 'Alexander', 'Mason', 'Michael', 'Ethan', 'Daniel', 'Logan',
  'Jackson', 'Levi', 'Sebastian', 'Mateo', 'Jack'
];

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
  late final String _donorName;
  
  @override
  void initState() {
    super.initState();
    _donorName = _donorNames[Random().nextInt(_donorNames.length)];
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
    widget.controller.selectPlan(
      planId: 'gifted_annual',
      price: 29,
      isGiftedDiscount: true,
      donorName: _donorName,
    );
    
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  OnboardingTheme.healthGreen,
                                  OnboardingTheme.accentIndigo,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              '🎁 YOU JUST RECEIVED A GIFT',
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
                          '$_donorName sponsored your health journey',
                          style: OnboardingTheme.headingTextStyle(fontSize: 34),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'They believe you deserve premium care. We agree—so we’re matching their generosity.',
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '\$49',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.4),
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: OnboardingTheme.accentIndigo,
                                      decorationThickness: 2,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Gift badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.healthGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'YOUR COMMUNITY MATCHED THIS GIFT',
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
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    '29',
                                    style: TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 18),
                                    child: Text(
                                      '/year',
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
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Sponsored by $_donorName • Matched by Crohn\'s Companion',
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
                        
                        // Impact message
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: OnboardingTheme.accentIndigo.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: OnboardingTheme.healthGreen,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Accepting this gift keeps our pay-it-forward circle alive. When you’re ready, you can sponsor someone else too.',
                                  style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
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
                                'Everything You Unlock',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _BenefitRow(text: 'Unlimited symptom tracking'),
                              _BenefitRow(text: 'AI-powered insights tailored to your journey'),
                              _BenefitRow(text: '24/7 compassionate AI health assistant'),
                              _BenefitRow(text: 'Cloud backup & sync across devices'),
                              _BenefitRow(text: 'Priority support when you need a real human'),
                              _BenefitRow(text: 'Cancel anytime—no strings attached'),
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
                                'You Save \$20 Today',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Regular price is \$49/year — your total is just \$29 thanks to $_donorName's gift and our match.",
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
                      ),
                      child: const Text(
                        'Accept Gift – \$29/year',
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
                      'Maybe later — continue without the gift',
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
