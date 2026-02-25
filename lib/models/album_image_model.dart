import 'package:hive/hive.dart';

part 'album_image_model.g.dart';

@HiveType(typeId: 22) // Unique typeId for album image model
class AlbumImageModel extends HiveObject {
  @HiveField(0)
  String id; // Resim ID'si

  @HiveField(1)
  String albumId; // Hangi albüme ait

  @HiveField(2)
  String imageUrl; // Resim URL'si (base64 veya file path)

  @HiveField(3)
  String? imagePath; // Yerel dosya yolu (opsiyonel)

  @HiveField(4)
  DateTime createdAt; // Eklenme tarihi

  @HiveField(5)
  String? title; // Resim başlığı (opsiyonel)

  @HiveField(6)
  String? description; // Resim açıklaması (opsiyonel)

  @HiveField(7)
  int fileSize; // Dosya boyutu (bytes)

  AlbumImageModel({
    required this.id,
    required this.albumId,
    required this.imageUrl,
    this.imagePath,
    required this.createdAt,
    this.title,
    this.description,
    this.fileSize = 0,
  });

  // JSON'dan model oluşturma
  factory AlbumImageModel.fromJson(Map<String, dynamic> json) {
    return AlbumImageModel(
      id: json['id'] ?? '',
      albumId: json['albumId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      imagePath: json['imagePath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      title: json['title'],
      description: json['description'],
      fileSize: json['fileSize'] ?? 0,
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumId': albumId,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'description': description,
      'fileSize': fileSize,
    };
  }

  // Kopyalama metodu
  AlbumImageModel copyWith({
    String? id,
    String? albumId,
    String? imageUrl,
    String? imagePath,
    DateTime? createdAt,
    String? title,
    String? description,
    int? fileSize,
  }) {
    return AlbumImageModel(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

