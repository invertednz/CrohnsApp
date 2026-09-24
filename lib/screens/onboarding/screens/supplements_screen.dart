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

  static const List<SupplementItem> _commonSupplements = [
    SupplementItem(
      name: 'Vitamin D',
      description: 'Supports bone health and immunity',
      icon: Icons.wb_sunny_outlined,
    ),
    SupplementItem(
      name: 'Probiotics',
      description: 'Live bacterial cultures (capsules, powders, drinks)',
      icon: Icons.bubble_chart_outlined,
    ),
    SupplementItem(
      name: 'Omega-3',
      description: 'Fish, krill, or algae oil',
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

  List<SupplementEntry> get _supplements => widget.controller.data.supplements;

  bool _isSupplementAdded(String name) {
    return _supplements.any((s) => s.name == name);
  }

  SupplementEntry? _getSupplementEntry(String name) {
    for (final supplement in _supplements) {
      if (supplement.name == name) return supplement;
    }
    return null;
  }

  int _getSupplementIndex(String name) {
    return _supplements.indexWhere((s) => s.name == name);
  }

  // Supplements the user typed that are not in the predefined list.
  List<SupplementEntry> get _customSupplements {
    return _supplements
        .where((s) => !_commonSupplements.any((item) => item.name == s.name))
        .toList();
  }

  bool get _canAddCustom => _customController.text.trim().isNotEmpty;

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

  /// Adds the typed supplement. A case-insensitive match of a common
  /// supplement selects that card, and an existing entry is not duplicated.
  void _addCustomSupplement() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    final lower = value.toLowerCase();
    final alreadyAdded = _supplements.any((s) => s.name.toLowerCase() == lower);
    String name = value;
    for (final item in _commonSupplements) {
      if (item.name.toLowerCase() == lower) {
        name = item.name;
        break;
      }
    }
    if (!alreadyAdded) {
      _addSupplement(name);
    }
    setState(_customController.clear);
  }

  void _removeSupplement(String name) {
    final index = _getSupplementIndex(name);
    if (index != -1) {
      setState(() {
        widget.controller.removeSupplement(index);
      });
    }
  }

  void _setTiming(String name, {bool? takesAM, bool? takesPM}) {
    final index = _getSupplementIndex(name);
    if (index == -1) return;
    final entry = _supplements[index];
    setState(() {
      widget.controller.updateSupplement(
        index,
        SupplementEntry(
          name: entry.name,
          takesAM: takesAM ?? entry.takesAM,
          takesPM: takesPM ?? entry.takesPM,
        ),
      );
    });
  }

  Widget _buildRemoveButton(String name, VoidCallback onDelete) {
    return IconButton(
      tooltip: 'Remove $name',
      onPressed: onDelete,
      icon: const Icon(Icons.close, color: Colors.red, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: Colors.red.withValues(alpha: 0.2),
        fixedSize: const Size(32, 32),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// A supplement card. With [onTap] the header is a checkbox that adds or
  /// removes the supplement; with [onDelete] it is a custom entry. Added
  /// supplements show AM/PM toggles below the header, outside the tap area,
  /// so a missed tap on a toggle can't remove the supplement.
  Widget _buildSupplementCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isAdded,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    SupplementEntry? entry,
  }) {
    final showTiming = isAdded && entry != null;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, showTiming ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAdded
                  ? OnboardingTheme.accentIndigo.withValues(alpha: 0.3)
                  : OnboardingTheme.accentIndigo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isAdded ? Colors.white : OnboardingTheme.lightIndigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
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
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            _buildRemoveButton(title, onDelete)
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
    );

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdded
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withValues(alpha: 0.2),
            width: isAdded ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (onTap == null)
              Semantics(container: true, child: header)
            else
              Semantics(
                container: true,
                checked: isAdded,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: header,
                ),
              ),
            if (showTiming)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const SizedBox(width: 64), // Align with text
                    Expanded(
                      child: Text(
                        'When do you take it?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TimeChip(
                      label: 'AM',
                      semanticLabel: 'Take ${entry.name} in the AM',
                      isSelected: entry.takesAM,
                      onTap: () => _setTiming(entry.name, takesAM: !entry.takesAM),
                    ),
                    const SizedBox(width: 8),
                    _TimeChip(
                      label: 'PM',
                      semanticLabel: 'Take ${entry.name} in the PM',
                      isSelected: entry.takesPM,
                      onTap: () => _setTiming(entry.name, takesPM: !entry.takesPM),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customSupplements = _customSupplements;
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
                      tooltip: 'Back',
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

                        const Text(
                          'Track vitamins and supplements you take',
                          style: OnboardingTheme.subheadingStyle,
                        ),

                        const SizedBox(height: 24),

                        // Add Custom Item section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: OnboardingTheme.accentIndigo.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.accentIndigo.withValues(alpha: 0.15),
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
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    hintText: 'Add custom supplement (e.g., Turmeric)',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _addCustomSupplement(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _canAddCustom ? _addCustomSupplement : null,
                                style: _addButtonStyle,
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Custom supplements section
                        if (customSupplements.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Your Custom Supplements',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(customSupplements.length, (index) {
                            final supplement = customSupplements[index];
                            return Padding(
                              key: ValueKey('custom-supplement-${supplement.name}'),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: StaggeredAnimation(
                                index: index,
                                child: _buildSupplementCard(
                                  title: supplement.name,
                                  description: 'Custom supplement',
                                  icon: Icons.medication_outlined,
                                  isAdded: true,
                                  entry: supplement,
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                            color: OnboardingTheme.accentIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: OnboardingTheme.accentIndigo.withValues(alpha: 0.3),
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

final ButtonStyle _addButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: OnboardingTheme.accentIndigo,
  foregroundColor: Colors.white,
  disabledBackgroundColor: OnboardingTheme.accentIndigo.withValues(alpha: 0.3),
  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  minimumSize: const Size(0, 40),
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

/// AM / PM toggle. Exposed to assistive tech as a checkbox named after the
/// supplement ("Take Vitamin D in the AM") so each toggle is distinguishable.
class _TimeChip extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.semanticLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: isSelected,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? OnboardingTheme.accentIndigo
                : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? OnboardingTheme.accentIndigo
                  : OnboardingTheme.accentIndigo.withValues(alpha: 0.3),
            ),
          ),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
