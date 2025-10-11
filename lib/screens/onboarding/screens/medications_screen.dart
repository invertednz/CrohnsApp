import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';

class MedicationsScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const MedicationsScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final TextEditingController _customController = TextEditingController();
  
  final List<_MedicationOption> _commonMedications = [
    _MedicationOption(
      name: 'Mesalamine',
      category: 'Anti-inflammatory',
      icon: Icons.medication,
    ),
    _MedicationOption(
      name: 'Prednisone',
      category: 'Corticosteroid',
      icon: Icons.medication,
    ),
    _MedicationOption(
      name: 'Azathioprine',
      category: 'Immunosuppressant',
      icon: Icons.medication,
    ),
    _MedicationOption(
      name: 'Infliximab',
      category: 'Biologic',
      icon: Icons.medication,
    ),
    _MedicationOption(
      name: 'Adalimumab',
      category: 'Biologic',
      icon: Icons.medication,
    ),
    _MedicationOption(
      name: 'Budesonide',
      category: 'Corticosteroid',
      icon: Icons.medication,
    ),
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
                        'Current Medications',
                        style: OnboardingTheme.headingTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Track medications you\'re currently taking',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Common medications
                      const Text(
                        'Common IBD Medications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ..._commonMedications.map((med) {
                        final isSelected = widget.controller.data.medications.contains(med.name);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                widget.controller.toggleMedication(med.name);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? OnboardingTheme.accentIndigo
                                      : OnboardingTheme.accentIndigo.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? OnboardingTheme.accentGradient
                                          : null,
                                      color: isSelected
                                          ? null
                                          : OnboardingTheme.accentIndigo.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      med.icon,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          med.category,
                                          style: OnboardingTheme.bodyStyle.copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: OnboardingTheme.healthGreen,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // Custom medication input
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: OnboardingTheme.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Other Medication',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customController,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: OnboardingTheme.inputDecoration(
                                      label: 'Medication name',
                                      hint: 'e.g., Ibuprofen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_customController.text.trim().isNotEmpty) {
                                      setState(() {
                                        widget.controller.addMedication(_customController.text.trim());
                                        _customController.clear();
                                      });
                                    }
                                  },
                                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                                    padding: const MaterialStatePropertyAll(
                                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  child: const Text('Add', style: TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Selected medications
                      if (widget.controller.data.medications.isNotEmpty) ...[
                        const Text(
                          'Your Medications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: OnboardingTheme.cardDecoration(),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.controller.data.medications.map((medication) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: OnboardingTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      medication,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          widget.controller.removeMedication(medication);
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
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
                      
                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.warningAmber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: OnboardingTheme.warningAmber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: OnboardingTheme.warningAmber,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Always consult your doctor before making medication changes',
                                style: OnboardingTheme.bodyStyle.copyWith(
                                  fontSize: 14,
                                  color: OnboardingTheme.warningAmber,
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

class _MedicationOption {
  final String name;
  final String category;
  final IconData icon;
  
  _MedicationOption({
    required this.name,
    required this.category,
    required this.icon,
  });
}
