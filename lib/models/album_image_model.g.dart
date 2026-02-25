// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_image_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlbumImageModelAdapter extends TypeAdapter<AlbumImageModel> {
  @override
  final int typeId = 22;

  @override
  AlbumImageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlbumImageModel(
      id: fields[0] as String,
      albumId: fields[1] as String,
      imageUrl: fields[2] as String,
      imagePath: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      title: fields[5] as String?,
      description: fields[6] as String?,
      fileSize: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AlbumImageModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.albumId)
      ..writeByte(2)
      ..write(obj.imageUrl)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.fileSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumImageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
