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
  
  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: OnboardingTheme.darkNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: OnboardingTheme.accentIndigo.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: OnboardingTheme.accentGradient,
                  shape: BoxShape.circle,
                  
                ),
                child: const Icon(
                  Icons.star,
                  size: 40,
                  color: OnboardingTheme.warningAmber,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your feedback helps us improve and helps others discover the app',
                style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: OnboardingTheme.warningAmber,
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OnboardingTheme.secondaryButtonStyle(),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Open app store review page
                        // For iOS: Use in_app_review package
                        // For Android: Use in_app_review package
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Thank you for your support!'),
                            backgroundColor: OnboardingTheme.healthGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: OnboardingTheme.primaryButtonStyle(),
                      child: const Text('Rate Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                            decoration: BoxDecoration(
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
                              
                              Text(
                                'For trusting us with your health journey',
                                style: OnboardingTheme.subheadingStyle,
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 48),
                              
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: OnboardingTheme.cardDecoration(withShadow: true),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.celebration,
                                      size: 48,
                                      color: OnboardingTheme.healthGreen,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Congratulations!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'You\'ve taken the first step towards better digestive health',
                                      style: OnboardingTheme.bodyStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Review request card
                              GestureDetector(
                                onTap: () {
                                  _showReviewDialog(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        OnboardingTheme.warningAmber.withOpacity(0.2),
                                        OnboardingTheme.accentIndigo.withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: OnboardingTheme.warningAmber.withOpacity(0.4),
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
                                        child: const Icon(
                                          Icons.star,
                                          color: OnboardingTheme.warningAmber,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Love the app?',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tap to leave us a review',
                                              style: OnboardingTheme.bodyStyle.copyWith(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: OnboardingTheme.lightIndigo,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Benefits list
                              StaggeredAnimation(
                                index: 0,
                                child: _BenefitItem(
                                  icon: Icons.track_changes,
                                  text: 'Track your symptoms and identify patterns',
                                ),
                              ),
                              const SizedBox(height: 16),
                              StaggeredAnimation(
                                index: 1,
                                child: _BenefitItem(
                                  icon: Icons.insights,
                                  text: 'Get personalized insights and recommendations',
                                ),
                              ),
                              const SizedBox(height: 16),
                              StaggeredAnimation(
                                index: 2,
                                child: _BenefitItem(
                                  icon: Icons.trending_up,
                                  text: 'Monitor your progress over time',
                                ),
                              ),
                              const SizedBox(height: 16),
                              StaggeredAnimation(
                                index: 3,
                                child: _BenefitItem(
                                  icon: Icons.support_agent,
                                  text: 'Access 24/7 AI health assistant',
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              StaggeredAnimation(
                                index: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        OnboardingTheme.healthGreen.withOpacity(0.2),
                                        OnboardingTheme.accentIndigo.withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: OnboardingTheme.healthGreen.withOpacity(0.3),
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
                                          'Your commitment to improving your health is inspiring!',
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
