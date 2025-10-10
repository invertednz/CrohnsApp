import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';

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
  final TextEditingController _nameController = TextEditingController();
  bool _takesAM = false;
  bool _takesPM = false;
  
  final List<String> _commonSupplements = [
    'Vitamin D',
    'Probiotics',
    'Omega-3',
    'Iron',
    'B12',
    'Calcium',
    'Zinc',
    'Magnesium',
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  void _addSupplement(String name) {
    if (name.trim().isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => _SupplementDialog(
        name: name,
        onAdd: (supplement) {
          setState(() {
            widget.controller.addSupplement(supplement);
          });
        },
      ),
    );
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
                        'Supplements',
                        style: OnboardingTheme.neonTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Track vitamins and supplements you take',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Common supplements
                      const Text(
                        'Common Supplements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _commonSupplements.map((supplement) {
                          return GestureDetector(
                            onTap: () => _addSupplement(supplement),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: OnboardingTheme.accentIndigo.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: OnboardingTheme.lightIndigo,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    supplement,
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
                      
                      // Custom supplement input
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: OnboardingTheme.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Custom Supplement',
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
                                    controller: _nameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: OnboardingTheme.inputDecoration(
                                      label: 'Supplement name',
                                      hint: 'e.g., Turmeric',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_nameController.text.trim().isNotEmpty) {
                                      _addSupplement(_nameController.text.trim());
                                      _nameController.clear();
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
                      
                      // Current supplements list
                      if (widget.controller.data.supplements.isNotEmpty) ...[
                        const Text(
                          'Your Supplements',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.controller.data.supplements.asMap().entries.map((entry) {
                          final index = entry.key;
                          final supplement = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: OnboardingTheme.cardDecoration(),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        supplement.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _TimeChip(
                                            label: 'AM',
                                            isSelected: supplement.takesAM,
                                            onTap: () {
                                              setState(() {
                                                widget.controller.updateSupplement(
                                                  index,
                                                  SupplementEntry(
                                                    name: supplement.name,
                                                    takesAM: !supplement.takesAM,
                                                    takesPM: supplement.takesPM,
                                                  ),
                                                );
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _TimeChip(
                                            label: 'PM',
                                            isSelected: supplement.takesPM,
                                            onTap: () {
                                              setState(() {
                                                widget.controller.updateSupplement(
                                                  index,
                                                  SupplementEntry(
                                                    name: supplement.name,
                                                    takesAM: supplement.takesAM,
                                                    takesPM: !supplement.takesPM,
                                                  ),
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      widget.controller.removeSupplement(index);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: OnboardingTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? OnboardingTheme.accentIndigo
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SupplementDialog extends StatefulWidget {
  final String name;
  final Function(SupplementEntry) onAdd;
  
  const _SupplementDialog({
    required this.name,
    required this.onAdd,
  });

  @override
  State<_SupplementDialog> createState() => _SupplementDialogState();
}

class _SupplementDialogState extends State<_SupplementDialog> {
  bool _takesAM = false;
  bool _takesPM = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: OnboardingTheme.darkNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: OnboardingTheme.accentIndigo.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'When do you take ${widget.name}?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimeChip(
                  label: 'AM',
                  isSelected: _takesAM,
                  onTap: () {
                    setState(() {
                      _takesAM = !_takesAM;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _TimeChip(
                  label: 'PM',
                  isSelected: _takesPM,
                  onTap: () {
                    setState(() {
                      _takesPM = !_takesPM;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OnboardingTheme.secondaryButtonStyle(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_takesAM || _takesPM)
                        ? () {
                            widget.onAdd(SupplementEntry(
                              name: widget.name,
                              takesAM: _takesAM,
                              takesPM: _takesPM,
                            ));
                            Navigator.pop(context);
                          }
                        : null,
                    style: OnboardingTheme.primaryButtonStyle(),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
