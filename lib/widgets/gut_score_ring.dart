import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gut_md/core/theme/app_theme.dart';

/// Animated 0-100 wellbeing ring with trend, computed from tracked data
/// (the same score the Insights screen shows). [score] is null until there
/// is enough logged feeling data.
class GutScoreRing extends StatelessWidget {
  final int? score;
  final String trend; // improving | stable | worsening | unknown
  final int daysTracked;
  final VoidCallback? onTap;

  const GutScoreRing({
    Key? key,
    required this.score,
    required this.trend,
    required this.daysTracked,
    this.onTap,
  }) : super(key: key);

  Color get _color {
    final s = score;
    if (s == null) return AppTheme.lightIndigo;
    if (s >= 70) return AppTheme.healthGreen;
    if (s >= 45) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }

  String get _trendLabel {
    switch (trend) {
      case 'improving':
        return 'Improving';
      case 'worsening':
        return 'Needs care';
      case 'stable':
        return 'Steady';
      default:
        return 'Building your baseline';
    }
  }

  IconData get _trendIcon {
    switch (trend) {
      case 'improving':
        return Icons.trending_up;
      case 'worsening':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = score;
    final hasData = s != null;
    return Semantics(
      button: onTap != null,
      label: hasData
          ? 'Wellbeing score $s out of 100, $_trendLabel. See AI insights'
          : 'Wellbeing score not ready yet. Check in to unlock it. See AI insights',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: hasData ? s / 100 : 0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _RingPainter(value: value, color: _color),
                    child: Center(
                      child: Text(
                        hasData ? '${(value * 100).round()}' : '--',
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wellbeing score',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    if (hasData)
                      Row(
                        children: [
                          Icon(_trendIcon, size: 18, color: _color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _trendLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _color, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        daysTracked == 0 ? 'Check in to unlock your score' : 'Rate how you feel to see it',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'See AI insights',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppTheme.lightIndigo.withOpacity(0.95), fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.lightIndigo, size: 20),
                      ],
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

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;

  _RingPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final track = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    final inset = rect.deflate(stroke / 2);
    canvas.drawArc(inset, 0, 2 * math.pi, false, track);
    canvas.drawArc(inset, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}
