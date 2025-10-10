import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:crohns_companion/core/theme/app_theme.dart';
import 'package:crohns_companion/screens/tracking/tracking_screen.dart';
import 'package:crohns_companion/screens/symptoms/symptoms_screen.dart';
import 'package:crohns_companion/screens/diet/diet_screen.dart';
import 'package:crohns_companion/screens/supplements/supplements_screen.dart';
import 'package:crohns_companion/screens/insights/insights_screen.dart';
import 'package:crohns_companion/screens/chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeContent(),
    const TrackingScreen(),
    const InsightsScreen(),
    const ChatScreen(),
  ];

  @override
  void initState() {
    developer.log('Initializing HomeScreen', name: 'HomeScreen');
    super.initState();
  }

  @override
  void dispose() {
    developer.log('Disposing HomeScreen', name: 'HomeScreen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building HomeScreen widget', name: 'HomeScreen');
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          developer.log('Changing tab to index: $index', name: 'HomeScreen');
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Insights',
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

class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Crohn\'s Companion',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 5,
                    ),
                    Shadow(
                      color: AppTheme.accentIndigo,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your personal health tracker',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.indigoGlow.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 32),
              
              // Feature grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  FeatureCard(
                    icon: Icons.note_alt_outlined,
                    title: 'Daily Tracking',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrackingScreen(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    icon: Icons.warning_amber_outlined,
                    title: 'Symptoms',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SymptomsScreen(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    icon: Icons.restaurant_outlined,
                    title: 'Diet Tracker',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DietScreen(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    icon: Icons.medication_outlined,
                    title: 'Supplements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupplementsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Insights shortcut
              ShortcutCard(
                title: 'Your Insights',
                description: 'View personalized health insights based on your tracking data',
                icon: Icons.lightbulb_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsightsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Chat shortcut
              ShortcutCard(
                title: 'Chat Assistant',
                description: 'Get answers to your questions about Crohn\'s disease',
                icon: Icons.chat_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Today's summary
              const Text(
                'Today\'s Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.cardDecoration(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.healthGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.healthGreen.withOpacity(0.5),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '🙂',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feeling Good',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'No major symptoms today',
                                style: TextStyle(
                                  color: AppTheme.indigoGlow,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(color: AppTheme.accentIndigo.withOpacity(0.3)),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SummaryItem(
                          icon: Icons.water_drop_outlined,
                          title: 'BM',
                          value: '2',
                        ),
                        SummaryItem(
                          icon: Icons.local_fire_department_outlined,
                          title: 'Pain',
                          value: '2/10',
                        ),
                        SummaryItem(
                          icon: Icons.battery_charging_full_outlined,
                          title: 'Energy',
                          value: '7/10',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                boxShadow: AppTheme.neonGlow(color: AppTheme.accentIndigo),
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
