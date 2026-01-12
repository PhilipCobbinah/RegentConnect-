import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  // Get or create chat room ID between two users
  String getChatRoomId(String otherUserId) {
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    return ids.join('_');
  }

  // Send a text message - updated with reply support
  Future<void> sendMessage({
    required String receiverId,
    required String message,
    String type = 'text',
    String? mediaUrl,
    int? audioDuration,
    Map<String, dynamic>? replyTo,
  }) async {
    if (currentUserId.isEmpty) return;

    final chatRoomId = getChatRoomId(receiverId);
    final timestamp = FieldValue.serverTimestamp();

    // Get sender info
    final senderDoc = await _firestore.collection('users').doc(currentUserId).get();
    final senderData = senderDoc.data() ?? {};

    final messageData = {
      'senderId': currentUserId,
      'senderEmail': currentUserEmail,
      'senderName': senderData['fullName'] ?? currentUserEmail,
      'senderPhoto': senderData['photoUrl'],
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'mediaUrl': mediaUrl,
      'audioDuration': audioDuration,
      'timestamp': timestamp,
      'isRead': false,
      'isDeleted': false,
      'reactions': {},
      'starredBy': [],
      'replyTo': replyTo != null ? {
        'messageId': replyTo['messageId'],
        'senderId': replyTo['senderId'],
        'senderName': replyTo['senderName'],
        'message': replyTo['message'],
        'type': replyTo['type'],
      } : null,
    };

    // Add message to chat room
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update chat room metadata
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': message,
      'lastMessageType': type,
      'lastMessageTime': timestamp,
      'lastSenderId': currentUserId,
      'lastSenderName': senderData['fullName'] ?? currentUserEmail,
    }, SetOptions(merge: true));
  }

  // Toggle reaction on a message
  Future<void> toggleReaction(String otherUserId, String messageId, String emoji) async {
    final chatRoomId = getChatRoomId(otherUserId);
    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);

    final doc = await messageRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final reactions = Map<String, List<dynamic>>.from(data['reactions'] ?? {});

    if (reactions[emoji] == null) {
      reactions[emoji] = [currentUserId];
    } else if (reactions[emoji]!.contains(currentUserId)) {
      reactions[emoji]!.remove(currentUserId);
      if (reactions[emoji]!.isEmpty) {
        reactions.remove(emoji);
      }
    } else {
      reactions[emoji]!.add(currentUserId);
    }

    await messageRef.update({'reactions': reactions});
  }

  // Toggle star on a message
  Future<void> toggleStar(String otherUserId, String messageId) async {
    final chatRoomId = getChatRoomId(otherUserId);
    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);

    final doc = await messageRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final starredBy = List<String>.from(data['starredBy'] ?? []);

    if (starredBy.contains(currentUserId)) {
      starredBy.remove(currentUserId);
    } else {
      starredBy.add(currentUserId);
    }

    await messageRef.update({'starredBy': starredBy});
  }

  // Delete message (soft delete) - updated to show who deleted
  Future<void> deleteMessage(String otherUserId, String messageId) async {
    final chatRoomId = getChatRoomId(otherUserId);
    
    // Get current user name
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userName = userDoc.data()?['fullName'] ?? userDoc.data()?['email'] ?? 'Someone';
    
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({
          'isDeleted': true,
          'deletedBy': currentUserId,
          'deletedByName': userName,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedForMe': true,
        });
  }

  // Delete for everyone - updated to show who deleted
  Future<void> deleteForEveryone(String otherUserId, String messageId) async {
    final chatRoomId = getChatRoomId(otherUserId);
    
    // Get current user name
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userName = userDoc.data()?['fullName'] ?? userDoc.data()?['email'] ?? 'Someone';
    
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({
          'message': '',
          'isDeleted': true,
          'deletedForEveryone': true,
          'deletedBy': currentUserId,
          'deletedByName': userName,
          'deletedAt': FieldValue.serverTimestamp(),
          'mediaUrl': null,
          'type': 'deleted',
        });
  }

  // Get messages stream between two users - with notification
  Stream<QuerySnapshot> getMessages(String otherUserId) {
    final chatRoomId = getChatRoomId(otherUserId);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Listen for new messages and play sound
  void listenForNewMessages(String otherUserId, {Function(Map<String, dynamic>)? onNewMessage}) {
    final chatRoomId = getChatRoomId(otherUserId);
    
    _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final data = snapshot.docs.first.data();
            // Only play sound if message is from other user and recent
            if (data['senderId'] != currentUserId) {
              final timestamp = data['timestamp'] as Timestamp?;
              if (timestamp != null) {
                final messageTime = timestamp.toDate();
                final now = DateTime.now();
                // Only if message is within last 5 seconds (new message)
                if (now.difference(messageTime).inSeconds < 5) {
                  _notificationService.playMessageSound();
                  onNewMessage?.call(data);
                }
              }
            }
          }
        });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    final chatRoomId = getChatRoomId(otherUserId);
    final unreadMessages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Get all chat rooms for current user
  Stream<QuerySnapshot> getChatRooms() {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String odbc) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Get user stream
  Stream<DocumentSnapshot> getUserStream(String odbc) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Clear chat (soft delete all messages for current user)
  Future<void> clearChat(String otherUserId) async {
    final chatRoomId = getChatRoomId(otherUserId);
    final messages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({
        'deletedFor': FieldValue.arrayUnion([currentUserId])
      });
    }
  }

  // Set typing status
  Future<void> setTypingStatus(String recipientId, bool isTyping) async {
    if (currentUserId.isEmpty) return;
    
    final chatRoomId = getChatRoomId(recipientId);
    
    // Get current user data for name
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userName = userDoc.data()?['fullName'] ?? userDoc.data()?['email'] ?? 'Someone';
    
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'typing': {
        currentUserId: isTyping ? userName : null,
      },
    }, SetOptions(merge: true));
    
    // Auto-clear typing after 5 seconds
    if (isTyping) {
      Future.delayed(const Duration(seconds: 5), () {
        setTypingStatus(recipientId, false);
      });
    }
  }

  // Listen to typing status
  Stream<DocumentSnapshot> getTypingStatus(String recipientId) {
    final chatRoomId = getChatRoomId(recipientId);
    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots();
  }
}
