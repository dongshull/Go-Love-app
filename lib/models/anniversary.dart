class Anniversary {
  final int id;
  final String? avatar;
  final String? name;
  final String? content;
  final String? moodTag;
  final int userId;
  final int creatorId;
  final String? creatorName;
  final String? username;
  final DateTime createdAt;
  final DateTime updatedAt;

  Anniversary({
    required this.id,
    this.avatar,
    this.name,
    this.content,
    this.moodTag,
    required this.userId,
    required this.creatorId,
    this.creatorName,
    this.username,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Anniversary.fromJson(Map<String, dynamic> json) {
    return Anniversary(
      id: json['id'] ?? 0,
      avatar: json['avatar'],
      name: json['name'],
      content: json['content'],
      moodTag: json['mood_tag'],
      userId: json['user_id'] ?? 0,
      creatorId: json['creator_id'] ?? 0,
      creatorName: json['creator_name'],
      username: json['username'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar': avatar,
      'name': name,
      'content': content,
      'moodTag': moodTag,
      'userId': userId,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}