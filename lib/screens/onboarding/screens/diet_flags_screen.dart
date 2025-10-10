import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

class DietFlagsScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const DietFlagsScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<DietFlagsScreen> createState() => _DietFlagsScreenState();
}

class _DietFlagsScreenState extends State<DietFlagsScreen> {
  final TextEditingController _customController = TextEditingController();
  
  final List<String> _commonDietFlags = [
    'Dairy',
    'Gluten',
    'Lactose',
    'Spicy Foods',
    'High Fiber',
    'Caffeine',
    'Alcohol',
    'Artificial Sweeteners',
    'Red Meat',
    'Fried Foods',
    'Raw Vegetables',
    'Nuts & Seeds',
  ];
  
  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

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
                        'Diet Considerations',
                        style: OnboardingTheme.neonTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Select foods or ingredients that affect you',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Common diet flags
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _commonDietFlags.map((flag) {
                          final isSelected = widget.controller.data.dietFlags.contains(flag);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                widget.controller.toggleDietFlag(flag);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? OnboardingTheme.accentIndigo
                                    : Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? OnboardingTheme.accentIndigo
                                      : OnboardingTheme.accentIndigo.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? OnboardingTheme.neonGlow() : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  Text(
                                    flag,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Custom diet flag input
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: OnboardingTheme.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Custom Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: OnboardingTheme.inputDecoration(
                                      label: 'Food or ingredient',
                                      hint: 'e.g., Tomatoes',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_customController.text.trim().isNotEmpty) {
                                      setState(() {
                                        widget.controller.addDietFlag(_customController.text.trim());
                                        _customController.clear();
                                      });
                                    }
                                  },
                                  style: OnboardingTheme.primaryButtonStyle(),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Selected items
                      if (widget.controller.data.dietFlags.isNotEmpty) ...[
                        const Text(
                          'Selected Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: OnboardingTheme.cardDecoration(),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.controller.data.dietFlags.map((flag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: OnboardingTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      flag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          widget.controller.removeDietFlag(flag);
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.accentIndigo.withOpacity(0.15),
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
                                'You can always update these later in settings',
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
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onNext,
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
}
