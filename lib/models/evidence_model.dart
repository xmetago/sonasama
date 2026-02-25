import 'package:hive/hive.dart';

part 'evidence_model.g.dart';

@HiveType(typeId: 10) // Unique typeId for evidence model
class EvidenceModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String davaId; // Hangi davaya ait

  @HiveField(2)
  String type; // 'image', 'video', 'text', 'link'

  @HiveField(3)
  String title; // Delil başlığı

  @HiveField(4)
  String description; // Delil açıklaması

  @HiveField(5)
  String filePath; // Dosya yolu (resim, video, pdf için)

  @HiveField(6)
  String url; // Link için URL

  @HiveField(7)
  int fileSize; // Dosya boyutu (bytes)

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  bool isVerified; // Link güvenlik kontrolü için

  @HiveField(10)
  String userId; // Hangi kullanıcı ekledi

  @HiveField(11)
  int likeCount; // Beğeni sayısı

  @HiveField(12)
  int dislikeCount; // Beğenmeme sayısı

  @HiveField(13)
  Map<dynamic, dynamic> likedBy; // Kullanıcı email -> 'like' veya 'dislike'

  EvidenceModel({
    required this.id,
    required this.davaId,
    required this.type,
    required this.title,
    required this.description,
    this.filePath = '',
    this.url = '',
    this.fileSize = 0,
    required this.createdAt,
    this.isVerified = false,
    required this.userId,
    this.likeCount = 0,
    this.dislikeCount = 0,
    Map<String, String>? likedBy,
  }) : likedBy = likedBy ?? {};

  // Özel ID oluşturma metodu: Davaid_01, Davaid_02, Davaid_03...
  static String generateEvidenceId(String davaId, int currentCount) {
    return '${davaId}_${(currentCount + 1).toString().padLeft(2, '0')}';
  }

  // JSON'dan model oluşturma
  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'] ?? '',
      davaId: json['davaId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      filePath: json['filePath'] ?? '',
      url: json['url'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isVerified: json['isVerified'] ?? false,
      userId: json['userId'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      dislikeCount: json['dislikeCount'] ?? 0,
      likedBy: json['likedBy'] != null 
          ? Map<String, String>.from(json['likedBy'])
          : {},
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'davaId': davaId,
      'type': type,
      'title': title,
      'description': description,
      'filePath': filePath,
      'url': url,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'userId': userId,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'likedBy': likedBy,
    };
  }

  // Kopyalama metodu
  EvidenceModel copyWith({
    String? id,
    String? davaId,
    String? type,
    String? title,
    String? description,
    String? filePath,
    String? url,
    int? fileSize,
    DateTime? createdAt,
    bool? isVerified,
    String? userId,
    int? likeCount,
    int? dislikeCount,
    Map<String, String>? likedBy,
  }) {
    return EvidenceModel(
      id: id ?? this.id,
      davaId: davaId ?? this.davaId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      userId: userId ?? this.userId,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      likedBy: likedBy ?? Map<String, String>.from(this.likedBy),
    );
  }
  
  /// Kullanıcının bu delili beğenip beğenmediğini kontrol et
  String? getUserVote(String userEmail) {
    return likedBy[userEmail]?.toString();
  }
  
  /// Kullanıcı beğendi mi?
  bool hasUserLiked(String userEmail) {
    return likedBy[userEmail] == 'like';
  }
  
  /// Kullanıcı beğenmedi mi?
  bool hasUserDisliked(String userEmail) {
    return likedBy[userEmail] == 'dislike';
  }
}

// Evidence limits and constraints
class EvidenceLimits {
  static const int maxImages = 19;
  static const int maxVideos = 19;
  static const int maxPdfs = 19;
  static const int maxLinks = 19;

  // File size limits (in bytes)
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 40 * 1024 * 1024; // 40MB (kullanıcı isteği)
  static const int maxPdfSize = 10 * 1024 * 1024; // 10MB

  // Validation rules
  static const int minTitleLength = 1; // Delil başlığı minimum 1 karakter
  static const int minDescriptionLength = 6; // Delil açıklaması minimum 6 karakter

  // Allowed file extensions
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedVideoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'];
  static const List<String> allowedPdfExtensions = ['pdf'];

  // Validation methods
  static bool isValidTitle(String title) {
    return title.trim().length >= minTitleLength;
  }

  static bool isValidDescription(String description) {
    return description.trim().length >= minDescriptionLength;
  }

  static bool isTitleUnique(String title, String davaId, List<EvidenceModel> existingEvidences) {
    return !existingEvidences.any((evidence) => 
      evidence.davaId == davaId && 
      evidence.title.toLowerCase().trim() == title.toLowerCase().trim()
    );
  }
}
