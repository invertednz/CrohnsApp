import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';

class TimelineScreen extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onComparePlans;

  const TimelineScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
    required this.onComparePlans,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final trialEnds = DateFormat('EEEE, MMMM d').format(controller.trialEndDate);
    final plan = controller.selectedPlan;
    return Container(
      decoration: const BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      
                      // Title
                      Semantics(
                        header: true,
                        child: const Text(
                          'GutMD',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'How your free trial works',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Timeline items
                    const _TimelineStep(
                      icon: Icons.play_arrow,
                      iconColor: Colors.white,
                      iconBgColor: OnboardingTheme.ctaGreen,
                      title: 'Today',
                      description: 'Full access to GutMD. No payment details needed.',
                      showConnector: true,
                    ),

                    const _TimelineStep(
                      icon: Icons.insights,
                      iconColor: Colors.white,
                      iconBgColor: OnboardingTheme.warningAmber,
                      title: 'During your trial',
                      description: 'Log symptoms, meals and medications and see what the AI finds in your patterns.',
                      showConnector: true,
                    ),

                    _TimelineStep(
                      icon: Icons.flag,
                      iconColor: Colors.white,
                      iconBgColor: OnboardingTheme.accentIndigo,
                      title: 'In $kTrialDays days',
                      description: 'Your trial ends on $trialEnds. Choose a plan to keep full access - you are never charged automatically.',
                      showConnector: false,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Plan card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: OnboardingTheme.accentIndigo.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Free trial badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: OnboardingTheme.healthGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'FREE TRIAL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: OnboardingTheme.healthGreen,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Plan info row
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: OnboardingTheme.lightIndigo,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_arrow,
                                    size: 14,
                                    color: OnboardingTheme.lightIndigo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Try it free',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'No commitment. Cancel anytime',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'then ${plan.priceLabel}${plan.period}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: OnboardingTheme.lightIndigo,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Try for FREE button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OnboardingTheme.ctaGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Try for FREE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Compare plans button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onComparePlans,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Compare plans',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;
  final bool showConnector;
  
  const _TimelineStep({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon and connector
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 50,
                color: Colors.white.withOpacity(0.2),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                if (showConnector) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
