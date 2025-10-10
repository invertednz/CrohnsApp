import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

class GoalScreen extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const GoalScreen({
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      Text(
                        'What\'s your main goal?',
                        style: OnboardingTheme.neonTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Help us personalize your experience',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      _GoalOption(
                        icon: Icons.trending_down,
                        title: 'Reduce Symptoms',
                        description: 'Track and minimize flare-ups and discomfort',
                        isSelected: controller.data.goal == 'reduce_symptoms',
                        onTap: () => controller.setGoal('reduce_symptoms'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _GoalOption(
                        icon: Icons.search,
                        title: 'Identify Triggers',
                        description: 'Discover what foods or activities affect you',
                        isSelected: controller.data.goal == 'identify_triggers',
                        onTap: () => controller.setGoal('identify_triggers'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _GoalOption(
                        icon: Icons.restaurant_menu,
                        title: 'Improve Diet',
                        description: 'Find foods that work best for your body',
                        isSelected: controller.data.goal == 'improve_diet',
                        onTap: () => controller.setGoal('improve_diet'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _GoalOption(
                        icon: Icons.insights,
                        title: 'Better Understanding',
                        description: 'Learn patterns and gain insights into your health',
                        isSelected: controller.data.goal == 'better_understanding',
                        onTap: () => controller.setGoal('better_understanding'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _GoalOption(
                        icon: Icons.favorite,
                        title: 'Overall Wellness',
                        description: 'Comprehensive health tracking and improvement',
                        isSelected: controller.data.goal == 'overall_wellness',
                        onTap: () => controller.setGoal('overall_wellness'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.data.goal != null ? onNext : null,
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

class _GoalOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _GoalOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? OnboardingTheme.neonGlow() : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? OnboardingTheme.accentGradient
                    : null,
                color: isSelected
                    ? null
                    : OnboardingTheme.accentIndigo.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: OnboardingTheme.healthGreen,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
