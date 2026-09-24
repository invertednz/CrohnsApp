import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/backend_service_provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  /// Feeling scale shared with Home: 0 = Terrible ... 4 = Great.
  static const List<String> _feelingEmojis = ['😫', '😔', '😐', '🙂', '😄'];
  static const List<String> _feelingLabels = ['Terrible', 'Bad', 'Okay', 'Good', 'Great'];
  static const List<Color> _feelingColors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.lightGreen,
    Colors.green,
  ];
  static const double _defaultPain = 0;
  static const double _defaultEnergy = 5;

  late DateTime _selectedDate = _initialDate();
  int? _selectedFeeling;
  int _bowelMovements = 0;
  double _painLevel = _defaultPain;
  double _energyLevel = _defaultEnergy;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showFeelingError = false;
  Map<String, Object?> _savedValues = const {};
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _feelGoodController = TextEditingController();
  final TextEditingController _feelBadController = TextEditingController();

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Opens on the day selected on Home (never a future day).
  static DateTime _initialDate() {
    final shared = _dayOnly(AppState().selectedDate);
    final today = _dayOnly(DateTime.now());
    return shared.isAfter(today) ? today : shared;
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  bool get _isToday => _dayOnly(_selectedDate) == _dayOnly(DateTime.now());

  String get _dateLabel => _isToday
      ? 'Today, ${DateFormat('MMM d').format(_selectedDate)}'
      : DateFormat('EEEE, MMM d').format(_selectedDate);

  Map<String, Object?> _currentValues() => {
        'feeling': _selectedFeeling,
        'bowel_movements': _bowelMovements,
        'pain_level': _painLevel.round(),
        'energy_level': _energyLevel.round(),
        'notes': _notesController.text.trim(),
        'feel_good_factors': _feelGoodController.text.trim(),
        'feel_bad_factors': _feelBadController.text.trim(),
      };

  bool get _hasUnsavedChanges => !mapEquals(_currentValues(), _savedValues);

  @override
  void initState() {
    super.initState();
    _savedValues = _currentValues();
    _loadTrackingData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _feelGoodController.dispose();
    _feelBadController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTrackingData() async {
    final requestedDate = _dateKey;
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await BackendServiceProvider.instance.tracking.getTrackingData(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        date: requestedDate,
        type: 'daily',
      );
      // Ignore responses for a day the user has already moved away from.
      if (!mounted || requestedDate != _dateKey) return;
      _applyEntry(data ?? const {});
    } catch (e) {
      if (!mounted || requestedDate != _dateKey) return;
      _applyEntry(const {});
      _showSnack('Couldn\'t load this day\'s entry. Please try again.');
    } finally {
      if (mounted && requestedDate == _dateKey) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyEntry(Map<String, dynamic> data) {
    int? asInt(Object? v) => v is num ? v.toInt() : null;
    double? asDouble(Object? v) => v is num ? v.toDouble() : null;
    String asText(Object? v) => v is String ? v : '';

    setState(() {
      final feeling = asInt(data['feeling']);
      _selectedFeeling = feeling?.clamp(0, 4);
      _bowelMovements = (asInt(data['bowel_movements']) ?? 0).clamp(0, 99);
      _painLevel = (asDouble(data['pain_level']) ?? _defaultPain).clamp(0, 10).roundToDouble();
      _energyLevel = (asDouble(data['energy_level']) ?? _defaultEnergy).clamp(0, 10).roundToDouble();
      _notesController.text = asText(data['notes']);
      _feelGoodController.text = asText(data['feel_good_factors']);
      _feelBadController.text = asText(data['feel_bad_factors']);
      _showFeelingError = false;
      _savedValues = _currentValues();
    });
  }

  /// Saves the selected day. Returns true when the entry was stored.
  Future<bool> _saveTrackingData() async {
    if (_selectedFeeling == null) {
      setState(() => _showFeelingError = true);
      _showSnack('Choose how you\'re feeling before saving');
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    final values = _currentValues();
    try {
      await BackendServiceProvider.instance.tracking.trackEvent(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        type: 'daily',
        data: {'date': _dateKey, ...values},
      );
      if (!mounted) return true;
      setState(() => _savedValues = values);
      _showSnack('Saved your entry for ${_isToday ? 'today' : DateFormat('MMM d').format(_selectedDate)}');
      return true;
    } catch (e) {
      if (mounted) {
        _showSnack('Couldn\'t save your entry. Please try again.');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Asks what to do with unsaved edits. Returns true when it's fine to leave
  /// the current day (nothing changed, the user discarded, or it was saved).
  Future<bool> _resolveUnsavedChanges() async {
    if (!_hasUnsavedChanges) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save your changes?'),
        content: Text('You have unsaved changes for ${_dateLabel.replaceFirst('Today, ', 'today, ')}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    if (choice == 'discard') return true;
    if (choice == 'save') return _saveTrackingData();
    return false;
  }

  Future<void> _leave() async {
    if (await _resolveUnsavedChanges() && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _changeDate(int days) async {
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + days);
    if (target.isAfter(_dayOnly(DateTime.now()))) return;
    if (!await _resolveUnsavedChanges() || !mounted) return;
    setState(() {
      _selectedDate = target;
    });
    AppState().setSelectedDate(target);
    _loadTrackingData();
  }

  void _selectFeeling(int index) {
    setState(() {
      _selectedFeeling = index;
      _showFeelingError = false;
    });
  }

  Widget _buildFeelingButton(int index) {
    final selected = _selectedFeeling == index;
    final color = _feelingColors[index];
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: _feelingLabels[index],
      excludeSemantics: true,
      onTap: () => _selectFeeling(index),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectFeeling(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: selected
                    ? Border.all(color: color, width: 2)
                    : Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
              ),
              child: Center(
                child: Text(
                  _feelingEmojis[index],
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _feelingLabels[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.textColor : AppTheme.lightTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildLevelCard({
    required String title,
    required double value,
    required String lowLabel,
    required String highLabel,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${value.round()}/10',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          MergeSemantics(
            child: Semantics(
              label: title,
              child: Slider(
                value: value,
                min: 0,
                max: 10,
                divisions: 10,
                label: '${value.round()}',
                activeColor: color,
                semanticFormatterCallback: (v) => '${v.round()} out of 10',
                onChanged: onChanged,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lowLabel, style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor)),
              Text(highLabel, style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactorField({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String hint,
    required TextEditingController controller,
  }) {
    // One container per question so the field is announced with its question.
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Column(
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.fromLTRB(12, 52, 24, 24),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: _leave,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Daily Tracking',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Track how you feel, your bowel movements, pain and energy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content with scrolling
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                tooltip: 'Previous day',
                                onPressed: () => _changeDate(-1),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Text(
                                  _dateLabel,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Next day',
                                onPressed: _isToday ? null : () => _changeDate(1),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // How are you feeling?
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isToday ? 'How are you feeling today?' : 'How did you feel this day?',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < _feelingLabels.length; i++)
                                      Expanded(child: _buildFeelingButton(i)),
                                  ],
                                ),
                                if (_showFeelingError) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Choose how you\'re feeling to save this day',
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Bowel Movements
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bowel Movements',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      tooltip: 'Decrease bowel movements',
                                      onPressed: _bowelMovements > 0
                                          ? () => setState(() => _bowelMovements--)
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      _bowelMovements.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      tooltip: 'Increase bowel movements',
                                      onPressed: _bowelMovements < 99
                                          ? () => setState(() => _bowelMovements++)
                                          : null,
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLevelCard(
                            title: 'Pain level',
                            value: _painLevel,
                            lowLabel: 'No pain',
                            highLabel: 'Worst pain',
                            color: Colors.red.shade400,
                            onChanged: (v) => setState(() => _painLevel = v),
                          ),
                          const SizedBox(height: 24),
                          _buildLevelCard(
                            title: 'Energy level',
                            value: _energyLevel,
                            lowLabel: 'Exhausted',
                            highLabel: 'Full of energy',
                            color: AppTheme.primaryColor,
                            onChanged: (v) => setState(() => _energyLevel = v),
                          ),
                          const SizedBox(height: 24),
                          // What made you feel good/bad
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFactorField(
                                  icon: Icons.thumb_up_outlined,
                                  iconColor: Colors.green,
                                  title: 'What made you feel good?',
                                  hint: 'e.g., Ate light meals, got good sleep, took a walk...',
                                  controller: _feelGoodController,
                                ),
                                const SizedBox(height: 20),
                                _buildFactorField(
                                  icon: Icons.thumb_down_outlined,
                                  iconColor: Colors.red,
                                  title: 'What made you feel bad?',
                                  hint: 'e.g., Ate dairy, stressed at work, poor sleep...',
                                  controller: _feelBadController,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Notes
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Additional Notes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  textCapitalization: TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: 'Any other observations about your day...',
                                    hintStyle: TextStyle(color: Colors.grey.shade500),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveTrackingData,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
