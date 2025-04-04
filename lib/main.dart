import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crohns_companion/core/backend_service_provider.dart';
import 'package:crohns_companion/core/theme/app_theme.dart';
import 'package:crohns_companion/screens/splash_screen.dart';

void main() async {
  developer.log('Starting app initialization', name: 'App.main');
  try {
    developer.log('Initializing WidgetsFlutterBinding', name: 'App.main');
    WidgetsFlutterBinding.ensureInitialized();
    
    developer.log('Setting preferred orientations', name: 'App.main');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    developer.log('Initializing BackendService', name: 'App.main');
    await BackendServiceProvider.initialize();
    
    developer.log('Running app', name: 'App.main');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    developer.log(
      'Error during app initialization',
      name: 'App.main',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
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