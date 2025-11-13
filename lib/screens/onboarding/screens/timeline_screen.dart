import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

class TimelineScreen extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const TimelineScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final trialStart = controller.data.trialStartDate ?? DateTime.now();
    final notificationDate = trialStart.add(const Duration(days: 5));
    final trialEnd = trialStart.add(const Duration(days: 7));
    
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
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      
                      Text(
                        'Your Trial Timeline',
                        style: OnboardingTheme.headingTextStyle(fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Here\'s what to expect',
                        style: OnboardingTheme.subheadingStyle,
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Timeline
                      _TimelineItem(
                        date: _formatDate(trialStart),
                        title: 'Trial Starts',
                        description: 'Full access to all premium features begins',
                        icon: Icons.play_circle_filled,
                        color: OnboardingTheme.healthGreen,
                        isFirst: true,
                      ),
                      
                      _TimelineConnector(),
                      
                      _TimelineItem(
                        date: _formatDate(notificationDate),
                        title: 'Reminder Notification',
                        description: 'We\'ll send you a friendly reminder that your trial is ending in 2 days',
                        icon: Icons.notifications_active,
                        color: OnboardingTheme.warningAmber,
                      ),
                      
                      _TimelineConnector(),
                      
                      _TimelineItem(
                        date: _formatDate(trialEnd),
                        title: 'Trial Ends',
                        description: 'Your subscription continues at \$49/year (or \$59 if you chose Pay It Forward)',
                        icon: Icons.event,
                        color: OnboardingTheme.accentIndigo,
                        isLast: true,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Info cards
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: OnboardingTheme.cardDecoration(withShadow: true),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: OnboardingTheme.lightIndigo,
                              size: 40,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Important Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              icon: Icons.cancel,
                              text: 'Cancel anytime before trial ends',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.credit_card_off,
                              text: 'No charges during the trial period',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.email,
                              text: 'Email reminders before billing',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.settings,
                              text: 'Manage subscription in settings',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Guarantee box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              OnboardingTheme.healthGreen.withOpacity(0.2),
                              OnboardingTheme.accentIndigo.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: OnboardingTheme.healthGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user,
                              color: OnboardingTheme.healthGreen,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Risk-Free Guarantee',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try it free for 7 days. Cancel anytime with no questions asked.',
                                    style: OnboardingTheme.bodyStyle.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                    padding: const MaterialStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _TimelineItem extends StatelessWidget {
  final String date;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isFirst;
  final bool isLast;
  
  const _TimelineItem({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 27),
        Container(
          width: 2,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                OnboardingTheme.accentIndigo.withOpacity(0.5),
                OnboardingTheme.accentIndigo.withOpacity(0.2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: OnboardingTheme.healthGreen,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
