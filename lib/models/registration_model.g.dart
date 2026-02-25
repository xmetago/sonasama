// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegistrationModelAdapter extends TypeAdapter<RegistrationModel> {
  @override
  final int typeId = 4;

  @override
  RegistrationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegistrationModel(
      id: fields[0] as String,
      judgeName: fields[1] as String,
      email: fields[2] as String,
      password: fields[3] as String,
      country: fields[4] as String,
      oath: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      isEmailVerified: fields[7] as bool,
      activationCode: fields[8] as String?,
      emailVerifiedAt: fields[9] as DateTime?,
      isActive: fields[10] as bool,
      phoneNumber: fields[11] as String?,
      profileImage: fields[12] as String?,
      lastLoginAt: fields[13] as DateTime,
      loginAttempts: fields[14] as int,
      lastLoginAttemptAt: fields[15] as DateTime?,
      isAdmin: fields[16] as bool,
      lastDavaAcTime: fields[17] as DateTime?,
      lastHaykirTime: fields[18] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RegistrationModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.judgeName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.country)
      ..writeByte(5)
      ..write(obj.oath)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isEmailVerified)
      ..writeByte(8)
      ..write(obj.activationCode)
      ..writeByte(9)
      ..write(obj.emailVerifiedAt)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.phoneNumber)
      ..writeByte(12)
      ..write(obj.profileImage)
      ..writeByte(13)
      ..write(obj.lastLoginAt)
      ..writeByte(14)
      ..write(obj.loginAttempts)
      ..writeByte(15)
      ..write(obj.lastLoginAttemptAt)
      ..writeByte(16)
      ..write(obj.isAdmin)
      ..writeByte(17)
      ..write(obj.lastDavaAcTime)
      ..writeByte(18)
      ..write(obj.lastHaykirTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistrationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
