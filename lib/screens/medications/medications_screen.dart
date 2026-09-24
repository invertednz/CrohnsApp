import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/widgets/calendar_bar.dart';

class MedicationItem {
  final String name;
  final String description;
  final IconData icon;

  const MedicationItem({
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// A medication in the user's list with its usual dosage and time of day.
class _MedicationPlan {
  final String name;
  String dosage;
  final bool am;
  final bool pm;

  _MedicationPlan({required this.name, this.dosage = '', this.am = false, this.pm = false});

  Map<String, dynamic> toJson() => {'name': name, 'dosage': dosage, 'am': am, 'pm': pm};
}

/// Medications tab: the user keeps a list of medications and, for the date
/// selected in the shared calendar, marks which were taken (and when).
///
/// Storage (via [BackendServiceProvider]):
/// - `medications` entry per day:
///   `{date, medications: [{name, dosage, time, taken}]}`.
/// - `tracked_lists/medications`: the list with dosages, shared across days.
class MedicationsScreenMain extends StatefulWidget {
  const MedicationsScreenMain({Key? key}) : super(key: key);

  @override
  State<MedicationsScreenMain> createState() => _MedicationsScreenMainState();
}

class _MedicationsScreenMainState extends State<MedicationsScreenMain> {
  static const _entryType = 'medications';
  static const _listsType = 'tracked_lists';
  static const _listId = 'medications';
  static const _errorTextColor = Color(0xFFFFB4AB);

  final _appState = AppState();
  final TextEditingController _customController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();

  // The user's medication list (shared across days).
  final List<_MedicationPlan> _myMedications = [];
  bool _listLoaded = false;
  bool _listSaved = false;

  // The selected day's log.
  final Set<String> _taken = {};
  final List<String> _loggedNames = [];
  final Map<String, bool> _takenAM = {};
  final Map<String, bool> _takenPM = {};
  final Map<String, String> _dayDosage = {};
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

  final List<MedicationItem> _commonMedications = const [
    MedicationItem(name: 'Mesalamine', description: 'Anti-inflammatory for IBD maintenance', icon: Icons.medication_outlined),
    MedicationItem(name: 'Prednisone', description: 'Corticosteroid for flare management', icon: Icons.medical_services_outlined),
    MedicationItem(name: 'Azathioprine', description: 'Immunosuppressant medication', icon: Icons.healing_outlined),
    MedicationItem(name: 'Infliximab', description: 'Biologic therapy (infusion)', icon: Icons.vaccines_outlined),
    MedicationItem(name: 'Adalimumab', description: 'Biologic therapy (injection)', icon: Icons.vaccines_outlined),
    MedicationItem(name: 'Budesonide', description: 'Targeted corticosteroid', icon: Icons.medical_services_outlined),
    MedicationItem(name: 'Methotrexate', description: 'Immunomodulator therapy', icon: Icons.healing_outlined),
    MedicationItem(name: 'Vedolizumab', description: 'Gut-selective biologic', icon: Icons.vaccines_outlined),
  ];

  /// Medications shown for the selected day: the list plus anything logged
  /// that day which has since been removed from the list.
  List<String> get _displayedMedications {
    final names = _myMedications.map((s) => s.name).toList();
    return [...names, ..._loggedNames.where((name) => !names.contains(name))];
  }

  _MedicationPlan? _planFor(String name) {
    for (final plan in _myMedications) {
      if (plan.name == name) return plan;
    }
    return null;
  }

  String _dosageFor(String name) => _dayDosage[name] ?? _planFor(name)?.dosage ?? '';
  bool _amFor(String name) => _takenAM[name] ?? _planFor(name)?.am ?? false;
  bool _pmFor(String name) => _takenPM[name] ?? _planFor(name)?.pm ?? false;

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
    _dosageController.dispose();
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
        _loadError = 'Sign in to track your medications.';
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
      debugPrint('MedicationsScreen: failed to load $dateKey: $error');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _loadError = "Couldn't load your medications. Check your connection and try again.";
      });
    }
  }

  void _applyList(Map<String, dynamic>? data) {
    _myMedications.clear();
    final items = data?['items'];
    if (items is List) {
      _listSaved = true;
      for (final item in items) {
        if (item is! Map) continue;
        final name = '${item['name'] ?? ''}'.trim();
        if (name.isEmpty || _planFor(name) != null) continue;
        _myMedications.add(_MedicationPlan(
          name: name,
          dosage: '${item['dosage'] ?? ''}'.trim(),
          am: item['am'] == true,
          pm: item['pm'] == true,
        ));
      }
    } else {
      // Nothing saved yet: start from the medications entered during onboarding.
      for (final medication in _appState.userMedications) {
        final name = medication.trim();
        if (name.isEmpty || _planFor(name) != null) continue;
        _myMedications.add(_MedicationPlan(name: name));
      }
    }
    _listLoaded = true;
  }

  void _applyDay(Map<String, dynamic>? data) {
    _taken.clear();
    _loggedNames.clear();
    _takenAM.clear();
    _takenPM.clear();
    _dayDosage.clear();
    _dayLogged = data != null;
    final logged = data?['medications'];
    if (logged is! List) return;
    for (final medication in logged) {
      if (medication is! Map) continue;
      final name = '${medication['name'] ?? ''}'.trim();
      if (name.isEmpty || _loggedNames.contains(name)) continue;
      _loggedNames.add(name);
      if (medication['taken'] == true) _taken.add(name);
      final times = '${medication['time'] ?? ''}'.toUpperCase().split(RegExp(r'[,&/ ]+'));
      _takenAM[name] = times.contains('AM');
      _takenPM[name] = times.contains('PM');
      final dosage = medication['dosage'];
      if (dosage != null) _dayDosage[name] = '$dosage';
    }
  }

  void _saveDay() {
    final userId = _userId;
    final dateKey = _loadedDateKey;
    if (userId == null || dateKey == null) return;
    final data = <String, dynamic>{
      'date': dateKey,
      'medications': [
        for (final name in _displayedMedications)
          {
            'name': name,
            'dosage': _dosageFor(name),
            'time': [if (_amFor(name)) 'AM', if (_pmFor(name)) 'PM'].join(', '),
            'taken': _taken.contains(name),
          },
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
      'items': [for (final plan in _myMedications) plan.toJson()],
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
      debugPrint('MedicationsScreen: failed to save $type: $error');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text("Couldn't save your medications. Please try again.")),
        );
      }
    }
  }

  void _toggleTaken(String name) {
    if (_loading) return;
    setState(() {
      if (!_taken.remove(name)) _taken.add(name);
      _dayLogged = true;
    });
    _saveDay();
  }

  void _toggleAM(String name) {
    if (_loading) return;
    setState(() {
      _takenAM[name] = !_amFor(name);
      _dayLogged = true;
    });
    _saveDay();
  }

  void _togglePM(String name) {
    if (_loading) return;
    setState(() {
      _takenPM[name] = !_pmFor(name);
      _dayLogged = true;
    });
    _saveDay();
  }

  void _markAllTaken() {
    if (_loading) return;
    setState(() {
      _taken.addAll(_displayedMedications);
      _dayLogged = true;
    });
    _saveDay();
  }

  void _clearAllTaken() {
    if (_loading) return;
    setState(() {
      _taken.clear();
      _dayLogged = true;
    });
    _saveDay();
  }

  void _addToMyList(String name, {String dosage = ''}) {
    setState(() {
      _myMedications.add(_MedicationPlan(name: name, dosage: dosage));
      _inputError = null;
    });
    _saveList();
    if (_dayLogged) _saveDay();
  }

  void _addCustomMedication() {
    if (_loading) return;
    final text = _customController.text.trim();
    if (text.isEmpty) {
      setState(() => _inputError = 'Enter a medication name to add it.');
      return;
    }
    final lower = text.toLowerCase();
    final existing = _myMedications.where((s) => s.name.toLowerCase() == lower);
    if (existing.isNotEmpty) {
      setState(() => _inputError = '${existing.first.name} is already in your list.');
      return;
    }
    // Typing one of the suggestions adds that suggestion.
    final common = _commonMedications.where((s) => s.name.toLowerCase() == lower);
    final dosage = _dosageController.text.trim();
    _customController.clear();
    _dosageController.clear();
    _addToMyList(common.isNotEmpty ? common.first.name : text, dosage: dosage);
  }

  void _removeMedication(String name) {
    if (_loading) return;
    setState(() {
      _myMedications.removeWhere((s) => s.name == name);
      _loggedNames.remove(name);
      _taken.remove(name);
      _takenAM.remove(name);
      _takenPM.remove(name);
      _dayDosage.remove(name);
    });
    _saveList();
    if (_dayLogged) _saveDay();
  }

  Future<void> _editDosage(String name) async {
    final plan = _planFor(name);
    if (_loading || plan == null) return;
    final dosage = await showDialog<String>(
      context: context,
      builder: (context) => _DosageDialog(title: '$name dosage', initialDosage: _dosageFor(name)),
    );
    if (dosage == null || !mounted) return;
    setState(() {
      plan.dosage = dosage.trim();
      _dayDosage.remove(name);
    });
    _saveList();
    if (_dayLogged) _saveDay();
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
    final total = _displayedMedications.length;
    if (total == 0) return 'Logged for $_dayPhrase: no medications';
    return 'Logged for $_dayPhrase: ${_taken.length} of $total taken';
  }

  MedicationItem? _commonFor(String name) {
    for (final medication in _commonMedications) {
      if (medication.name == name) return medication;
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
                    'Medications',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your daily medications',
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
                        semanticsLabel: 'Loading medications',
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
    final displayed = _displayedMedications;
    final myNames = _myMedications.map((s) => s.name).toSet();
    final suggestions = _commonMedications.where((s) => !myNames.contains(s.name)).toList();

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
        if (displayed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickAction('Mark All Taken', Icons.check_circle_outline, AppTheme.healthGreen, _markAllTaken),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickAction('Clear All', Icons.cancel_outlined, Colors.redAccent, _clearAllTaken),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayed.isNotEmpty) ...[
                  Text(
                    'My Medications - tap to mark taken',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  ...displayed.map(_buildMedicationCard),
                ] else
                  _buildEmptyList(),
                const SizedBox(height: 20),

                // Add custom medication
                _buildAddCustomSection(),

                const SizedBox(height: 20),

                // Add from common medications
                if (suggestions.isNotEmpty) ...[
                  Text(
                    'Add to My Medications',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  ...suggestions.map(_buildAddMedicationCard),
                ],

                const SizedBox(height: 16),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Always consult your doctor before making medication changes',
                          style: TextStyle(fontSize: 13, color: Colors.amber.withValues(alpha: 0.9)),
                        ),
                      ),
                    ],
                  ),
                ),

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
        "You haven't added any medications yet. Add the ones you take below.",
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
    final hintStyle = TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14);
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
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Add custom medication',
                    hintStyle: hintStyle,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) {
                    if (_inputError != null) setState(() => _inputError = null);
                  },
                  onSubmitted: (_) => _addCustomMedication(),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 64),
              Expanded(
                child: TextField(
                  controller: _dosageController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  decoration: InputDecoration(
                    hintText: 'Dosage (optional)',
                    hintStyle: hintStyle,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _addCustomMedication(),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                container: true,
                button: true,
                child: Material(
                  color: AppTheme.accentIndigo,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _addCustomMedication,
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

  Widget _buildMedicationCard(String name) {
    final isTaken = _taken.contains(name);
    final plan = _planFor(name);
    final common = _commonFor(name);
    final dosage = _dosageFor(name);
    final description = common?.description ?? 'Custom medication';
    final subtitle = dosage.isEmpty ? description : '$dosage · $description';
    final icon = common?.icon ?? Icons.medication_outlined;
    void toggle() => _toggleTaken(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isTaken ? AppTheme.healthGreen.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTaken ? AppTheme.healthGreen : Colors.white.withValues(alpha: 0.1),
          width: isTaken ? 2 : 1,
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
                      checked: isTaken,
                      label: name,
                      hint: subtitle,
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
                                  color: isTaken ? AppTheme.healthGreen.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isTaken ? Icons.check : icon,
                                  color: isTaken ? AppTheme.healthGreen : Colors.white70,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isTaken ? Colors.white : Colors.white.withValues(alpha: 0.9))),
                                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (plan != null)
                    IconButton(
                      tooltip: 'Edit dosage for $name',
                      onPressed: () => _editDosage(name),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: Colors.white70,
                      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                      padding: EdgeInsets.zero,
                    ),
                  IconButton(
                    tooltip: 'Remove $name',
                    onPressed: () => _removeMedication(name),
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.white70,
                    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              if (isTaken)
                Padding(
                  padding: const EdgeInsets.fromLTRB(64, 4, 6, 6),
                  child: Row(
                    children: [
                      Text('When taken:', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                      const Spacer(),
                      _buildTimeChip(name, 'AM', _amFor(name), () => _toggleAM(name)),
                      const SizedBox(width: 8),
                      _buildTimeChip(name, 'PM', _pmFor(name), () => _togglePM(name)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMedicationCard(MedicationItem med) {
    void add() => _addToMyList(med.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        container: true,
        button: true,
        label: 'Add ${med.name}',
        hint: med.description,
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
                    child: Icon(med.icon, color: Colors.white54, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),
                        Text(med.description, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
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

  Widget _buildTimeChip(String name, String label, bool isSelected, VoidCallback onTap) {
    return Semantics(
      container: true,
      checked: isSelected,
      label: '$name taken $label',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.healthGreen.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.healthGreen : Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppTheme.healthGreen : Colors.white70),
          ),
        ),
      ),
    );
  }
}

/// Asks for a new dosage; pops with the entered text, or null when cancelled.
class _DosageDialog extends StatefulWidget {
  final String title;
  final String initialDosage;

  const _DosageDialog({required this.title, required this.initialDosage});

  @override
  State<_DosageDialog> createState() => _DosageDialogState();
}

class _DosageDialogState extends State<_DosageDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialDosage);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        inputFormatters: [LengthLimitingTextInputFormatter(40)],
        decoration: const InputDecoration(labelText: 'Dosage'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: const Text('Save')),
      ],
    );
  }
}
