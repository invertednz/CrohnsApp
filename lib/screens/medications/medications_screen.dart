import 'package:flutter/material.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/widgets/calendar_bar.dart';

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

class MedicationsScreenMain extends StatefulWidget {
  const MedicationsScreenMain({Key? key}) : super(key: key);

  @override
  State<MedicationsScreenMain> createState() => _MedicationsScreenMainState();
}

class _MedicationsScreenMainState extends State<MedicationsScreenMain> {
  final _appState = AppState();
  final TextEditingController _customController = TextEditingController();
  bool _initialized = false;
  
  // User's medication list (persists across days)
  final Set<String> _myMedications = {};
  final List<String> _customMedications = [];
  
  // Per-day tracking data
  final Map<String, Set<String>> _takenByDate = {};
  final Map<String, Map<String, bool>> _takenAMByDate = {};
  final Map<String, Map<String, bool>> _takenPMByDate = {};

  DateTime get _selectedDate => _appState.selectedDate;
  String get _dateKey => '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
  
  Set<String> get _takenToday => _takenByDate[_dateKey] ?? {};

  @override
  void initState() {
    super.initState();
    _loadFromOnboarding();
  }

  void _loadFromOnboarding() {
    if (_initialized) return;
    _initialized = true;
    
    // Load medications from onboarding data
    final onboardingMeds = _appState.userMedications;
    for (var med in onboardingMeds) {
      _myMedications.add(med);
    }
  }

  final List<MedicationItem> _commonMedications = const [
    MedicationItem(name: 'Mesalamine', description: 'Anti-inflammatory for IBD maintenance', icon: Icons.medication_outlined),
    MedicationItem(name: 'Prednisone', description: 'Corticosteroid for flare management', icon: Icons.medical_services_outlined),
    MedicationItem(name: 'Azathioprine', description: 'Immunosuppressant medication', icon: Icons.healing_outlined),
    MedicationItem(name: 'Infliximab', description: 'Biologic therapy (infusion)', icon: Icons.vaccines_outlined),
    MedicationItem(name: 'Adalimumab', description: 'Biologic therapy (injection)', icon: Icons.vaccines_outlined),
    MedicationItem(name: 'Budesonide', description: 'Targeted corticosteroid', icon: Icons.medical_services_outlined),
    MedicationItem(name: 'Methotrexate', description: 'Immunomodulator therapy', icon: Icons.healing_outlined),
    MedicationItem(name: 'Vedolizumab', description: 'Gut-selective biologic', icon: Icons.vaccines_outlined),
  ];

  List<String> get _allMyMedications => [..._myMedications, ..._customMedications];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggleInMyList(String name) {
    setState(() {
      if (_myMedications.contains(name)) {
        _myMedications.remove(name);
      } else {
        _myMedications.add(name);
      }
    });
  }

  void _toggleTakenToday(String name) {
    setState(() {
      _takenByDate[_dateKey] ??= {};
      _takenAMByDate[_dateKey] ??= {};
      _takenPMByDate[_dateKey] ??= {};
      
      if (_takenByDate[_dateKey]!.contains(name)) {
        _takenByDate[_dateKey]!.remove(name);
      } else {
        _takenByDate[_dateKey]!.add(name);
      }
    });
  }

  void _toggleAM(String name) {
    setState(() {
      _takenAMByDate[_dateKey] ??= {};
      _takenAMByDate[_dateKey]![name] = !(_takenAMByDate[_dateKey]![name] ?? false);
    });
  }

  void _togglePM(String name) {
    setState(() {
      _takenPMByDate[_dateKey] ??= {};
      _takenPMByDate[_dateKey]![name] = !(_takenPMByDate[_dateKey]![name] ?? false);
    });
  }

  void _markAllTaken() {
    setState(() {
      _takenByDate[_dateKey] = {..._allMyMedications};
    });
  }

  void _clearAllTaken() {
    setState(() {
      _takenByDate[_dateKey]?.clear();
    });
  }

  void _addCustomMedication() {
    final text = _customController.text.trim();
    if (text.isNotEmpty && !_customMedications.contains(text) && !_myMedications.contains(text)) {
      setState(() {
        _customMedications.add(text);
        _customController.clear();
      });
    }
  }

  void _removeCustomMedication(String name) {
    setState(() {
      _customMedications.remove(name);
      for (var set in _takenByDate.values) {
        set.remove(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMyMedications = _allMyMedications.isNotEmpty;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medications',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your daily medications',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 16),
                  CalendarBar(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) => setState(() => _appState.setSelectedDate(date)),
                  ),
                ],
              ),
            ),
            
            // Quick actions for daily tracking
            if (hasMyMedications)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction('Mark All Taken', Icons.check_circle_outline, AppTheme.healthGreen, _markAllTaken),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickAction('Clear All', Icons.cancel_outlined, Colors.redAccent, _clearAllTaken),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Medications list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My Medications - Daily Tracking
                    if (hasMyMedications) ...[
                      Text(
                        'My Medications - Tap to mark taken',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 12),
                      ..._allMyMedications.map((name) {
                        final isTaken = _takenToday.contains(name);
                        final takenAM = _takenAMByDate[_dateKey]?[name] ?? false;
                        final takenPM = _takenPMByDate[_dateKey]?[name] ?? false;
                        final isCustom = _customMedications.contains(name);
                        final commonMedList = _commonMedications.where((m) => m.name == name);
                        final commonMed = commonMedList.isNotEmpty ? commonMedList.first : null;
                        
                        return _buildDailyTrackingCard(
                          name: name,
                          description: isCustom ? 'Custom medication' : (commonMed?.description ?? ''),
                          icon: isCustom ? Icons.medication_outlined : (commonMed?.icon ?? Icons.medication_outlined),
                          isTaken: isTaken,
                          takenAM: takenAM,
                          takenPM: takenPM,
                          isCustom: isCustom,
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                    
                    // Add custom medication
                    _buildAddCustomSection(),
                    
                    const SizedBox(height: 20),
                    
                    // Add from common medications
                    Text(
                      'Add to My Medications',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 12),
                    
                    ..._commonMedications.where((m) => !_myMedications.contains(m.name)).map((med) => 
                      _buildAddMedicationCard(med)),
                    
                    const SizedBox(height: 16),
                    
                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Always consult your doctor before making medication changes',
                              style: TextStyle(fontSize: 13, color: Colors.amber.withOpacity(0.9)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCustomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentIndigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add_circle_outline, color: Colors.white.withOpacity(0.7), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _customController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add custom medication',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addCustomMedication(),
            ),
          ),
          GestureDetector(
            onTap: _addCustomMedication,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accentIndigo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrackingCard({
    required String name,
    required String description,
    required IconData icon,
    required bool isTaken,
    required bool takenAM,
    required bool takenPM,
    required bool isCustom,
  }) {
    return GestureDetector(
      onTap: () => _toggleTakenToday(name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isTaken ? AppTheme.healthGreen.withOpacity(0.15) : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isTaken ? AppTheme.healthGreen : Colors.white.withOpacity(0.1),
            width: isTaken ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isTaken ? AppTheme.healthGreen.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isTaken ? Icons.check : icon,
                    color: isTaken ? AppTheme.healthGreen : Colors.white70,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isTaken ? Colors.white : Colors.white.withOpacity(0.9))),
                      if (description.isNotEmpty)
                        Text(description, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
                if (isCustom)
                  GestureDetector(
                    onTap: () => _removeCustomMedication(name),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.close, color: Colors.red, size: 16),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _toggleInMyList(name),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.remove, color: Colors.white54, size: 16),
                    ),
                  ),
              ],
            ),
            if (isTaken) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 58),
                  Text('Time:', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                  const Spacer(),
                  _buildTimeChip('AM', takenAM, () => _toggleAM(name)),
                  const SizedBox(width: 8),
                  _buildTimeChip('PM', takenPM, () => _togglePM(name)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddMedicationCard(MedicationItem med) {
    return GestureDetector(
      onTap: () => _toggleInMyList(med.name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(med.icon, color: Colors.white54, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8))),
                  Text(med.description, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentIndigo.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('+ Add', style: TextStyle(color: AppTheme.accentIndigo, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.healthGreen.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.healthGreen : Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppTheme.healthGreen : Colors.white70),
        ),
      ),
    );
  }
}
