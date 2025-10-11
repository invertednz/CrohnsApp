import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const NotificationPreferencesScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final List<_NotificationTime> _times = [
    _NotificationTime(
      id: 'morning',
      title: 'Morning',
      subtitle: '7:00 AM - 11:00 AM',
      icon: Icons.wb_sunny,
      color: OnboardingTheme.warningAmber,
      description: 'Start your day with a gentle reminder',
    ),
    _NotificationTime(
      id: 'midday',
      title: 'Midday',
      subtitle: '11:00 AM - 2:00 PM',
      icon: Icons.light_mode,
      color: OnboardingTheme.healthGreen,
      description: 'Perfect for lunch tracking',
    ),
    _NotificationTime(
      id: 'afternoon',
      title: 'Afternoon',
      subtitle: '2:00 PM - 6:00 PM',
      icon: Icons.wb_twilight,
      color: OnboardingTheme.accentIndigo,
      description: 'Track your afternoon progress',
    ),
    _NotificationTime(
      id: 'evening',
      title: 'Evening',
      subtitle: '6:00 PM - 10:00 PM',
      icon: Icons.nightlight,
      color: OnboardingTheme.lightIndigo,
      description: 'End of day reflection',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      Text(
                        'Notification Preferences',
                        style: OnboardingTheme.headingTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'When would you like to receive reminders?',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Info card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: OnboardingTheme.cardDecoration(withShadow: true),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: OnboardingTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                                
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Stay on Track',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Choose one or more times for daily tracking reminders',
                                    style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Time options
                      ..._times.map((time) {
                        final isSelected = widget.controller.data.notificationTimes.contains(time.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                widget.controller.toggleNotificationTime(time.id);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? time.color
                                      : OnboardingTheme.accentIndigo.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? time.color.withOpacity(0.2)
                                          : OnboardingTheme.accentIndigo.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      time.icon,
                                      color: isSelected ? time.color : Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          time.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          time.subtitle,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected
                                                ? time.color
                                                : OnboardingTheme.lightIndigo,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          time.description,
                                          style: OnboardingTheme.bodyStyle.copyWith(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: time.color,
                                      size: 28,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // Skip option
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.accentIndigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: OnboardingTheme.lightIndigo,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can change these settings anytime in your profile',
                                style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Skip notifications
                        widget.controller.data.notificationTimes.clear();
                        widget.onNext();
                      },
                      style: OnboardingTheme.secondaryButtonStyle().copyWith(
                        padding: const MaterialStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: widget.controller.data.notificationTimes.isNotEmpty
                          ? widget.onNext
                          : null,
                      style: OnboardingTheme.primaryButtonStyle().copyWith(
                        padding: const MaterialStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      child: Text(
                        widget.controller.data.notificationTimes.isEmpty
                            ? 'Select at least one'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTime {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String description;
  
  _NotificationTime({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.description,
  });
}
