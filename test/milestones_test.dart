import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/widgets/milestone_badges.dart';

void main() {
  test('nothing is unlocked for a brand-new user', () {
    final milestones = milestonesFor(streak: 0, daysTracked: 0, logEntries: 0);
    expect(milestones.where((m) => m.unlocked), isEmpty);
  });

  test('milestones unlock from real streak, days tracked and diary entries', () {
    final milestones = milestonesFor(streak: 7, daysTracked: 9, logEntries: 2);
    final unlocked = milestones.where((m) => m.unlocked).map((m) => m.title).toList();
    expect(unlocked, ['First check-in', '3-day streak', 'First diary entry', '7-day streak']);
    expect(milestones.firstWhere((m) => m.title == '14 days tracked').unlocked, isFalse);
  });
}
