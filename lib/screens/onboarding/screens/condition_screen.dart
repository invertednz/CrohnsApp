import 'package:flutter/material.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';
import '../onboarding_theme.dart';
import '../widgets/staggered_animation.dart';

class ConditionScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ConditionScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ConditionScreen> createState() => _ConditionScreenState();
}

class _ConditionScreenState extends State<ConditionScreen> {
  final Set<GutCondition> _selectedConditions = {};

  @override
  void initState() {
    super.initState();
    // Load any previously selected conditions
    _selectedConditions.addAll(widget.controller.data.conditions);
    if (widget.controller.data.condition != null) {
      _selectedConditions.add(widget.controller.data.condition!);
    }
  }

  void _toggleCondition(GutCondition condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
    });
  }

  void _handleNext() {
    // Save selected conditions
    widget.controller.data.conditions = _selectedConditions.toList();
    if (_selectedConditions.isNotEmpty) {
      widget.controller.data.condition = _selectedConditions.first;
    }
    widget.onNext();
  }

  IconData _getConditionIcon(GutCondition condition) {
    switch (condition) {
      case GutCondition.crohns:
        return Icons.local_fire_department_outlined;
      case GutCondition.ulcerativeColitis:
        return Icons.healing_outlined;
      case GutCondition.ibs:
        return Icons.waves_outlined;
      case GutCondition.ibd:
        return Icons.medical_services_outlined;
      case GutCondition.celiac:
        return Icons.no_food_outlined;
      case GutCondition.gerd:
        return Icons.whatshot_outlined;
      case GutCondition.other:
        return Icons.more_horiz_outlined;
      case GutCondition.notSure:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Step 1 of 15',
                        style: OnboardingTheme.bodyStyle.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'What condition(s)\nare you managing?',
                    style: OnboardingTheme.headingTextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select all that apply. This helps us personalize your experience.',
                    style: OnboardingTheme.bodyStyle,
                  ),
                ],
              ),
            ),
            // Condition options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: GutCondition.values.asMap().entries.map((entry) {
                    final index = entry.key;
                    final condition = entry.value;
                    final isSelected = _selectedConditions.contains(condition);

                    return StaggeredAnimation(
                      index: index,
                      child: GestureDetector(
                        onTap: () => _toggleCondition(condition),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? OnboardingTheme.healthGreen.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getConditionIcon(condition),
                                  color: isSelected
                                      ? OnboardingTheme.healthGreen
                                      : Colors.white70,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      condition.displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      condition.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? OnboardingTheme.healthGreen
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? OnboardingTheme.healthGreen
                                        : Colors.white54,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedConditions.isNotEmpty ? _handleNext : null,
                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  child: Text(
                    _selectedConditions.isEmpty
                        ? 'Select at least one condition'
                        : 'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedConditions.isEmpty
                          ? Colors.white54
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
