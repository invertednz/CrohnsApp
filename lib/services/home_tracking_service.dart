import 'package:intl/intl.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/services/daily_log_service.dart';

/// Loads and saves the Home dashboard's data through the tracking backend:
///
/// * `daily` entries keyed by date: `feeling` (0 = Terrible .. 4 = Great),
///   `bowel_movements`, `supplements_followed`, `medications_followed`,
///   `diet_followed`. Saving merges, so the Daily Tracking screen's fields
///   (pain, energy, notes) on the same day are kept.
/// * `log` entries keyed by date: `{date, entries: [DailyLogEntry...]}`.
class HomeTrackingService {
  final UnifiedTrackingService tracking;
  final String userId;

  const HomeTrackingService({required this.tracking, required this.userId});

  /// Number of days of history loaded for the streak and summary stats.
  static const int historyDays = 120;

  static String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<Map<String, dynamic>?> loadDaily(String date) =>
      tracking.getTrackingData(userId: userId, date: date, type: 'daily');

  Future<void> saveDaily(String date, Map<String, dynamic> fields) => tracking.trackEvent(
        userId: userId,
        type: 'daily',
        data: {...fields, 'date': date},
      );

  /// Recent `daily` entries by date.
  Future<Map<String, Map<String, dynamic>>> dailyHistory({int limit = historyDays}) async {
    final entries = await tracking.getTrackingHistory(userId: userId, type: 'daily', limit: limit);
    return {
      for (final entry in entries)
        if (entry['date'] is String) entry['date'] as String: entry,
    };
  }

  Future<List<DailyLogEntry>> loadLogs(String date) async {
    final day = await tracking.getTrackingData(userId: userId, date: date, type: 'log');
    return _entries(day);
  }

  /// Recent log entries by date.
  Future<Map<String, List<DailyLogEntry>>> logHistory({int limit = historyDays}) async {
    final days = await tracking.getTrackingHistory(userId: userId, type: 'log', limit: limit);
    return {
      for (final day in days)
        if (day['date'] is String) day['date'] as String: _entries(day),
    };
  }

  /// Appends [entry] to the day's log and returns the saved list. Re-reads
  /// the day first so entries saved elsewhere are never overwritten.
  Future<List<DailyLogEntry>> addLog(String date, DailyLogEntry entry) async {
    final current = await loadLogs(date);
    final updated = sortEntries([...current.where((e) => e.id != entry.id), entry]);
    await tracking.trackEvent(
      userId: userId,
      type: 'log',
      data: {
        'date': date,
        'entries': updated.map((e) => e.toJson()).toList(),
      },
    );
    return updated;
  }

  static List<DailyLogEntry> sortEntries(List<DailyLogEntry> entries) {
    final sorted = List.of(entries);
    sorted.sort((a, b) {
      final byTime = a.time.compareTo(b.time);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return sorted;
  }

  static List<DailyLogEntry> _entries(Map<String, dynamic>? day) {
    final raw = day?['entries'];
    if (raw is! List) return const [];
    return sortEntries([
      for (final item in raw)
        if (item is Map) DailyLogEntry.fromJson(Map<String, dynamic>.from(item)),
    ]);
  }
}

/// Stats on the Home dashboard, computed only from what the user tracked.
class HomeSummary {
  /// Days counted for "days tracked", average feeling and adherence.
  static const int windowDays = 30;

  /// Consecutive tracked days ending today (or yesterday, so a streak is not
  /// lost before today has been logged).
  final int streak;

  /// True when the streak reaches the end of the loaded history, so the real
  /// streak may be longer.
  final bool streakCapped;
  final int daysTracked;

  /// Mean feeling (0 = Terrible .. 4 = Great) over the window, or null.
  final double? averageFeeling;
  final int supplementsDays;
  final int medicationsDays;
  final int dietDays;

  const HomeSummary({
    required this.streak,
    required this.streakCapped,
    required this.daysTracked,
    required this.averageFeeling,
    required this.supplementsDays,
    required this.medicationsDays,
    required this.dietDays,
  });

  bool get hasAnyData => daysTracked > 0 || streak > 0;

  /// Whether a `daily` entry holds anything the user actually recorded.
  static bool hasDailyData(Map<String, dynamic>? entry) {
    if (entry == null) return false;
    final bowel = entry['bowel_movements'];
    final notes = entry['notes'];
    return entry['feeling'] is num ||
        (bowel is num && bowel > 0) ||
        entry['supplements_followed'] is bool ||
        entry['medications_followed'] is bool ||
        entry['diet_followed'] is bool ||
        entry['pain_level'] is num ||
        entry['energy_level'] is num ||
        (notes is String && notes.trim().isNotEmpty);
  }

  factory HomeSummary.compute({
    required Map<String, Map<String, dynamic>> daily,
    required Map<String, List<DailyLogEntry>> logs,
    required DateTime today,
    int maxStreakDays = HomeTrackingService.historyDays,
  }) {
    bool tracked(String key) =>
        hasDailyData(daily[key]) || (logs[key]?.isNotEmpty ?? false);
    String keyFor(int daysAgo) =>
        HomeTrackingService.dateKey(DateTime(today.year, today.month, today.day - daysAgo));

    final start = tracked(keyFor(0)) ? 0 : 1;
    var streak = 0;
    while (streak < maxStreakDays && tracked(keyFor(start + streak))) {
      streak++;
    }

    var daysTracked = 0;
    var supplements = 0;
    var medications = 0;
    var diet = 0;
    final feelings = <num>[];
    for (var i = 0; i < windowDays; i++) {
      final key = keyFor(i);
      if (tracked(key)) daysTracked++;
      final entry = daily[key];
      if (entry == null) continue;
      final feeling = entry['feeling'];
      if (feeling is num && feeling >= 0 && feeling <= 4) feelings.add(feeling);
      if (entry['supplements_followed'] == true) supplements++;
      if (entry['medications_followed'] == true) medications++;
      if (entry['diet_followed'] == true) diet++;
    }

    return HomeSummary(
      streak: streak,
      streakCapped: streak >= maxStreakDays,
      daysTracked: daysTracked,
      averageFeeling: feelings.isEmpty
          ? null
          : feelings.reduce((a, b) => a + b) / feelings.length,
      supplementsDays: supplements,
      medicationsDays: medications,
      dietDays: diet,
    );
  }
}
