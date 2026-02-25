import 'package:hive/hive.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 20) // Yeni bir typeId kullanıyoruz
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String conversationId; // İki kullanıcı arasındaki konuşma ID'si (user1Id_user2Id şeklinde sıralı)

  @HiveField(2)
  String senderId; // Mesajı gönderen kullanıcının ID'si

  @HiveField(3)
  String senderEmail; // Mesajı gönderen kullanıcının email'i

  @HiveField(4)
  String senderName; // Mesajı gönderen kullanıcının adı

  @HiveField(5)
  String? senderAvatarUrl; // Mesajı gönderen kullanıcının avatar URL'i

  @HiveField(6)
  String receiverId; // Mesajı alan kullanıcının ID'si

  @HiveField(7)
  String receiverEmail; // Mesajı alan kullanıcının email'i

  @HiveField(8)
  String text; // Mesaj metni

  @HiveField(9)
  DateTime createdAt; // Mesaj oluşturulma tarihi

  @HiveField(10)
  bool isRead; // Mesaj okundu mu?

  @HiveField(11)
  DateTime? readAt; // Mesaj okunma tarihi

  @HiveField(12)
  String? imageUrl; // Görsel mesaj URL'i (varsa)

  @HiveField(13)
  String? fileUrl; // Dosya URL'i (varsa)

  @HiveField(14)
  String? fileType; // Dosya tipi (pdf, doc, vs.)

  @HiveField(15)
  String? audioUrl; // Sesli mesaj URL'i (varsa)

  @HiveField(16)
  int? audioDuration; // Sesli mesaj süresi (saniye)

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderEmail,
    required this.senderName,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.receiverEmail,
    required this.text,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.imageUrl,
    this.fileUrl,
    this.fileType,
    this.audioUrl,
    this.audioDuration,
  });

  // JSON'dan model oluşturma
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      senderName: json['senderName'] ?? '',
      senderAvatarUrl: json['senderAvatarUrl'],
      receiverId: json['receiverId'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      imageUrl: json['imageUrl'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      audioUrl: json['audioUrl'],
      audioDuration: json['audioDuration'],
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverId': receiverId,
      'receiverEmail': receiverEmail,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
    };
  }

  // İki kullanıcı ID'sinden conversation ID oluşturma (sıralı)
  static String createConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}

