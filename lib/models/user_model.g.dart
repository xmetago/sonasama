// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      username: fields[1] as String,
      email: fields[2] as String,
      profilResmi: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      lastLoginAt: fields[5] as DateTime,
      isActive: fields[6] as bool,
      totalDavalar: fields[7] as int,
      totalKatildigiDavalar: fields[8] as int,
      totalLikes: fields[9] as int,
      phoneNumber: fields[10] as String?,
      country: fields[11] as String?,
      energyLevel: fields[12] as int,
      lastEnergyUpdate: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.profilResmi)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastLoginAt)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.totalDavalar)
      ..writeByte(8)
      ..write(obj.totalKatildigiDavalar)
      ..writeByte(9)
      ..write(obj.totalLikes)
      ..writeByte(10)
      ..write(obj.phoneNumber)
      ..writeByte(11)
      ..write(obj.country)
      ..writeByte(12)
      ..write(obj.energyLevel)
      ..writeByte(13)
      ..write(obj.lastEnergyUpdate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
