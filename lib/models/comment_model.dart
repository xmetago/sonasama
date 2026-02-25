import 'package:hive/hive.dart';

part 'comment_model.g.dart';

@HiveType(typeId: 2)
class CommentModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String davaId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  String userUsername;

  @HiveField(4)
  String? userProfilResmi;

  @HiveField(5)
  String content;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  int likeCount;

  @HiveField(8)
  int dislikeCount;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  String? parentCommentId;

  @HiveField(11)
  List<String> likedByUsers;

  @HiveField(12)
  List<String> dislikedByUsers;

  CommentModel({
    required this.id,
    required this.davaId,
    required this.userId,
    required this.userUsername,
    this.userProfilResmi,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.isActive = true,
    this.parentCommentId,
    this.likedByUsers = const [],
    this.dislikedByUsers = const [],
  });

  // JSON'dan model oluşturma
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      davaId: json['davaId'] ?? '',
      userId: json['userId'] ?? '',
      userUsername: json['userUsername'] ?? '',
      userProfilResmi: json['userProfilResmi'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      likeCount: json['likeCount'] ?? 0,
      dislikeCount: json['dislikeCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      parentCommentId: json['parentCommentId'],
      likedByUsers: List<String>.from(json['likedByUsers'] ?? []),
      dislikedByUsers: List<String>.from(json['dislikedByUsers'] ?? []),
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'davaId': davaId,
      'userId': userId,
      'userUsername': userUsername,
      'userProfilResmi': userProfilResmi,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'isActive': isActive,
      'parentCommentId': parentCommentId,
      'likedByUsers': likedByUsers,
      'dislikedByUsers': dislikedByUsers,
    };
  }

  // Kopyalama metodu
  CommentModel copyWith({
    String? id,
    String? davaId,
    String? userId,
    String? userUsername,
    String? userProfilResmi,
    String? content,
    DateTime? createdAt,
    int? likeCount,
    int? dislikeCount,
    bool? isActive,
    String? parentCommentId,
    List<String>? likedByUsers,
    List<String>? dislikedByUsers,
  }) {
    return CommentModel(
      id: id ?? this.id,
      davaId: davaId ?? this.davaId,
      userId: userId ?? this.userId,
      userUsername: userUsername ?? this.userUsername,
      userProfilResmi: userProfilResmi ?? this.userProfilResmi,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isActive: isActive ?? this.isActive,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      dislikedByUsers: dislikedByUsers ?? this.dislikedByUsers,
    );
  }
} 