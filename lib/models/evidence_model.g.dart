// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EvidenceModelAdapter extends TypeAdapter<EvidenceModel> {
  @override
  final int typeId = 10;

  @override
  EvidenceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EvidenceModel(
      id: fields[0] as String,
      davaId: fields[1] as String,
      type: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String,
      filePath: fields[5] as String,
      url: fields[6] as String,
      fileSize: fields[7] as int,
      createdAt: fields[8] as DateTime,
      isVerified: fields[9] as bool,
      userId: fields[10] as String,
      likeCount: fields[11] as int,
      dislikeCount: fields[12] as int,
      neutralCount: fields[14] == null ? 0 : fields[14] as int,
      likedBy: (fields[13] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, EvidenceModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.davaId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.filePath)
      ..writeByte(6)
      ..write(obj.url)
      ..writeByte(7)
      ..write(obj.fileSize)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isVerified)
      ..writeByte(10)
      ..write(obj.userId)
      ..writeByte(11)
      ..write(obj.likeCount)
      ..writeByte(12)
      ..write(obj.dislikeCount)
      ..writeByte(14)
      ..write(obj.neutralCount)
      ..writeByte(13)
      ..write(obj.likedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
