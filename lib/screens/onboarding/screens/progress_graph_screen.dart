import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../onboarding_theme.dart';

class ProgressGraphScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const ProgressGraphScreen({
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
                        'Your Progress Journey',
                        style: OnboardingTheme.neonTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Typical improvement timeline with consistent use',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Graph card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: OnboardingTheme.cardDecoration(withGlow: true),
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
                      
                      // Timeline milestones
                      _TimelineMilestone(
                        week: 'Week 1-2',
                        title: 'Getting Started',
                        description: 'Building tracking habits and gathering baseline data',
                        icon: Icons.play_circle_outline,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _TimelineMilestone(
                        week: 'Week 3-4',
                        title: 'Early Insights',
                        description: 'Beginning to identify patterns and potential triggers',
                        icon: Icons.lightbulb_outline,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _TimelineMilestone(
                        week: 'Week 5-8',
                        title: 'Noticeable Changes',
                        description: 'Implementing changes and seeing symptom reduction',
                        icon: Icons.trending_up,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _TimelineMilestone(
                        week: 'Week 9+',
                        title: 'Sustained Improvement',
                        description: 'Maintaining healthy habits and continued progress',
                        icon: Icons.emoji_events,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Encouragement box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: OnboardingTheme.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: OnboardingTheme.neonGlow(),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.rocket_launch,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Your journey is unique. Stay consistent and you\'ll see results!',
                                style: OnboardingTheme.bodyStyle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
