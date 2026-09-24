import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/backend_service_provider.dart';

/// Foods offered as one-tap choices when logging meals and tagging foods.
const List<String> _commonFoods = [
  'Bread',
  'Pasta',
  'Rice',
  'Chicken',
  'Beef',
  'Fish',
  'Eggs',
  'Milk',
  'Cheese',
  'Yogurt',
  'Broccoli',
  'Spinach',
  'Carrots',
  'Tomatoes',
  'Apples',
  'Bananas',
  'Coffee',
  'Tea',
  'Chocolate',
  'Nuts',
];

List<String> _strings(Object? value) =>
    value is List ? value.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList() : <String>[];

bool _containsFood(List<String> list, String food) =>
    list.any((f) => f.toLowerCase() == food.toLowerCase());

class DietScreen extends StatefulWidget {
  const DietScreen({Key? key}) : super(key: key);

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  late DateTime _selectedDate = _initialDate();
  bool _isLoading = false;
  bool _isSaving = false;
  final List<Map<String, dynamic>> _meals = [];
  final List<String> _foodTriggers = [];
  final List<String> _safeFoods = [];

  /// Meals analysed from photos on Home (`meal` entries) for this day.
  List<Map<String, dynamic>> _photoMeals = const [];
  String _savedSignature = '';

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

  String _signature() => jsonEncode({
        'meals': _meals,
        'food_triggers': _foodTriggers,
        'safe_foods': _safeFoods,
      });

  bool get _hasUnsavedChanges => _signature() != _savedSignature;

  @override
  void initState() {
    super.initState();
    _savedSignature = _signature();
    _loadDietData();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static List<Map<String, dynamic>> _parseMeals(Object? value) {
    if (value is! List) return [];
    return [
      for (final meal in value)
        if (meal is Map)
          {
            'name': '${meal['name'] ?? 'Meal'}',
            'time': '${meal['time'] ?? ''}',
            'foods': _strings(meal['foods']),
          },
    ];
  }

  /// Triggers and safe foods belong to the person, not to one day, so they
  /// come from the diet entry that was saved most recently.
  static Map<String, dynamic>? _latestFoodLists(List<Map<String, dynamic>> history) {
    Map<String, dynamic>? latest;
    for (final entry in history) {
      if (!entry.containsKey('food_triggers') && !entry.containsKey('safe_foods')) continue;
      if (latest == null ||
          '${entry['recorded_at'] ?? ''}'.compareTo('${latest['recorded_at'] ?? ''}') > 0) {
        latest = entry;
      }
    }
    return latest;
  }

  Future<void> _loadDietData() async {
    final requestedDate = _dateKey;
    setState(() {
      _isLoading = true;
    });

    try {
      final backend = BackendServiceProvider.instance;
      final userId = backend.auth.currentUser?.id ?? '';
      final day = await backend.tracking.getTrackingData(
        userId: userId,
        date: requestedDate,
        type: 'diet',
      );
      final dietHistory = await backend.tracking.getTrackingHistory(
        userId: userId,
        type: 'diet',
        limit: 30,
      );
      final mealHistory = await backend.tracking.getTrackingHistory(
        userId: userId,
        type: 'meal',
        limit: 50,
      );
      // Ignore responses for a day the user has already moved away from.
      if (!mounted || requestedDate != _dateKey) return;

      final lists = _latestFoodLists(dietHistory) ?? day;
      final photoMeals = mealHistory.where((m) => m['date'] == requestedDate).toList()
        ..sort((a, b) => '${a['time'] ?? ''}'.compareTo('${b['time'] ?? ''}'));
      setState(() {
        _meals
          ..clear()
          ..addAll(_parseMeals(day?['meals']));
        _foodTriggers
          ..clear()
          ..addAll(_strings(lists?['food_triggers']));
        _safeFoods
          ..clear()
          ..addAll(_strings(lists?['safe_foods']));
        _photoMeals = photoMeals;
        _savedSignature = _signature();
      });
    } catch (e) {
      if (mounted && requestedDate == _dateKey) {
        _showSnack('Couldn\'t load your diet log. Please try again.');
      }
    } finally {
      if (mounted && requestedDate == _dateKey) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Saves the selected day's meals plus the trigger and safe-food lists.
  /// Returns true when stored.
  Future<bool> _saveDietData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await BackendServiceProvider.instance.tracking.trackEvent(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        type: 'diet',
        data: {
          'date': _dateKey,
          // Copies, so later edits on screen never leak into stored data.
          'meals': [
            for (final meal in _meals)
              {
                'name': meal['name'],
                'time': meal['time'],
                'foods': List<String>.from(meal['foods'] as List),
              },
          ],
          'food_triggers': List<String>.from(_foodTriggers),
          'safe_foods': List<String>.from(_safeFoods),
        },
      );
      if (!mounted) return true;
      setState(() => _savedSignature = _signature());
      _showSnack('Saved your diet log for ${_isToday ? 'today' : DateFormat('MMM d').format(_selectedDate)}');
      return true;
    } catch (e) {
      if (mounted) {
        _showSnack('Couldn\'t save your diet log. Please try again.');
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
        content: Text('You have unsaved diet changes for ${_dateLabel.replaceFirst('Today, ', 'today, ')}.'),
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
    if (choice == 'save') return _saveDietData();
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
    _loadDietData();
  }

  Future<void> _showAddMealDialog() async {
    final meal = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddMealDialog(
        time: _isToday ? DateFormat('HH:mm').format(DateTime.now()) : '',
      ),
    );
    if (meal == null || !mounted) return;
    setState(() {
      _meals.add(meal);
    });
  }

  Future<void> _showFoodTagDialog(bool isTrigger) async {
    final mealFoods = <String>[];
    for (final meal in [..._meals, ..._photoMeals]) {
      for (final food in _strings(meal['foods'])) {
        if (!_containsFood(mealFoods, food)) mealFoods.add(food);
      }
    }
    final foods = await showDialog<List<String>>(
      context: context,
      builder: (context) => _FoodTagDialog(
        isTrigger: isTrigger,
        alreadyAdded: isTrigger ? _foodTriggers : _safeFoods,
        suggestions: [
          ...mealFoods,
          ..._commonFoods.where((f) => !_containsFood(mealFoods, f)),
        ],
      ),
    );
    if (foods == null || foods.isEmpty || !mounted) return;

    final moved = <String>[];
    setState(() {
      final target = isTrigger ? _foodTriggers : _safeFoods;
      final other = isTrigger ? _safeFoods : _foodTriggers;
      for (final food in foods) {
        if (!_containsFood(target, food)) target.add(food);
        // A food can't be both a trigger and safe.
        final before = other.length;
        other.removeWhere((f) => f.toLowerCase() == food.toLowerCase());
        if (other.length != before) moved.add(food);
      }
    });
    if (moved.isNotEmpty) {
      _showSnack('${moved.join(', ')} moved to ${isTrigger ? 'food triggers' : 'safe foods'}');
    }
  }

  Color _foodColor(String food) {
    if (_containsFood(_foodTriggers, food)) return Colors.red.withValues(alpha: 0.3);
    if (_containsFood(_safeFoods, food)) return Colors.green.withValues(alpha: 0.3);
    return AppTheme.accentIndigo.withValues(alpha: 0.25);
  }

  Widget? _foodAvatar(String food) {
    if (_containsFood(_foodTriggers, food)) {
      return const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent);
    }
    if (_containsFood(_safeFoods, food)) {
      return const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent);
    }
    return null;
  }

  Widget _buildFoodChips(List<String> foods) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: foods
          .map((food) => Chip(
                label: Text(food, style: const TextStyle(color: Colors.white)),
                backgroundColor: _foodColor(food),
                side: BorderSide.none,
                avatar: _foodAvatar(food),
              ))
          .toList(),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final name = '${meal['name']}';
    final time = '${meal['time'] ?? ''}';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(color: AppTheme.lightTextColor),
                  ),
                IconButton(
                  tooltip: 'Remove $name',
                  icon: const Icon(Icons.delete_outline, color: AppTheme.lightTextColor),
                  onPressed: () {
                    setState(() {
                      _meals.remove(meal);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFoodChips(_strings(meal['foods'])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoMealCard(Map<String, dynamic> meal) {
    final description = '${meal['description'] ?? ''}';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined, size: 18, color: AppTheme.lightIndigo),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Meal from photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                Text(
                  '${meal['time'] ?? ''}',
                  style: const TextStyle(color: AppTheme.lightTextColor),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(color: AppTheme.lightTextColor)),
            ],
            const SizedBox(height: 12),
            _buildFoodChips(_strings(meal['foods'])),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection({
    required String title,
    required String addLabel,
    required String emptyText,
    required List<String> foods,
    required Color color,
    required String removeSuffix,
    required VoidCallback onAdd,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(addLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            foods.isEmpty
                ? Text(
                    emptyText,
                    style: const TextStyle(color: AppTheme.lightTextColor),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: foods.map((food) {
                      return Chip(
                        label: Text(food, style: const TextStyle(color: Colors.white)),
                        backgroundColor: color.withValues(alpha: 0.3),
                        side: BorderSide.none,
                        deleteIconColor: Colors.white,
                        deleteButtonTooltipMessage: 'Remove $food $removeSuffix',
                        onDeleted: () {
                          setState(() {
                            foods.remove(food);
                          });
                        },
                      );
                    }).toList(),
                  ),
          ],
        ),
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
                          'Diet Tracker',
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
                      'Log your meals and keep track of trigger and safe foods',
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
                          // Add meal button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showAddMealDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Meal'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Meals list
                          if (_meals.isNotEmpty || _photoMeals.isNotEmpty) ...[
                            Text(
                              _isToday ? 'Today\'s Meals' : 'Meals',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._meals.map(_buildMealCard),
                            ..._photoMeals.map(_buildPhotoMealCard),
                          ] else ...[
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Icon(
                                    Icons.restaurant_outlined,
                                    size: 64,
                                    color: AppTheme.lightTextColor.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No meals logged for this day',
                                    style: TextStyle(
                                      color: AppTheme.lightTextColor.withValues(alpha: 0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap "Add Meal" to log what you ate',
                                    style: TextStyle(
                                      color: AppTheme.lightTextColor.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildTagSection(
                            title: 'Food Triggers',
                            addLabel: 'Add trigger',
                            emptyText: 'No trigger foods yet. Add foods that seem to upset your gut.',
                            foods: _foodTriggers,
                            color: Colors.red,
                            removeSuffix: 'from triggers',
                            onAdd: () => _showFoodTagDialog(true),
                          ),
                          const SizedBox(height: 16),
                          _buildTagSection(
                            title: 'Safe Foods',
                            addLabel: 'Add safe food',
                            emptyText: 'No safe foods yet. Add foods you tolerate well.',
                            foods: _safeFoods,
                            color: Colors.green,
                            removeSuffix: 'from safe foods',
                            onAdd: () => _showFoodTagDialog(false),
                          ),
                          const SizedBox(height: 24),
                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveDietData,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Save diet log'),
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

/// Collects a meal name and its foods; pops with `{name, time, foods}`.
class _AddMealDialog extends StatefulWidget {
  final String time;

  const _AddMealDialog({required this.time});

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<_AddMealDialog> {
  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _foodController = TextEditingController();
  final List<String> _foods = [];
  String? _nameError;
  String? _foodsError;

  @override
  void dispose() {
    _nameController.dispose();
    _foodController.dispose();
    super.dispose();
  }

  void _addTypedFood() {
    final food = _foodController.text.trim();
    if (food.isEmpty) return;
    setState(() {
      if (!_containsFood(_foods, food)) _foods.add(food);
      _foodController.clear();
      _foodsError = null;
    });
  }

  void _toggleFood(String food, bool selected) {
    setState(() {
      if (selected) {
        if (!_containsFood(_foods, food)) _foods.add(food);
      } else {
        _foods.removeWhere((f) => f.toLowerCase() == food.toLowerCase());
      }
      _foodsError = null;
    });
  }

  void _submit() {
    // A food typed but not yet added with + still counts.
    _addTypedFood();
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Enter a meal name' : null;
      _foodsError = _foods.isEmpty ? 'Add at least one food' : null;
    });
    if (_nameError != null || _foodsError != null) return;
    Navigator.pop(context, <String, dynamic>{
      'name': name,
      'time': widget.time,
      'foods': List<String>.from(_foods),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Meal name',
                hintText: 'e.g., Breakfast, Lunch, Dinner',
                errorText: _nameError,
              ),
              // Rebuild so the meal-type chips follow what is typed.
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _mealTypes
                  .map((type) => ChoiceChip(
                        label: Text(type),
                        selected: _nameController.text.trim() == type,
                        onSelected: (_) {
                          setState(() {
                            _nameController.text = type;
                            _nameError = null;
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Foods',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _foodController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Add a food',
                      hintText: 'e.g., Toast, Eggs',
                    ),
                    onSubmitted: (_) => _addTypedFood(),
                  ),
                ),
                IconButton(
                  tooltip: 'Add food',
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.lightIndigo,
                  onPressed: _addTypedFood,
                ),
              ],
            ),
            if (_foods.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _foods.map((food) {
                  return Chip(
                    label: Text(food, style: const TextStyle(color: Colors.white)),
                    backgroundColor: AppTheme.accentIndigo.withValues(alpha: 0.35),
                    side: BorderSide.none,
                    deleteIconColor: Colors.white,
                    deleteButtonTooltipMessage: 'Remove $food',
                    onDeleted: () => _toggleFood(food, false),
                  );
                }).toList(),
              ),
            ],
            if (_foodsError != null) ...[
              const SizedBox(height: 8),
              Text(_foodsError!, style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            const Text(
              'Common foods',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonFoods.map((food) {
                return FilterChip(
                  label: Text(food),
                  selected: _containsFood(_foods, food),
                  onSelected: (selected) => _toggleFood(food, selected),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add Meal'),
        ),
      ],
    );
  }
}

/// Picks foods to add as triggers or safe foods; pops with the chosen names.
class _FoodTagDialog extends StatefulWidget {
  final bool isTrigger;
  final List<String> alreadyAdded;
  final List<String> suggestions;

  const _FoodTagDialog({
    required this.isTrigger,
    required this.alreadyAdded,
    required this.suggestions,
  });

  @override
  State<_FoodTagDialog> createState() => _FoodTagDialogState();
}

class _FoodTagDialogState extends State<_FoodTagDialog> {
  final TextEditingController _foodController = TextEditingController();
  final List<String> _selected = [];
  String? _error;

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }

  void _submit() {
    final typed = _foodController.text.trim();
    final foods = [
      if (typed.isNotEmpty) typed,
      ..._selected.where((f) => f.toLowerCase() != typed.toLowerCase()),
    ];
    if (foods.isEmpty) {
      setState(() => _error = 'Type a food or pick one below');
      return;
    }
    Navigator.pop(context, foods);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        (widget.isTrigger ? Colors.red : Colors.green).withValues(alpha: 0.35);
    return AlertDialog(
      title: Text(widget.isTrigger ? 'Add Food Trigger' : 'Add Safe Food'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _foodController,
              autofocus: false,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Food name',
                hintText: widget.isTrigger ? 'e.g., Dairy, Spicy food' : 'e.g., Rice, Chicken',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Or pick foods',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.suggestions.map((food) {
                final alreadyAdded = _containsFood(widget.alreadyAdded, food);
                return FilterChip(
                  label: Text(food),
                  selected: alreadyAdded || _selected.contains(food),
                  selectedColor: selectedColor,
                  onSelected: alreadyAdded
                      ? null
                      : (selected) {
                          setState(() {
                            _error = null;
                            if (selected) {
                              _selected.add(food);
                            } else {
                              _selected.remove(food);
                            }
                          });
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
