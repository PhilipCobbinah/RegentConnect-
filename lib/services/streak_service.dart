import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate streak ID from two user IDs
  String _generateStreakId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 
        ? '$userId1-$userId2' 
        : '$userId2-$userId1';
  }

  // Update streak when message is sent
  Future<void> updateStreak({
    required String senderId,
    required String senderName,
    required String? senderPhotoUrl,
    required String recipientId,
    required String recipientName,
    required String? recipientPhotoUrl,
  }) async {
    final streakId = _generateStreakId(senderId, recipientId);

    try {
      final streakDoc = await _firestore
          .collection('streaks')
          .doc(streakId)
          .get();

      if (streakDoc.exists) {
        final streak = StreakModel.fromMap(streakDoc.data() as Map<String, dynamic>);
        final today = DateTime.now();
        final lastMessageDay = DateTime(
          streak.lastMessageDate.year,
          streak.lastMessageDate.month,
          streak.lastMessageDate.day,
        );
        final todayDay = DateTime(today.year, today.month, today.day);

        // Check if message was sent today
        if (todayDay == lastMessageDay) {
          // Same day, no streak increase
          return;
        }

        // Check if last message was yesterday
        final yesterday = todayDay.subtract(const Duration(days: 1));
        if (lastMessageDay == yesterday) {
          // Streak continues, increment count
          await _firestore.collection('streaks').doc(streakId).update({
            'streakCount': streak.streakCount + 1,
            'lastMessageDate': today,
            'isActive': true,
          });
        } else {
          // Streak broken, reset to 1
          await _firestore.collection('streaks').doc(streakId).update({
            'streakCount': 1,
            'lastMessageDate': today,
            'isActive': true,
          });
        }
      } else {
        // Create new streak
        final newStreak = StreakModel(
          id: streakId,
          userId1: senderId,
          userId2: recipientId,
          user1Name: senderName,
          user2Name: recipientName,
          user1PhotoUrl: senderPhotoUrl,
          user2PhotoUrl: recipientPhotoUrl,
          streakCount: 1,
          lastMessageDate: DateTime.now(),
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection('streaks')
            .doc(streakId)
            .set(newStreak.toMap());
      }
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // Get all streaks for a user
  Stream<List<StreakModel>> getUserStreaks(String userId) {
    return _firestore
        .collection('streaks')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StreakModel.fromMap(doc.data()))
            .where((streak) =>
                (streak.userId1 == userId || streak.userId2 == userId) &&
                streak.streakCount > 0)
            .toList()
            .cast<StreakModel>());
  }

  // Get streak between two users
  Future<StreakModel?> getStreak(String userId1, String userId2) async {
    final streakId = _generateStreakId(userId1, userId2);
    final doc = await _firestore.collection('streaks').doc(streakId).get();

    if (doc.exists) {
      return StreakModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
