import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/screens/symptoms/symptoms_screen.dart';
import 'package:gut_md/screens/supplements/supplements_screen.dart';
import 'package:gut_md/screens/chat/chat_screen.dart';
import 'package:gut_md/screens/medications/medications_screen.dart';
import 'package:gut_md/widgets/calendar_bar.dart';
import 'package:gut_md/services/meal_analysis_service.dart';
import 'package:gut_md/core/app_state.dart';

class DailyLogEntry {
  final String description;
  final String time;
  final double digestScore;
  final String? imagePath;

  DailyLogEntry({
    required this.description,
    required this.time,
    required this.digestScore,
    this.imagePath,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeContent(onNavigateToTab: _navigateToTab),
      const SymptomsScreen(),
      const SupplementsScreenMain(),
      const MedicationsScreenMain(),
      const ChatScreen(),
    ];
    
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            activeIcon: Icon(Icons.warning_amber),
            label: 'Symptoms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'Supps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Meds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const HomeContent({Key? key, this.onNavigateToTab}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _appState = AppState();
  final TextEditingController _logController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLogging = false;
  
  // Per-day data storage
  final Map<String, int?> _feelingsByDate = {};
  final Map<String, int> _bowelMovementsByDate = {};
  final Map<String, bool?> _supplementsByDate = {};
  final Map<String, bool?> _medicationsByDate = {};
  final Map<String, bool?> _dietByDate = {};
  final Map<String, List<DailyLogEntry>> _logEntriesByDate = {};

  final List<Map<String, dynamic>> _feelings = [
    {'emoji': '😫', 'label': 'Terrible', 'color': Colors.red},
    {'emoji': '😔', 'label': 'Bad', 'color': Colors.orange},
    {'emoji': '😐', 'label': 'Okay', 'color': Colors.amber},
    {'emoji': '🙂', 'label': 'Good', 'color': Colors.lightGreen},
    {'emoji': '😄', 'label': 'Great', 'color': Colors.green},
  ];

  DateTime get _selectedDate => _appState.selectedDate;
  String get _dateKey => '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
  
  int? get _selectedFeeling => _feelingsByDate[_dateKey];
  int get _bowelMovements => _bowelMovementsByDate[_dateKey] ?? 0;
  bool? get _followedSupplements => _supplementsByDate[_dateKey];
  bool? get _followedMedications => _medicationsByDate[_dateKey];
  bool? get _followedDiet => _dietByDate[_dateKey];
  List<DailyLogEntry> get _todayLogs => _logEntriesByDate[_dateKey] ?? [];

  @override
  void dispose() {
    _logController.dispose();
    super.dispose();
  }

  void _setFeeling(int index) {
    setState(() => _feelingsByDate[_dateKey] = index);
  }

  void _setBowelMovements(int value) {
    setState(() => _bowelMovementsByDate[_dateKey] = value);
  }

  void _setSupplements(bool? value) {
    setState(() => _supplementsByDate[_dateKey] = value);
  }

  void _setMedications(bool? value) {
    setState(() => _medicationsByDate[_dateKey] = value);
  }

  void _setDiet(bool? value) {
    setState(() => _dietByDate[_dateKey] = value);
  }

  // Calculate streak (days with any tracking data)
  int get _currentStreak {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      final hasData = _feelingsByDate.containsKey(key) ||
          _bowelMovementsByDate.containsKey(key) ||
          _supplementsByDate.containsKey(key) ||
          _medicationsByDate.containsKey(key) ||
          _dietByDate.containsKey(key) ||
          (_logEntriesByDate[key]?.isNotEmpty ?? false);
      
      if (hasData) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        // Today has no data yet, check yesterday
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak > 0 ? streak : 1; // Show at least 1 for demo
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppTheme.healthGreen,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '$_currentStreak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with streak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GutMD',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your daily health',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        _buildStreakBadge(),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Calendar Bar
                    CalendarBar(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() => _appState.setSelectedDate(date));
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // How are you feeling section
                    _buildSectionTitle('How are you feeling?'),
                    const SizedBox(height: 10),
                    _buildFeelingSelector(),
                    
                    const SizedBox(height: 20),
                    
                    // Compact 2x2 grid for tracking
                    _buildCompactTrackingGrid(),
                    
                    const SizedBox(height: 20),
                    
                    // AI Insights section
                    _buildSectionTitle('Your Health Insights'),
                    const SizedBox(height: 10),
                    _buildHealthInsights(),
                    
                    const SizedBox(height: 20),
                    
                    // Daily Logs section
                    _buildSectionTitle('Daily Logs'),
                    const SizedBox(height: 10),
                    _buildDailyLogs(),
                    
                    const SizedBox(height: 100), // Space for bottom input
                  ],
                ),
              ),
            ),
            
            // Bottom input bar
            _buildBottomInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFeelingSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_feelings.length, (index) {
          final feeling = _feelings[index];
          final isSelected = _selectedFeeling == index;
          
          return GestureDetector(
            onTap: () => _setFeeling(index),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (feeling['color'] as Color).withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected 
                        ? Border.all(color: feeling['color'] as Color, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      feeling['emoji'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feeling['label'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.5),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompactTrackingGrid() {
    return Column(
      children: [
        // First row: Bowel Movements + Supplements
        Row(
          children: [
            Expanded(child: _buildCompactBowelCard()),
            const SizedBox(width: 10),
            Expanded(child: _buildCompactGuideCard('Supplements', Icons.medication_outlined, _followedSupplements, _setSupplements, 2)),
          ],
        ),
        const SizedBox(height: 10),
        // Second row: Medications + Diet
        Row(
          children: [
            Expanded(child: _buildCompactGuideCard('Medications', Icons.medical_services_outlined, _followedMedications, _setMedications, 3)),
            const SizedBox(width: 10),
            Expanded(child: _buildCompactGuideCard('Diet', Icons.restaurant_outlined, _followedDiet, _setDiet, -1)),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactBowelCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: Colors.white.withOpacity(0.7), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Bowel Motions',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_bowelMovements',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Row(
                children: [
                  _buildSmallCounterButton(Icons.remove, () {
                    if (_bowelMovements > 0) _setBowelMovements(_bowelMovements - 1);
                  }),
                  const SizedBox(width: 6),
                  _buildSmallCounterButton(Icons.add, () => _setBowelMovements(_bowelMovements + 1)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildCompactGuideCard(String title, IconData icon, bool? followed, Function(bool?) onChanged, int tabIndex) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: followed == true ? AppTheme.healthGreen.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: followed == true ? AppTheme.healthGreen : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Had All',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: followed == true ? FontWeight.w600 : FontWeight.normal,
                          color: followed == true ? AppTheme.healthGreen : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    onChanged(false);
                    // Navigate to the corresponding page if tabIndex is valid
                    if (tabIndex >= 0 && widget.onNavigateToTab != null) {
                      widget.onNavigateToTab!(tabIndex);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: followed == false ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: followed == false ? Colors.amber : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Different',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: followed == false ? FontWeight.w600 : FontWeight.normal,
                          color: followed == false ? Colors.amber : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInsights() {
    // Calculate actual stats from tracking data
    final totalDaysTracked = _feelingsByDate.length;
    final avgFeeling = _feelingsByDate.values.whereType<int>().isEmpty 
        ? 0.0 
        : _feelingsByDate.values.whereType<int>().reduce((a, b) => a + b) / _feelingsByDate.values.whereType<int>().length;
    final supplementsDaysTaken = _supplementsByDate.values.where((v) => v == true).length;
    final medicationsDaysTaken = _medicationsByDate.values.where((v) => v == true).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInsightCard(
                icon: Icons.calendar_today,
                iconColor: AppTheme.accentIndigo,
                title: 'Days Tracked',
                value: '$totalDaysTracked',
                subtitle: 'Total',
              ),
              const SizedBox(width: 10),
              _buildInsightCard(
                icon: Icons.sentiment_satisfied,
                iconColor: avgFeeling >= 3 ? AppTheme.healthGreen : avgFeeling >= 2 ? Colors.amber : Colors.orange,
                title: 'Avg Feeling',
                value: avgFeeling > 0 ? avgFeeling.toStringAsFixed(1) : '-',
                subtitle: avgFeeling >= 3 ? 'Good' : avgFeeling >= 2 ? 'Okay' : avgFeeling > 0 ? 'Low' : 'N/A',
              ),
              const SizedBox(width: 10),
              _buildInsightCard(
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                title: 'Streak',
                value: '$_currentStreak',
                subtitle: 'Days',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentIndigo.withOpacity(0.2), Colors.purple.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentIndigo.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentIndigo.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tracking Summary',
                        style: TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalDaysTracked == 0
                            ? 'Start tracking today to see your patterns and insights!'
                            : 'Supplements taken: $supplementsDaysTaken days • Medications: $medicationsDaysTaken days',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogs() {
    if (_todayLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No logs for this day yet.\nUse the input below to add entries.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: _todayLogs.map((log) => _buildLogItem(log)).toList(),
    );
  }

  Widget _buildLogItem(DailyLogEntry log) {
    Color borderColor = log.digestScore >= 7 ? AppTheme.healthGreen 
        : log.digestScore >= 4 ? Colors.amber 
        : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.description,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  log.time,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Digest Score',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              Text(
                log.digestScore.toStringAsFixed(1),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: borderColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          // Photo button
          GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentIndigo.withOpacity(0.3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Text input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _logController,
                decoration: InputDecoration(
                  hintText: 'What did you eat, do, or feel?',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                onSubmitted: (_) => _submitLog(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: _submitLog,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentIndigo,
                borderRadius: BorderRadius.circular(22),
              ),
              child: _isLogging
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() => _isLogging = true);
        
        // Analyze the photo
        final analysis = await MealAnalysisService.analyzeMealPhoto(File(photo.path));
        
        // Add log entry
        final entry = DailyLogEntry(
          description: analysis.foods.join(', '),
          time: TimeOfDay.now().format(context),
          digestScore: _calculateDigestScore(analysis),
          imagePath: photo.path,
        );
        
        setState(() {
          _logEntriesByDate[_dateKey] = [..._todayLogs, entry];
          _isLogging = false;
        });
        
        // Save meal data
        await MealAnalysisService.saveMealData(
          analysis: analysis,
          date: _selectedDate,
          imagePath: photo.path,
        );
      }
    } catch (e) {
      setState(() => _isLogging = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  double _calculateDigestScore(MealAnalysisResult analysis) {
    // Simple scoring based on triggers
    double score = 8.5;
    if (analysis.potentialTriggers != null) {
      score -= analysis.potentialTriggers!.length * 0.8;
    }
    return score.clamp(0.0, 10.0);
  }

  Future<void> _submitLog() async {
    final text = _logController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLogging = true);

    // Add log entry
    final entry = DailyLogEntry(
      description: text,
      time: TimeOfDay.now().format(context),
      digestScore: 7.5, // Default score for text entries
    );

    setState(() {
      _logEntriesByDate[_dateKey] = [..._todayLogs, entry];
      _logController.clear();
      _isLogging = false;
    });
  }

}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: AppTheme.cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ShortcutCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const ShortcutCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: AppTheme.cardDecoration(),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.indigoGlow,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.lightIndigo.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const SummaryItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.lightIndigo,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.indigoGlow,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
