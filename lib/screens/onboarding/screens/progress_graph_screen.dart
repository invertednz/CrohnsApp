import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../onboarding_theme.dart';

class ProgressGraphScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const ProgressGraphScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ProgressGraphScreen> createState() => _ProgressGraphScreenState();
}

class _ProgressGraphScreenState extends State<ProgressGraphScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
                style: OnboardingTheme.headingTextStyle(fontSize: 32),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Your journey to better health',
                style: OnboardingTheme.subheadingStyle,
              ),
              
              const SizedBox(height: 32),
              
              // Carousel with arrows
              Expanded(
                child: Stack(
                  children: [
                    // PageView
                    PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildGraphPage(),
                        _buildMilestonePage(
                          week: 'Week 1-2',
                          title: 'Getting Started',
                          description: 'Building tracking habits and gathering baseline data',
                          icon: Icons.play_circle_outline,
                        ),
                        _buildMilestonePage(
                          week: 'Week 3-4',
                          title: 'Early Insights',
                          description: 'Beginning to identify patterns and potential triggers',
                          icon: Icons.lightbulb_outline,
                        ),
                        _buildMilestonePage(
                          week: 'Week 5-8',
                          title: 'Noticeable Changes',
                          description: 'Implementing changes and seeing symptom reduction',
                          icon: Icons.trending_up,
                        ),
                        _buildMilestonePage(
                          week: 'Week 9+',
                          title: 'Sustained Improvement',
                          description: 'Maintaining healthy habits and continued progress',
                          icon: Icons.emoji_events,
                        ),
                      ],
                    ),
                    
                    // Left Arrow
                    if (_currentPage > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            onPressed: _previousPage,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    // Right Arrow
                    if (_currentPage < _totalPages - 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            onPressed: _nextPage,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? OnboardingTheme.accentIndigo
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
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

  Widget _buildGraphPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      
                      // Graph card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: OnboardingTheme.cardDecoration(withShadow: true),
                        child: Column(
                          children: [
                            const Text(
                              'Symptom Improvement Over Time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Custom graph
                            SizedBox(
                              height: 250,
                              child: CustomPaint(
                                painter: ProgressGraphPainter(),
                                child: Container(),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _LegendItem(
                                  color: OnboardingTheme.healthGreen,
                                  label: 'Improvement',
                                ),
                                _LegendItem(
                                  color: OnboardingTheme.warningAmber,
                                  label: 'Learning Phase',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMilestonePage({
    required String week,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: OnboardingTheme.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Week badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: OnboardingTheme.accentIndigo.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: OnboardingTheme.accentIndigo,
                    width: 2,
                  ),
                ),
                child: Text(
                  week,
                  style: const TextStyle(
                    fontSize: 16,
                    color: OnboardingTheme.lightIndigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                title,
                style: OnboardingTheme.headingTextStyle(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Container(
                padding: const EdgeInsets.all(24),
                decoration: OnboardingTheme.cardDecoration(),
                child: Text(
                  description,
                  style: OnboardingTheme.bodyStyle.copyWith(
                    fontSize: 16,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  
  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: OnboardingTheme.bodyStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _TimelineMilestone extends StatelessWidget {
  final String week;
  final String title;
  final String description;
  final IconData icon;
  
  const _TimelineMilestone({
    required this.week,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: OnboardingTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: OnboardingTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  week,
                  style: const TextStyle(
                    fontSize: 12,
                    color: OnboardingTheme.lightIndigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
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

class ProgressGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Draw grid lines
    final gridPaint = Paint()
      ..color = OnboardingTheme.accentIndigo.withOpacity(0.2)
      ..strokeWidth = 1;
    
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // Draw progress curve (slow start, then ramp up)
    final path = Path();
    final points = <Offset>[];
    
    for (int i = 0; i <= 100; i++) {
      final x = size.width * i / 100;
      // Exponential growth curve
      final progress = i / 100;
      final y = size.height * (1 - math.pow(progress, 2));
      points.add(Offset(x, y));
    }
    
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    // Draw gradient under curve
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          OnboardingTheme.healthGreen.withOpacity(0.3),
          OnboardingTheme.healthGreen.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, gradientPaint);
    
    // Draw the curve line
    paint.color = OnboardingTheme.healthGreen;
    paint.strokeWidth = 3;
    canvas.drawPath(path, paint);
    
    // Draw points at key milestones
    final pointPaint = Paint()
      ..color = OnboardingTheme.healthGreen
      ..style = PaintingStyle.fill;
    
    final milestones = [0, 25, 50, 75, 100];
    for (final milestone in milestones) {
      final point = points[milestone];
      canvas.drawCircle(point, 6, pointPaint);
      canvas.drawCircle(point, 6, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
