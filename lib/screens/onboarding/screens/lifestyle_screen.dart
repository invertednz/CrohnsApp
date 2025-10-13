import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../widgets/staggered_animation.dart';

class LifestyleScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const LifestyleScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  final TextEditingController _customController = TextEditingController();
  
  final List<_LifestyleFactor> _factors = [
    _LifestyleFactor(
      name: 'Poor Sleep',
      icon: Icons.bedtime_outlined,
      description: 'Less than 7 hours per night',
    ),
    _LifestyleFactor(
      name: 'High Stress',
      icon: Icons.psychology_outlined,
      description: 'Work or personal stress',
    ),
    _LifestyleFactor(
      name: 'Irregular Meals',
      icon: Icons.schedule_outlined,
      description: 'Inconsistent eating times',
    ),
    _LifestyleFactor(
      name: 'Low Exercise',
      icon: Icons.directions_run_outlined,
      description: 'Sedentary lifestyle',
    ),
    _LifestyleFactor(
      name: 'Smoking',
      icon: Icons.smoke_free_outlined,
      description: 'Tobacco use',
    ),
    _LifestyleFactor(
      name: 'Dehydration',
      icon: Icons.water_drop_outlined,
      description: 'Not drinking enough water',
    ),
    _LifestyleFactor(
      name: 'Late Night Eating',
      icon: Icons.nightlight_outlined,
      description: 'Eating close to bedtime',
    ),
    _LifestyleFactor(
      name: 'Anxiety',
      icon: Icons.sentiment_dissatisfied_outlined,
      description: 'Ongoing anxiety or worry',
    ),
  ];
  
  @override
  void dispose() {
    _customController.dispose();
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
                    onPressed: widget.onBack,
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
                        'Lifestyle Factors',
                        style: OnboardingTheme.headingTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Select factors that may affect your symptoms',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Lifestyle factors grid
                      ..._factors.asMap().entries.map((entry) {
                        final index = entry.key;
                        final factor = entry.value;
                        final isSelected = widget.controller.data.lifestyle.contains(factor.name);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StaggeredAnimation(
                            index: index,
                            child: GestureDetector(
                            onTap: () {
                              setState(() {
                                widget.controller.toggleLifestyle(factor.name);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? OnboardingTheme.accentIndigo
                                      : OnboardingTheme.accentIndigo.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? OnboardingTheme.accentGradient
                                          : null,
                                      color: isSelected
                                          ? null
                                          : OnboardingTheme.accentIndigo.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      factor.icon,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          factor.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          factor.description,
                                          style: OnboardingTheme.bodyStyle.copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: OnboardingTheme.healthGreen,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // Custom lifestyle factor
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: OnboardingTheme.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Custom Factor',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customController,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: OnboardingTheme.inputDecoration(
                                      label: 'Lifestyle factor',
                                      hint: 'e.g., Travel',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_customController.text.trim().isNotEmpty) {
                                      setState(() {
                                        widget.controller.addLifestyle(_customController.text.trim());
                                        _customController.clear();
                                      });
                                    }
                                  },
                                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                                    padding: const MaterialStatePropertyAll(
                                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  child: const Text('Add', style: TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Selected factors
                      if (widget.controller.data.lifestyle.isNotEmpty) ...[
                        const Text(
                          'Selected Factors',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: OnboardingTheme.cardDecoration(),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.controller.data.lifestyle.map((factor) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: OnboardingTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      factor,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          widget.controller.removeLifestyle(factor);
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
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
      ),
    );
  }
}

class _LifestyleFactor {
  final String name;
  final IconData icon;
  final String description;
  
  _LifestyleFactor({
    required this.name,
    required this.icon,
    required this.description,
  });
}
