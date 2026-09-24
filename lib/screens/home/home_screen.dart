import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/screens/auth/sign_in_screen.dart';
import 'package:gut_md/screens/auth/sign_up_screen.dart';
import 'package:gut_md/screens/chat/chat_screen.dart';
import 'package:gut_md/screens/diet/diet_screen.dart';
import 'package:gut_md/screens/insights/insights_screen.dart';
import 'package:gut_md/screens/medications/medications_screen.dart';
import 'package:gut_md/screens/supplements/supplements_screen.dart';
import 'package:gut_md/screens/symptoms/symptoms_screen.dart';
import 'package:gut_md/screens/tracking/tracking_screen.dart';
import 'package:gut_md/services/daily_log_service.dart';
import 'package:gut_md/services/gut_plan_service.dart';
import 'package:gut_md/services/home_tracking_service.dart';
import 'package:gut_md/services/insights_generator.dart';
import 'package:gut_md/services/meal_analysis_service.dart';
import 'package:gut_md/widgets/calendar_bar.dart';
import 'package:gut_md/widgets/gut_score_ring.dart';
import 'package:gut_md/widgets/milestone_badges.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      // IndexedStack keeps every tab mounted, so switching tabs never throws
      // away what the user was doing on another tab.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeContent(onNavigateToTab: _navigateToTab),
          const SymptomsScreen(),
          const SupplementsScreenMain(),
          const MedicationsScreenMain(),
          const ChatScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            activeIcon: Icon(Icons.warning_amber),
            label: 'Symptoms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'Supps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Meds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

/// The Home dashboard. Everything shown here is loaded from and saved to the
/// tracking backend (see [HomeTrackingService]) for the date selected in the
/// shared [AppState].
class HomeContent extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const HomeContent({Key? key, this.onNavigateToTab}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _appState = AppState();
  final TextEditingController _logController = TextEditingController();
  final FocusNode _logFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  /// `daily` entries and log entries by date (yyyy-MM-dd).
  final Map<String, Map<String, dynamic>> _dailyByDate = {};
  final Map<String, List<DailyLogEntry>> _logsByDate = {};

  /// Bumped for a date whenever the user changes it locally, so a load that
  /// started earlier never overwrites the newer local state.
  final Map<String, int> _editVersion = {};

  late String _shownDateKey;
  int _dayRequest = 0;
  bool _loadingDay = false;
  bool _isLogging = false;
  bool _signingOut = false;
  int _logFieldVersion = 0;

  static const List<Map<String, dynamic>> _feelings = [
    {'emoji': '😫', 'label': 'Terrible', 'color': Colors.red},
    {'emoji': '😔', 'label': 'Bad', 'color': Colors.orange},
    {'emoji': '😐', 'label': 'Okay', 'color': Colors.amber},
    {'emoji': '🙂', 'label': 'Good', 'color': Colors.lightGreen},
    {'emoji': '😄', 'label': 'Great', 'color': Colors.green},
  ];

  DateTime get _selectedDate => _appState.selectedDate;
  String get _dateKey => HomeTrackingService.dateKey(_selectedDate);

  HomeTrackingService get _service {
    final backend = BackendServiceProvider.instance;
    return HomeTrackingService(
      tracking: backend.tracking,
      userId: backend.auth.currentUser?.id ?? '',
    );
  }

  Map<String, dynamic>? get _day => _dailyByDate[_dateKey];

  int? get _selectedFeeling {
    final value = _day?['feeling'];
    return value is num ? value.round() : null;
  }

  int get _bowelMovements {
    final value = _day?['bowel_movements'];
    return value is num ? value.round() : 0;
  }

  bool? _followed(String field) {
    final value = _day?[field];
    return value is bool ? value : null;
  }

  List<DailyLogEntry> get _dayLogs => _logsByDate[_dateKey] ?? const [];

  @override
  void initState() {
    super.initState();
    _shownDateKey = _dateKey;
    _appState.addListener(_onAppStateChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _logController.dispose();
    _logFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasUser =>
      !_signingOut && BackendServiceProvider.instance.auth.currentUser != null;

  /// The selected date is shared with the other tabs: reload when it changes.
  void _onAppStateChanged() {
    if (!mounted) return;
    if (_dateKey == _shownDateKey) {
      // Onboarding answers (e.g. the personal plan) may have been restored.
      setState(() {});
      return;
    }
    setState(() => _shownDateKey = _dateKey);
    if (_hasUser) _loadDay();
  }

  void _bumpVersion(String key) => _editVersion[key] = (_editVersion[key] ?? 0) + 1;

  /// Loads recent history (for the streak and stats), then the selected day.
  Future<void> _loadHistory() async {
    if (!_hasUser) return;
    final versions = Map<String, int>.from(_editVersion);
    bool unchanged(String key) => (_editVersion[key] ?? 0) == (versions[key] ?? 0);
    try {
      final service = _service;
      final results = await Future.wait<Object>([
        service.dailyHistory(),
        service.logHistory(),
      ]);
      if (!mounted) return;
      final daily = results[0] as Map<String, Map<String, dynamic>>;
      final logs = results[1] as Map<String, List<DailyLogEntry>>;
      setState(() {
        daily.forEach((key, entry) {
          if (unchanged(key)) _dailyByDate[key] = entry;
        });
        logs.forEach((key, entries) {
          if (unchanged(key)) _logsByDate[key] = entries;
        });
      });
    } catch (e) {
      debugPrint('HomeContent: failed to load tracking history: $e');
      _showMessage("Couldn't load your tracking history. Check your connection and try again.");
    }
    await _loadDay();
  }

  /// Loads the selected day's `daily` entry and log entries.
  Future<void> _loadDay() async {
    if (!mounted || !_hasUser) return;
    final key = _dateKey;
    final request = ++_dayRequest;
    final version = _editVersion[key] ?? 0;
    setState(() => _loadingDay = true);
    try {
      final service = _service;
      final results = await Future.wait<Object?>([
        service.loadDaily(key),
        service.loadLogs(key),
      ]);
      if (!mounted) return;
      // Results are keyed by date, so a slow response for another day is
      // still valid; only skip it if the user changed that day meanwhile.
      if ((_editVersion[key] ?? 0) == version) {
        setState(() {
          final daily = results[0] as Map<String, dynamic>?;
          if (daily == null) {
            _dailyByDate.remove(key);
          } else {
            _dailyByDate[key] = daily;
          }
          _logsByDate[key] = results[1] as List<DailyLogEntry>;
        });
      }
    } catch (e) {
      debugPrint('HomeContent: failed to load $key: $e');
      if (request == _dayRequest) {
        _showMessage("Couldn't load this day's data. Check your connection and try again.");
      }
    } finally {
      if (mounted && request == _dayRequest) setState(() => _loadingDay = false);
    }
  }

  /// Saves [fields] into the selected day's `daily` entry (merged).
  Future<void> _updateDaily(Map<String, dynamic> fields) async {
    // Web: the check-in controls take no focus, so without this the log field
    // stays focused while its DOM <input> is blurred and later typing is lost.
    _logFocus.unfocus();
    final key = _dateKey;
    _bumpVersion(key);
    setState(() {
      _dailyByDate[key] = {...?_dailyByDate[key], ...fields, 'date': key};
    });
    try {
      await _service.saveDaily(key, fields);
    } catch (e) {
      debugPrint('HomeContent: failed to save $key: $e');
      _showMessage("Couldn't save that change. Check your connection and try again.");
      await _loadDay();
    }
  }

  Future<void> _setFeeling(int index) async {
    final isToday = _dateKey == HomeTrackingService.dateKey(DateTime.now());
    final firstCheckIn = _selectedFeeling == null;
    await _updateDaily({'feeling': index});
    if (!mounted || !isToday || !firstCheckIn) return;
    final streak = HomeSummary.compute(daily: _dailyByDate, logs: _logsByDate, today: DateTime.now()).streak;
    HapticFeedback.lightImpact();
    _showMessage(streak > 1
        ? 'Checked in for today. $streak-day streak, keep it going!'
        : 'Checked in for today. Come back tomorrow to start a streak!');
  }

  void _setFollowed(String field, bool value) => _updateDaily({field: value});

  void _showMessage(String message) {
    if (!mounted) return;
    // Float above the log input bar so the message never covers it.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final summary = HomeSummary.compute(
      daily: _dailyByDate,
      logs: _logsByDate,
      today: DateTime.now(),
    );
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(summary),

                    if (_isGuest) ...[
                      const SizedBox(height: 14),
                      _buildGuestBanner(),
                    ],

                    const SizedBox(height: 16),

                    CalendarBar(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        _logFocus.unfocus();
                        _appState.setSelectedDate(date);
                      },
                    ),

                    SizedBox(
                      height: 20,
                      child: _loadingDay
                          ? Center(
                              child: Semantics(
                                container: true,
                                label: 'Loading day data',
                                child: LinearProgressIndicator(
                                  minHeight: 2,
                                  color: AppTheme.lightIndigo,
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            )
                          : null,
                    ),

                    // How are you feeling section
                    _buildSectionTitle('How are you feeling?',
                        action: 'Add details',
                        onAction: () => _open(const TrackingScreen(), reloadHistory: true)),
                    const SizedBox(height: 10),
                    _buildFeelingSelector(),

                    const SizedBox(height: 20),

                    // Compact 2x2 grid for tracking
                    _buildCompactTrackingGrid(),

                    const SizedBox(height: 20),

                    // Stats from the user's tracked history
                    _buildSectionTitle('Your Health Insights',
                        action: 'AI insights', onAction: () => _open(const InsightsScreen())),
                    const SizedBox(height: 10),
                    _buildScoreRing(summary),
                    const SizedBox(height: 12),
                    _buildHealthInsights(summary),

                    if (_plan != null) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Your 14-day plan'),
                      const SizedBox(height: 10),
                      _buildPlanCard(_plan!, summary),
                    ],

                    const SizedBox(height: 20),
                    _buildSectionTitle('Milestones'),
                    const SizedBox(height: 10),
                    MilestoneBadges(
                      milestones: milestonesFor(
                        streak: summary.streak,
                        daysTracked: summary.daysTracked,
                        logEntries: _logsByDate.values.fold(0, (n, day) => n + day.length),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Daily Logs section
                    _buildSectionTitle('Daily Logs',
                        action: 'Meals & triggers', onAction: () => _open(const DietScreen())),
                    const SizedBox(height: 10),
                    _buildDailyLogs(),

                    const SizedBox(height: 100), // Space for bottom input
                  ],
                ),
              ),
            ),

            // Bottom input bar
            _buildBottomInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(HomeSummary summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GutMD',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _greeting(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            _buildStreakBadge(summary),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Sign out',
              onPressed: _showSignOutDialog,
              icon: const Icon(Icons.logout, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _dayCount(int days) => days == 1 ? '1 day' : '$days days';

  bool get _isGuest =>
      BackendServiceProvider.isInitialized &&
      BackendServiceProvider.instance.auth.currentUser?.isAnonymous == true;

  GutPlan? get _plan {
    final json = _appState.onboardingData?.plan;
    return json == null ? null : GutPlan.fromJson(json);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final part = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');
    final user = BackendServiceProvider.isInitialized ? BackendServiceProvider.instance.auth.currentUser : null;
    final name = user?.displayName?.trim().split(' ').first;
    return name == null || name.isEmpty ? part : '$part, $name';
  }

  Widget _buildGuestBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppTheme.warningAmber),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "You're using GutMD as a guest. Create a free account so you never lose your log.",
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            ),
            style: TextButton.styleFrom(foregroundColor: AppTheme.warningAmber),
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRing(HomeSummary summary) {
    final daily = _dailyByDate.values.toList()
      ..sort((a, b) => '${b['date']}'.compareTo('${a['date']}'));
    final health = InsightsGenerator.localInsights({'daily': daily})['health_summary'] as Map;
    final score = health['score'];
    return GutScoreRing(
      score: score is num ? score.round() : null,
      trend: '${health['trend'] ?? 'unknown'}',
      daysTracked: summary.daysTracked,
      onTap: () => _open(const InsightsScreen()),
    );
  }

  Widget _buildPlanCard(GutPlan plan, HomeSummary summary) {
    final done = summary.daysTracked.clamp(0, 14);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.headline,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$done/14 days',
                style: const TextStyle(color: AppTheme.healthGreen, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: '$done of 14 plan days checked in',
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: done / 14,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: AppTheme.healthGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.science_outlined, color: AppTheme.warningAmber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.firstExperiment,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _streakText(HomeSummary summary) =>
      '${summary.streak}${summary.streakCapped ? '+' : ''}';

  Widget _buildStreakBadge(HomeSummary summary) {
    return Semantics(
      container: true,
      label: 'Current streak: ${_streakText(summary)} ${summary.streak == 1 ? 'day' : 'days'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: AppTheme.healthGreen,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              _streakText(summary),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(Widget screen, {bool reloadHistory = false}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    // The opened screen may have changed this day's (or other days') data.
    if (reloadHistory) {
      await _loadHistory();
    } else {
      await _loadDay();
    }
  }

  Widget _buildSectionTitle(String title, {String? action, VoidCallback? onAction}) {
    final text = Semantics(
      headingLevel: 2,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
    if (action == null) return text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: text),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.lightIndigo,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(48, 36),
          ),
          child: Text(action),
        ),
      ],
    );
  }

  Widget _buildFeelingSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_feelings.length, (index) {
          final feeling = _feelings[index];
          final isSelected = _selectedFeeling == index;
          final color = feeling['color'] as Color;

          // One choice of a radio group: "Great, radio button, checked".
          return Expanded(
            child: Semantics(
            container: true,
            inMutuallyExclusiveGroup: true,
            checked: isSelected,
            label: feeling['label'] as String,
            onTap: () => _setFeeling(index),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setFeeling(index),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: color, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        feeling['emoji'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feeling['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompactTrackingGrid() {
    return Column(
      children: [
        // First row: Bowel Movements + Supplements
        Row(
          children: [
            Expanded(child: _buildCompactBowelCard()),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCompactGuideCard(
                  'Supplements', Icons.medication_outlined, 'supplements_followed', 2),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Second row: Medications + Diet
        Row(
          children: [
            Expanded(
              child: _buildCompactGuideCard(
                  'Medications', Icons.medical_services_outlined, 'medications_followed', 3),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCompactGuideCard('Diet', Icons.restaurant_outlined, 'diet_followed', -1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactBowelCard() {
    final count = _bowelMovements;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: Colors.white.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    'Bowel Motions',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                container: true,
                label: 'Bowel motions: $count',
                excludeSemantics: true,
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Row(
                children: [
                  _buildSmallCounterButton(
                    Icons.remove,
                    'Remove bowel motion',
                    count > 0 ? () => _updateDaily({'bowel_movements': count - 1}) : null,
                  ),
                  const SizedBox(width: 6),
                  _buildSmallCounterButton(
                    Icons.add,
                    'Add bowel motion',
                    () => _updateDaily({'bowel_movements': count + 1}),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCounterButton(IconData icon, String tooltip, VoidCallback? onPressed) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
        minimumSize: const Size(36, 36),
        fixedSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCompactGuideCard(String title, IconData icon, String field, int tabIndex) {
    final followed = _followed(field);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGuideChoice(
                  text: 'Had All',
                  semanticsLabel: '$title: Had All',
                  selected: followed == true,
                  color: AppTheme.healthGreen,
                  onTap: () => _setFollowed(field, true),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildGuideChoice(
                  text: 'Different',
                  semanticsLabel: '$title: Different',
                  selected: followed == false,
                  color: Colors.amber,
                  onTap: () {
                    _setFollowed(field, false);
                    // Open the matching tab so the user can log what changed.
                    if (tabIndex >= 0) widget.onNavigateToTab?.call(tabIndex);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideChoice({
    required String text,
    required String semanticsLabel,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? color : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthInsights(HomeSummary summary) {
    final avg = summary.averageFeeling;
    final avgLabel = avg == null ? null : _feelings[avg.round().clamp(0, 4)]['label'] as String;
    final avgValue = avg == null ? null : (avg + 1).toStringAsFixed(1);
    final avgColor = avg == null
        ? Colors.white60
        : avg >= 2.5
            ? AppTheme.healthGreen
            : avg >= 1.5
                ? Colors.amber
                : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInsightCard(
                icon: Icons.calendar_today,
                iconColor: AppTheme.lightIndigo,
                title: 'Days Tracked',
                value: '${summary.daysTracked}',
                subtitle: 'Last 30 days',
                semanticsLabel: 'Days tracked in the last 30 days: ${summary.daysTracked}',
              ),
              const SizedBox(width: 10),
              _buildInsightCard(
                icon: Icons.sentiment_satisfied,
                iconColor: avgColor,
                title: 'Avg Feeling',
                value: avgValue == null ? '–' : '$avgValue/5',
                subtitle: avgLabel ?? 'No data yet',
                semanticsLabel: avgValue == null
                    ? 'Average feeling: no entries in the last 30 days'
                    : 'Average feeling, last 30 days: $avgValue out of 5 ($avgLabel)',
              ),
              const SizedBox(width: 10),
              _buildInsightCard(
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                title: 'Streak',
                value: _streakText(summary),
                subtitle: summary.streak == 1 ? 'Day' : 'Days',
                semanticsLabel:
                    'Streak: ${_streakText(summary)} ${summary.streak == 1 ? 'day' : 'days'}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentIndigo.withValues(alpha: 0.2),
                  Colors.purple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentIndigo.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentIndigo.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tracking Summary',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary.hasAnyData
                            ? 'Last 30 days: had all supplements on '
                                '${_dayCount(summary.supplementsDays)}, all medications on '
                                '${_dayCount(summary.medicationsDays)}, and kept to your diet on '
                                '${_dayCount(summary.dietDays)}.'
                            : 'Start tracking today to see your patterns and insights!',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required String semanticsLabel,
  }) {
    return Expanded(
      child: Semantics(
        container: true,
        label: semanticsLabel,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyLogs() {
    final logs = _dayLogs;
    final children = <Widget>[
      ...logs.map(_buildLogItem),
      if (_isLogging)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
              const SizedBox(width: 10),
              Text(
                'Analysing your entry…',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
              ),
            ],
          ),
        ),
    ];

    if (children.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No logs for this day yet.\nUse the input below to add entries.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
        ),
      );
    }

    return Column(children: children);
  }

  String _formatTime(String hhmm) {
    final parts = hhmm.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null) return hhmm;
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
  }

  IconData _categoryIcon(DailyLogEntry log) {
    if (log.isPhoto) return Icons.photo_camera_outlined;
    switch (log.category) {
      case 'meal':
        return Icons.restaurant_outlined;
      case 'drink':
        return Icons.local_cafe_outlined;
      case 'symptom':
      case 'bowel_movement':
        return Icons.healing_outlined;
      case 'activity':
        return Icons.directions_walk;
      case 'mood':
        return Icons.mood;
      case 'medication':
        return Icons.medication_outlined;
      default:
        return Icons.notes;
    }
  }

  String _analysisCaption(DailyLogEntry log) {
    switch (log.analysis) {
      case LogAnalysis.gemini:
        return 'AI estimate · not medical advice';
      case LogAnalysis.sample:
        return 'Sample analysis (offline mode)';
      default:
        return 'No AI analysis · common-trigger keyword check only';
    }
  }

  Widget _buildLogItem(DailyLogEntry log) {
    final score = log.digestibilityScore;
    final Color borderColor;
    final Color scoreColor;
    if (score == null) {
      borderColor = AppTheme.lightIndigo;
      scoreColor = const Color(0xFF4B5563);
    } else if (score >= 7) {
      borderColor = AppTheme.healthGreen;
      scoreColor = const Color(0xFF047857);
    } else if (score >= 4) {
      borderColor = Colors.amber;
      scoreColor = const Color(0xFFB45309);
    } else {
      borderColor = Colors.redAccent;
      scoreColor = const Color(0xFFB91C1C);
    }

    String symptomText(Map<String, dynamic> s) {
      final severity = s['severity'];
      return severity is num ? '${s['name']} ($severity/5)' : '${s['name']}';
    }

    final details = <String>[
      if (log.foods.isNotEmpty) 'Foods: ${log.foods.join(', ')}',
      if (log.symptoms.isNotEmpty) 'Symptoms: ${log.symptoms.map(symptomText).join(', ')}',
      if (log.mood != null) 'Mood: ${log.mood}',
      if (log.potentialTriggers.isNotEmpty) 'Possible triggers: ${log.potentialTriggers.join(', ')}',
    ];
    const detailStyle = TextStyle(fontSize: 12, color: Color(0xFF374151));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_categoryIcon(log), size: 14, color: const Color(0xFF4B5563)),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(log.time),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                for (final detail in details)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(detail, style: detailStyle),
                  ),
                if (log.digestibilityRationale != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      log.digestibilityRationale!,
                      style: detailStyle.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _analysisCaption(log),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Digestibility',
                style: TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
              ),
              Text(
                score == null ? 'Not scored' : '$score/10',
                style: TextStyle(
                  fontSize: score == null ? 12 : 18,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Add meal photo',
            onPressed: _isLogging ? null : _addMealPhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 22),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white38,
              backgroundColor: AppTheme.accentIndigo.withValues(alpha: 0.3),
              disabledBackgroundColor: AppTheme.accentIndigo.withValues(alpha: 0.15),
              fixedSize: const Size(44, 44),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: TextField(
                // A new key after each saved entry gives the web engine a fresh,
                // empty <input>: its value only syncs while the field is active.
                key: ValueKey(_logFieldVersion),
                controller: _logController,
                focusNode: _logFocus,
                readOnly: _isLogging,
                textInputAction: TextInputAction.send,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                decoration: InputDecoration(
                  hintText: 'What did you eat, do, or feel?',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                onSubmitted: (_) => _submitLog(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Add log',
            onPressed: _isLogging ? null : _submitLog,
            icon: _isLogging
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.accentIndigo,
              disabledBackgroundColor: AppTheme.accentIndigo.withValues(alpha: 0.6),
              fixedSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await BackendServiceProvider.instance.auth.signOut();
    } catch (e) {
      debugPrint('HomeContent: sign out failed: $e');
      _showMessage("Couldn't sign out. Please try again.");
      return;
    }
    _signingOut = true;
    // Clear the shared date and onboarding lists so the next account starts fresh.
    _appState.reset();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  void _scrollToLatestLog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Saves [entry] to the day's log (and the analysed meal to the `meal`
  /// history the AI assistant reads). Returns false if the log was not saved.
  Future<bool> _saveLogEntry(
    String key,
    DateTime date,
    DailyLogEntry entry, {
    MealAnalysisResult? meal,
  }) async {
    _bumpVersion(key);
    try {
      final entries = await _service.addLog(key, entry);
      if (mounted) setState(() => _logsByDate[key] = entries);
    } catch (e) {
      debugPrint('HomeContent: failed to save log entry: $e');
      _showMessage("Couldn't save your log. Check your connection and try again.");
      return false;
    }
    if (meal != null && meal.foods.isNotEmpty) {
      try {
        await MealAnalysisService.saveMealData(analysis: meal, date: date);
      } catch (e) {
        debugPrint('HomeContent: failed to save meal for AI context: $e');
      }
    }
    if (key == _dateKey) _scrollToLatestLog();
    return true;
  }

  Future<void> _submitLog() async {
    if (_isLogging) return;
    final text = _logController.text.trim();
    if (text.isEmpty) {
      _showMessage('Type what you ate, did or felt first.');
      return;
    }

    final date = _selectedDate;
    final key = _dateKey;
    setState(() => _isLogging = true);
    try {
      final loggedAt = DateTime.now();
      final entry = await DailyLogAnalyzer.analyzeText(text, now: loggedAt);
      final saved = await _saveLogEntry(
        key,
        date,
        entry,
        meal: entry.foods.isEmpty ? null : entry.toMealAnalysis(loggedAt),
      );
      if (saved && mounted) {
        _logController.clear();
        _logFocus.unfocus();
        _logFieldVersion++;
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.darkNavy,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Colors.white),
              title: const Text('Take a photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: const Text('Choose from library', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMealPhoto() async {
    if (_isLogging) return;
    // On the web the browser's file picker already offers the camera on
    // phones, so go straight to it.
    final source = kIsWeb ? ImageSource.gallery : await _chooseImageSource();
    if (source == null || !mounted) return;

    XFile? photo;
    try {
      photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('HomeContent: image picker failed: $e');
      _showMessage("Couldn't open your camera or photos. Check the app's permissions.");
      return;
    }
    if (photo == null || !mounted) return;

    final date = _selectedDate;
    final key = _dateKey;
    setState(() => _isLogging = true);
    try {
      final MealAnalysisResult analysis;
      try {
        analysis = await MealAnalysisService.analyzeMealPhoto(
          await photo.readAsBytes(),
          mimeType: photo.mimeType ?? 'image/jpeg',
        );
      } catch (e) {
        debugPrint('HomeContent: meal photo analysis failed: $e');
        _showMessage("Couldn't analyse that photo right now. Describe the meal in the box below instead.");
        return;
      }
      if (analysis.foods.isEmpty) {
        _showMessage('No food was recognised in that photo. Try another photo or describe the meal below.');
        return;
      }
      await _saveLogEntry(key, date, DailyLogAnalyzer.fromMealPhoto(analysis), meal: analysis);
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }
}
