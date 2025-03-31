import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crohns_companion/core/theme/app_theme.dart';
import 'package:crohns_companion/core/backend_service_provider.dart';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({Key? key}) : super(key: key);

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  final List<String> _commonSymptoms = [
    'Abdominal Pain',
    'Diarrhea',
    'Fatigue',
    'Nausea',
    'Bloating',
    'Joint Pain',
    'Fever',
    'Weight Loss',
    'Mouth Sores',
    'Skin Issues',
  ];
  final List<String> _selectedSymptoms = [];
  final Map<String, int> _symptomSeverity = {};
  final List<Map<String, dynamic>> _activeSymptoms = [];
  final List<Map<String, dynamic>> _symptomHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSymptomData();
  }

  Future<void> _loadSymptomData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      final data = await trackingService.getTrackingData(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        type: 'symptoms',
      );

      if (data != null && data.isNotEmpty) {
        setState(() {
          if (data['active_symptoms'] != null) {
            _activeSymptoms.clear();
            for (var symptom in data['active_symptoms']) {
              _activeSymptoms.add(symptom);
              _selectedSymptoms.add(symptom['name']);
              _symptomSeverity[symptom['name']] = symptom['severity'];
            }
          }

          if (data['symptom_history'] != null) {
            _symptomHistory.clear();
            _symptomHistory.addAll(List<Map<String, dynamic>>.from(data['symptom_history']));
          }
        });
      } else {
        // Reset to defaults if no data
        setState(() {
          _selectedSymptoms.clear();
          _symptomSeverity.clear();
          _activeSymptoms.clear();
          // We don't clear history as it should persist
        });
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load symptom data: ${e.toString()}')),
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

  Future<void> _saveSymptomData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      
      // Prepare active symptoms data
      final List<Map<String, dynamic>> activeSymptoms = [];
      for (var symptom in _selectedSymptoms) {
        activeSymptoms.add({
          'name': symptom,
          'severity': _symptomSeverity[symptom] ?? 1,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        });
      }

      await trackingService.trackEvent(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        type: 'symptoms',
        data: {
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'active_symptoms': activeSymptoms,
        },
      );

      // Update local active symptoms list
      setState(() {
        _activeSymptoms.clear();
        _activeSymptoms.addAll(activeSymptoms);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Symptom data saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save symptom data: ${e.toString()}')),
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
    _loadSymptomData();
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
        _symptomSeverity.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
        _symptomSeverity[symptom] = 1; // Default severity
      }
    });
  }

  void _updateSeverity(String symptom, int severity) {
    setState(() {
      _symptomSeverity[symptom] = severity;
    });
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
                      'Symptoms Tracker',
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
                  'Track and monitor your Crohn\'s symptoms',
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
                        // Common symptoms
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Common Symptoms',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _commonSymptoms.map((symptom) {
                                    final isSelected = _selectedSymptoms.contains(symptom);
                                    return GestureDetector(
                                      onTap: () => _toggleSymptom(symptom),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.neutralColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          symptom,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Active symptoms
                        if (_selectedSymptoms.isNotEmpty) ...[                          
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Symptoms',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._selectedSymptoms.map((symptom) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              symptom,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Severity: ${_symptomSeverity[symptom] ?? 1}/5',
                                              style: const TextStyle(
                                                color: AppTheme.lightTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Expanded(
                                              child: GestureDetector(
                                                onTap: () => _updateSeverity(symptom, index + 1),
                                                child: Container(
                                                  height: 24,
                                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                                  decoration: BoxDecoration(
                                                    color: index < (_symptomSeverity[symptom] ?? 1)
                                                        ? _getSeverityColor(index + 1)
                                                        : AppTheme.neutralColor,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Symptom history
                        if (_symptomHistory.isNotEmpty) ...[                          
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Symptom History',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._symptomHistory.map((entry) {
                                    final date = DateTime.parse(entry['date']);
                                    final formattedDate = DateFormat('MMM d, yyyy').format(date);
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: (entry['symptoms'] as List).map((symptom) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getSeverityColor(symptom['severity']),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                symptom['name'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const Divider(height: 32),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedSymptoms.isEmpty || _isSaving
                                ? null
                                : _saveSymptomData,
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
                                : const Text('Save Symptoms'),
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

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}