import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  // Post a new status
  Future<void> postStatus({
    required String type, // 'text', 'image', 'video'
    String? text,
    String? mediaUrl,
    String? backgroundColor,
    bool allowReshare = true,
    bool isMuted = false, // New: for video statuses
  }) async {
    if (currentUserId.isEmpty) return;

    // Get user data
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() ?? {};

    final statusId = '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    final statusData = {
      'statusId': statusId,
      'userId': currentUserId,
      'userName': userData['fullName'] ?? userData['email'] ?? 'Unknown',
      'userPhoto': userData['photoUrl'],
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'backgroundColor': backgroundColor ?? '#7C4DFF',
      'allowReshare': allowReshare,
      'isMuted': isMuted, // New field
      'views': [],
      'viewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };

    await _firestore.collection('statuses').doc(statusId).set(statusData);
  }

  // Upload media for status
  Future<String?> uploadStatusMedia(File file, String type) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('status_media/$currentUserId/$type/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading status media: $e');
      return null;
    }
  }

  // Get all active statuses (not expired)
  Stream<QuerySnapshot> getAllStatuses() {
    final now = Timestamp.now();
    return _firestore
        .collection('statuses')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get statuses grouped by user
  Future<Map<String, List<Map<String, dynamic>>>> getStatusesGroupedByUser() async {
    final now = Timestamp.now();
    final snapshot = await _firestore
        .collection('statuses')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .get();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final odbc = data['userId'] as String;
      if (!grouped.containsKey(userId)) {
        grouped[userId] = [];
      }
      grouped[userId]!.add(data);
    }

    return grouped;
  }

  // Get current user's statuses
  Stream<QuerySnapshot> getMyStatuses() {
    final now = Timestamp.now();
    return _firestore
        .collection('statuses')
        .where('userId', isEqualTo: currentUserId)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // View a status (add current user to views)
  Future<void> viewStatus(String statusId) async {
    if (currentUserId.isEmpty) return;

    final statusRef = _firestore.collection('statuses').doc(statusId);
    final statusDoc = await statusRef.get();
    
    if (!statusDoc.exists) return;
    
    final data = statusDoc.data()!;
    final views = List<Map<String, dynamic>>.from(data['views'] ?? []);
    
    // Check if already viewed
    final alreadyViewed = views.any((view) => view['userId'] == currentUserId);
    if (alreadyViewed) return;

    // Get current user data
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() ?? {};

    // Add view
    views.add({
      'userId': currentUserId,
      'userName': userData['fullName'] ?? userData['email'] ?? 'Unknown',
      'userPhoto': userData['photoUrl'],
      'viewedAt': DateTime.now().toIso8601String(),
    });

    await statusRef.update({
      'views': views,
      'viewCount': views.length,
    });
  }

  // Get viewers of a status
  Future<List<Map<String, dynamic>>> getStatusViewers(String statusId) async {
    final doc = await _firestore.collection('statuses').doc(statusId).get();
    if (!doc.exists) return [];
    
    final data = doc.data()!;
    return List<Map<String, dynamic>>.from(data['views'] ?? []);
  }

  // Reshare a status
  Future<void> reshareStatus(String originalStatusId) async {
    if (currentUserId.isEmpty) return;

    final originalDoc = await _firestore.collection('statuses').doc(originalStatusId).get();
    if (!originalDoc.exists) return;

    final originalData = originalDoc.data()!;
    
    // Check if reshare is allowed
    if (originalData['allowReshare'] != true) {
      throw Exception('This status cannot be reshared');
    }

    // Get current user data
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() ?? {};

    final statusId = '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    final resharedStatus = {
      'statusId': statusId,
      'userId': currentUserId,
      'userName': userData['fullName'] ?? userData['email'] ?? 'Unknown',
      'userPhoto': userData['photoUrl'],
      'type': originalData['type'],
      'text': originalData['text'],
      'mediaUrl': originalData['mediaUrl'],
      'backgroundColor': originalData['backgroundColor'],
      'allowReshare': originalData['allowReshare'],
      'isReshared': true,
      'originalStatusId': originalStatusId,
      'originalUserId': originalData['userId'],
      'originalUserName': originalData['userName'],
      'views': [],
      'viewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };

    await _firestore.collection('statuses').doc(statusId).set(resharedStatus);
  }

  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    await _firestore.collection('statuses').doc(statusId).delete();
  }

  // Update reshare settings
  Future<void> updateReshareSettings(String statusId, bool allowReshare) async {
    await _firestore.collection('statuses').doc(statusId).update({
      'allowReshare': allowReshare,
    });
  }
}
