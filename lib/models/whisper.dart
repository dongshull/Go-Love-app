class Whisper {
  final int id;
  final String? avatar;
  final String? name;
  final String? content;
  final int userId;
  final String? username;
  final DateTime createdAt;
  final DateTime updatedAt;

  Whisper({
    required this.id,
    this.avatar,
    this.name,
    this.content,
    required this.userId,
    this.username,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Whisper.fromJson(Map<String, dynamic> json) {
    return Whisper(
      id: json['id'] ?? 0,
      avatar: json['avatar'],
      name: json['name'],
      content: json['content'],
      userId: json['user_id'] ?? 0,
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
      'name': name,
      'content': content,
      'avatar': avatar,
      'user_id': userId,
      'username': username,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}