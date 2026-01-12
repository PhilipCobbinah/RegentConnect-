
class GroupModel {
  final String id;
  final String name;
  final String? profilePictureUrl;
  final String createdBy;
  final String creatorName;
  final String? creatorPhotoUrl;
  final DateTime createdAt;
  final List<String> members;
  final String description;
  final String? inviteLink;

  // Aliases for compatibility
  String get groupName => name;
  List<String> get memberIds => members;

  GroupModel({
    required this.id,
    required this.name,
    this.profilePictureUrl,
    required this.createdBy,
    required this.creatorName,
    this.creatorPhotoUrl,
    required this.createdAt,
    required this.members,
    this.description = '',
    this.inviteLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profilePictureUrl': profilePictureUrl,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'creatorPhotoUrl': creatorPhotoUrl,
      'createdAt': createdAt,
      'members': members,
      'description': description,
      'inviteLink': inviteLink,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      createdBy: map['createdBy'] ?? '',
      creatorName: map['creatorName'] ?? '',
      creatorPhotoUrl: map['creatorPhotoUrl'],
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      members: List<String>.from(map['members'] ?? []),
      description: map['description'] ?? '',
      inviteLink: map['inviteLink'],
    );
  }
}
