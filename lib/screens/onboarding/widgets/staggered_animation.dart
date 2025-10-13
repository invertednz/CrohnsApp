import 'package:flutter/material.dart';

/// A widget that applies a staggered fade + slide-up animation to its child.
/// 
/// Used for animating lists of cards, features, or options with a sequential reveal effect.
class StaggeredAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final int staggerDelayMs;
  final int durationMs;
  
  const StaggeredAnimation({
    Key? key,
    required this.child,
    required this.index,
    this.staggerDelayMs = 100,
    this.durationMs = 600,
  }) : super(key: key);

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMs),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), // Slide up from 10% below
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Start animation after stagger delay
    Future.delayed(
      Duration(milliseconds: widget.index * widget.staggerDelayMs),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
