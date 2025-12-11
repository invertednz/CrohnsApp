import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:gut_md/core/analytics/mixpanel_service.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/screens/onboarding/onboarding_flow.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    developer.log('Initializing SplashScreen', name: 'SplashScreen');
    super.initState();
    MixpanelService.trackEvent('SplashScreen_Viewed');
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    developer.log('Disposing SplashScreen', name: 'SplashScreen');
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      developer.log('Starting navigation delay', name: 'SplashScreen');
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) {
        developer.log('Widget not mounted after delay', name: 'SplashScreen');
        return;
      }
      
      developer.log('Navigating to OnboardingFlow', name: 'SplashScreen');
      MixpanelService.trackEvent('SplashScreen_NavigatingToOnboarding');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingFlow()),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error during navigation',
        name: 'SplashScreen',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building SplashScreen widget', name: 'SplashScreen');
    try {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // App name
                const Text(
                  'Crohn\'s Companion',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // App tagline
                const Text(
                  'Your personal health tracker',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error building SplashScreen widget',
        name: 'SplashScreen',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}