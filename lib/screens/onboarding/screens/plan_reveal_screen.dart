import 'package:flutter/material.dart';

import 'package:gut_md/services/gut_plan_service.dart';
import '../onboarding_theme.dart';
import '../widgets/staggered_animation.dart';

/// Reveals the personalised plan generated from the onboarding answers.
class PlanRevealScreen extends StatelessWidget {
  final GutPlan plan;
  final VoidCallback onNext;

  const PlanRevealScreen({
    Key? key,
    required this.plan,
    required this.onNext,
  }) : super(key: key);

  static const _focusIcons = [Icons.search, Icons.monitor_heart_outlined, Icons.check_circle_outline];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: OnboardingTheme.primaryGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.healthGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          plan.source == 'gemini' ? 'Personalised with AI' : 'Personalised for you',
                          style: const TextStyle(color: OnboardingTheme.healthGreen, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        plan.headline,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, height: 1.15),
                      ),
                      const SizedBox(height: 24),
                      for (var i = 0; i < plan.focusAreas.length; i++)
                        StaggeredAnimation(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _Card(
                              icon: _focusIcons[i % _focusIcons.length],
                              title: plan.focusAreas[i].title,
                              body: plan.focusAreas[i].detail,
                            ),
                          ),
                        ),
                      StaggeredAnimation(
                        index: plan.focusAreas.length,
                        child: _Card(
                          icon: Icons.science_outlined,
                          title: 'Your first experiment',
                          body: plan.firstExperiment,
                          accent: OnboardingTheme.warningAmber,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your daily routine',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      for (final step in plan.dailyRoutine)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check, size: 18, color: OnboardingTheme.healthGreen),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(step, style: OnboardingTheme.bodyStyle)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        plan.encouragement,
                        style: OnboardingTheme.bodyStyle.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                    padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 18)),
                  ),
                  child: const Text('Start my plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  const _Card({
    required this.icon,
    required this.title,
    required this.body,
    this.accent = OnboardingTheme.lightIndigo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: OnboardingTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: accent.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(body, style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
