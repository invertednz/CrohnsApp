import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';
import '../widgets/staggered_animation.dart';

class SymptomItem {
  final String name;
  final String description;
  final IconData icon;

  const SymptomItem({
    required this.name,
    required this.description,
    required this.icon,
  });
}

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
  final TextEditingController _customController = TextEditingController();

  final List<SymptomItem> _commonSymptoms = const [
    SymptomItem(
      name: 'Abdominal Pain',
      description: 'Stomach cramps or discomfort',
      icon: Icons.emergency_outlined,
    ),
    SymptomItem(
      name: 'Diarrhea',
      description: 'Frequent loose or watery stools',
      icon: Icons.water_drop_outlined,
    ),
    SymptomItem(
      name: 'Bloating',
      description: 'Feeling of fullness or swelling',
      icon: Icons.air,
    ),
    SymptomItem(
      name: 'Gas',
      description: 'Excessive flatulence',
      icon: Icons.cloud_outlined,
    ),
    SymptomItem(
      name: 'Fatigue',
      description: 'Tiredness and low energy',
      icon: Icons.battery_0_bar,
    ),
    SymptomItem(
      name: 'Nausea',
      description: 'Feeling sick or queasy',
      icon: Icons.sick_outlined,
    ),
    SymptomItem(
      name: 'Loss of Appetite',
      description: 'Reduced desire to eat',
      icon: Icons.no_meals_outlined,
    ),
    SymptomItem(
      name: 'Weight Loss',
      description: 'Unintentional weight reduction',
      icon: Icons.trending_down,
    ),
    SymptomItem(
      name: 'Fever',
      description: 'Elevated body temperature',
      icon: Icons.thermostat,
    ),
    SymptomItem(
      name: 'Joint Pain',
      description: 'Aching or stiff joints',
      icon: Icons.accessibility_new,
    ),
    SymptomItem(
      name: 'Constipation',
      description: 'Difficulty passing stools',
      icon: Icons.block,
    ),
    SymptomItem(
      name: 'Blood in Stool',
      description: 'Rectal bleeding (consult doctor)',
      icon: Icons.warning_amber,
    ),
  ];

  // Get custom symptoms (not in predefined list)
  List<SymptomEntry> get _customSymptoms {
    return widget.controller.data.currentSymptoms
        .where((s) => s.isCustom || !_commonSymptoms.any((item) => item.name == s.name))
        .toList();
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Mild':
        return OnboardingTheme.healthGreen;
      case 'Moderate':
        return OnboardingTheme.warningAmber;
      case 'Severe':
        return OnboardingTheme.errorRed;
      default:
        return OnboardingTheme.warningAmber;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Widget _buildSymptomCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isCustom = false,
    VoidCallback? onDelete,
    SymptomEntry? entry,
  }) {
    final severityColor = entry != null ? _getSeverityColor(entry.severity) : OnboardingTheme.accentIndigo;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? severityColor
                : OnboardingTheme.accentIndigo.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? severityColor.withOpacity(0.3)
                        : OnboardingTheme.accentIndigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? severityColor : OnboardingTheme.lightIndigo,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button for custom or checkmark
                if (isCustom && onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  )
                else if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
            // Severity toggles when selected
            if (isSelected && entry != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 64), // Align with text
                  Text(
                    'Severity:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  _SeverityChip(
                    label: 'Mild',
                    isSelected: entry.severity == 'Mild',
                    color: OnboardingTheme.healthGreen,
                    onTap: () {
                      setState(() {
                        widget.controller.updateSymptomSeverity(title, 'Mild');
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _SeverityChip(
                    label: 'Moderate',
                    isSelected: entry.severity == 'Moderate',
                    color: OnboardingTheme.warningAmber,
                    onTap: () {
                      setState(() {
                        widget.controller.updateSymptomSeverity(title, 'Moderate');
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _SeverityChip(
                    label: 'Severe',
                    isSelected: entry.severity == 'Severe',
                    color: OnboardingTheme.errorRed,
                    onTap: () {
                      setState(() {
                        widget.controller.updateSymptomSeverity(title, 'Severe');
                      });
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
                        'Current Symptoms',
                        style: OnboardingTheme.headingTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Select symptoms you\'re currently experiencing',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Add Custom Item section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: OnboardingTheme.accentIndigo.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_circle_outline,
                                color: OnboardingTheme.lightIndigo,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _customController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Add custom symptom',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    setState(() {
                                      widget.controller.addSymptom(SymptomEntry(
                                        name: value.trim(),
                                        severity: 'Moderate',
                                        isCustom: true,
                                      ));
                                      _customController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_customController.text.trim().isNotEmpty) {
                                  setState(() {
                                    widget.controller.addSymptom(SymptomEntry(
                                      name: _customController.text.trim(),
                                      severity: 'Moderate',
                                      isCustom: true,
                                    ));
                                    _customController.clear();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.accentIndigo,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Custom symptoms section
                      if (_customSymptoms.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Your Custom Symptoms',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_customSymptoms.length, (index) {
                          final symptom = _customSymptoms[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StaggeredAnimation(
                              index: index,
                              child: _buildSymptomCard(
                                title: symptom.name,
                                description: 'Custom symptom',
                                icon: Icons.health_and_safety_outlined,
                                isSelected: true,
                                isCustom: true,
                                entry: symptom,
                                onTap: () {},
                                onDelete: () {
                                  setState(() {
                                    widget.controller.removeSymptom(symptom.name);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Common Symptoms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Common symptoms as cards
                      ...List.generate(_commonSymptoms.length, (index) {
                        final item = _commonSymptoms[index];
                        final isSelected = widget.controller.hasSymptom(item.name);
                        final entry = widget.controller.getSymptom(item.name);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StaggeredAnimation(
                            index: index,
                            child: _buildSymptomCard(
                              title: item.name,
                              description: item.description,
                              icon: item.icon,
                              isSelected: isSelected,
                              entry: entry,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    widget.controller.removeSymptom(item.name);
                                  } else {
                                    widget.controller.addSymptom(SymptomEntry(
                                      name: item.name,
                                      severity: 'Moderate',
                                      isCustom: false,
                                    ));
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 16),
                      
                      // Info box
                      if (widget.controller.data.currentSymptoms.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OnboardingTheme.healthGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: OnboardingTheme.healthGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.celebration,
                                color: OnboardingTheme.healthGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No symptoms? Great! We\'ll help you stay healthy.',
                                  style: OnboardingTheme.bodyStyle.copyWith(
                                    fontSize: 14,
                                    color: OnboardingTheme.healthGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: OnboardingTheme.accentIndigo.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: OnboardingTheme.lightIndigo,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Set severity levels to help us understand your condition better',
                                  style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
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

class _SeverityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  
  const _SeverityChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
