import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

class CurrentSymptomsScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const CurrentSymptomsScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<CurrentSymptomsScreen> createState() => _CurrentSymptomsScreenState();
}

class _CurrentSymptomsScreenState extends State<CurrentSymptomsScreen> {
  final List<_SymptomOption> _symptoms = [
    _SymptomOption(
      name: 'Abdominal Pain',
      icon: Icons.emergency_outlined,
      severity: 'High',
      color: OnboardingTheme.errorRed,
    ),
    _SymptomOption(
      name: 'Diarrhea',
      icon: Icons.water_drop_outlined,
      severity: 'High',
      color: OnboardingTheme.errorRed,
    ),
    _SymptomOption(
      name: 'Bloating',
      icon: Icons.air,
      severity: 'Medium',
      color: OnboardingTheme.warningAmber,
    ),
    _SymptomOption(
      name: 'Gas',
      icon: Icons.cloud_outlined,
      severity: 'Medium',
      color: OnboardingTheme.warningAmber,
    ),
    _SymptomOption(
      name: 'Fatigue',
      icon: Icons.battery_0_bar,
      severity: 'Medium',
      color: OnboardingTheme.warningAmber,
    ),
    _SymptomOption(
      name: 'Nausea',
      icon: Icons.sick_outlined,
      severity: 'Medium',
      color: OnboardingTheme.warningAmber,
    ),
    _SymptomOption(
      name: 'Loss of Appetite',
      icon: Icons.no_meals_outlined,
      severity: 'Medium',
      color: OnboardingTheme.warningAmber,
    ),
    _SymptomOption(
      name: 'Weight Loss',
      icon: Icons.trending_down,
      severity: 'High',
      color: OnboardingTheme.errorRed,
    ),
    _SymptomOption(
      name: 'Fever',
      icon: Icons.thermostat,
      severity: 'High',
      color: OnboardingTheme.errorRed,
    ),
    _SymptomOption(
      name: 'Joint Pain',
      icon: Icons.accessibility_new,
      severity: 'Low',
      color: OnboardingTheme.lightIndigo,
    ),
    _SymptomOption(
      name: 'Constipation',
      icon: Icons.block,
      severity: 'Medium',
      color: OnboardingTheme.warningAmber,
    ),
    _SymptomOption(
      name: 'Blood in Stool',
      icon: Icons.warning_amber,
      severity: 'High',
      color: OnboardingTheme.errorRed,
    ),
  ];

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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      Text(
                        'Current Symptoms',
                        style: OnboardingTheme.neonTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Select symptoms you\'re currently experiencing',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Symptoms grid
                      ..._symptoms.map((symptom) {
                        final isSelected = widget.controller.data.currentSymptoms.contains(symptom.name);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                widget.controller.toggleSymptom(symptom.name);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? symptom.color
                                      : OnboardingTheme.accentIndigo.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: symptom.color.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? symptom.color.withOpacity(0.2)
                                          : OnboardingTheme.accentIndigo.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      symptom.icon,
                                      color: isSelected ? symptom.color : Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          symptom.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${symptom.severity} severity',
                                          style: OnboardingTheme.bodyStyle.copyWith(
                                            fontSize: 13,
                                            color: symptom.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: symptom.color,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // Selected symptoms summary
                      if (widget.controller.data.currentSymptoms.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: OnboardingTheme.cardDecoration(withGlow: true),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.checklist,
                                    color: OnboardingTheme.healthGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${widget.controller.data.currentSymptoms.length} symptoms selected',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'We\'ll help you track and understand these symptoms',
                                style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: OnboardingTheme.healthGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: OnboardingTheme.healthGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.celebration,
                                color: OnboardingTheme.healthGreen,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Great! No current symptoms means you\'re doing well. We\'ll help you stay that way!',
                                  style: OnboardingTheme.bodyStyle.copyWith(
                                    color: OnboardingTheme.healthGreen,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}

class _SymptomOption {
  final String name;
  final IconData icon;
  final String severity;
  final Color color;
  
  _SymptomOption({
    required this.name,
    required this.icon,
    required this.severity,
    required this.color,
  });
}
