import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crohns_companion/core/theme/app_theme.dart';
import 'package:crohns_companion/core/backend_service_provider.dart';

class SupplementsScreen extends StatefulWidget {
  const SupplementsScreen({Key? key}) : super(key: key);

  @override
  State<SupplementsScreen> createState() => _SupplementsScreenState();
}

class _SupplementsScreenState extends State<SupplementsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  final List<Map<String, dynamic>> _supplements = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final List<String> _timeOptions = ['Morning', 'Afternoon', 'Evening', 'Bedtime'];
  String _selectedTime = 'Morning';
  final List<String> _commonSupplements = [
    'Vitamin D',
    'Vitamin B12',
    'Iron',
    'Calcium',
    'Zinc',
    'Folic Acid',
    'Probiotics',
    'Omega-3',
    'Multivitamin',
    'Magnesium',
  ];

  @override
  void initState() {
    super.initState();
    _loadSupplementsData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _loadSupplementsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      final data = await trackingService.getTrackingData(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        type: 'supplements',
      );

      if (data != null && data.isNotEmpty && data['supplements'] != null) {
        setState(() {
          _supplements.clear();
          _supplements.addAll(List<Map<String, dynamic>>.from(data['supplements']));
        });
      } else {
        // Reset to defaults if no data
        setState(() {
          _supplements.clear();
        });
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load supplements data: ${e.toString()}')),
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

  Future<void> _saveSupplementsData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      await trackingService.trackEvent(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        type: 'supplements',
        data: {
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'supplements': _supplements,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplements data saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save supplements data: ${e.toString()}')),
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
    _loadSupplementsData();
  }

  void _showAddSupplementDialog() {
    _nameController.clear();
    _dosageController.clear();
    _selectedTime = 'Morning';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Supplement'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Supplement Name',
                      hintText: 'e.g., Vitamin D, Iron, etc.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: 'e.g., 1000 IU, 500 mg, etc.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Time of Day',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeOptions.map((time) {
                      return ChoiceChip(
                        label: Text(time),
                        selected: _selectedTime == time,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedTime = time;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Common Supplements',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonSupplements.map((supplement) {
                      return ActionChip(
                        label: Text(supplement),
                        backgroundColor: AppTheme.neutralColor,
                        onPressed: () {
                          setDialogState(() {
                            _nameController.text = supplement;
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
                  if (_nameController.text.isNotEmpty) {
                    setState(() {
                      _supplements.add({
                        'name': _nameController.text.trim(),
                        'dosage': _dosageController.text.trim(),
                        'time': _selectedTime,
                        'taken': false,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleTaken(int index) {
    setState(() {
      _supplements[index]['taken'] = !_supplements[index]['taken'];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group supplements by time of day
    final Map<String, List<Map<String, dynamic>>> groupedSupplements = {};
    for (final time in _timeOptions) {
      groupedSupplements[time] = [];
    }

    for (final supplement in _supplements) {
      final time = supplement['time'] as String;
      if (groupedSupplements.containsKey(time)) {
        groupedSupplements[time]!.add(supplement);
      }
    }

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
                      'Supplements Tracker',
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
                  'Track your supplements and medications',
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
                        // Add supplement button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showAddSupplementDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Supplement'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Supplements list grouped by time of day
                        if (_supplements.isEmpty) ...[                          
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                Icon(
                                  Icons.medication_outlined,
                                  size: 64,
                                  color: AppTheme.lightTextColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No supplements recorded for this day',
                                  style: TextStyle(
                                    color: AppTheme.lightTextColor.withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the "Add Supplement" button to start tracking',
                                  style: TextStyle(
                                    color: AppTheme.lightTextColor.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[                          
                          for (final time in _timeOptions) ...[                            
                            if (groupedSupplements[time]!.isNotEmpty) ...[                              
                              Row(
                                children: [
                                  Icon(
                                    _getTimeIcon(time),
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...groupedSupplements[time]!.asMap().entries.map((entry) {
                                final index = _supplements.indexOf(entry.value);
                                final supplement = entry.value;
                                final bool isTaken = supplement['taken'] ?? false;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Checkbox(
                                      value: isTaken,
                                      activeColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (_) => _toggleTaken(index),
                                    ),
                                    title: Text(
                                      supplement['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        decoration: isTaken
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isTaken
                                            ? AppTheme.lightTextColor
                                            : null,
                                      ),
                                    ),
                                    subtitle: supplement['dosage'] != null &&
                                            supplement['dosage'].isNotEmpty
                                        ? Text(
                                            supplement['dosage'],
                                            style: TextStyle(
                                              color: AppTheme.lightTextColor,
                                              decoration: isTaken
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          )
                                        : null,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: AppTheme.lightTextColor,
                                      onPressed: () {
                                        setState(() {
                                          _supplements.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ],
                        // Save button
                        if (_supplements.isNotEmpty) ...[                          
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveSupplementsData,
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
                                  : const Text('Save Supplements'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getTimeIcon(String time) {
    switch (time) {
      case 'Morning':
        return Icons.wb_sunny_outlined;
      case 'Afternoon':
        return Icons.wb_twighlight;
      case 'Evening':
        return Icons.nights_stay_outlined;
      case 'Bedtime':
        return Icons.bedtime_outlined;
      default:
        return Icons.access_time;
    }
  }
}