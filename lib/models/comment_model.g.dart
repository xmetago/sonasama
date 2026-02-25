// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommentModelAdapter extends TypeAdapter<CommentModel> {
  @override
  final int typeId = 2;

  @override
  CommentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommentModel(
      id: fields[0] as String,
      davaId: fields[1] as String,
      userId: fields[2] as String,
      userUsername: fields[3] as String,
      userProfilResmi: fields[4] as String?,
      content: fields[5] as String,
      createdAt: fields[6] as DateTime,
      likeCount: fields[7] as int,
      dislikeCount: fields[8] as int,
      isActive: fields[9] as bool,
      parentCommentId: fields[10] as String?,
      likedByUsers: (fields[11] as List).cast<String>(),
      dislikedByUsers: (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CommentModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.davaId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.userUsername)
      ..writeByte(4)
      ..write(obj.userProfilResmi)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.likeCount)
      ..writeByte(8)
      ..write(obj.dislikeCount)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.parentCommentId)
      ..writeByte(11)
      ..write(obj.likedByUsers)
      ..writeByte(12)
      ..write(obj.dislikedByUsers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
