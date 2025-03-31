import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crohns_companion/core/theme/app_theme.dart';
import 'package:crohns_companion/core/backend_service_provider.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({Key? key}) : super(key: key);

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  final List<Map<String, dynamic>> _meals = [];
  final List<String> _foodTriggers = [];
  final List<String> _safeFoods = [];
  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _foodItemController = TextEditingController();
  final List<String> _mealFoods = [];
  final List<String> _commonFoods = [
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

  @override
  void initState() {
    super.initState();
    _loadDietData();
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _foodItemController.dispose();
    super.dispose();
  }

  Future<void> _loadDietData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      final data = await trackingService.getTrackingData(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        type: 'diet',
      );

      if (data != null && data.isNotEmpty) {
        setState(() {
          if (data['meals'] != null) {
            _meals.clear();
            _meals.addAll(List<Map<String, dynamic>>.from(data['meals']));
          }

          if (data['food_triggers'] != null) {
            _foodTriggers.clear();
            _foodTriggers.addAll(List<String>.from(data['food_triggers']));
          }

          if (data['safe_foods'] != null) {
            _safeFoods.clear();
            _safeFoods.addAll(List<String>.from(data['safe_foods']));
          }
        });
      } else {
        // Reset to defaults if no data
        setState(() {
          _meals.clear();
          // We don't clear triggers and safe foods as they should persist
        });
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load diet data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDietData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      await trackingService.trackEvent(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        type: 'diet',
        data: {
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'meals': _meals,
          'food_triggers': _foodTriggers,
          'safe_foods': _safeFoods,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diet data saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save diet data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadDietData();
  }

  void _showAddMealDialog() {
    _mealNameController.clear();
    _mealFoods.clear();
    _foodItemController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Meal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _mealNameController,
                    decoration: const InputDecoration(
                      labelText: 'Meal Name',
                      hintText: 'e.g., Breakfast, Lunch, Dinner',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Food Items',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _foodItemController,
                          decoration: const InputDecoration(
                            labelText: 'Food Item',
                            hintText: 'e.g., Bread, Eggs, etc.',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          if (_foodItemController.text.isNotEmpty) {
                            setDialogState(() {
                              _mealFoods.add(_foodItemController.text.trim());
                              _foodItemController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Common Foods',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonFoods.map((food) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            if (!_mealFoods.contains(food)) {
                              _mealFoods.add(food);
                            }
                          });
                        },
                        child: Chip(
                          label: Text(food),
                          backgroundColor: AppTheme.neutralColor,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_mealFoods.isNotEmpty) ...[                    
                    const Text(
                      'Selected Foods',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _mealFoods.map((food) {
                        return Chip(
                          label: Text(food),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                          deleteIconColor: AppTheme.primaryColor,
                          onDeleted: () {
                            setDialogState(() {
                              _mealFoods.remove(food);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_mealNameController.text.isNotEmpty && _mealFoods.isNotEmpty) {
                    setState(() {
                      _meals.add({
                        'name': _mealNameController.text.trim(),
                        'time': DateFormat('HH:mm').format(DateTime.now()),
                        'foods': List<String>.from(_mealFoods),
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Meal'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFoodTagDialog(bool isTrigger) {
    _foodItemController.clear();
    final List<String> selectedFoods = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isTrigger ? 'Add Food Trigger' : 'Add Safe Food'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _foodItemController,
                    decoration: InputDecoration(
                      labelText: 'Food Item',
                      hintText: isTrigger
                          ? 'e.g., Dairy, Spicy food, etc.'
                          : 'e.g., Rice, Chicken, etc.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Common Foods',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonFoods.map((food) {
                      final bool isAlreadyAdded = isTrigger
                          ? _foodTriggers.contains(food)
                          : _safeFoods.contains(food);
                      final bool isSelected = selectedFoods.contains(food);

                      return FilterChip(
                        label: Text(food),
                        selected: isSelected,
                        backgroundColor: isAlreadyAdded
                            ? AppTheme.lightTextColor.withOpacity(0.2)
                            : AppTheme.neutralColor,
                        selectedColor: isTrigger
                            ? Colors.red.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        onSelected: isAlreadyAdded
                            ? null
                            : (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedFoods.add(food);
                                  } else {
                                    selectedFoods.remove(food);
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
                onPressed: () {
                  setState(() {
                    if (_foodItemController.text.isNotEmpty) {
                      final String newFood = _foodItemController.text.trim();
                      if (isTrigger) {
                        if (!_foodTriggers.contains(newFood)) {
                          _foodTriggers.add(newFood);
                        }
                      } else {
                        if (!_safeFoods.contains(newFood)) {
                          _safeFoods.add(newFood);
                        }
                      }
                    }

                    for (final food in selectedFoods) {
                      if (isTrigger) {
                        if (!_foodTriggers.contains(food)) {
                          _foodTriggers.add(food);
                        }
                      } else {
                        if (!_safeFoods.contains(food)) {
                          _safeFoods.add(food);
                        }
                      }
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Diet Tracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track your meals and identify food triggers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
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
                              onPressed: () => _changeDate(-1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              _selectedDate.day == DateTime.now().day &&
                                      _selectedDate.month == DateTime.now().month &&
                                      _selectedDate.year == DateTime.now().year
                                  ? 'Today, ${DateFormat('MMM d').format(_selectedDate)}'
                                  : DateFormat('EEEE, MMM d').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _changeDate(1),
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
                        if (_meals.isNotEmpty) ...[                          
                          const Text(
                            'Today\'s Meals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._meals.map((meal) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          meal['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          meal['time'],
                                          style: const TextStyle(
                                            color: AppTheme.lightTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (meal['foods'] as List).map<Widget>((food) {
                                        final bool isTrigger = _foodTriggers.contains(food);
                                        final bool isSafe = _safeFoods.contains(food);

                                        return Chip(
                                          label: Text(food),
                                          backgroundColor: isTrigger
                                              ? Colors.red.withOpacity(0.2)
                                              : isSafe
                                                  ? Colors.green.withOpacity(0.2)
                                                  : AppTheme.neutralColor,
                                          avatar: isTrigger
                                              ? const Icon(Icons.warning, size: 16, color: Colors.red)
                                              : isSafe
                                                  ? const Icon(Icons.check_circle, size: 16, color: Colors.green)
                                                  : null,
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _meals.remove(meal);
                                            });
                                          },
                                          icon: const Icon(Icons.delete_outline, size: 16),
                                          label: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ] else ...[                          
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                Icon(
                                  Icons.restaurant_outlined,
                                  size: 64,
                                  color: AppTheme.lightTextColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No meals recorded for this day',
                                  style: TextStyle(
                                    color: AppTheme.lightTextColor.withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the "Add Meal" button to start tracking',
                                  style: TextStyle(
                                    color: AppTheme.lightTextColor.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Food triggers section
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Food Triggers',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showFoodTagDialog(true),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _foodTriggers.isEmpty
                                    ? const Text(
                                        'No food triggers identified yet',
                                        style: TextStyle(
                                          color: AppTheme.lightTextColor,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _foodTriggers.map((food) {
                                          return Chip(
                                            label: Text(food),
                                            backgroundColor: Colors.red.withOpacity(0.2),
                                            deleteIconColor: Colors.red,
                                            onDeleted: () {
                                              setState(() {
                                                _foodTriggers.remove(food);
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Safe foods section
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Safe Foods',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showFoodTagDialog(false),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _safeFoods.isEmpty
                                    ? const Text(
                                        'No safe foods identified yet',
                                        style: TextStyle(
                                          color: AppTheme.lightTextColor,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _safeFoods.map((food) {
                                          return Chip(
                                            label: Text(food),
                                            backgroundColor: Colors.green.withOpacity(0.2),
                                            deleteIconColor: Colors.green,
                                            onDeleted: () {
                                              setState(() {
                                                _safeFoods.remove(food);
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                              ],
                            ),
                          ),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Save Diet Data'),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}