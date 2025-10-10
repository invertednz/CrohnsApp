import 'package:flutter/material.dart';
import '../onboarding_theme.dart';

class AppUsageScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const AppUsageScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<_CarouselItem> _items = [
    _CarouselItem(
      icon: Icons.edit_note,
      title: 'Daily Tracking',
      description: 'Log your symptoms, meals, and activities in seconds',
      features: [
        'Quick symptom logging',
        'Meal photo capture',
        'Activity tracking',
        'Mood monitoring',
      ],
    ),
    _CarouselItem(
      icon: Icons.insights,
      title: 'Smart Insights',
      description: 'AI-powered analysis identifies patterns and triggers',
      features: [
        'Trigger identification',
        'Pattern recognition',
        'Personalized recommendations',
        'Progress tracking',
      ],
    ),
    _CarouselItem(
      icon: Icons.restaurant_menu,
      title: 'Diet Management',
      description: 'Discover which foods work best for your body',
      features: [
        'Food diary',
        'Trigger foods alerts',
        'Meal planning',
        'Nutrition insights',
      ],
    ),
    _CarouselItem(
      icon: Icons.chat_bubble_outline,
      title: 'AI Assistant',
      description: 'Get instant answers to your health questions',
      features: [
        '24/7 availability',
        'Evidence-based answers',
        'Personalized advice',
        'Symptom guidance',
      ],
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              
              const SizedBox(height: 24),
              
              Text(
                'How It Works',
                style: OnboardingTheme.neonTextStyle(fontSize: 32),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Swipe to explore features',
                style: OnboardingTheme.subheadingStyle,
              ),
              
              const SizedBox(height: 32),
              
              // Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return _CarouselCard(item: _items[index]);
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? OnboardingTheme.accentIndigo
                          : OnboardingTheme.accentIndigo.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Navigation buttons
              Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OnboardingTheme.secondaryButtonStyle(),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _items.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          widget.onNext();
                        }
                      },
                      style: OnboardingTheme.primaryButtonStyle().copyWith(
                        padding: const MaterialStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      child: Text(
                        _currentPage < _items.length - 1 ? 'Next' : 'Continue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}

class _CarouselItem {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  
  _CarouselItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });
}

class _CarouselCard extends StatelessWidget {
  final _CarouselItem item;
  
  const _CarouselCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: OnboardingTheme.cardDecoration(withGlow: true),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: OnboardingTheme.accentGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: OnboardingTheme.neonGlow(),
            ),
            child: Icon(
              item.icon,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            item.description,
            style: OnboardingTheme.subheadingStyle.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Features
          ...item.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: OnboardingTheme.healthGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: OnboardingTheme.bodyStyle.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
