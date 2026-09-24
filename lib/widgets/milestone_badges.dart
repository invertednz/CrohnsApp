import 'package:flutter/material.dart';

import 'package:gut_md/core/theme/app_theme.dart';

/// A milestone the user can unlock through consistent tracking.
class Milestone {
  final String emoji;
  final String title;
  final bool unlocked;
  const Milestone(this.emoji, this.title, this.unlocked);
}

/// Builds the milestone list from real tracking stats.
List<Milestone> milestonesFor({
  required int streak,
  required int daysTracked,
  required int logEntries,
}) {
  return [
    Milestone('🌱', 'First check-in', daysTracked >= 1),
    Milestone('🔥', '3-day streak', streak >= 3),
    Milestone('📝', 'First diary entry', logEntries >= 1),
    Milestone('⭐', '7-day streak', streak >= 7),
    Milestone('🧭', '14 days tracked', daysTracked >= 14),
    Milestone('🏆', '30-day streak', streak >= 30),
  ];
}

/// Horizontal row of milestone badges; locked ones are dimmed.
class MilestoneBadges extends StatelessWidget {
  final List<Milestone> milestones;

  const MilestoneBadges({Key? key, required this.milestones}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unlocked = milestones.where((m) => m.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$unlocked of ${milestones.length} milestones unlocked',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: milestones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final m = milestones[i];
              return Semantics(
                label: '${m.title}, ${m.unlocked ? 'unlocked' : 'locked'}',
                excludeSemantics: true,
                child: Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: m.unlocked ? AppTheme.accentIndigo.withOpacity(0.35) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: m.unlocked ? AppTheme.lightIndigo : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: m.unlocked ? 1 : 0.3,
                        child: Text(m.emoji, style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: Colors.white.withOpacity(m.unlocked ? 1 : 0.45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
