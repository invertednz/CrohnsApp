import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/services/ai_chat_service.dart';
import 'package:gut_md/services/insights_generator.dart';

/// Firestore layout (all user data lives under the user's own document so
/// security rules can restrict access to `request.auth.uid == userId`):
///
///   users/{uid}                                   profile
///   users/{uid}/tracking/{type}/entries/{entryId} tracking entries
///   users/{uid}/chat/{messageId}                  assistant conversation
///   users/{uid}/insights/latest                   latest generated insights
class FirebaseBackend {
  FirebaseBackend._();

  static Future<UnifiedBackendService> create() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    // Wait for a persisted session to be restored before the UI asks for it.
    await auth.authStateChanges().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => auth.currentUser,
        );
    final tracking = _FirebaseTrackingService(firestore);
    return UnifiedBackendService(
      auth: _FirebaseAuthService(auth, firestore),
      tracking: tracking,
      insights: _FirebaseInsightsService(firestore, tracking),
      chat: _FirebaseChatService(firestore, tracking),
      isMock: false,
    );
  }
}

DocumentReference<Map<String, dynamic>> _userDoc(FirebaseFirestore db, String uid) {
  if (uid.isEmpty) {
    throw StateError('You need to be signed in to save your data.');
  }
  return db.collection('users').doc(uid);
}

/// Converts Firestore values (Timestamps) into JSON-friendly values.
Map<String, dynamic> _plain(Map<String, dynamic> data) => data.map(
      (k, v) => MapEntry(k, v is Timestamp ? v.toDate().toIso8601String() : v),
    );

class _FirebaseAuthService implements UnifiedAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  _FirebaseAuthService(this._auth, this._db);

  AppUser? _map(User? user) => user == null
      ? null
      : AppUser(
          id: user.uid,
          email: user.email,
          displayName: user.displayName,
          isAnonymous: user.isAnonymous,
        );

  Future<void> _saveProfile(User user, [Map<String, dynamic>? extra]) {
    return _userDoc(_db, user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'isAnonymous': user.isAnonymous,
      'lastSignInAt': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    }, SetOptions(merge: true));
  }

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    final credential = EmailAuthProvider.credential(email: email, password: password);
    final current = _auth.currentUser;
    // Upgrade a guest account in place so everything they logged is kept.
    final result = current != null && current.isAnonymous
        ? await current.linkWithCredential(credential)
        : await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = result.user!;
    final name = userData?['name'] as String?;
    if (name != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }
    final refreshed = _auth.currentUser ?? user;
    await _saveProfile(refreshed, {'createdAt': FieldValue.serverTimestamp(), ...?userData});
    return _map(refreshed);
  }

  @override
  Future<AppUser?> signInWithEmail({required String email, required String password}) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _saveProfile(result.user!);
    return _map(result.user);
  }

  Future<AppUser?> _signInWithProvider(AuthProvider provider) async {
    final current = _auth.currentUser;
    UserCredential result;
    if (current != null && current.isAnonymous) {
      // Upgrade the guest account so everything logged as a guest is kept.
      try {
        result = kIsWeb
            ? await current.linkWithPopup(provider)
            : await current.linkWithProvider(provider);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use' || e.credential == null) rethrow;
        // The provider account already exists: sign in to it instead.
        result = await _auth.signInWithCredential(e.credential!);
      }
    } else {
      result = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
    }
    await _saveProfile(result.user!);
    return _map(result.user);
  }

  @override
  Future<AppUser?> signInWithGoogle() => _signInWithProvider(GoogleAuthProvider());

  @override
  Future<AppUser?> signInWithApple() => _signInWithProvider(AppleAuthProvider());

  @override
  Future<AppUser?> signInAsGuest() async {
    final existing = _auth.currentUser;
    if (existing != null) return _map(existing);
    final result = await _auth.signInAnonymously();
    await _saveProfile(result.user!, {'createdAt': FieldValue.serverTimestamp()});
    return _map(result.user);
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();
}

class _FirebaseTrackingService implements UnifiedTrackingService {
  final FirebaseFirestore _db;

  _FirebaseTrackingService(this._db);

  CollectionReference<Map<String, dynamic>> _entries(String uid, String type) =>
      _userDoc(_db, uid).collection('tracking').doc(type).collection('entries');

  @override
  Future<void> trackEvent({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final id = (data['entry_id'] ?? data['date'] ?? DateTime.now().toIso8601String()).toString();
    await _entries(userId, type).doc(id).set({
      ...data,
      'type': type,
      'recorded_at': FieldValue.serverTimestamp(),
      // Client clock, readable immediately (recorded_at is null until the
      // server confirms the write).
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>?> getTrackingData({
    required String userId,
    required String date,
    required String type,
  }) async {
    final snapshot = await _entries(userId, type).doc(date).get();
    final data = snapshot.data();
    return data == null ? null : _plain(data);
  }

  @override
  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    required String type,
    int limit = 30,
  }) async {
    final snapshot = await _entries(userId, type)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => _plain(d.data())).toList();
  }
}

class _FirebaseInsightsService implements UnifiedInsightsService {
  final FirebaseFirestore _db;
  final UnifiedTrackingService _tracking;

  _FirebaseInsightsService(this._db, this._tracking);

  DocumentReference<Map<String, dynamic>> _latest(String uid) =>
      _userDoc(_db, uid).collection('insights').doc('latest');

  @override
  Future<Map<String, dynamic>?> getUserInsights(String userId) async {
    final snapshot = await _latest(userId).get();
    if (snapshot.exists) return _plain(snapshot.data()!);
    // First visit: build insights from whatever has been tracked so far.
    await generateInsights(userId);
    final generated = await _latest(userId).get();
    return generated.data() == null ? null : _plain(generated.data()!);
  }

  @override
  Future<void> generateInsights(String userId) async {
    final history = await loadRecentHistory(_tracking, userId);
    final insights = await InsightsGenerator.generate(history);
    await _latest(userId).set(insights);
  }
}

class _FirebaseChatService implements UnifiedChatService {
  final FirebaseFirestore _db;
  final UnifiedTrackingService _tracking;
  final AIChatService _ai = const AIChatService();

  _FirebaseChatService(this._db, this._tracking);

  CollectionReference<Map<String, dynamic>> _messages(String uid) =>
      _userDoc(_db, uid).collection('chat');

  Future<void> _save(String uid, String text, bool isUser) {
    return _messages(uid).add({
      'text': text,
      'isUser': isUser,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    final snapshot = await _messages(userId)
        .orderBy('timestamp')
        .limitToLast(50)
        .get();
    return snapshot.docs.map((d) => _plain(d.data())).toList();
  }

  @override
  Future<String> sendMessage(String userId, String message) async {
    final previous = await getChatHistory(userId);
    await _save(userId, message, true);
    final history = await loadRecentHistory(_tracking, userId);
    final reply = await _ai.generateResponse(
      userMessage: message,
      context: buildHealthContext(history, previous),
    );
    await _save(userId, reply, false);
    return reply;
  }
}
