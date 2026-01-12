class StreakModel {
  final String id;
  final String userId1;
  final String userId2;
  final String user1Name;
  final String user2Name;
  final String? user1PhotoUrl;
  final String? user2PhotoUrl;
  final int streakCount;
  final DateTime lastMessageDate;
  final DateTime createdAt;
  final bool isActive;

  StreakModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.user1Name,
    required this.user2Name,
    this.user1PhotoUrl,
    this.user2PhotoUrl,
    required this.streakCount,
    required this.lastMessageDate,
    required this.createdAt,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'user1PhotoUrl': user1PhotoUrl,
      'user2PhotoUrl': user2PhotoUrl,
      'streakCount': streakCount,
      'lastMessageDate': lastMessageDate,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory StreakModel.fromMap(Map<String, dynamic> map) {
    return StreakModel(
      id: map['id'] ?? '',
      userId1: map['userId1'] ?? '',
      userId2: map['userId2'] ?? '',
      user1Name: map['user1Name'] ?? '',
      user2Name: map['user2Name'] ?? '',
      user1PhotoUrl: map['user1PhotoUrl'],
      user2PhotoUrl: map['user2PhotoUrl'],
      streakCount: map['streakCount'] ?? 0,
      lastMessageDate: (map['lastMessageDate'] as dynamic)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}
