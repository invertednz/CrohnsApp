import 'package:flutter/material.dart';
import '../onboarding_theme.dart';

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
                        style: OnboardingTheme.neonTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Real results from consistent tracking',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Results cards
                      _ResultCard(
                        icon: Icons.calendar_today,
                        title: 'More Regular Bowel Movements',
                        description: 'Track patterns and identify what helps maintain regularity',
                        color: OnboardingTheme.healthGreen,
                        delay: 0,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _ResultCard(
                        icon: Icons.favorite_border,
                        title: 'Reduced Pain & Discomfort',
                        description: 'Identify triggers and minimize painful episodes',
                        color: OnboardingTheme.accentIndigo,
                        delay: 100,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _ResultCard(
                        icon: Icons.air,
                        title: 'Less Bloating & Gas',
                        description: 'Discover foods and habits that reduce digestive issues',
                        color: OnboardingTheme.lightIndigo,
                        delay: 200,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _ResultCard(
                        icon: Icons.energy_savings_leaf,
                        title: 'Increased Energy Levels',
                        description: 'Better nutrition and symptom management boost vitality',
                        color: OnboardingTheme.warningAmber,
                        delay: 300,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _ResultCard(
                        icon: Icons.psychology,
                        title: 'Better Mental Clarity',
                        description: 'Understanding your body reduces stress and anxiety',
                        color: OnboardingTheme.indigoGlow,
                        delay: 400,
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
                                'Results vary by individual. Consistency is key to seeing improvements.',
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

class _ResultCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final int delay;
  
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.delay = 0,
  });

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_animation),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: OnboardingTheme.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: OnboardingTheme.bodyStyle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
