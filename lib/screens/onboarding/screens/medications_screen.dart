import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';
import '../widgets/staggered_animation.dart';

class MedicationItem {
  final String name;
  final String description;
  final IconData icon;

  /// Common brand names, shown as examples and accepted when typed.
  final List<String> brands;

  /// Other names accepted when typed (international names, biosimilars).
  final List<String> aliases;

  const MedicationItem({
    required this.name,
    required this.description,
    required this.icon,
    this.brands = const [],
    this.aliases = const [],
  });

  bool matches(String lowerCaseName) =>
      name.toLowerCase() == lowerCaseName ||
      brands.any((brand) => brand.toLowerCase() == lowerCaseName) ||
      aliases.any((alias) => alias.toLowerCase() == lowerCaseName);

  String get displayDescription =>
      brands.isEmpty ? description : '$description, e.g. ${brands.join(', ')}';
}

class _MedicationGroup {
  final String title;
  final List<MedicationItem> items;

  const _MedicationGroup(this.title, this.items);
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

  static const _MedicationGroup _ibdGroup = _MedicationGroup('Common IBD Medications', [
    MedicationItem(
      name: 'Mesalamine',
      description: 'Aminosalicylate (5-ASA)',
      icon: Icons.medication_outlined,
      brands: ['Asacol', 'Lialda', 'Pentasa'],
      aliases: ['Mesalazine', 'Octasa', 'Salofalk', 'Mezavant'],
    ),
    MedicationItem(
      name: 'Prednisone',
      description: 'Corticosteroid for flare management',
      icon: Icons.medical_services_outlined,
    ),
    MedicationItem(
      name: 'Budesonide',
      description: 'Targeted corticosteroid',
      icon: Icons.medical_services_outlined,
      brands: ['Entocort', 'Uceris'],
    ),
    MedicationItem(
      name: 'Azathioprine',
      description: 'Immunomodulator',
      icon: Icons.healing_outlined,
      brands: ['Imuran'],
    ),
    MedicationItem(
      name: 'Methotrexate',
      description: 'Immunomodulator (tablet or injection)',
      icon: Icons.healing_outlined,
    ),
    MedicationItem(
      name: 'Infliximab',
      description: 'Biologic (infusion)',
      icon: Icons.vaccines_outlined,
      brands: ['Remicade', 'Inflectra'],
      aliases: ['Remsima', 'Flixabi'],
    ),
    MedicationItem(
      name: 'Adalimumab',
      description: 'Biologic (injection)',
      icon: Icons.vaccines_outlined,
      brands: ['Humira'],
      aliases: ['Amgevita', 'Imraldi', 'Hyrimoz', 'Hulio', 'Yuflyma'],
    ),
    MedicationItem(
      name: 'Vedolizumab',
      description: 'Gut-selective biologic',
      icon: Icons.vaccines_outlined,
      brands: ['Entyvio'],
    ),
    MedicationItem(
      name: 'Ustekinumab',
      description: 'Biologic (injection)',
      icon: Icons.vaccines_outlined,
      brands: ['Stelara'],
    ),
    MedicationItem(
      name: 'Risankizumab',
      description: 'Biologic (infusion, then injection)',
      icon: Icons.vaccines_outlined,
      brands: ['Skyrizi'],
    ),
    MedicationItem(
      name: 'Upadacitinib',
      description: 'JAK inhibitor (tablet)',
      icon: Icons.medication_outlined,
      brands: ['Rinvoq'],
    ),
  ]);

  static const _MedicationGroup _ibsGroup = _MedicationGroup('Common IBS Medications', [
    MedicationItem(
      name: 'Loperamide',
      description: 'Anti-diarrheal',
      icon: Icons.medication_outlined,
      brands: ['Imodium'],
    ),
    MedicationItem(
      name: 'Hyoscine Butylbromide',
      description: 'Antispasmodic',
      icon: Icons.medication_outlined,
      brands: ['Buscopan'],
    ),
    MedicationItem(
      name: 'Dicyclomine',
      description: 'Antispasmodic',
      icon: Icons.medication_outlined,
      brands: ['Bentyl'],
    ),
    MedicationItem(
      name: 'Linaclotide',
      description: 'For IBS with constipation',
      icon: Icons.medication_outlined,
      brands: ['Linzess'],
    ),
    MedicationItem(
      name: 'Rifaximin',
      description: 'Antibiotic for IBS with diarrhea',
      icon: Icons.medication_outlined,
      brands: ['Xifaxan'],
    ),
    MedicationItem(
      name: 'Amitriptyline',
      description: 'Low-dose tricyclic, used for gut pain',
      icon: Icons.healing_outlined,
    ),
  ]);

  static const _MedicationGroup _refluxGroup = _MedicationGroup('Common Reflux (GERD) Medications', [
    MedicationItem(
      name: 'Omeprazole',
      description: 'Proton pump inhibitor',
      icon: Icons.medication_outlined,
      brands: ['Prilosec', 'Losec'],
    ),
    MedicationItem(
      name: 'Esomeprazole',
      description: 'Proton pump inhibitor',
      icon: Icons.medication_outlined,
      brands: ['Nexium'],
    ),
    MedicationItem(
      name: 'Pantoprazole',
      description: 'Proton pump inhibitor',
      icon: Icons.medication_outlined,
      brands: ['Protonix'],
    ),
    MedicationItem(
      name: 'Famotidine',
      description: 'H2 blocker',
      icon: Icons.medication_outlined,
      brands: ['Pepcid'],
    ),
    MedicationItem(
      name: 'Antacids',
      description: 'Alginates and antacids',
      icon: Icons.local_drink_outlined,
      brands: ['Gaviscon', 'Tums'],
    ),
  ]);

  /// Medication lists relevant to the conditions picked earlier. Celiac,
  /// other, unsure or no answer shows every list so nothing is hidden.
  List<_MedicationGroup> get _groups {
    final data = widget.controller.data;
    final conditions = {...data.conditions, if (data.condition != null) data.condition!};
    final hasIbd = conditions.contains(GutCondition.crohns) ||
        conditions.contains(GutCondition.ulcerativeColitis) ||
        conditions.contains(GutCondition.ibd);
    final groups = <_MedicationGroup>[
      if (hasIbd) _ibdGroup,
      if (conditions.contains(GutCondition.ibs)) _ibsGroup,
      if (conditions.contains(GutCondition.gerd)) _refluxGroup,
    ];
    return groups.isEmpty ? const [_ibdGroup, _ibsGroup, _refluxGroup] : groups;
  }

  // Selected medications without a card on screen: typed by the user, or
  // picked from a list for a condition that is no longer selected.
  List<String> _customMedications(List<_MedicationGroup> groups) {
    return widget.controller.data.medications
        .where((med) => !groups.any((g) => g.items.any((item) => item.name == med)))
        .toList();
  }

  bool get _canAddCustom => _customController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  /// Canonical name for typed text: a listed generic, brand or alias maps to
  /// the generic medication, anything else is kept as typed.
  String _canonicalName(String value) {
    final lower = value.toLowerCase();
    for (final group in [_ibdGroup, _ibsGroup, _refluxGroup]) {
      for (final item in group.items) {
        if (item.matches(lower)) return item.name;
      }
    }
    return value;
  }

  void _addCustomMedication() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    final name = _canonicalName(value);
    final lower = name.toLowerCase();
    final alreadyAdded =
        widget.controller.data.medications.any((med) => med.toLowerCase() == lower);
    setState(() {
      if (!alreadyAdded) {
        widget.controller.addMedication(name);
      }
      _customController.clear();
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

  /// A medication card. With [onTap] it is a checkbox the user can toggle;
  /// with [onDelete] it is an entry without a list card that can be removed.
  Widget _buildMedicationCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? OnboardingTheme.accentIndigo.withValues(alpha: 0.3)
                  : OnboardingTheme.accentIndigo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : OnboardingTheme.lightIndigo,
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
    );

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: onTap == null
            ? Semantics(container: true, child: content)
            : Semantics(
                container: true,
                checked: isSelected,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: content,
                ),
              ),
      ),
    );
  }

  List<Widget> _buildGroup(_MedicationGroup group) {
    return [
      const SizedBox(height: 24),
      Text(
        group.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
      const SizedBox(height: 12),
      ...List.generate(group.items.length, (index) {
        final item = group.items[index];
        final isSelected = widget.controller.data.medications.contains(item.name);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StaggeredAnimation(
            index: index,
            child: _buildMedicationCard(
              title: item.name,
              description: item.displayDescription,
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final customMedications = _customMedications(groups);
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
                          'Current Medications',
                          style: OnboardingTheme.headingTextStyle(fontSize: 32),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Track medications you\'re currently taking',
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
                                    hintText: 'Add custom medication',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _addCustomMedication(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _canAddCustom ? _addCustomMedication : null,
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

                        // Custom medications section
                        if (customMedications.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Your Custom Medications',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(customMedications.length, (index) {
                            final medication = customMedications[index];
                            return Padding(
                              key: ValueKey('custom-medication-$medication'),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: StaggeredAnimation(
                                index: index,
                                child: _buildMedicationCard(
                                  title: medication,
                                  description: 'Custom medication',
                                  icon: Icons.medication_outlined,
                                  isSelected: true,
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

                        // Condition-specific medication lists
                        for (final group in groups) ..._buildGroup(group),

                        const SizedBox(height: 16),

                        // Disclaimer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OnboardingTheme.warningAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: OnboardingTheme.warningAmber.withValues(alpha: 0.3),
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
