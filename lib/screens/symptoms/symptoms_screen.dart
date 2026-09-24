import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/widgets/calendar_bar.dart';

class SymptomItem {
  final String name;
  final String description;
  final IconData icon;

  const SymptomItem({
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// Symptoms tab: the user keeps a personal list of symptoms and, for the date
/// selected in the shared calendar, marks the ones they experienced with a
/// 1-5 severity.
///
/// Storage (via [BackendServiceProvider]):
/// - `symptoms` entry per day: `{date, active_symptoms: [{name, severity}]}`
///   (read by the AI assistant and insights).
/// - `tracked_lists/symptoms`: the personal list, shared across days.
class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({Key? key}) : super(key: key);

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  static const _entryType = 'symptoms';
  static const _listsType = 'tracked_lists';
  static const _listId = 'symptoms';
  static const _defaultSeverityLevel = 3;
  static const _severityLabels = ['Very mild', 'Mild', 'Moderate', 'Severe', 'Very severe'];
  static const _errorTextColor = Color(0xFFFFB4AB);

  final _appState = AppState();
  final TextEditingController _customController = TextEditingController();

  // The user's symptom list (shared across days).
  final List<String> _mySymptoms = [];
  final Map<String, int> _defaultSeverity = {};
  bool _listLoaded = false;
  bool _listSaved = false;

  // The selected day's log: symptom name -> severity (1-5).
  final Map<String, int> _active = {};
  bool _dayLogged = false;
  String? _loadedDateKey;
  String? _requestedDateKey;

  bool _loading = true;
  String? _loadError;
  String? _inputError;
  int _loadGeneration = 0;

  DateTime get _selectedDate => _appState.selectedDate;
  String? get _userId => BackendServiceProvider.instance.auth.currentUser?.id;

  static String _dateKeyFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  final List<SymptomItem> _commonSymptoms = const [
    SymptomItem(name: 'Abdominal Pain', description: 'Stomach cramps or discomfort', icon: Icons.emergency_outlined),
    SymptomItem(name: 'Diarrhea', description: 'Frequent loose or watery stools', icon: Icons.water_drop_outlined),
    SymptomItem(name: 'Bloating', description: 'Feeling of fullness or swelling', icon: Icons.air),
    SymptomItem(name: 'Gas', description: 'Excessive flatulence', icon: Icons.cloud_outlined),
    SymptomItem(name: 'Fatigue', description: 'Tiredness and low energy', icon: Icons.battery_0_bar),
    SymptomItem(name: 'Nausea', description: 'Feeling sick or queasy', icon: Icons.sick_outlined),
    SymptomItem(name: 'Loss of Appetite', description: 'Reduced desire to eat', icon: Icons.no_meals_outlined),
    SymptomItem(name: 'Constipation', description: 'Difficulty passing stools', icon: Icons.block),
    SymptomItem(name: 'Joint Pain', description: 'Aching or stiff joints', icon: Icons.accessibility_new),
    SymptomItem(name: 'Fever', description: 'Elevated body temperature', icon: Icons.thermostat),
  ];

  /// Symptoms shown for the selected day: the personal list plus anything
  /// logged that day which has since been removed from the list.
  List<String> get _displayedSymptoms => [
        ..._mySymptoms,
        ..._active.keys.where((name) => !_mySymptoms.contains(name)),
      ];

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    _load();
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _customController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (_dateKeyFor(_selectedDate) != _requestedDateKey) _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final dateKey = _dateKeyFor(_selectedDate);
    _requestedDateKey = dateKey;
    final userId = _userId;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    if (userId == null) {
      setState(() {
        _loading = false;
        _loadError = 'Sign in to track your symptoms.';
      });
      return;
    }

    try {
      final tracking = BackendServiceProvider.instance.tracking;
      final listFuture = _listLoaded
          ? Future<Map<String, dynamic>?>.value(null)
          : tracking.getTrackingData(userId: userId, date: _listId, type: _listsType);
      final dayFuture = tracking.getTrackingData(userId: userId, date: dateKey, type: _entryType);
      final list = await listFuture;
      final day = await dayFuture;
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        if (!_listLoaded) _applyList(list);
        _applyDay(day);
        _loadedDateKey = dateKey;
        _loading = false;
      });
    } catch (error) {
      debugPrint('SymptomsScreen: failed to load $dateKey: $error');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _loadError = "Couldn't load your symptoms. Check your connection and try again.";
      });
    }
  }

  void _applyList(Map<String, dynamic>? data) {
    _mySymptoms.clear();
    _defaultSeverity.clear();
    final items = data?['items'];
    if (items is List) {
      _listSaved = true;
      for (final item in items) {
        if (item is! Map) continue;
        final name = '${item['name'] ?? ''}'.trim();
        if (name.isEmpty || _mySymptoms.contains(name)) continue;
        _mySymptoms.add(name);
        if (item['default_severity'] != null) {
          _defaultSeverity[name] = _parseSeverity(item['default_severity']);
        }
      }
    } else {
      // Nothing saved yet: start from the symptoms picked during onboarding.
      for (final symptom in _appState.userSymptoms) {
        final name = symptom.name.trim();
        if (name.isEmpty || _mySymptoms.contains(name)) continue;
        _mySymptoms.add(name);
        _defaultSeverity[name] = _parseSeverity(symptom.severity);
      }
    }
    _listLoaded = true;
  }

  void _applyDay(Map<String, dynamic>? data) {
    _active.clear();
    _dayLogged = data != null;
    final logged = data?['active_symptoms'];
    if (logged is! List) return;
    for (final symptom in logged) {
      if (symptom is! Map) continue;
      final name = '${symptom['name'] ?? ''}'.trim();
      if (name.isNotEmpty) _active[name] = _parseSeverity(symptom['severity']);
    }
  }

  /// Accepts the stored 1-5 scale and the Mild/Moderate/Severe words used
  /// during onboarding.
  static int _parseSeverity(Object? value) {
    if (value is num) return value.round().clamp(1, 5);
    final text = '${value ?? ''}'.trim().toLowerCase();
    final asNumber = int.tryParse(text);
    if (asNumber != null) return asNumber.clamp(1, 5);
    final index = _severityLabels.indexWhere((label) => label.toLowerCase() == text);
    return index == -1 ? _defaultSeverityLevel : index + 1;
  }

  void _saveDay() {
    final userId = _userId;
    final dateKey = _loadedDateKey;
    if (userId == null || dateKey == null) return;
    final data = <String, dynamic>{
      'date': dateKey,
      'active_symptoms': [
        for (final entry in _active.entries) {'name': entry.key, 'severity': entry.value},
      ],
    };
    _persist(userId, _entryType, data);
    if (!_listSaved) _saveList();
  }

  void _saveList() {
    final userId = _userId;
    if (userId == null) return;
    _listSaved = true;
    final data = <String, dynamic>{
      'entry_id': _listId,
      'items': [
        for (final name in _mySymptoms)
          {
            'name': name,
            if (_defaultSeverity[name] != null) 'default_severity': _defaultSeverity[name],
          },
      ],
    };
    _persist(userId, _listsType, data);
  }

  /// Each save sends the full current state, so saves can overlap: both
  /// backends apply them in the order they were issued, and reads include
  /// writes that are still in flight.
  Future<void> _persist(String userId, String type, Map<String, dynamic> data) async {
    try {
      await BackendServiceProvider.instance.tracking.trackEvent(userId: userId, type: type, data: data);
    } catch (error) {
      debugPrint('SymptomsScreen: failed to save $type: $error');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text("Couldn't save your symptoms. Please try again.")),
        );
      }
    }
  }

  void _toggleExperienced(String name) {
    if (_loading) return;
    setState(() {
      if (_active.containsKey(name)) {
        _active.remove(name);
      } else {
        _active[name] = _defaultSeverity[name] ?? _defaultSeverityLevel;
      }
      _dayLogged = true;
    });
    _saveDay();
  }

  void _setSeverity(String name, int severity) {
    if (_loading || _active[name] == severity) return;
    setState(() {
      _active[name] = severity;
      _dayLogged = true;
    });
    _saveDay();
  }

  void _markAllExperienced() {
    if (_loading) return;
    setState(() {
      for (final name in _displayedSymptoms) {
        _active[name] ??= _defaultSeverity[name] ?? _defaultSeverityLevel;
      }
      _dayLogged = true;
    });
    _saveDay();
  }

  void _markNoneExperienced() {
    if (_loading) return;
    setState(() {
      _active.clear();
      _dayLogged = true;
    });
    _saveDay();
  }

  void _addToMyList(String name) {
    setState(() {
      _mySymptoms.add(name);
      _inputError = null;
    });
    _saveList();
  }

  void _addCustomSymptom() {
    if (_loading) return;
    final text = _customController.text.trim();
    if (text.isEmpty) {
      setState(() => _inputError = 'Enter a symptom name to add it.');
      return;
    }
    final lower = text.toLowerCase();
    final existing = _mySymptoms.where((name) => name.toLowerCase() == lower);
    if (existing.isNotEmpty) {
      setState(() => _inputError = '${existing.first} is already in your list.');
      return;
    }
    // Typing one of the suggestions adds that suggestion.
    final common = _commonSymptoms.where((s) => s.name.toLowerCase() == lower);
    _customController.clear();
    _addToMyList(common.isNotEmpty ? common.first.name : text);
  }

  void _removeFromMyList(String name) {
    if (_loading) return;
    final wasLogged = _active.containsKey(name);
    setState(() {
      _mySymptoms.remove(name);
      _defaultSeverity.remove(name);
      _active.remove(name);
    });
    _saveList();
    if (wasLogged) _saveDay();
  }

  String get _dayPhrase {
    final date = _selectedDate;
    final now = DateTime.now();
    bool sameDay(DateTime other) =>
        date.year == other.year && date.month == other.month && date.day == other.day;
    if (sameDay(now)) return 'today';
    if (sameDay(DateTime(now.year, now.month, now.day - 1))) return 'yesterday';
    return DateFormat('EEE d MMM').format(date);
  }

  String get _daySummary {
    if (!_dayLogged) return 'Nothing logged for $_dayPhrase yet';
    final count = _active.length;
    if (count == 0) return 'Logged for $_dayPhrase: no symptoms';
    return 'Logged for $_dayPhrase: $count symptom${count == 1 ? '' : 's'}';
  }

  Color _severityColor(int severity) {
    switch (severity) {
      case 1:
        return AppTheme.healthGreen;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.orange;
      default:
        return Colors.redAccent;
    }
  }

  SymptomItem? _commonFor(String name) {
    for (final symptom in _commonSymptoms) {
      if (symptom.name == name) return symptom;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Symptoms',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log the symptoms you experienced each day',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 16),
                  CalendarBar(
                    selectedDate: _selectedDate,
                    onDateSelected: _appState.setSelectedDate,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        semanticsLabel: 'Loading symptoms',
                      ),
                    )
                  : _loadError != null
                      ? _buildLoadError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            if (_userId != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Try Again')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final displayed = _displayedSymptoms;
    final suggestions = _commonSymptoms.where((s) => !_mySymptoms.contains(s.name)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _daySummary,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
        const SizedBox(height: 10),
        // Quick actions for the selected day
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (displayed.isNotEmpty) ...[
                Expanded(
                  child: _buildQuickAction('Had All', Icons.check_circle_outline, Colors.amber, _markAllExperienced),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _buildQuickAction('Had None', Icons.sentiment_satisfied_alt, AppTheme.healthGreen, _markNoneExperienced),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayed.isNotEmpty) ...[
                  Text(
                    'My Symptoms - tap the ones you experienced',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  ...displayed.map(_buildSymptomCard),
                ] else
                  _buildEmptyList(),
                const SizedBox(height: 20),

                // Add custom symptom
                _buildAddCustomSection(),

                const SizedBox(height: 20),

                // Add from common symptoms
                if (suggestions.isNotEmpty) ...[
                  Text(
                    'Add Symptoms to Track',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  ...suggestions.map(_buildAddSymptomCard),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        "You're not tracking any symptoms yet. Add the ones you want to track below.",
        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Semantics(
      container: true,
      button: true,
      child: Material(
        color: color.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddCustomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accentIndigo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_circle_outline, color: Colors.white.withValues(alpha: 0.7), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _customController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  inputFormatters: [LengthLimitingTextInputFormatter(60)],
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add custom symptom',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) {
                    if (_inputError != null) setState(() => _inputError = null);
                  },
                  onSubmitted: (_) => _addCustomSymptom(),
                ),
              ),
              Semantics(
                container: true,
                button: true,
                child: Material(
                  color: AppTheme.accentIndigo,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _addCustomSymptom,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_inputError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 64),
              child: Semantics(
                liveRegion: true,
                child: Text(_inputError!, style: const TextStyle(color: _errorTextColor, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(String name) {
    final severity = _active[name];
    final isExperienced = severity != null;
    final severityColor = _severityColor(severity ?? _defaultSeverityLevel);
    final common = _commonFor(name);
    final description = common?.description ?? 'Custom symptom';
    final icon = common?.icon ?? Icons.edit_note;
    void toggle() => _toggleExperienced(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExperienced ? severityColor.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExperienced ? severityColor : Colors.white.withValues(alpha: 0.1),
          width: isExperienced ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      container: true,
                      checked: isExperienced,
                      label: name,
                      hint: severity != null
                          ? 'Severity ${_severityLabels[severity - 1]}, $severity of 5'
                          : description,
                      onTap: toggle,
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: toggle,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isExperienced ? severityColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isExperienced ? Icons.check : icon,
                                  color: isExperienced ? severityColor : Colors.white70,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isExperienced ? Colors.white : Colors.white.withValues(alpha: 0.9))),
                                    Text(description, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove $name',
                    onPressed: () => _removeFromMyList(name),
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.white70,
                    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              if (severity != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(64, 4, 6, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Severity: ${_severityLabels[severity - 1]} ($severity/5)',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (var level = 1; level <= 5; level++) ...[
                            _buildSeverityChip(name, level, level == severity),
                            if (level < 5) const SizedBox(width: 6),
                          ],
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

  Widget _buildAddSymptomCard(SymptomItem symp) {
    void add() => _addToMyList(symp.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        container: true,
        button: true,
        label: 'Add ${symp.name}',
        hint: symp.description,
        onTap: add,
        excludeSemantics: true,
        child: Material(
          color: Colors.black.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: InkWell(
            onTap: add,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(symp.icon, color: Colors.white54, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(symp.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),
                        Text(symp.description, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentIndigo.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('+ Add', style: TextStyle(color: AppTheme.lightIndigo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityChip(String name, int level, bool isSelected) {
    final color = _severityColor(level);
    void select() => _setSeverity(name, level);
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      label: '$name severity $level of 5, ${_severityLabels[level - 1]}',
      onTap: select,
      excludeSemantics: true,
      child: InkWell(
        onTap: select,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$level',
            style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal, color: isSelected ? color : Colors.white70),
          ),
        ),
      ),
    );
  }
}
