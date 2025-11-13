import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/services.dart';

import 'package:crohns_companion/core/analytics/mixpanel_service.dart';
import 'package:crohns_companion/core/backend_service_provider.dart';
import 'package:crohns_companion/core/environment.dart';
import 'package:crohns_companion/core/firebase/firebase_service.dart';
import 'package:crohns_companion/core/theme/app_theme.dart';
import 'package:crohns_companion/screens/splash_screen.dart';

Future<void> main() async {
  developer.log('Starting app initialization', name: 'App.main');

  try {
    developer.log('Initializing WidgetsFlutterBinding', name: 'App.main');
    WidgetsFlutterBinding.ensureInitialized();

    developer.log('Setting preferred orientations', name: 'App.main');
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    developer.log('Loading environment configuration', name: 'App.main');
    await Environment.initialize();
  } catch (error, stackTrace) {
    developer.log(
      'Non-fatal error during synchronous initialization',
      name: 'App.main',
      error: error,
      stackTrace: stackTrace,
    );
  }

  developer.log('Running app', name: 'App.main');

  // Ensure all debug paint flags are disabled in debug/profile to avoid baseline lines
  try {
    if (kDebugMode || kProfileMode) {
      rendering.debugPaintBaselinesEnabled = false;
      rendering.debugPaintSizeEnabled = false;
      rendering.debugPaintLayerBordersEnabled = false;
      rendering.debugRepaintRainbowEnabled = false;
    }
  } catch (_) {}

  runApp(const MyApp());

  // Kick off backend initialization in the background so the UI is never blocked
  unawaited(_initializeBackend());
  unawaited(_initializeAnalytics());
  unawaited(_initializeFirebase());
}

Future<void> _initializeBackend() async {
  if (kIsWeb) {
    developer.log(
      'Skipping BackendService initialization on web',
      name: 'App.main',
    );
    return;
  }

  try {
    developer.log('Initializing BackendService', name: 'App.main');
    await BackendServiceProvider.initialize();
    developer.log('BackendService initialized successfully', name: 'App.main');
  } catch (error, stackTrace) {
    developer.log(
      'BackendService initialization failed, continuing in offline mode',
      name: 'App.main',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _initializeAnalytics() async {
  try {
    developer.log('Initializing MixpanelService', name: 'App.main');
    await MixpanelService.initialize();
    developer.log('MixpanelService initialized successfully', name: 'App.main');
  } catch (error, stackTrace) {
    developer.log(
      'MixpanelService initialization failed',
      name: 'App.main',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _initializeFirebase() async {
  try {
    developer.log('Initializing FirebaseService', name: 'App.main');
    await FirebaseService.initialize();
    developer.log(
      'FirebaseService initialized successfully (using ${FirebaseService.isUsingMock ? "mock" : "Firebase"} data)',
      name: 'App.main',
    );
  } catch (error, stackTrace) {
    developer.log(
      'FirebaseService initialization failed',
      name: 'App.main',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log('Building MaterialApp', name: 'App.MyApp');
    try {
      return MaterialApp(
        title: 'Crohn\'s Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Use dark theme to match onboarding
        home: const SplashScreen(),
        builder: (context, child) {
          final media = MediaQuery.of(context).copyWith(textScaleFactor: 1.0);
          return MediaQuery(
            data: media,
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
              ),
              child: child!,
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error building MaterialApp',
        name: 'App.MyApp',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}