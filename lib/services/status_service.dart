import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/status_model.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'statuses';

  // Post text status
  Future<String?> postTextStatus({
    required String odId,
    required String content,
    required String posterName,
    String? posterPhotoUrl,
    String backgroundColor = '#1565C0',
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final docRef = await _firestore.collection(_collection).add({
        'odId': odId,
        'postedBy': odId,
        'posterName': posterName,
        'posterPhotoUrl': posterPhotoUrl,
        'content': content,
        'type': 'text',
        'backgroundColor': backgroundColor,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewedBy': [],
      });

      return docRef.id;
    } catch (e) {
      print('Error posting status: $e');
      return null;
    }
  }

  // Post image status
  Future<String?> postImageStatus({
    required String odId,
    required String posterName,
    String? posterPhotoUrl,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Upload image
      final storagePath = 'statuses/$odId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref().child(storagePath);
      await ref.putData(imageBytes);
      final imageUrl = await ref.getDownloadURL();

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final docRef = await _firestore.collection(_collection).add({
        'odId': odId,
        'postedBy': odId,
        'posterName': posterName,
        'posterPhotoUrl': posterPhotoUrl,
        'content': imageUrl,
        'type': 'image',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewedBy': [],
      });

      return docRef.id;
    } catch (e) {
      print('Error posting image status: $e');
      return null;
    }
  }

  // Get all active statuses (not expired)
  Stream<List<StatusModel>> getActiveStatuses() {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StatusModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get user's statuses
  Stream<List<StatusModel>> getUserStatuses(String odId) {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('postedBy', isEqualTo: odId)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StatusModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Mark status as viewed
  Future<void> markAsViewed(String statusId, String odId) async {
    await _firestore.collection(_collection).doc(statusId).update({
      'viewedBy': FieldValue.arrayUnion([odId]),
    });
  }

  // Delete status
  Future<bool> deleteStatus(String statusId, String? imageUrl) async {
    try {
      if (imageUrl != null && imageUrl.contains('firebase')) {
        await _storage.refFromURL(imageUrl).delete();
      }
      await _firestore.collection(_collection).doc(statusId).delete();
      return true;
    } catch (e) {
      print('Error deleting status: $e');
      return false;
    }
  }

  // Clean up expired statuses (can be called periodically)
  Future<void> cleanupExpiredStatuses() async {
    final now = DateTime.now();
    final expired = await _firestore
        .collection(_collection)
        .where('expiresAt', isLessThan: Timestamp.fromDate(now))
        .get();

    for (var doc in expired.docs) {
      final data = doc.data();
      if (data['type'] == 'image') {
        try {
          await _storage.refFromURL(data['content']).delete();
        } catch (_) {}
      }
      await doc.reference.delete();
    }
  }

  // Like/Unlike status
  Future<void> toggleLikeStatus(String statusId, String userId) async {
    final statusDoc = await _firestore.collection('statuses').doc(statusId).get();
    final likedBy = List<String>.from(statusDoc['likedBy'] ?? []);

    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }

    await _firestore.collection('statuses').doc(statusId).update({'likedBy': likedBy});
  }

  // Get like count
  Future<int> getLikeCount(String statusId) async {
    final doc = await _firestore.collection('statuses').doc(statusId).get();
    return (doc['likedBy'] as List).length;
  }
}
