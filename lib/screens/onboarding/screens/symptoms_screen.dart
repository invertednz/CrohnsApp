import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../onboarding_data.dart';
import '../widgets/staggered_animation.dart';

class SymptomItem {
  final String name;
  final String description;
  final IconData icon;

  const SymptomItem({
    required this.name,
    required this.description,
    required this.icon,
  });
}

class CurrentSymptomsScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CurrentSymptomsScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<CurrentSymptomsScreen> createState() => _CurrentSymptomsScreenState();
}

class _CurrentSymptomsScreenState extends State<CurrentSymptomsScreen> {
  final TextEditingController _customController = TextEditingController();

  static const List<SymptomItem> _commonSymptoms = [
    SymptomItem(
      name: 'Abdominal Pain',
      description: 'Stomach cramps or discomfort',
      icon: Icons.emergency_outlined,
    ),
    SymptomItem(
      name: 'Diarrhea',
      description: 'Frequent loose or watery stools',
      icon: Icons.water_drop_outlined,
    ),
    SymptomItem(
      name: 'Urgency',
      description: 'Sudden need to go that is hard to delay',
      icon: Icons.timer_outlined,
    ),
    SymptomItem(
      name: 'Bloating',
      description: 'Feeling of fullness or swelling',
      icon: Icons.air,
    ),
    SymptomItem(
      name: 'Gas',
      description: 'Excessive flatulence',
      icon: Icons.cloud_outlined,
    ),
    SymptomItem(
      name: 'Fatigue',
      description: 'Tiredness and low energy',
      icon: Icons.battery_0_bar,
    ),
    SymptomItem(
      name: 'Nausea',
      description: 'Feeling sick or queasy',
      icon: Icons.sick_outlined,
    ),
    SymptomItem(
      name: 'Heartburn',
      description: 'Burning feeling in the chest or throat',
      icon: Icons.local_fire_department_outlined,
    ),
    SymptomItem(
      name: 'Loss of Appetite',
      description: 'Reduced desire to eat',
      icon: Icons.no_meals_outlined,
    ),
    SymptomItem(
      name: 'Weight Loss',
      description: 'Unintentional weight reduction',
      icon: Icons.trending_down,
    ),
    SymptomItem(
      name: 'Fever',
      description: 'Elevated body temperature',
      icon: Icons.thermostat,
    ),
    SymptomItem(
      name: 'Joint Pain',
      description: 'Aching or stiff joints',
      icon: Icons.accessibility_new,
    ),
    SymptomItem(
      name: 'Constipation',
      description: 'Difficulty passing stools',
      icon: Icons.block,
    ),
    SymptomItem(
      name: 'Blood in Stool',
      description: 'Rectal bleeding (consult doctor)',
      icon: Icons.warning_amber,
    ),
  ];

  /// Symptoms that warrant a prompt to contact a clinician.
  static const Set<String> _seekCareSymptoms = {'Blood in Stool', 'Fever'};

  static const List<String> _severities = ['Mild', 'Moderate', 'Severe'];

  List<SymptomEntry> get _symptoms => widget.controller.data.currentSymptoms;

  // Symptoms the user typed that are not in the predefined list.
  List<SymptomEntry> get _customSymptoms {
    return _symptoms
        .where((s) => !_commonSymptoms.any((item) => item.name == s.name))
        .toList();
  }

  bool get _showSeekCareNotice => _symptoms.any((s) => _seekCareSymptoms.contains(s.name));

  bool get _canAddCustom => _customController.text.trim().isNotEmpty;

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Mild':
        return OnboardingTheme.healthGreen;
      case 'Moderate':
        return OnboardingTheme.warningAmber;
      case 'Severe':
        return OnboardingTheme.errorRed;
      default:
        return OnboardingTheme.warningAmber;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  /// Adds the typed symptom. A case-insensitive match of a common symptom
  /// selects that card, and an existing entry is not duplicated.
  void _addCustomSymptom() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    final lower = value.toLowerCase();
    final alreadyAdded = _symptoms.any((s) => s.name.toLowerCase() == lower);
    SymptomItem? common;
    for (final item in _commonSymptoms) {
      if (item.name.toLowerCase() == lower) {
        common = item;
        break;
      }
    }
    setState(() {
      if (!alreadyAdded) {
        widget.controller.addSymptom(SymptomEntry(
          name: common?.name ?? value,
          severity: 'Moderate',
          isCustom: common == null,
        ));
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

  /// A symptom card. With [onTap] the header is a checkbox that adds or
  /// removes the symptom; with [onDelete] it is a custom entry. Selected
  /// symptoms show severity options below the header, outside the tap area,
  /// so a missed tap on a severity can't remove the symptom.
  Widget _buildSymptomCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    SymptomEntry? entry,
  }) {
    final severityColor =
        entry != null ? _getSeverityColor(entry.severity) : OnboardingTheme.accentIndigo;
    final showSeverity = isSelected && entry != null;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, showSeverity ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? severityColor.withValues(alpha: 0.3)
                  : OnboardingTheme.accentIndigo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? severityColor : OnboardingTheme.lightIndigo,
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
                color: severityColor,
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
                ? severityColor
                : OnboardingTheme.accentIndigo.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (onTap == null)
              Semantics(container: true, child: header)
            else
              Semantics(
                container: true,
                checked: isSelected,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: header,
                ),
              ),
            if (showSeverity)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const SizedBox(width: 64), // Align with text
                    Text(
                      'Severity:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final severity in _severities)
                            _SeverityChip(
                              label: severity,
                              semanticLabel: '$title severity: $severity',
                              isSelected: entry.severity == severity,
                              color: _getSeverityColor(severity),
                              onTap: () {
                                setState(() {
                                  widget.controller.updateSymptomSeverity(title, severity);
                                });
                              },
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
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required Color color,
    required String text,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: OnboardingTheme.bodyStyle.copyWith(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customSymptoms = _customSymptoms;
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
                          'Current Symptoms',
                          style: OnboardingTheme.headingTextStyle(fontSize: 32),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Select symptoms you\'re currently experiencing',
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
                                    hintText: 'Add custom symptom',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _addCustomSymptom(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _canAddCustom ? _addCustomSymptom : null,
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

                        // Custom symptoms section
                        if (customSymptoms.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Your Custom Symptoms',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(customSymptoms.length, (index) {
                            final symptom = customSymptoms[index];
                            return Padding(
                              key: ValueKey('custom-symptom-${symptom.name}'),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: StaggeredAnimation(
                                index: index,
                                child: _buildSymptomCard(
                                  title: symptom.name,
                                  description: 'Custom symptom',
                                  icon: Icons.health_and_safety_outlined,
                                  isSelected: true,
                                  entry: symptom,
                                  onDelete: () {
                                    setState(() {
                                      widget.controller.removeSymptom(symptom.name);
                                    });
                                  },
                                ),
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 24),

                        Text(
                          'Common Symptoms',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Common symptoms as cards
                        ...List.generate(_commonSymptoms.length, (index) {
                          final item = _commonSymptoms[index];
                          final entry = widget.controller.getSymptom(item.name);
                          final isSelected = entry != null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StaggeredAnimation(
                              index: index,
                              child: _buildSymptomCard(
                                title: item.name,
                                description: item.description,
                                icon: item.icon,
                                isSelected: isSelected,
                                entry: entry,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      widget.controller.removeSymptom(item.name);
                                    } else {
                                      widget.controller.addSymptom(SymptomEntry(
                                        name: item.name,
                                        severity: 'Moderate',
                                        isCustom: false,
                                      ));
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        if (_showSeekCareNotice) ...[
                          _buildNotice(
                            icon: Icons.local_hospital_outlined,
                            color: OnboardingTheme.errorRed,
                            text: 'Blood in stool and fever can need prompt medical attention. '
                                'If they are new, heavy, or getting worse, contact your doctor or care team.',
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Info box
                        if (_symptoms.isEmpty)
                          _buildNotice(
                            icon: Icons.info_outline,
                            color: OnboardingTheme.healthGreen,
                            textColor: OnboardingTheme.healthGreen,
                            text: 'No symptoms right now? Just continue. You can log symptoms any time.',
                          )
                        else
                          _buildNotice(
                            icon: Icons.info_outline,
                            color: OnboardingTheme.lightIndigo,
                            text: 'Set a severity for each symptom so you have a baseline to compare against.',
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

/// One option of a symptom's severity. Exposed to assistive tech as a radio
/// button named after the symptom ("Bloating severity: Mild").
class _SeverityChip extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _SeverityChip({
    required this.label,
    required this.semanticLabel,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
            ),
          ),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
