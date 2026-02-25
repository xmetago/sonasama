// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dava_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DavaModelAdapter extends TypeAdapter<DavaModel> {
  @override
  final int typeId = 0;

  @override
  DavaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DavaModel(
      id: fields[0] as String,
      adi: fields[1] as String,
      davali: fields[2] as String,
      mevkii: fields[3] as String,
      kalanSure: fields[4] as String,
      profilResmi: fields[5] as String,
      createdAt: fields[6] as DateTime,
      kategori: fields[7] as String,
      altKategori: fields[8] as String,
      aciklama: fields[9] as String,
      likeCount: fields[10] as int,
      dislikeCount: fields[11] as int,
      commentCount: fields[12] as int,
      isActive: fields[13] as bool,
      userId: fields[14] as String,
      davaAdi: fields[15] as String,
      davaci: fields[16] as String,
      isOpened: fields[17] as bool,
      acceptedAt: fields[18] as DateTime?,
      remainingHours: fields[19] as int?,
      hukumSonucu: fields[20] as String?,
      hukumTarihi: fields[21] as DateTime?,
      hukumAciklamasi: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DavaModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.adi)
      ..writeByte(2)
      ..write(obj.davali)
      ..writeByte(3)
      ..write(obj.mevkii)
      ..writeByte(4)
      ..write(obj.kalanSure)
      ..writeByte(5)
      ..write(obj.profilResmi)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.kategori)
      ..writeByte(8)
      ..write(obj.altKategori)
      ..writeByte(9)
      ..write(obj.aciklama)
      ..writeByte(10)
      ..write(obj.likeCount)
      ..writeByte(11)
      ..write(obj.dislikeCount)
      ..writeByte(12)
      ..write(obj.commentCount)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.userId)
      ..writeByte(15)
      ..write(obj.davaAdi)
      ..writeByte(16)
      ..write(obj.davaci)
      ..writeByte(17)
      ..write(obj.isOpened)
      ..writeByte(18)
      ..write(obj.acceptedAt)
      ..writeByte(19)
      ..write(obj.remainingHours)
      ..writeByte(20)
      ..write(obj.hukumSonucu)
      ..writeByte(21)
      ..write(obj.hukumTarihi)
      ..writeByte(22)
      ..write(obj.hukumAciklamasi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DavaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
