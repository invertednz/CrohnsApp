import 'package:flutter/material.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/widgets/calendar_bar.dart';

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

class SupplementsScreenMain extends StatefulWidget {
  const SupplementsScreenMain({Key? key}) : super(key: key);

  @override
  State<SupplementsScreenMain> createState() => _SupplementsScreenMainState();
}

class _SupplementsScreenMainState extends State<SupplementsScreenMain> {
  final _appState = AppState();
  final TextEditingController _customController = TextEditingController();
  bool _initialized = false;
  
  // User's supplement list (persists across days)
  final Set<String> _mySupplements = {};
  final List<String> _customSupplements = [];
  
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
    
    // Load supplements from onboarding data
    final onboardingSupps = _appState.userSupplements;
    for (var supp in onboardingSupps) {
      _mySupplements.add(supp.name);
      // Set default AM/PM from onboarding
      if (supp.takesAM || supp.takesPM) {
        _takenAMByDate[_dateKey] ??= {};
        _takenPMByDate[_dateKey] ??= {};
        _takenAMByDate[_dateKey]![supp.name] = supp.takesAM;
        _takenPMByDate[_dateKey]![supp.name] = supp.takesPM;
      }
    }
  }

  final List<SupplementItem> _commonSupplements = const [
    SupplementItem(name: 'Vitamin D', description: 'Supports bone health and immunity', icon: Icons.wb_sunny_outlined),
    SupplementItem(name: 'Probiotics', description: 'Gut health and digestive support', icon: Icons.bubble_chart_outlined),
    SupplementItem(name: 'Omega-3', description: 'Anti-inflammatory fish oils', icon: Icons.water_outlined),
    SupplementItem(name: 'Iron', description: 'Essential for blood health', icon: Icons.fitness_center_outlined),
    SupplementItem(name: 'B12', description: 'Energy and nerve function', icon: Icons.bolt_outlined),
    SupplementItem(name: 'Calcium', description: 'Bone and teeth strength', icon: Icons.shield_outlined),
    SupplementItem(name: 'Zinc', description: 'Immune system support', icon: Icons.security_outlined),
    SupplementItem(name: 'Magnesium', description: 'Muscle and nerve function', icon: Icons.auto_awesome_outlined),
    SupplementItem(name: 'Folic Acid', description: 'Cell growth and metabolism', icon: Icons.favorite_outlined),
    SupplementItem(name: 'Multivitamin', description: 'Daily essential nutrients', icon: Icons.medication_outlined),
  ];

  List<String> get _allMySupplements => [..._mySupplements, ..._customSupplements];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggleInMyList(String name) {
    setState(() {
      if (_mySupplements.contains(name)) {
        _mySupplements.remove(name);
      } else {
        _mySupplements.add(name);
      }
    });
  }

  void _toggleTakenToday(String name) {
    setState(() {
      _takenByDate[_dateKey] ??= {};
      
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
      _takenByDate[_dateKey] = {..._allMySupplements};
    });
  }

  void _clearAllTaken() {
    setState(() {
      _takenByDate[_dateKey]?.clear();
    });
  }

  void _addCustomSupplement() {
    final text = _customController.text.trim();
    if (text.isNotEmpty && !_customSupplements.contains(text) && !_mySupplements.contains(text)) {
      setState(() {
        _customSupplements.add(text);
        _customController.clear();
      });
    }
  }

  void _removeCustomSupplement(String name) {
    setState(() {
      _customSupplements.remove(name);
      for (var set in _takenByDate.values) {
        set.remove(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMySupplements = _allMySupplements.isNotEmpty;
    
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
                    'Supplements',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your daily supplements',
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
            if (hasMySupplements)
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
            
            // Supplements list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My Supplements - Daily Tracking
                    if (hasMySupplements) ...[
                      Text(
                        'My Supplements - Tap to mark taken',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 12),
                      ..._allMySupplements.map((name) {
                        final isTaken = _takenToday.contains(name);
                        final takenAM = _takenAMByDate[_dateKey]?[name] ?? false;
                        final takenPM = _takenPMByDate[_dateKey]?[name] ?? false;
                        final isCustom = _customSupplements.contains(name);
                        final commonSuppList = _commonSupplements.where((s) => s.name == name);
                        final commonSupp = commonSuppList.isNotEmpty ? commonSuppList.first : null;
                        
                        return _buildDailyTrackingCard(
                          name: name,
                          description: isCustom ? 'Custom supplement' : (commonSupp?.description ?? ''),
                          icon: isCustom ? Icons.medication_outlined : (commonSupp?.icon ?? Icons.medication_outlined),
                          isTaken: isTaken,
                          takenAM: takenAM,
                          takenPM: takenPM,
                          isCustom: isCustom,
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                    
                    // Add custom supplement
                    _buildAddCustomSection(),
                    
                    const SizedBox(height: 20),
                    
                    // Add from common supplements
                    Text(
                      'Add to My Supplements',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 12),
                    
                    ..._commonSupplements.where((s) => !_mySupplements.contains(s.name)).map((supp) => 
                      _buildAddSupplementCard(supp)),
                    
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
                hintText: 'Add custom supplement',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addCustomSupplement(),
            ),
          ),
          GestureDetector(
            onTap: _addCustomSupplement,
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
                    onTap: () => _removeCustomSupplement(name),
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

  Widget _buildAddSupplementCard(SupplementItem supp) {
    return GestureDetector(
      onTap: () => _toggleInMyList(supp.name),
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
              child: Icon(supp.icon, color: Colors.white54, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(supp.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8))),
                  Text(supp.description, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
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
