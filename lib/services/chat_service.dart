import '../models/chat_message_model.dart';
import 'user_session_service.dart';
import 'chat_service_firestore.dart';
import 'dart:async';

/// Chat Service - Firestore entegrasyonlu real-time mesajlaşma
/// Eski metodlar geriye dönük uyumluluk için korunuyor
class ChatService {
  // Hive box ChatServiceFirestore tarafından yönetiliyor

  /// Chat servisini başlat (Firestore ile)
  static Future<void> initialize() async {
    await ChatServiceFirestore.initialize();
  }

  /// Mesaj gönder (Firestore'a yönlendir)
  static Future<ChatMessageModel> sendMessage({
    required String receiverId,
    required String receiverEmail,
    required String text,
    String? imageUrl,
    String? fileUrl,
    String? fileType,
    String? audioUrl,
    int? audioDuration,
  }) async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    // Firestore servisine yönlendir
    return ChatServiceFirestore.sendMessage(
      receiverId: receiverId,
      receiverEmail: receiverEmail,
      text: text,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileType: fileType,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
    );
  }

  /// Konuşmadaki tüm mesajları getir (Firestore'dan)
  static Future<List<ChatMessageModel>> getMessages(String userId1, String userId2) async {
    return ChatServiceFirestore.getMessages(userId1, userId2);
  }
  
  /// Konuşmadaki tüm mesajları getir (Senkron - geriye dönük uyumluluk için)
  static List<ChatMessageModel> getMessagesSync(String userId1, String userId2) {
    return ChatServiceFirestore.getMessagesFromHive(
      ChatMessageModel.createConversationId(userId1, userId2),
    );
  }

  /// Konuşmadaki son mesajı getir (Firestore'dan)
  static Future<ChatMessageModel?> getLastMessage(String userId1, String userId2) async {
    return ChatServiceFirestore.getLastMessage(userId1, userId2);
  }
  
  /// Konuşmadaki son mesajı getir (Senkron - geriye dönük uyumluluk için)
  static ChatMessageModel? getLastMessageSync(String userId1, String userId2) {
    final messages = getMessagesSync(userId1, userId2);
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Mesajı okundu olarak işaretle (Firestore)
  static Future<void> markAsRead(String messageId) async {
    return ChatServiceFirestore.markAsRead(messageId);
  }

  /// Konuşmadaki tüm mesajları okundu olarak işaretle (Firestore)
  static Future<void> markConversationAsRead(String userId1, String userId2) async {
    return ChatServiceFirestore.markConversationAsRead(userId1, userId2);
  }

  /// Kullanıcının tüm konuşmalarını getir (Firestore'dan)
  static Future<Map<String, ChatMessageModel?>> getAllConversations() async {
    return ChatServiceFirestore.getAllConversations();
  }
  
  /// Kullanıcının tüm konuşmalarını getir (Senkron - geriye dönük uyumluluk için)
  static Map<String, ChatMessageModel?> getAllConversationsSync() {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return {};

    final box = ChatServiceFirestore.chatMessageBox;
    if (box == null) return {};

    final conversations = <String, ChatMessageModel?>{};
    final allMessages = box.values.toList();

    // Her konuşma için son mesajı bul
    for (final message in allMessages) {
      if (message.senderId == currentUser.id || message.receiverId == currentUser.id) {
        final otherUserId = message.senderId == currentUser.id
            ? message.receiverId
            : message.senderId;

        final existingLastMessage = conversations[otherUserId];
        if (existingLastMessage == null ||
            message.createdAt.isAfter(existingLastMessage.createdAt)) {
          conversations[otherUserId] = message;
        }
      }
    }

    return conversations;
  }

  /// Okunmamış mesaj sayısını getir (Firestore'dan)
  static Future<int> getUnreadCount(String userId1, String userId2) async {
    return ChatServiceFirestore.getUnreadCount(userId1, userId2);
  }
  
  /// Okunmamış mesaj sayısını getir (Senkron - geriye dönük uyumluluk için)
  static int getUnreadCountSync(String userId1, String userId2) {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return 0;

    final messages = getMessagesSync(userId1, userId2);
    return messages
        .where((message) =>
            message.receiverId == currentUser.id && !message.isRead)
        .length;
  }

  /// Toplam okunmamış mesaj sayısını getir (Firestore'dan)
  static Future<int> getTotalUnreadCount() async {
    return ChatServiceFirestore.getTotalUnreadCount();
  }
  
  /// Toplam okunmamış mesaj sayısını getir (Senkron - geriye dönük uyumluluk için)
  static int getTotalUnreadCountSync() {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return 0;

    final box = ChatServiceFirestore.chatMessageBox;
    if (box == null) return 0;

    return box.values
        .where((message) =>
            message.receiverId == currentUser.id && !message.isRead)
        .length;
  }

  /// Mesaj sil (Firestore)
  static Future<void> deleteMessage(String messageId) async {
    return ChatServiceFirestore.deleteMessage(messageId);
  }

  /// Konuşmayı sil (Firestore)
  static Future<void> deleteConversation(String userId1, String userId2) async {
    return ChatServiceFirestore.deleteConversation(userId1, userId2);
  }

  /// Konuşmayı real-time olarak izle (Firestore Stream)
  static Stream<List<ChatMessageModel>> watchConversation(
      String userId1, String userId2) {
    return ChatServiceFirestore.watchConversation(userId1, userId2);
  }
}


