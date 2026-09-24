import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../widgets/staggered_animation.dart';

class ExpectedResultsScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ExpectedResultsScreen({
    Key? key,
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
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      Text(
                        'What to Expect',
                        style: OnboardingTheme.headingTextStyle(fontSize: 32),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Consistent tracking helps you and your care team see the full picture',
                        style: OnboardingTheme.subheadingStyle,
                      ),

                      const SizedBox(height: 32),

                      // What tracking can help with
                      const StaggeredAnimation(
                        index: 0,
                        child: _ResultCard(
                          icon: Icons.calendar_today,
                          title: 'Clearer Bowel Patterns',
                          description: 'See how frequency and consistency change across days and weeks',
                          color: OnboardingTheme.healthGreen,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const StaggeredAnimation(
                        index: 1,
                        child: _ResultCard(
                          icon: Icons.favorite_border,
                          title: 'A Record of Pain & Flares',
                          description: 'Log pain levels to see when flares happen and what came before them',
                          color: OnboardingTheme.accentIndigo,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const StaggeredAnimation(
                        index: 2,
                        child: _ResultCard(
                          icon: Icons.restaurant,
                          title: 'Possible Food Triggers',
                          description: 'Compare meals with symptoms to find foods worth discussing with your doctor',
                          color: OnboardingTheme.lightIndigo,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const StaggeredAnimation(
                        index: 3,
                        child: _ResultCard(
                          icon: Icons.energy_savings_leaf,
                          title: 'Energy & Wellbeing Trends',
                          description: 'Follow how your energy and mood shift alongside your symptoms',
                          color: OnboardingTheme.warningAmber,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const StaggeredAnimation(
                        index: 4,
                        child: _ResultCard(
                          icon: Icons.forum_outlined,
                          title: 'Better-Informed Appointments',
                          description: 'Bring an accurate history to your doctor instead of relying on memory',
                          color: OnboardingTheme.indigoGlow,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Info box
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
                              Icons.info_outline,
                              color: OnboardingTheme.lightIndigo,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'GutMD is a tracking tool, not a treatment. Everyone is different, and it does not replace advice from your healthcare team.',
                                style: OnboardingTheme.bodyStyle.copyWith(
                                  fontSize: 14,
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
                  onPressed: onNext,
                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                    padding: const MaterialStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  child: const Text(
                    'Continue',
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

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ResultCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: OnboardingTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: OnboardingTheme.bodyStyle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
