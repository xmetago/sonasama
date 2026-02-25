// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendship_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FriendshipModelAdapter extends TypeAdapter<FriendshipModel> {
  @override
  final int typeId = 5;

  @override
  FriendshipModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FriendshipModel(
      id: fields[0] as String,
      requesterId: fields[1] as String,
      recipientId: fields[2] as String,
      status: fields[3] as FriendshipStatus,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime?,
      message: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FriendshipModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.requesterId)
      ..writeByte(2)
      ..write(obj.recipientId)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.message);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendshipModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FriendshipStatusAdapter extends TypeAdapter<FriendshipStatus> {
  @override
  final int typeId = 6;

  @override
  FriendshipStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FriendshipStatus.none;
      case 1:
        return FriendshipStatus.pending;
      case 2:
        return FriendshipStatus.accepted;
      case 3:
        return FriendshipStatus.rejected;
      case 4:
        return FriendshipStatus.blocked;
      case 5:
        return FriendshipStatus.following;
      default:
        return FriendshipStatus.none;
    }
  }

  @override
  void write(BinaryWriter writer, FriendshipStatus obj) {
    switch (obj) {
      case FriendshipStatus.none:
        writer.writeByte(0);
        break;
      case FriendshipStatus.pending:
        writer.writeByte(1);
        break;
      case FriendshipStatus.accepted:
        writer.writeByte(2);
        break;
      case FriendshipStatus.rejected:
        writer.writeByte(3);
        break;
      case FriendshipStatus.blocked:
        writer.writeByte(4);
        break;
      case FriendshipStatus.following:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendshipStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
