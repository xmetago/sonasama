import 'package:hive/hive.dart';

/// Kullanıcıya özel tek yönlü arkadaş kategorisi kaydı.
class FriendCategoryModel extends HiveObject {
  final String id;
  final String ownerUserId; // Kategoriyi belirleyen kullanıcı
  final String targetUserId; // Kategoriye eklenen kullanıcı
  final String category; // Örn: Arkadaş, Takipçi, Grup-19, Herkes/Tanımadıklarım
  final DateTime createdAt;
  final DateTime? updatedAt;

  FriendCategoryModel({
    required this.id,
    required this.ownerUserId,
    required this.targetUserId,
    required this.category,
    required this.createdAt,
    this.updatedAt,
  });

  FriendCategoryModel copyWith({
    String? id,
    String? ownerUserId,
    String? targetUserId,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendCategoryModel(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      targetUserId: targetUserId ?? this.targetUserId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Manuel TypeAdapter (build_runner kullanılmadan)
class FriendCategoryModelAdapter extends TypeAdapter<FriendCategoryModel> {
  @override
  final int typeId = 21; // Benzersiz typeId

  @override
  FriendCategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FriendCategoryModel(
      id: fields[0] as String,
      ownerUserId: fields[1] as String,
      targetUserId: fields[2] as String,
      category: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FriendCategoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerUserId)
      ..writeByte(2)
      ..write(obj.targetUserId)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }
}


