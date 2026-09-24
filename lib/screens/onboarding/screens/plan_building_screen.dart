import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gut_md/services/gut_plan_service.dart';
import '../onboarding_controller.dart';
import '../onboarding_theme.dart';

/// "Building your plan" moment between the quiz and the plan reveal.
///
/// Generates the plan (Gemini, or on-device offline) while a progress ring
/// and checklist animate, so the result feels earned.
class PlanBuildingScreen extends StatefulWidget {
  final OnboardingController controller;
  final ValueChanged<GutPlan> onComplete;

  const PlanBuildingScreen({
    Key? key,
    required this.controller,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<PlanBuildingScreen> createState() => _PlanBuildingScreenState();
}

class _PlanBuildingScreenState extends State<PlanBuildingScreen>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    'Reviewing your conditions',
    'Mapping symptoms to track',
    'Choosing your first food experiment',
    'Setting your daily routine',
  ];

  late final AnimationController _progress;
  GutPlan? _plan;
  bool _animationDone = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationDone = true;
          _finishIfReady();
        }
      })
      ..forward();
    unawaited(_generate());
  }

  Future<void> _generate() async {
    final plan = await GutPlanService.generate(widget.controller.data);
    if (!mounted) return;
    _plan = plan;
    _finishIfReady();
  }

  void _finishIfReady() {
    final plan = _plan;
    if (_animationDone && plan != null && mounted) {
      widget.onComplete(plan);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _progress.value;
    // Hold at 99% until the plan itself is ready.
    final percent = (_plan == null ? (value * 100).clamp(0, 99) : value * 100).round();
    final completedSteps = (value * _steps.length).floor();

    return Container(
      decoration: const BoxDecoration(gradient: OnboardingTheme.primaryGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(OnboardingTheme.healthGreen),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Semantics(
                      label: 'Building your plan, $percent percent',
                      excludeSemantics: true,
                      child: Text(
                        '$percent%',
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Building your personal plan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < _steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: i < completedSteps
                            ? const Icon(Icons.check_circle, key: ValueKey('done'), color: OnboardingTheme.healthGreen)
                            : Icon(Icons.radio_button_unchecked, key: const ValueKey('todo'), color: Colors.white.withOpacity(0.3)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _steps[i],
                          style: TextStyle(
                            fontSize: 16,
                            color: i < completedSteps ? Colors.white : Colors.white.withOpacity(0.55),
                            fontWeight: i < completedSteps ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: OnboardingTheme.cardDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: OnboardingTheme.warningAmber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keeping a food and symptom diary is one of the most common first steps '
                        'gastroenterologists and dietitians suggest for finding personal triggers.',
                        style: OnboardingTheme.bodyStyle.copyWith(fontSize: 13),
                      ),
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
