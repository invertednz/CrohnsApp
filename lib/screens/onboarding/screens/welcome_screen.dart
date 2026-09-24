import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../widgets/staggered_animation.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onLogin;
  
  const WelcomeScreen({Key? key, required this.onNext, required this.onLogin}) : super(key: key);

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
                      const SizedBox(height: 12),

                      // Brand
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: OnboardingTheme.accentGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.spa_outlined, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'GutMD',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Semantics(
                        header: true,
                        child: Text(
                          'Find what calms\nyour gut',
                          style: OnboardingTheme.headingTextStyle(fontSize: 36),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'Check in daily, snap your meals, and let AI spot your patterns.',
                        style: OnboardingTheme.subheadingStyle,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      const StaggeredAnimation(index: 0, child: _ProductPreview()),

                      const SizedBox(height: 16),

                      const Text(
                        "Made for Crohn's, colitis & IBS",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: OnboardingTheme.healthGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Feature highlights
                      const Row(
                        children: [
                          Expanded(
                            child: StaggeredAnimation(
                              index: 1,
                              child: _FeatureCard(
                                icon: Icons.edit_note,
                                label: 'Quick daily check-ins',
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StaggeredAnimation(
                              index: 2,
                              child: _FeatureCard(
                                icon: Icons.restaurant_menu,
                                label: 'Meal & trigger diary',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Row(
                        children: [
                          Expanded(
                            child: StaggeredAnimation(
                              index: 3,
                              child: _FeatureCard(
                                icon: Icons.auto_awesome,
                                label: 'AI pattern insights',
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StaggeredAnimation(
                              index: 4,
                              child: _FeatureCard(
                                icon: Icons.medication_outlined,
                                label: 'Meds & supplements log',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Medical disclaimer
                      StaggeredAnimation(
                        index: 5,
                        child: Container(
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
                                Icons.info_outline,
                                color: OnboardingTheme.warningAmber,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "GutMD is a tracking tool. It does not diagnose or treat any condition, so keep following your care team's advice.",
                                  style: OnboardingTheme.bodyStyle.copyWith(
                                    fontSize: 14,
                                    color: OnboardingTheme.warningAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onLogin,
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: OnboardingTheme.cardDecoration(),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: OnboardingTheme.lightIndigo,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: OnboardingTheme.bodyStyle.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// An illustrative preview of what the app shows once you track, clearly
/// labelled as an example so it is never mistaken for real results.
class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Example of GutMD: a wellbeing score of 78 and improving, a meal photo rated gentle on your gut, '
          'and a possible trigger found from your own logs',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: 0.78,
                          strokeWidth: 7,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation(OnboardingTheme.healthGreen),
                        ),
                      ),
                      const Text('78', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wellbeing score',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: OnboardingTheme.healthGreen, size: 16),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Improving',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: OnboardingTheme.healthGreen, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Example', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _PreviewRow(
              icon: Icons.photo_camera_outlined,
              color: OnboardingTheme.lightIndigo,
              title: 'Salmon, rice & zucchini',
              subtitle: 'Gentle on your gut: 8/10',
            ),
            const SizedBox(height: 10),
            const _PreviewRow(
              icon: Icons.search,
              color: OnboardingTheme.warningAmber,
              title: 'Possible trigger: dairy',
              subtitle: 'Eaten on 3 of your 4 tough days',
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _PreviewRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
