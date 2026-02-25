import 'package:hive/hive.dart';

part 'friendship_model.g.dart';

@HiveType(typeId: 6)
enum FriendshipStatus {
  @HiveField(0)
  none,
  @HiveField(1)
  pending,
  @HiveField(2)
  accepted,
  @HiveField(3)
  rejected,
  @HiveField(4)
  blocked,
  @HiveField(5)
  following
}

@HiveType(typeId: 5)
class FriendshipModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String requesterId;

  @HiveField(2)
  final String recipientId;

  @HiveField(3)
  final FriendshipStatus status;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  final String? message;

  FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.message,
  });

  // Kopyalama metodu
  FriendshipModel copyWith({
    String? id,
    String? requesterId,
    String? recipientId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? message,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      recipientId: recipientId ?? this.recipientId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      message: message ?? this.message,
    );
  }

  // JSON dönüşümleri
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'recipientId': recipientId,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'message': message,
    };
  }

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'],
      requesterId: json['requesterId'],
      recipientId: json['recipientId'],
      status: FriendshipStatus.values[json['status']],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      message: json['message'],
    );
  }
}
