import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blocked_user_model.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Block a user
  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
    required String blockedUserName,
    String? blockedUserPhotoUrl,
  }) async {
    final blockedUser = BlockedUserModel(
      blockedUserId: blockedUserId,
      blockedUserName: blockedUserName,
      blockedUserPhotoUrl: blockedUserPhotoUrl,
      blockedAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .set(blockedUser.toMap());
  }

  // Unblock a user
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .delete();
  }

  // Get blocked users
  Stream<List<BlockedUserModel>> getBlockedUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BlockedUserModel.fromMap(doc.data()))
            .toList());
  }

  // Check if user is blocked
  Future<bool> isUserBlocked({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(otherUserId)
        .get();
    return doc.exists;
  }
}
