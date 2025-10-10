import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crohns_companion/core/backend_service_provider.dart';
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
  } catch (error, stackTrace) {
    developer.log(
      'Non-fatal error during synchronous initialization',
      name: 'App.main',
      error: error,
      stackTrace: stackTrace,
    );
  }

  developer.log('Running app', name: 'App.main');
  runApp(const MyApp());

  // Kick off backend initialization in the background so the UI is never blocked
  unawaited(_initializeBackend());
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
        themeMode: ThemeMode.light, // Default to light theme
        home: const SplashScreen(),
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