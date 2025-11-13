import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'data_provider.dart';

/// Firebase implementation of DataProvider
class FirebaseDataProvider implements DataProvider {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FirebaseDataProvider({
    required this.firestore,
    required this.auth,
  });

  @override
  Future<void> initialize() async {
    debugPrint('FirebaseDataProvider: Initialized');
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (error) {
      debugPrint('FirebaseDataProvider: Error getting user profile: $error');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await firestore.collection('users').doc(userId).set(
            data,
            SetOptions(merge: true),
          );
    } catch (error) {
      debugPrint('FirebaseDataProvider: Error updating user profile: $error');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHealthData(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = firestore
          .collection('users')
          .doc(userId)
          .collection('health_data');

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (error) {
      debugPrint('FirebaseDataProvider: Error getting health data: $error');
      return [];
    }
  }

  @override
  Future<void> saveHealthData(String userId, Map<String, dynamic> data) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('health_data')
          .add(data);
    } catch (error) {
      debugPrint('FirebaseDataProvider: Error saving health data: $error');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getNotificationPreferences(String userId) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();
      return doc.data();
    } catch (error) {
      debugPrint('FirebaseDataProvider: Error getting notification preferences: $error');
      return null;
    }
  }

  @override
  Future<void> updateNotificationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set(preferences, SetOptions(merge: true));
    } catch (error) {
      debugPrint('FirebaseDataProvider: Error updating notification preferences: $error');
      rethrow;
    }
  }

  @override
  Future<String?> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user?.uid;
    } catch (error) {
      debugPrint('FirebaseDataProvider: Error signing in: $error');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (error) {
      debugPrint('FirebaseDataProvider: Error signing out: $error');
      rethrow;
    }
  }

  @override
  String? getCurrentUserId() {
    return auth.currentUser?.uid;
  }

  @override
  bool isAuthenticated() {
    return auth.currentUser != null;
  }
}
