import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../widgets/staggered_animation.dart';

class MedicationItem {
  final String name;
  final String description;
  final IconData icon;

  const MedicationItem({
    required this.name,
    required this.description,
    required this.icon,
  });
}

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
  
  final List<MedicationItem> _commonMedications = const [
    MedicationItem(
      name: 'Mesalamine',
      description: 'Anti-inflammatory for IBD maintenance',
      icon: Icons.medication_outlined,
    ),
    MedicationItem(
      name: 'Prednisone',
      description: 'Corticosteroid for flare management',
      icon: Icons.medical_services_outlined,
    ),
    MedicationItem(
      name: 'Azathioprine',
      description: 'Immunosuppressant medication',
      icon: Icons.healing_outlined,
    ),
    MedicationItem(
      name: 'Infliximab',
      description: 'Biologic therapy (infusion)',
      icon: Icons.vaccines_outlined,
    ),
    MedicationItem(
      name: 'Adalimumab',
      description: 'Biologic therapy (injection)',
      icon: Icons.vaccines_outlined,
    ),
    MedicationItem(
      name: 'Budesonide',
      description: 'Targeted corticosteroid',
      icon: Icons.medical_services_outlined,
    ),
    MedicationItem(
      name: 'Methotrexate',
      description: 'Immunomodulator therapy',
      icon: Icons.healing_outlined,
    ),
    MedicationItem(
      name: 'Vedolizumab',
      description: 'Gut-selective biologic',
      icon: Icons.vaccines_outlined,
    ),
  ];

  // Get custom medications (not in predefined list)
  List<String> get _customMedications {
    return widget.controller.data.medications
        .where((med) => !_commonMedications.any((item) => item.name == med))
        .toList();
  }
  
  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Widget _buildMedicationCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? OnboardingTheme.accentIndigo.withOpacity(0.3)
                    : OnboardingTheme.accentIndigo.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : OnboardingTheme.lightIndigo,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
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
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Delete button for custom or checkmark
            if (isCustom && onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              )
            else if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: OnboardingTheme.accentIndigo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                      
                      const SizedBox(height: 24),
                      
                      // Add Custom Item section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: OnboardingTheme.accentIndigo.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_circle_outline,
                                color: OnboardingTheme.lightIndigo,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _customController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Add custom medication',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    setState(() {
                                      widget.controller.addMedication(value.trim());
                                      _customController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_customController.text.trim().isNotEmpty) {
                                  setState(() {
                                    widget.controller.addMedication(_customController.text.trim());
                                    _customController.clear();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.accentIndigo,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Custom medications section
                      if (_customMedications.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Your Custom Medications',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_customMedications.length, (index) {
                          final medication = _customMedications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StaggeredAnimation(
                              index: index,
                              child: _buildMedicationCard(
                                title: medication,
                                description: 'Custom medication',
                                icon: Icons.medication_outlined,
                                isSelected: true,
                                isCustom: true,
                                onTap: () {},
                                onDelete: () {
                                  setState(() {
                                    widget.controller.removeMedication(medication);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Common IBD Medications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Common medications as cards
                      ...List.generate(_commonMedications.length, (index) {
                        final item = _commonMedications[index];
                        final isSelected = widget.controller.data.medications.contains(item.name);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StaggeredAnimation(
                            index: index,
                            child: _buildMedicationCard(
                              title: item.name,
                              description: item.description,
                              icon: item.icon,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  widget.controller.toggleMedication(item.name);
                                });
                              },
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 16),
                      
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
                    padding: const WidgetStatePropertyAll(
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
      ),
    );
  }
}
