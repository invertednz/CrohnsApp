/// This file demonstrates how to use the FirebaseService data provider
/// in your screens and widgets. The same code works for both mock and Firebase modes.

import 'package:flutter/material.dart';
import 'firebase_service.dart';

class DataProviderUsageExample extends StatefulWidget {
  const DataProviderUsageExample({Key? key}) : super(key: key);

  @override
  State<DataProviderUsageExample> createState() =>
      _DataProviderUsageExampleState();
}

class _DataProviderUsageExampleState extends State<DataProviderUsageExample> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _healthData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Example: Loading user data on screen init
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final dataProvider = FirebaseService.dataProvider;
      final userId = dataProvider.getCurrentUserId();

      if (userId != null) {
        // Load user profile
        final profile = await dataProvider.getUserProfile(userId);

        // Load health data for the last 30 days
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 30));
        final healthData = await dataProvider.getHealthData(
          userId,
          startDate: startDate,
          endDate: endDate,
        );

        setState(() {
          _userProfile = profile;
          _healthData = healthData;
        });
      }
    } catch (error) {
      debugPrint('Error loading data: $error');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Example: Saving health tracking data
  Future<void> _saveHealthEntry() async {
    try {
      final dataProvider = FirebaseService.dataProvider;
      final userId = dataProvider.getCurrentUserId();

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await dataProvider.saveHealthData(userId, {
        'date': DateTime.now(),
        'symptomSeverity': 4,
        'notes': 'Mild discomfort after breakfast',
        'meals': ['Toast', 'Coffee'],
        'createdAt': DateTime.now(),
      });

      // Reload data to show the new entry
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health entry saved!')),
        );
      }
    } catch (error) {
      debugPrint('Error saving health data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $error')),
        );
      }
    }
  }

  /// Example: Updating user profile
  Future<void> _updateProfile() async {
    try {
      final dataProvider = FirebaseService.dataProvider;
      final userId = dataProvider.getCurrentUserId();

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await dataProvider.updateUserProfile(userId, {
        'name': 'Updated Name',
        'age': 31,
        'lastUpdated': DateTime.now(),
      });

      // Reload data to show updates
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (error) {
      debugPrint('Error updating profile: $error');
    }
  }

  /// Example: Updating notification preferences
  Future<void> _updateNotifications(bool enabled) async {
    try {
      final dataProvider = FirebaseService.dataProvider;
      final userId = dataProvider.getCurrentUserId();

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await dataProvider.updateNotificationPreferences(userId, {
        'morningReminder': enabled,
        'morningTime': '09:00',
        'eveningReminder': enabled,
        'eveningTime': '21:00',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifications ${enabled ? "enabled" : "disabled"}'),
          ),
        );
      }
    } catch (error) {
      debugPrint('Error updating notifications: $error');
    }
  }

  /// Example: User authentication
  Future<void> _signIn(String email, String password) async {
    try {
      final dataProvider = FirebaseService.dataProvider;
      final userId = await dataProvider.signIn(email, password);

      if (userId != null) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed in successfully!')),
          );
        }
      } else {
        throw Exception('Invalid credentials');
      }
    } catch (error) {
      debugPrint('Sign in error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $error')),
        );
      }
    }
  }

  /// Example: Sign out
  Future<void> _signOut() async {
    try {
      final dataProvider = FirebaseService.dataProvider;
      await dataProvider.signOut();

      setState(() {
        _userProfile = null;
        _healthData = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      }
    } catch (error) {
      debugPrint('Sign out error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          FirebaseService.isUsingMock
              ? 'Mock Data Mode'
              : 'Firebase Mode',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User profile section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Profile',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${_userProfile?['name'] ?? 'N/A'}'),
                          Text('Email: ${_userProfile?['email'] ?? 'N/A'}'),
                          Text('Age: ${_userProfile?['age'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _updateProfile,
                            child: const Text('Update Profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Health data section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health Entries (${_healthData.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          if (_healthData.isEmpty)
                            const Text('No health data yet')
                          else
                            ..._healthData.map((entry) => ListTile(
                                  title: Text(entry['notes'] ?? 'No notes'),
                                  subtitle: Text(
                                    'Severity: ${entry['symptomSeverity']}/10',
                                  ),
                                  trailing: Text(
                                    entry['date'].toString().substring(0, 10),
                                  ),
                                )),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _saveHealthEntry,
                            child: const Text('Add Health Entry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notification settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Enable Reminders'),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () => _updateNotifications(true),
                                child: const Text('Enable'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _updateNotifications(false),
                                child: const Text('Disable'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
