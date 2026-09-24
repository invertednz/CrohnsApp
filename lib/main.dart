import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:gut_md/core/analytics/mixpanel_service.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/screens/splash_screen.dart';

Future<void> main() async {
  developer.log('Starting app initialization', name: 'App.main');

  try {
    developer.log('Initializing WidgetsFlutterBinding', name: 'App.main');
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) {
      // Always build the web accessibility tree so screen readers (and the
      // E2E suite) can see every control without an opt-in click.
      SemanticsBinding.instance.ensureSemantics();
    }

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

  // Start backend initialization without blocking the first frame; the splash
  // screen awaits it before routing anywhere that needs data.
  unawaited(BackendServiceProvider.initialize());
  unawaited(_initializeAnalytics());
}

Future<void> _initializeAnalytics() async {
  try {
    developer.log('Initializing MixpanelService', name: 'App.main');
    await MixpanelService.initialize()
        .timeout(const Duration(seconds: 10));
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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log('Building MaterialApp', name: 'App.MyApp');
    try {
      return MaterialApp(
        title: 'GutMD',
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