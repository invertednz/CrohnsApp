import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

class TrialOfferScreen extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const TrialOfferScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      
                      // Special offer badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              OnboardingTheme.warningAmber,
                              OnboardingTheme.warningAmber.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🎉 SPECIAL OFFER',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        '7 Days Free',
                        style: OnboardingTheme.headingTextStyle(fontSize: 48),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Start your journey with a free trial',
                        style: OnboardingTheme.subheadingStyle,
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Main offer card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: OnboardingTheme.cardDecoration(withShadow: true),
                        child: Column(
                          children: [
                            // Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FREE',
                                  style: OnboardingTheme.headingTextStyle(fontSize: 48),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(
                                      'for 7 days',
                                      style: OnboardingTheme.bodyStyle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Then \$49/year',
                                      style: OnboardingTheme.bodyStyle.copyWith(
                                        fontSize: 16,
                                        color: OnboardingTheme.healthGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Pay it Forward option: \$59/year',
                                      style: OnboardingTheme.bodyStyle.copyWith(
                                        fontSize: 14,
                                        color: OnboardingTheme.lightIndigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'Choose from our \$49 annual plan or become a hero by sponsoring someone for \$59.',
                              textAlign: TextAlign.center,
                              style: OnboardingTheme.bodyStyle.copyWith(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            const Divider(
                              color: OnboardingTheme.accentIndigo,
                              thickness: 1,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Features
                            _FeatureItem(
                              icon: Icons.all_inclusive,
                              text: 'Unlimited symptom tracking',
                            ),
                            const SizedBox(height: 12),
                            _FeatureItem(
                              icon: Icons.insights,
                              text: 'AI-powered insights & patterns',
                            ),
                            const SizedBox(height: 12),
                            _FeatureItem(
                              icon: Icons.restaurant_menu,
                              text: 'Complete diet & meal tracking',
                            ),
                            const SizedBox(height: 12),
                            _FeatureItem(
                              icon: Icons.chat_bubble_outline,
                              text: '24/7 AI health assistant',
                            ),
                            const SizedBox(height: 12),
                            _FeatureItem(
                              icon: Icons.cloud_sync,
                              text: 'Cloud backup & sync',
                            ),
                            const SizedBox(height: 12),
                            _FeatureItem(
                              icon: Icons.notifications_active,
                              text: 'Smart reminders & alerts',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Notification info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.accentIndigo.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active,
                              color: OnboardingTheme.lightIndigo,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'We\'ll remind you',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You\'ll get a notification 2 days before your trial ends',
                                    style: OnboardingTheme.bodyStyle.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Guarantee
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.healthGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: OnboardingTheme.healthGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user,
                              color: OnboardingTheme.healthGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cancel anytime. No commitments.',
                                style: OnboardingTheme.bodyStyle.copyWith(
                                  fontSize: 14,
                                  color: OnboardingTheme.healthGreen,
                                  fontWeight: FontWeight.w600,
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
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.startTrial();
                    onNext();
                  },
                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                    padding: const MaterialStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  child: const Text(
                    'Start Free Trial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: OnboardingTheme.healthGreen,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
