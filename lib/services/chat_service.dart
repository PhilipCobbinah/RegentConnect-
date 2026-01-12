import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';
import '../core/constants.dart';
import 'streak_service.dart';
import 'auth_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  final streakService = StreakService();
  final AuthService _authService = AuthService();

  // Generate consistent chat ID for two users
  String getChatId(String odId1, String odId2) {
    final ids = [odId1, odId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Get messages stream
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Send text message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String? senderPhotoUrl,
    required String recipientId,
    required String recipientName,
    required String? recipientPhotoUrl,
    required String content,
    required String type,
  }) async {
    final messageId = _uuid.v4();

    try {
      // Send message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set({
            'id': messageId,
            'chatId': chatId,
            'senderId': senderId,
            'senderName': senderName,
            'senderPhotoUrl': senderPhotoUrl,
            'recipientId': recipientId,
            'content': content,
            'type': type,
            'timestamp': Timestamp.now(),
            'isRead': false,
          });

      // Update last message
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [senderId, recipientId],
        'lastMessage': content,
        'lastMessageTime': Timestamp.now(),
        'lastSenderId': senderId,
      }, SetOptions(merge: true));

      // Update streak
      await streakService.updateStreak(
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        recipientId: recipientId,
        recipientName: recipientName,
        recipientPhotoUrl: recipientPhotoUrl,
      );
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send media message
  Future<void> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required Uint8List fileBytes,
    required String fileName,
    required String type,
    bool isViewOnce = false,
  }) async {
    final messageId = _uuid.v4();
    
    // Upload file
    final storagePath = 'chats/$chatId/$messageId/$fileName';
    final ref = _storage.ref().child(storagePath);
    await ref.putData(fileBytes, SettableMetadata(contentType: _getContentType(type, fileName)));
    final mediaUrl = await ref.getDownloadURL();

    // Calculate file size
    final fileSize = _formatFileSize(fileBytes.length);

    final message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      content: type == 'text' ? '' : '📎 ${_getMediaLabel(type)}',
      type: type,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      isViewOnce: isViewOnce,
      timestamp: DateTime.now(),
    );

    // Update chat
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, recipientId],
      'lastMessage': '📎 ${_getMediaLabel(type)}',
      'lastMessageTime': Timestamp.now(),
      'lastMessageSender': senderId,
    }, SetOptions(merge: true));

    // Add message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());
  }

  // Mark view once as viewed
  Future<void> markViewOnceAsViewed(String messageId, String odId) async {
    // Find the message and update viewedBy
    final chats = await _firestore.collection('chats').get();
    for (var chat in chats.docs) {
      final messageDoc = await chat.reference
          .collection('messages')
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        await messageDoc.reference.update({
          'viewedBy': FieldValue.arrayUnion([odId]),
        });
        break;
      }
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId, String odId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('recipientId', isEqualTo: odId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Edit message (within 15 minutes)
  Future<bool> editMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      final messageDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) return false;

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final timestamp = (messageData['timestamp'] as Timestamp).toDate();
      final now = DateTime.now();
      final editWindow = timestamp.add(const Duration(minutes: 15));

      // Check if edit window is still open
      if (now.isAfter(editWindow)) {
        return false; // Cannot edit after 15 minutes
      }

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'content': newContent,
            'editedAt': DateTime.now(),
          });

      return true;
    } catch (e) {
      print('Error editing message: $e');
      return false;
    }
  }

  // Delete message
  Future<bool> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // Send reply message
  Future<bool> sendReplyMessage({
    required String chatId,
    required String receiverId,
    required String messageContent,
    required String replyToMessageId,
    required String replyToSenderName,
    required String replyToContent,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = DateTime.now();

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set({
            'id': messageId,
            'chatId': chatId,
            'senderId': currentUser.uid,
            'senderName': currentUser.displayName,
            'senderPhotoUrl': currentUser.photoURL,
            'content': messageContent,
            'type': 'text',
            'timestamp': timestamp,
            'isRead': false,
            'replyToMessageId': replyToMessageId,
            'replyToSenderName': replyToSenderName,
            'replyToContent': replyToContent,
          });

      // Update chat metadata
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': messageContent,
        'lastMessageTime': timestamp,
        'lastSenderId': currentUser.uid,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error sending reply: $e');
      return false;
    }
  }

  String _getContentType(String type, String fileName) {
    switch (type) {
      case 'image':
        return 'image/jpeg';
      case 'video':
        return 'video/mp4';
      case 'audio':
        return 'audio/mpeg';
      default:
        final ext = fileName.split('.').last.toLowerCase();
        switch (ext) {
          case 'pdf':
            return 'application/pdf';
          case 'doc':
          case 'docx':
            return 'application/msword';
          default:
            return 'application/octet-stream';
        }
    }
  }

  String _getMediaLabel(String type) {
    switch (type) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'file':
        return 'Document';
      default:
        return 'File';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Create group
  Future<GroupModel> createGroup({
    required String groupName,
    required String? profilePictureUrl,
    required List<String> memberIds,
    required String createdBy,
    required String creatorName,
    String? creatorPhotoUrl,
    String description = '',
  }) async {
    try {
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final group = GroupModel(
        id: groupId,
        name: groupName,
        profilePictureUrl: profilePictureUrl,
        createdBy: createdBy,
        creatorName: creatorName,
        creatorPhotoUrl: creatorPhotoUrl,
        createdAt: DateTime.now(),
        members: memberIds,
        description: description,
      );

      await _firestore.collection('groups').doc(groupId).set(group.toMap());
      return group;
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  // Join group via link
  Future<void> joinGroup(String groupId, String userId) async {
    await _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  // Get user's groups
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data()))
            .toList());
  }
}
