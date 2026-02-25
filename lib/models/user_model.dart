import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? profilResmi;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime lastLoginAt;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  int totalDavalar;

  @HiveField(8)
  int totalKatildigiDavalar;

  @HiveField(9)
  int totalLikes;

  @HiveField(10)
  String? phoneNumber;

  @HiveField(11)
  String? country;

  @HiveField(12)
  int energyLevel;

  @HiveField(13)
  DateTime? lastEnergyUpdate;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profilResmi,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.totalDavalar = 0,
    this.totalKatildigiDavalar = 0,
    this.totalLikes = 0,
    this.phoneNumber,
    this.country,
    this.energyLevel = 100,
    this.lastEnergyUpdate,
  });

  // JSON'dan model oluşturma
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilResmi: json['profilResmi'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      totalDavalar: json['totalDavalar'] ?? 0,
      totalKatildigiDavalar: json['totalKatildigiDavalar'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      phoneNumber: json['phoneNumber'],
      country: json['country'],
      energyLevel: json['energyLevel'] ?? 100,
      lastEnergyUpdate: json['lastEnergyUpdate'] != null 
          ? DateTime.parse(json['lastEnergyUpdate']) 
          : null,
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profilResmi': profilResmi,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isActive': isActive,
      'totalDavalar': totalDavalar,
      'totalKatildigiDavalar': totalKatildigiDavalar,
      'totalLikes': totalLikes,
      'phoneNumber': phoneNumber,
      'country': country,
      'energyLevel': energyLevel,
      'lastEnergyUpdate': lastEnergyUpdate?.toIso8601String(),
    };
  }

  // Kopyalama metodu
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? profilResmi,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    int? totalDavalar,
    int? totalKatildigiDavalar,
    int? totalLikes,
    String? phoneNumber,
    String? country,
    int? energyLevel,
    DateTime? lastEnergyUpdate,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilResmi: profilResmi ?? this.profilResmi,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      totalDavalar: totalDavalar ?? this.totalDavalar,
      totalKatildigiDavalar: totalKatildigiDavalar ?? this.totalKatildigiDavalar,
      totalLikes: totalLikes ?? this.totalLikes,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      energyLevel: energyLevel ?? this.energyLevel,
      lastEnergyUpdate: lastEnergyUpdate ?? this.lastEnergyUpdate,
    );
  }
} 