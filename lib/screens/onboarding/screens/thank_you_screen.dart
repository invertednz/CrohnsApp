import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../widgets/staggered_animation.dart';

class ThankYouScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ThankYouScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  static const List<_Benefit> _benefits = [
    _Benefit(Icons.track_changes, 'Track your symptoms and identify patterns'),
    _Benefit(Icons.insights, 'See trends and insights from your own logs'),
    _Benefit(Icons.trending_up, 'Monitor your progress over time'),
    _Benefit(Icons.support_agent, 'Ask the AI assistant about your tracked data'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                      tooltip: 'Back',
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ],
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated checkmark
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: const BoxDecoration(
                                gradient: OnboardingTheme.accentGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Thank You!',
                                  style: OnboardingTheme.headingTextStyle(fontSize: 40),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 16),

                                const Text(
                                  'For trusting us with your health journey',
                                  style: OnboardingTheme.subheadingStyle,
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 48),

                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: OnboardingTheme.cardDecoration(withShadow: true),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.celebration,
                                        size: 48,
                                        color: OnboardingTheme.healthGreen,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Congratulations!',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'You\'ve taken the first step towards better digestive health',
                                        style: OnboardingTheme.bodyStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Benefits list
                                for (var i = 0; i < _benefits.length; i++) ...[
                                  StaggeredAnimation(
                                    index: i,
                                    child: _BenefitItem(
                                      icon: _benefits[i].icon,
                                      text: _benefits[i].text,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                StaggeredAnimation(
                                  index: _benefits.length,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          OnboardingTheme.healthGreen.withValues(alpha: 0.2),
                                          OnboardingTheme.accentIndigo.withValues(alpha: 0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: OnboardingTheme.healthGreen.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: OnboardingTheme.healthGreen,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            'A quick daily check-in is all it takes to start seeing your patterns.',
                                            style: OnboardingTheme.bodyStyle.copyWith(
                                              fontWeight: FontWeight.w600,
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
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onNext,
                    style: OnboardingTheme.primaryButtonStyle().copyWith(
                      padding: const WidgetStatePropertyAll(
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
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String text;

  const _Benefit(this.icon, this.text);
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: OnboardingTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: OnboardingTheme.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
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
      ),
    );
  }
}
