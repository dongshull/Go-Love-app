class Memory {
  final int id;
  final String? avatar;
  final String? title;
  final String? content;
  final String? image;
  final String? moodTag;
  final int userId;
  final String? username;
  final String? creatorName;
  final String? creatorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  Memory({
    required this.id,
    this.avatar,
    this.title,
    this.content,
    this.image,
    this.moodTag,
    required this.userId,
    this.username,
    this.creatorName,
    this.creatorAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    print('解析Memory数据: $json');
    
    // 检查图片数据是否在avatar字段中
    String? imageData = json['image'];
    final avatarData = json['avatar'];
    
    // 如果image为空且avatar包含图片数据，则移动数据
    if (imageData == null && avatarData != null && avatarData.toString().startsWith('data:image/')) {
      print('警告: 图片数据在avatar字段中，将移动到image字段');
      imageData = avatarData;
    }

    return Memory(
      id: json['id'] ?? 0,
      avatar: avatarData != null && !avatarData.toString().startsWith('data:image/') ? avatarData : null,
      title: json['title'],
      content: json['content'],
      image: imageData,
      moodTag: json['mood_tag'],
      userId: json['user_id'] ?? 0,
      username: json['username'],
      creatorName: json['creator_name'],
      creatorAvatar: json['creator_avatar'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}