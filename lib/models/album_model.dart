import 'package:hive/hive.dart';

part 'album_model.g.dart';

@HiveType(typeId: 21) // Unique typeId for album model
class AlbumModel extends HiveObject {
  @HiveField(0)
  String id; // Albüm ID'si

  @HiveField(1)
  String name; // Albüm adı

  @HiveField(2)
  String userEmail; // Hangi kullanıcıya ait

  @HiveField(3)
  DateTime createdAt; // Oluşturulma tarihi

  @HiveField(4)
  DateTime? updatedAt; // Son güncelleme tarihi

  @HiveField(5)
  String? description; // Albüm açıklaması (opsiyonel)

  AlbumModel({
    required this.id,
    required this.name,
    required this.userEmail,
    required this.createdAt,
    this.updatedAt,
    this.description,
  });

  // JSON'dan model oluşturma
  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      userEmail: json['userEmail'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      description: json['description'],
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userEmail': userEmail,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'description': description,
    };
  }

  // Kopyalama metodu
  AlbumModel copyWith({
    String? id,
    String? name,
    String? userEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userEmail: userEmail ?? this.userEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }
}

