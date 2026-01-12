import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
    required String program,
    required int level,
    required String role,
    required String stream,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);

        // Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': displayName,
          'program': program,
          'level': level,
          'role': role,
          'stream': stream,
          'about': 'Hey there! I\'m using Regent Connect',
          'createdAt': DateTime.now(),
          'showOnlineStatus': true,
          'readReceipts': true,
          'pushNotifications': true,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update online status
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'isOnline': true,
          'lastSeen': Timestamp.now(),
        });
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': false,
        'lastSeen': Timestamp.now(),
      });
    }
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
