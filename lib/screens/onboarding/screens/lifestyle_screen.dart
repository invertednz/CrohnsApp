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

  static const List<_LifestyleFactor> _factors = [
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
      icon: Icons.smoking_rooms_outlined,
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

  bool get _canAddCustom => _customController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  /// Adds the typed factor. A case-insensitive match of a listed factor
  /// selects that card, and an existing entry is not duplicated.
  void _addCustomFactor() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    final lower = value.toLowerCase();
    final alreadyAdded =
        widget.controller.data.lifestyle.any((item) => item.toLowerCase() == lower);
    String name = value;
    for (final factor in _factors) {
      if (factor.name.toLowerCase() == lower) {
        name = factor.name;
        break;
      }
    }
    setState(() {
      if (!alreadyAdded) {
        widget.controller.addLifestyle(name);
      }
      _customController.clear();
    });
  }

  Widget _buildFactorCard(_LifestyleFactor factor, bool isSelected) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Semantics(
          container: true,
          checked: isSelected,
          child: InkWell(
            onTap: () {
              setState(() {
                widget.controller.toggleLifestyle(factor.name);
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isSelected ? OnboardingTheme.accentGradient : null,
                      color: isSelected
                          ? null
                          : OnboardingTheme.accentIndigo.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _buildSelectedChip(String factor) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 2, top: 2, bottom: 2),
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
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'Remove $factor',
              onPressed: () {
                setState(() {
                  widget.controller.removeLifestyle(factor);
                });
              },
              icon: const Icon(Icons.close, color: Colors.white),
              iconSize: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.controller.data.lifestyle;
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

                        const Text(
                          'Select factors that may affect your symptoms',
                          style: OnboardingTheme.subheadingStyle,
                        ),

                        const SizedBox(height: 32),

                        // Lifestyle factors
                        ..._factors.asMap().entries.map((entry) {
                          final factor = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: StaggeredAnimation(
                              index: entry.key,
                              child: _buildFactorCard(factor, selected.contains(factor.name)),
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
                                      textInputAction: TextInputAction.done,
                                      decoration: OnboardingTheme.inputDecoration(
                                        label: 'Lifestyle factor',
                                        hint: 'e.g., Travel',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      onSubmitted: (_) => _addCustomFactor(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: _canAddCustom ? _addCustomFactor : null,
                                    style: OnboardingTheme.primaryButtonStyle().copyWith(
                                      padding: const WidgetStatePropertyAll(
                                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      backgroundColor: WidgetStateProperty.resolveWith(
                                        (states) => states.contains(WidgetState.disabled)
                                            ? OnboardingTheme.accentIndigo.withValues(alpha: 0.3)
                                            : OnboardingTheme.accentIndigo,
                                      ),
                                      foregroundColor: WidgetStateProperty.resolveWith(
                                        (states) => states.contains(WidgetState.disabled)
                                            ? Colors.white.withValues(alpha: 0.5)
                                            : Colors.white,
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
                        if (selected.isNotEmpty) ...[
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
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: OnboardingTheme.cardDecoration(),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: selected.map(_buildSelectedChip).toList(),
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

class _LifestyleFactor {
  final String name;
  final IconData icon;
  final String description;

  const _LifestyleFactor({
    required this.name,
    required this.icon,
    required this.description,
  });
}
