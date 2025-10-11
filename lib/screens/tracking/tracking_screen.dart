import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crohns_companion/core/theme/app_theme.dart';
import 'package:crohns_companion/core/backend_service_provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedFeeling = 2; // Default to 'Good' (index 2)
  int _bowelMovements = 0;
  double _painLevel = 0;
  double _energyLevel = 5;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      final data = await trackingService.getTrackingData(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        type: 'daily',
      );

      if (data != null && data.isNotEmpty) {
        setState(() {
          _selectedFeeling = data['feeling'] ?? 2;
          _bowelMovements = data['bowel_movements'] ?? 0;
          _painLevel = (data['pain_level'] ?? 0).toDouble();
          _energyLevel = (data['energy_level'] ?? 5).toDouble();
        });
      } else {
        // Reset to defaults if no data
        setState(() {
          _selectedFeeling = 2;
          _bowelMovements = 0;
          _painLevel = 0;
          _energyLevel = 5;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tracking data: ${e.toString()}')),
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

  Future<void> _saveTrackingData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final trackingService = BackendServiceProvider.instance.tracking;
      await trackingService.trackEvent(
        userId: BackendServiceProvider.instance.auth.currentUser?.id ?? '',
        type: 'daily',
        data: {
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'feeling': _selectedFeeling,
          'bowel_movements': _bowelMovements,
          'pain_level': _painLevel,
          'energy_level': _energyLevel,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tracking data saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save tracking data: ${e.toString()}')),
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
    _loadTrackingData();
  }

  Widget _buildFeelingButton(int index, String emoji) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeeling = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _selectedFeeling == index 
              ? AppTheme.accentIndigo.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: _selectedFeeling == index
              ? Border.all(color: AppTheme.accentIndigo, width: 2)
              : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
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
                      'Daily Tracking',
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
                  'Track your bowel movements and daily feelings',
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
                        // How are you feeling today?
                        Card(
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'How are you feeling today?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildFeelingButton(0, '😞'),
                                    _buildFeelingButton(1, '😐'),
                                    _buildFeelingButton(2, '🙂'),
                                    _buildFeelingButton(3, '😊'),
                                    _buildFeelingButton(4, '🤗'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Bowel Movements
                        Card(
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
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
                                      onPressed: () {
                                        if (_bowelMovements > 0) {
                                          setState(() {
                                            _bowelMovements--;
                                          });
                                        }
                                      },
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
                                      onPressed: () {
                                        setState(() {
                                          _bowelMovements++;
                                        });
                                      },
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}