import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:gut_md/core/analytics/mixpanel_service.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/screens/home/home_screen.dart';
import 'package:gut_md/screens/onboarding/onboarding_controller.dart';
import 'package:gut_md/screens/onboarding/onboarding_flow.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _failed = false;

  @override
  void initState() {
    developer.log('Initializing SplashScreen', name: 'SplashScreen');
    super.initState();
    MixpanelService.trackEvent('SplashScreen_Viewed');
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 1200)),
        BackendServiceProvider.initialize(),
      ]);

      if (!mounted) {
        developer.log('Widget not mounted after delay', name: 'SplashScreen');
        return;
      }

      // Returning users go straight to their dashboard.
      final user = BackendServiceProvider.instance.auth.currentUser;
      final signedIn = user != null;
      if (signedIn) {
        // Load the returning user's onboarding answers for the tabs and AI.
        try {
          await OnboardingProfileStore.restore(user.id).timeout(const Duration(seconds: 5));
        } catch (error) {
          developer.log('Could not restore onboarding answers', name: 'SplashScreen', error: error);
        }
        if (!mounted) return;
      }
      MixpanelService.trackEvent(
        signedIn ? 'SplashScreen_NavigatingToHome' : 'SplashScreen_NavigatingToOnboarding',
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => signedIn ? const HomeScreen() : const OnboardingFlow(),
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error during navigation',
        name: 'SplashScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    _navigateToNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.spa_outlined,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App name
              const Text(
                'GutMD',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // App tagline
              const Text(
                'Your personal gut health tracker',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              if (_failed) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'GutMD couldn\'t start. Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Try again'),
                ),
              ] else
                Semantics(
                  label: 'Loading',
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
