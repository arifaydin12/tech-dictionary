class Comment {
  final String? id;
  final String wordId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;

  Comment({
    this.id,
    required this.wordId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    DateTime? createdAt,
    this.likes = 0,
    this.likedBy = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'wordId': wordId,
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'likes': likes,
    'likedBy': likedBy,
  };

  factory Comment.fromFirestore(Map<String, dynamic> json, String docId) {
    return Comment(
      id: docId,
      wordId: json['wordId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(json['likedBy'] as List? ?? []),
    );
  }
}

class WordLike {
  final String wordId;
  final String userId;
  final DateTime createdAt;

  WordLike({
    required this.wordId,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'wordId': wordId,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
  };
}

class UserFollow {
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  UserFollow({
    required this.followerId,
    required this.followingId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'followerId': followerId,
    'followingId': followingId,
    'createdAt': createdAt.toIso8601String(),
  };
}

