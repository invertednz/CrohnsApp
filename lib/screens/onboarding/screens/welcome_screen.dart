import 'package:flutter/material.dart';
import '../onboarding_theme.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;
  
  const WelcomeScreen({Key? key, required this.onNext}) : super(key: key);

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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      
                      // App Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          size: 50,
                          color: OnboardingTheme.accentIndigo,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Welcome heading
                      Text(
                        'Welcome to\nCrohn\'s Companion',
                        style: OnboardingTheme.headingTextStyle(fontSize: 36),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Your journey to better digestive health starts here',
                        style: OnboardingTheme.subheadingStyle,
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Social proof card
                      Container(
                        decoration: OnboardingTheme.cardDecoration(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 48,
                              color: OnboardingTheme.healthGreen,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Clinically Validated',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Based on peer-reviewed research showing significant improvements in digestive symptoms',
                              style: OnboardingTheme.bodyStyle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Stats grid
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              value: '87%',
                              label: 'Report reduced symptoms',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              value: '92%',
                              label: 'Feel more in control',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              value: '10k+',
                              label: 'Active users',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              value: '4.8★',
                              label: 'Average rating',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Research note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.warningAmber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: OnboardingTheme.warningAmber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.science_outlined,
                              color: OnboardingTheme.warningAmber,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Evidence-based tracking methods proven to help identify triggers',
                                style: OnboardingTheme.bodyStyle.copyWith(
                                  fontSize: 14,
                                  color: OnboardingTheme.warningAmber,
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
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                    padding: const MaterialStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  
  const _StatCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: OnboardingTheme.cardDecoration(),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: OnboardingTheme.lightIndigo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: OnboardingTheme.bodyStyle.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
