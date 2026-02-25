// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_comment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EvidenceCommentModelAdapter extends TypeAdapter<EvidenceCommentModel> {
  @override
  final int typeId = 7;

  @override
  EvidenceCommentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EvidenceCommentModel(
      id: fields[0] as String,
      evidenceId: fields[1] as String,
      davaId: fields[2] as String,
      userRole: fields[3] as String,
      userEmail: fields[4] as String,
      commentText: fields[5] as String,
      criticism: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
      isVerified: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EvidenceCommentModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.evidenceId)
      ..writeByte(2)
      ..write(obj.davaId)
      ..writeByte(3)
      ..write(obj.userRole)
      ..writeByte(4)
      ..write(obj.userEmail)
      ..writeByte(5)
      ..write(obj.commentText)
      ..writeByte(6)
      ..write(obj.criticism)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isVerified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceCommentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
