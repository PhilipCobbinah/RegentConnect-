class BlockedUserModel {
  final String blockedUserId;
  final String blockedUserName;
  final String? blockedUserPhotoUrl;
  final DateTime blockedAt;

  BlockedUserModel({
    required this.blockedUserId,
    required this.blockedUserName,
    this.blockedUserPhotoUrl,
    required this.blockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'blockedUserId': blockedUserId,
      'blockedUserName': blockedUserName,
      'blockedUserPhotoUrl': blockedUserPhotoUrl,
      'blockedAt': blockedAt,
    };
  }

  factory BlockedUserModel.fromMap(Map<String, dynamic> map) {
    return BlockedUserModel(
      blockedUserId: map['blockedUserId'] ?? '',
      blockedUserName: map['blockedUserName'] ?? '',
      blockedUserPhotoUrl: map['blockedUserPhotoUrl'],
      blockedAt: (map['blockedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
