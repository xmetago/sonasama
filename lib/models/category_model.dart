import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> subCategories;

  @HiveField(3)
  String? iconPath;

  @HiveField(4)
  bool isActive;

  @HiveField(5)
  int totalDavalar;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  int orderIndex;

  CategoryModel({
    required this.id,
    required this.name,
    required this.subCategories,
    this.iconPath,
    this.isActive = true,
    this.totalDavalar = 0,
    required this.createdAt,
    this.orderIndex = 0,
  });

  // JSON'dan model oluşturma
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subCategories: List<String>.from(json['subCategories'] ?? []),
      iconPath: json['iconPath'],
      isActive: json['isActive'] ?? true,
      totalDavalar: json['totalDavalar'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      orderIndex: json['orderIndex'] ?? 0,
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subCategories': subCategories,
      'iconPath': iconPath,
      'isActive': isActive,
      'totalDavalar': totalDavalar,
      'createdAt': createdAt.toIso8601String(),
      'orderIndex': orderIndex,
    };
  }

  // Kopyalama metodu
  CategoryModel copyWith({
    String? id,
    String? name,
    List<String>? subCategories,
    String? iconPath,
    bool? isActive,
    int? totalDavalar,
    DateTime? createdAt,
    int? orderIndex,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subCategories: subCategories ?? this.subCategories,
      iconPath: iconPath ?? this.iconPath,
      isActive: isActive ?? this.isActive,
      totalDavalar: totalDavalar ?? this.totalDavalar,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
} 