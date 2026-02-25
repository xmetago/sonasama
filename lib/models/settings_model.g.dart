// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 11;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      userEmail: fields[0] as String,
      privacySettings: (fields[1] as Map?)?.cast<String, bool>(),
      stringSettings: (fields[2] as Map?)?.cast<String, String>(),
      profileImageUrl: fields[3] as String?,
      philosophy: fields[4] as String?,
      postrestantAddress: fields[5] as String?,
      country: fields[6] as String?,
      language: fields[7] as String?,
      lastUpdated: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userEmail)
      ..writeByte(1)
      ..write(obj.privacySettings)
      ..writeByte(2)
      ..write(obj.stringSettings)
      ..writeByte(3)
      ..write(obj.profileImageUrl)
      ..writeByte(4)
      ..write(obj.philosophy)
      ..writeByte(5)
      ..write(obj.postrestantAddress)
      ..writeByte(6)
      ..write(obj.country)
      ..writeByte(7)
      ..write(obj.language)
      ..writeByte(8)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
