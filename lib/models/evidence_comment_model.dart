import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'evidence_comment_model.g.dart';

@HiveType(typeId: 7) // Unique typeId for evidence comment model
class EvidenceCommentModel extends HiveObject {
  @HiveField(0)
  String id; // Benzersiz yorum ID'si: evidenceId_userRole_userEmail

  @HiveField(1)
  String evidenceId; // Hangi delile ait

  @HiveField(2)
  String davaId; // Hangi davaya ait

  @HiveField(3)
  String userRole; // Kullanıcı rolü (Temyiz hakimi, Yargıç, vb.)

  @HiveField(4)
  String userEmail; // Kullanıcı e-postası

  @HiveField(5)
  String commentText; // Yorum metni

  @HiveField(6)
  String criticism; // Eleştiri türü: 'positive', 'negative', 'neutral'

  @HiveField(7)
  DateTime createdAt; // Oluşturulma tarihi

  @HiveField(8)
  DateTime? updatedAt; // Güncellenme tarihi

  @HiveField(9)
  bool isVerified; // Doğrulanmış mı

  EvidenceCommentModel({
    required this.id,
    required this.evidenceId,
    required this.davaId,
    required this.userRole,
    required this.userEmail,
    required this.commentText,
    this.criticism = 'neutral',
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
  });

  // Benzersiz ID oluşturma metodu
  static String generateCommentId(String evidenceId, String userRole, String userEmail) {
    return '${evidenceId}_${userRole}_$userEmail';
  }

  // JSON'dan model oluşturma
  factory EvidenceCommentModel.fromJson(Map<String, dynamic> json) {
    return EvidenceCommentModel(
      id: json['id'] ?? '',
      evidenceId: json['evidenceId'] ?? '',
      davaId: json['davaId'] ?? '',
      userRole: json['userRole'] ?? '',
      userEmail: json['userEmail'] ?? '',
      commentText: json['commentText'] ?? '',
      criticism: json['criticism'] ?? 'neutral',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isVerified: json['isVerified'] ?? false,
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'evidenceId': evidenceId,
      'davaId': davaId,
      'userRole': userRole,
      'userEmail': userEmail,
      'commentText': commentText,
      'criticism': criticism,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  // Kopyalama metodu
  EvidenceCommentModel copyWith({
    String? id,
    String? evidenceId,
    String? davaId,
    String? userRole,
    String? userEmail,
    String? commentText,
    String? criticism,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) {
    return EvidenceCommentModel(
      id: id ?? this.id,
      evidenceId: evidenceId ?? this.evidenceId,
      davaId: davaId ?? this.davaId,
      userRole: userRole ?? this.userRole,
      userEmail: userEmail ?? this.userEmail,
      commentText: commentText ?? this.commentText,
      criticism: criticism ?? this.criticism,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

// Rol bilgileri
class EvidenceCommentRole {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const EvidenceCommentRole({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  // 8 rol listesi
  static List<EvidenceCommentRole> get allRoles => [
    const EvidenceCommentRole(
      label: 'Temyiz hakimi',
      value: 'Temyiz hakimi',
      icon: Icons.gavel,
      color: Colors.purple,
    ),
    const EvidenceCommentRole(
      label: 'Yargıç',
      value: 'Yargıç',
      icon: Icons.account_balance,
      color: Colors.blue,
    ),
    const EvidenceCommentRole(
      label: 'Davacı avukatı',
      value: 'Davacı avukatı',
      icon: Icons.business_center,
      color: Colors.green,
    ),
    const EvidenceCommentRole(
      label: 'Davalı avukatı',
      value: 'Davalı avukatı',
      icon: Icons.business_center,
      color: Colors.orange,
    ),
    const EvidenceCommentRole(
      label: '1.Jüri',
      value: '1.Jüri',
      icon: Icons.people,
      color: Colors.teal,
    ),
    const EvidenceCommentRole(
      label: '2.Jüri',
      value: '2.Jüri',
      icon: Icons.people,
      color: Colors.indigo,
    ),
    const EvidenceCommentRole(
      label: 'Davacı Şahidi',
      value: 'Davacı Şahidi',
      icon: Icons.person,
      color: Colors.cyan,
    ),
    const EvidenceCommentRole(
      label: 'Davalı Şahidi',
      value: 'Davalı Şahidi',
      icon: Icons.person_outline,
      color: Colors.pink,
    ),
  ];
}

