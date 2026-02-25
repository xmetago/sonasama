// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageModelAdapter extends TypeAdapter<ChatMessageModel> {
  @override
  final int typeId = 20;

  @override
  ChatMessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessageModel(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      senderId: fields[2] as String,
      senderEmail: fields[3] as String,
      senderName: fields[4] as String,
      senderAvatarUrl: fields[5] as String?,
      receiverId: fields[6] as String,
      receiverEmail: fields[7] as String,
      text: fields[8] as String,
      createdAt: fields[9] as DateTime,
      isRead: fields[10] as bool,
      readAt: fields[11] as DateTime?,
      imageUrl: fields[12] as String?,
      fileUrl: fields[13] as String?,
      fileType: fields[14] as String?,
      audioUrl: fields[15] as String?,
      audioDuration: fields[16] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderEmail)
      ..writeByte(4)
      ..write(obj.senderName)
      ..writeByte(5)
      ..write(obj.senderAvatarUrl)
      ..writeByte(6)
      ..write(obj.receiverId)
      ..writeByte(7)
      ..write(obj.receiverEmail)
      ..writeByte(8)
      ..write(obj.text)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isRead)
      ..writeByte(11)
      ..write(obj.readAt)
      ..writeByte(12)
      ..write(obj.imageUrl)
      ..writeByte(13)
      ..write(obj.fileUrl)
      ..writeByte(14)
      ..write(obj.fileType)
      ..writeByte(15)
      ..write(obj.audioUrl)
      ..writeByte(16)
      ..write(obj.audioDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
