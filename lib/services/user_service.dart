import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUserId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get current user stream
  Stream<DocumentSnapshot> getCurrentUserStream() {
    return _firestore.collection('users').doc(currentUserId).snapshots();
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String odbc) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture(File imageFile) async {
    if (currentUserId.isEmpty) return null;

    try {
      // Create unique filename
      final fileName = 'profile_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_pictures/$fileName');

      // Upload file
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update user document with new photo URL
      await _firestore.collection('users').doc(currentUserId).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth profile
      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  // Update profile picture from URL
  Future<bool> updateProfilePictureUrl(String url) async {
    if (currentUserId.isEmpty) return false;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _auth.currentUser?.updatePhotoURL(url);
      return true;
    } catch (e) {
      print('Error updating profile picture: $e');
      return false;
    }
  }

  // Remove profile picture
  Future<bool> removeProfilePicture() async {
    if (currentUserId.isEmpty) return false;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'photoUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _auth.currentUser?.updatePhotoURL(null);
      return true;
    } catch (e) {
      print('Error removing profile picture: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? phone,
    String? program,
    String? level,
  }) async {
    if (currentUserId.isEmpty) return false;

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fullName != null) updates['fullName'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (program != null) updates['program'] = program;
      if (level != null) updates['level'] = level;

      await _firestore.collection('users').doc(currentUserId).update(updates);
      
      if (fullName != null) {
        await _auth.currentUser?.updateDisplayName(fullName);
      }

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Get all users
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs.map((doc) => {...doc.data(), 'uid': doc.id}).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Create or update user document on sign up/login
  Future<void> createOrUpdateUser({
    required String odbc,
    required String email,
    String? fullName,
    String? photoUrl,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Create new user
        await userDoc.set({
          'uid': userId,
          'email': email,
          'fullName': fullName ?? email.split('@')[0],
          'photoUrl': photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing user
        await userDoc.update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating/updating user: $e');
    }
  }

  // Set user online status
  Future<void> setOnlineStatus(bool isOnline) async {
    if (currentUserId.isEmpty) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error setting online status: $e');
    }
  }
}
