import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../onboarding_theme.dart';

/// A small commitment moment: press and hold to commit to 14 days of
/// check-ins. Screen-reader users can activate it with a normal tap action.
class CommitmentScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CommitmentScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<CommitmentScreen> createState() => _CommitmentScreenState();
}

class _CommitmentScreenState extends State<CommitmentScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _hold;
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _commit();
      });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    if (_committed) return;
    HapticFeedback.mediumImpact();
    setState(() => _committed = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onNext();
  }

  void _release() {
    if (!_committed) _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: OnboardingTheme.primaryGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Make a promise to yourself',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'I\'ll check in for 14 days so I can finally see what my gut is telling me.',
                textAlign: TextAlign.center,
                style: OnboardingTheme.subheadingStyle,
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: _committed ? 'Committed' : 'Hold to commit',
                onTap: _commit,
                excludeSemantics: true,
                child: GestureDetector(
                  onTapDown: (_) => _hold.forward(),
                  onTapUp: (_) => _release(),
                  onTapCancel: _release,
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: _committed ? 1 : _hold.value,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.12),
                            valueColor: const AlwaysStoppedAnimation(OnboardingTheme.healthGreen),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 140 + 10 * _hold.value,
                          height: 140 + 10 * _hold.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _committed ? null : OnboardingTheme.accentGradient,
                            color: _committed ? OnboardingTheme.healthGreen : null,
                          ),
                          child: Icon(
                            _committed ? Icons.check_rounded : Icons.fingerprint,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _committed ? 'Committed! Let\'s do this.' : 'Press and hold to commit',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
