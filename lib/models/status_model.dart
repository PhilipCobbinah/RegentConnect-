import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String id;
  final String odId;
  final String postedBy;
  final String posterName;
  final String? posterPhotoUrl;
  final String content; // text or image url
  final String type; // 'text', 'image'
  final String? backgroundColor; // for text status
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;
  final List<String> likedBy;

  StatusModel({
    required this.id,
    required this.odId,
    required this.postedBy,
    required this.posterName,
    this.posterPhotoUrl,
    required this.content,
    required this.type,
    this.backgroundColor,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.likedBy = const [],
  });

  factory StatusModel.fromMap(Map<String, dynamic> map, String id) {
    return StatusModel(
      id: id,
      odId: map['odId'] ?? '',
      postedBy: map['postedBy'] ?? '',
      posterName: map['posterName'] ?? '',
      posterPhotoUrl: map['posterPhotoUrl'],
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      backgroundColor: map['backgroundColor'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'odId': odId,
      'postedBy': postedBy,
      'posterName': posterName,
      'posterPhotoUrl': posterPhotoUrl,
      'content': content,
      'type': type,
      'backgroundColor': backgroundColor,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': viewedBy,
      'likedBy': likedBy,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
