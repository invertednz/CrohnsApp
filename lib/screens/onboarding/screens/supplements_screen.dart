import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';
import '../widgets/staggered_animation.dart';

class SupplementItem {
  final String name;
  final String description;
  final IconData icon;

  const SupplementItem({
    required this.name,
    required this.description,
    required this.icon,
  });
}

class SupplementsScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const SupplementsScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<SupplementsScreen> createState() => _SupplementsScreenState();
}

class _SupplementsScreenState extends State<SupplementsScreen> {
  final TextEditingController _customController = TextEditingController();
  
  final List<SupplementItem> _commonSupplements = const [
    SupplementItem(
      name: 'Vitamin D',
      description: 'Supports bone health and immunity',
      icon: Icons.wb_sunny_outlined,
    ),
    SupplementItem(
      name: 'Probiotics',
      description: 'Gut health and digestive support',
      icon: Icons.bubble_chart_outlined,
    ),
    SupplementItem(
      name: 'Omega-3',
      description: 'Anti-inflammatory fish oils',
      icon: Icons.water_outlined,
    ),
    SupplementItem(
      name: 'Iron',
      description: 'Essential for blood health',
      icon: Icons.fitness_center_outlined,
    ),
    SupplementItem(
      name: 'B12',
      description: 'Energy and nerve function',
      icon: Icons.bolt_outlined,
    ),
    SupplementItem(
      name: 'Calcium',
      description: 'Bone and teeth strength',
      icon: Icons.shield_outlined,
    ),
    SupplementItem(
      name: 'Zinc',
      description: 'Immune system support',
      icon: Icons.security_outlined,
    ),
    SupplementItem(
      name: 'Magnesium',
      description: 'Muscle and nerve function',
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  // Check if supplement is already added
  bool _isSupplementAdded(String name) {
    return widget.controller.data.supplements.any((s) => s.name == name);
  }

  // Get supplement entry by name
  SupplementEntry? _getSupplementEntry(String name) {
    try {
      return widget.controller.data.supplements.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get index of supplement
  int _getSupplementIndex(String name) {
    return widget.controller.data.supplements.indexWhere((s) => s.name == name);
  }

  // Get custom supplements (not in predefined list)
  List<SupplementEntry> get _customSupplements {
    return widget.controller.data.supplements
        .where((s) => !_commonSupplements.any((item) => item.name == s.name))
        .toList();
  }
  
  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addSupplement(String name) {
    if (name.trim().isEmpty) return;
    if (_isSupplementAdded(name)) return;
    
    setState(() {
      widget.controller.addSupplement(SupplementEntry(
        name: name,
        takesAM: false,
        takesPM: false,
      ));
    });
  }

  void _removeSupplement(String name) {
    final index = _getSupplementIndex(name);
    if (index != -1) {
      setState(() {
        widget.controller.removeSupplement(index);
      });
    }
  }

  Widget _buildSupplementCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isAdded,
    required VoidCallback onTap,
    bool isCustom = false,
    VoidCallback? onDelete,
    SupplementEntry? entry,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdded
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withOpacity(0.2),
            width: isAdded ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isAdded
                        ? OnboardingTheme.accentIndigo.withOpacity(0.3)
                        : OnboardingTheme.accentIndigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isAdded ? Colors.white : OnboardingTheme.lightIndigo,
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
                else if (isAdded)
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
            // AM/PM toggles when added
            if (isAdded && entry != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 64), // Align with text
                  Text(
                    'When do you take it?',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  _TimeChip(
                    label: 'AM',
                    isSelected: entry.takesAM,
                    onTap: () {
                      final index = _getSupplementIndex(title);
                      if (index != -1) {
                        setState(() {
                          widget.controller.updateSupplement(
                            index,
                            SupplementEntry(
                              name: entry.name,
                              takesAM: !entry.takesAM,
                              takesPM: entry.takesPM,
                            ),
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _TimeChip(
                    label: 'PM',
                    isSelected: entry.takesPM,
                    onTap: () {
                      final index = _getSupplementIndex(title);
                      if (index != -1) {
                        setState(() {
                          widget.controller.updateSupplement(
                            index,
                            SupplementEntry(
                              name: entry.name,
                              takesAM: entry.takesAM,
                              takesPM: !entry.takesPM,
                            ),
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
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
                        'Supplements',
                        style: OnboardingTheme.headingTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Track vitamins and supplements you take',
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
                                  hintText: 'Add custom supplement (e.g., Turmeric)',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    _addSupplement(value.trim());
                                    _customController.clear();
                                  }
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_customController.text.trim().isNotEmpty) {
                                  _addSupplement(_customController.text.trim());
                                  _customController.clear();
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
                      
                      // Custom supplements section
                      if (_customSupplements.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Your Custom Supplements',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_customSupplements.length, (index) {
                          final supplement = _customSupplements[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StaggeredAnimation(
                              index: index,
                              child: _buildSupplementCard(
                                title: supplement.name,
                                description: 'Custom supplement',
                                icon: Icons.medication_outlined,
                                isAdded: true,
                                isCustom: true,
                                entry: supplement,
                                onTap: () {},
                                onDelete: () => _removeSupplement(supplement.name),
                              ),
                            ),
                          );
                        }),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Common Supplements',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Common supplements as cards
                      ...List.generate(_commonSupplements.length, (index) {
                        final item = _commonSupplements[index];
                        final isAdded = _isSupplementAdded(item.name);
                        final entry = _getSupplementEntry(item.name);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StaggeredAnimation(
                            index: index,
                            child: _buildSupplementCard(
                              title: item.name,
                              description: item.description,
                              icon: item.icon,
                              isAdded: isAdded,
                              entry: entry,
                              onTap: () {
                                if (isAdded) {
                                  _removeSupplement(item.name);
                                } else {
                                  _addSupplement(item.name);
                                }
                              },
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 16),
                      
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
                                'Select AM/PM to track when you take each supplement',
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

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? OnboardingTheme.accentIndigo
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
