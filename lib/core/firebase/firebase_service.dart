import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../environment.dart';
import 'data_provider.dart';
import 'firebase_data_provider.dart';
import 'mock_data_provider.dart';

/// Singleton service that manages Firebase initialization and provides
/// access to data through either Firebase or mock implementations
class FirebaseService {
  static FirebaseService? _instance;
  static DataProvider? _dataProvider;

  FirebaseService._();

  /// Get the singleton instance
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// Get the current data provider (mock or Firebase)
  static DataProvider get dataProvider {
    if (_dataProvider == null) {
      throw Exception(
        'FirebaseService not initialized. Call initialize() first.',
      );
    }
    return _dataProvider!;
  }

  /// Initialize Firebase and set up the appropriate data provider
  static Future<void> initialize() async {
    try {
      final useMock = Environment.useMockData;
      final useFirebase = Environment.useFirebase;

      debugPrint('FirebaseService: useMockData=$useMock, useFirebase=$useFirebase');

      if (useMock) {
        debugPrint('FirebaseService: Using mock data provider');
        _dataProvider = MockDataProvider();
        await _dataProvider!.initialize();
        return;
      }

      if (useFirebase) {
        debugPrint('FirebaseService: Initializing Firebase');
        await Firebase.initializeApp();
        debugPrint('FirebaseService: Firebase initialized successfully');
        
        _dataProvider = FirebaseDataProvider(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        );
        await _dataProvider!.initialize();
      } else {
        debugPrint('FirebaseService: Neither mock nor Firebase enabled, defaulting to mock');
        _dataProvider = MockDataProvider();
        await _dataProvider!.initialize();
      }
    } catch (error, stackTrace) {
      debugPrint('FirebaseService: Initialization failed, falling back to mock data');
      debugPrint('Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      
      _dataProvider = MockDataProvider();
      await _dataProvider!.initialize();
    }
  }

  /// Check if currently using Firebase (vs mock)
  static bool get isUsingFirebase => _dataProvider is FirebaseDataProvider;

  /// Check if currently using mock data
  static bool get isUsingMock => _dataProvider is MockDataProvider;
}
