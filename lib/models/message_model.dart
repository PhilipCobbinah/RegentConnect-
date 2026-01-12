import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String? recipientId;
  final String content;
  final String type; // 'text', 'image', 'video', 'audio', 'file'
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final bool isViewOnce;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final String? replyToSenderName;
  final String? replyToContent;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    this.recipientId,
    required this.content,
    required this.type,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.isViewOnce = false,
    required this.timestamp,
    this.isRead = false,
    this.editedAt,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToContent,
  });

  bool get canEdit {
    final now = DateTime.now();
    final editWindow = timestamp.add(const Duration(minutes: 15));
    return now.isBefore(editWindow);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'recipientId': recipientId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isViewOnce': isViewOnce,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'replyToMessageId': replyToMessageId,
      'replyToSenderName': replyToSenderName,
      'replyToContent': replyToContent,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return MessageModel(
      id: docId ?? map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      senderPhotoUrl: map['senderPhotoUrl'],
      recipientId: map['recipientId'],
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      isViewOnce: map['isViewOnce'] ?? false,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      editedAt: map['editedAt'] != null
          ? (map['editedAt'] as Timestamp).toDate()
          : null,
      replyToMessageId: map['replyToMessageId'],
      replyToSenderName: map['replyToSenderName'],
      replyToContent: map['replyToContent'],
    );
  }

  MessageModel copyWith({
    String? content,
    DateTime? editedAt,
    bool? isRead,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      recipientId: recipientId,
      content: content ?? this.content,
      type: type,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      isViewOnce: isViewOnce,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      editedAt: editedAt ?? this.editedAt,
      replyToMessageId: replyToMessageId,
      replyToSenderName: replyToSenderName,
      replyToContent: replyToContent,
    );
  }
}
