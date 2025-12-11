import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

class ComparePlansScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onSelectPlan;
  final VoidCallback onBack;
  
  const ComparePlansScreen({
    Key? key,
    required this.controller,
    required this.onSelectPlan,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ComparePlansScreen> createState() => _ComparePlansScreenState();
}

class _ComparePlansScreenState extends State<ComparePlansScreen> {
  String _selectedPlan = 'annual';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Compare Plans',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Annual Plan (Recommended)
                    _PlanCard(
                      title: 'Annual',
                      price: '\$49',
                      period: '/year',
                      savings: 'Save 60%',
                      description: 'Best value for long-term tracking',
                      features: const [
                        'Unlimited symptom tracking',
                        'AI-powered insights',
                        'Diet & meal logging',
                        '24/7 AI health assistant',
                        'Cloud backup & sync',
                        'Smart reminders',
                      ],
                      isSelected: _selectedPlan == 'annual',
                      isRecommended: true,
                      onTap: () {
                        setState(() {
                          _selectedPlan = 'annual';
                        });
                        widget.controller.data.selectedPlan = 'annual';
                        widget.controller.data.planPrice = 49;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Monthly Plan
                    _PlanCard(
                      title: 'Monthly',
                      price: '\$9.99',
                      period: '/month',
                      savings: null,
                      description: 'Flexible month-to-month billing',
                      features: const [
                        'Unlimited symptom tracking',
                        'AI-powered insights',
                        'Diet & meal logging',
                        '24/7 AI health assistant',
                        'Cloud backup & sync',
                        'Smart reminders',
                      ],
                      isSelected: _selectedPlan == 'monthly',
                      isRecommended: false,
                      onTap: () {
                        setState(() {
                          _selectedPlan = 'monthly';
                        });
                        widget.controller.data.selectedPlan = 'monthly';
                        widget.controller.data.planPrice = 9.99;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pay It Forward Plan
                    _PlanCard(
                      title: 'Pay It Forward',
                      price: '\$59',
                      period: '/year',
                      savings: 'Help Others',
                      savingsColor: OnboardingTheme.healthGreen,
                      description: 'Your extra \$10 sponsors someone in need',
                      features: const [
                        'Everything in Annual',
                        'Sponsor a user in need',
                        'Pay It Forward badge',
                        'Priority support',
                      ],
                      isSelected: _selectedPlan == 'payitforward',
                      isRecommended: false,
                      onTap: () {
                        setState(() {
                          _selectedPlan = 'payitforward';
                        });
                        widget.controller.data.selectedPlan = 'annual';
                        widget.controller.data.isPayItForward = true;
                        widget.controller.data.planPrice = 59;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Features comparison note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: OnboardingTheme.accentIndigo.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: OnboardingTheme.accentIndigo.withOpacity(0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All plans include a 7-day free trial. Cancel anytime.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
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
            
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onSelectPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OnboardingTheme.accentIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue with ${_selectedPlan == 'annual' ? 'Annual' : _selectedPlan == 'monthly' ? 'Monthly' : 'Pay It Forward'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? savings;
  final Color? savingsColor;
  final String description;
  final List<String> features;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;
  
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.savings,
    this.savingsColor,
    required this.description,
    required this.features,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? OnboardingTheme.accentIndigo.withOpacity(0.05) 
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? OnboardingTheme.accentIndigo 
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: OnboardingTheme.accentIndigo.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? OnboardingTheme.accentIndigo 
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? OnboardingTheme.accentIndigo 
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                        ? OnboardingTheme.accentIndigo 
                        : const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                if (savings != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (savingsColor ?? OnboardingTheme.warningAmber).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      savings!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: savingsColor ?? OnboardingTheme.warningAmber,
                      ),
                    ),
                  ),
                if (isRecommended && savings == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: OnboardingTheme.accentIndigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: OnboardingTheme.accentIndigo,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            if (isSelected) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              // Features
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: OnboardingTheme.healthGreen,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
