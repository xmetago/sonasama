import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message_model.dart';
import 'hive_database_service.dart';
import 'user_session_service.dart';
import 'dart:async';

/// Real-time mesajlaşma için Firestore entegrasyonlu Chat Service
/// Hive offline cache olarak kullanılır, Firestore real-time sync için
class ChatServiceFirestore {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatMessageBoxName = 'chat_message_box';
  static Box<ChatMessageModel>? _chatMessageBox;
  static const String _messagesCollection = 'messages';
  static const String _conversationsCollection = 'conversations';
  
  /// Hive box'a erişim (ChatService için)
  static Box<ChatMessageModel>? get chatMessageBox => _chatMessageBox;

  /// Chat servisini başlat
  static Future<void> initialize() async {
    // Hive adapter'ı kaydet
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(ChatMessageModelAdapter());
    }
    _chatMessageBox = await Hive.openBox<ChatMessageModel>(_chatMessageBoxName);
  }

  /// Mesaj gönder (Firestore'a kaydet)
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

    final receiver = HiveDatabaseService.getRegistrationByEmail(receiverEmail);
    if (receiver == null) {
      throw Exception('Alıcı kullanıcı bulunamadı');
    }

    final conversationId = ChatMessageModel.createConversationId(
      currentUser.id,
      receiverId,
    );

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = ChatMessageModel(
      id: messageId,
      conversationId: conversationId,
      senderId: currentUser.id,
      senderEmail: currentUser.email,
      senderName: currentUser.judgeName,
      senderAvatarUrl: currentUser.profileImage,
      receiverId: receiverId,
      receiverEmail: receiverEmail,
      text: text,
      createdAt: DateTime.now(),
      isRead: false,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileType: fileType,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
    );

    // Firestore'a kaydet
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .set(message.toJson());

      // Konuşma bilgisini güncelle
      await _updateConversation(conversationId, message);

      // Hive'a da kaydet (offline cache)
      await _chatMessageBox?.put(messageId, message);
    } catch (e) {
      // Hata durumunda sadece Hive'a kaydet (offline mode)
      await _chatMessageBox?.put(messageId, message);
      print('⚠️ Firestore hatası, mesaj Hive\'a kaydedildi: $e');
    }

    return message;
  }

  /// Konuşma bilgisini güncelle
  static Future<void> _updateConversation(
      String conversationId, ChatMessageModel message) async {
    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .set({
        'lastMessage': message.text,
        'lastMessageTime': message.createdAt.toIso8601String(),
        'lastMessageSenderId': message.senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': [message.senderId, message.receiverId],
      }, SetOptions(merge: true));
    } catch (e) {
      print('⚠️ Konuşma güncellenirken hata: $e');
    }
  }

  /// Konuşmadaki tüm mesajları getir (Firestore'dan)
  static Future<List<ChatMessageModel>> getMessages(
      String userId1, String userId2) async {
    final conversationId = ChatMessageModel.createConversationId(userId1, userId2);

    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('createdAt', descending: false)
          .get();

      final messages = snapshot.docs
          .map((doc) => ChatMessageModel.fromJson(doc.data()))
          .toList();

      // Hive'a da kaydet (cache)
      for (final message in messages) {
        await _chatMessageBox?.put(message.id, message);
      }

      return messages;
    } catch (e) {
      print('⚠️ Firestore\'dan mesajlar alınamadı, Hive\'dan okunuyor: $e');
      // Hata durumunda Hive'dan oku
      return getMessagesFromHive(conversationId);
    }
  }

  /// Hive'dan mesajları getir (public - ChatService tarafından kullanılıyor)
  static List<ChatMessageModel> getMessagesFromHive(String conversationId) {
    if (_chatMessageBox == null) return [];

    final allMessages = _chatMessageBox!.values
        .where((message) => message.conversationId == conversationId)
        .toList();

    allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return allMessages;
  }

  /// Konuşmadaki son mesajı getir
  static Future<ChatMessageModel?> getLastMessage(
      String userId1, String userId2) async {
    final messages = await getMessages(userId1, userId2);
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Mesajı okundu olarak işaretle
  static Future<void> markAsRead(String messageId) async {
    try {
      // Firestore'da güncelle
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });

      // Hive'da da güncelle
      final message = _chatMessageBox?.get(messageId);
      if (message != null) {
        message.isRead = true;
        message.readAt = DateTime.now();
        await _chatMessageBox?.put(messageId, message);
      }
    } catch (e) {
      print('⚠️ Mesaj okundu işaretlenirken hata: $e');
    }
  }

  /// Konuşmadaki tüm mesajları okundu olarak işaretle
  static Future<void> markConversationAsRead(
      String userId1, String userId2) async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    final conversationId = ChatMessageModel.createConversationId(userId1, userId2);

    try {
      // Firestore'da batch update
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUser.id)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();

      // Hive'da da güncelle
      final messages = getMessagesFromHive(conversationId);
      for (final message in messages) {
        if (message.receiverId == currentUser.id && !message.isRead) {
          await markAsRead(message.id);
        }
      }
    } catch (e) {
      print('⚠️ Konuşma okundu işaretlenirken hata: $e');
    }
  }

  /// Konuşmayı real-time olarak izle (Stream)
  static Stream<List<ChatMessageModel>> watchConversation(
      String userId1, String userId2) {
    final conversationId = ChatMessageModel.createConversationId(userId1, userId2);

    try {
      return _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs
            .map((doc) => ChatMessageModel.fromJson(doc.data()))
            .toList();

        // Hive'a cache'le
        for (final message in messages) {
          _chatMessageBox?.put(message.id, message);
        }

        return messages;
      });
    } catch (e) {
      print('⚠️ Real-time dinleme hatası, Hive stream kullanılıyor: $e');
      // Hata durumunda Hive stream'i kullan
      return _watchConversationFromHive(conversationId);
    }
  }

  /// Hive'dan stream oluştur
  static Stream<List<ChatMessageModel>> _watchConversationFromHive(
      String conversationId) {
    if (_chatMessageBox == null) {
      return Stream.value([]);
    }

    return _chatMessageBox!.watch().map((event) {
      final allMessages = _chatMessageBox!.values
          .where((message) => message.conversationId == conversationId)
          .toList();
      allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return allMessages;
    });
  }

  /// Kullanıcının tüm konuşmalarını getir
  static Future<Map<String, ChatMessageModel?>> getAllConversations() async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return {};

    try {
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .where('participants', arrayContains: currentUser.id)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final conversations = <String, ChatMessageModel?>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUser.id,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          final lastMessage = await getLastMessage(currentUser.id, otherUserId);
          conversations[otherUserId] = lastMessage;
        }
      }

      return conversations;
    } catch (e) {
      print('⚠️ Konuşmalar alınamadı: $e');
      return {};
    }
  }

  /// Okunmamış mesaj sayısını getir
  static Future<int> getUnreadCount(String userId1, String userId2) async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return 0;

    final conversationId = ChatMessageModel.createConversationId(userId1, userId2);

    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUser.id)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('⚠️ Okunmamış mesaj sayısı alınamadı: $e');
      return 0;
    }
  }

  /// Toplam okunmamış mesaj sayısını getir
  static Future<int> getTotalUnreadCount() async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return 0;

    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: currentUser.id)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('⚠️ Toplam okunmamış mesaj sayısı alınamadı: $e');
      return 0;
    }
  }

  /// Mesaj sil
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).delete();
      await _chatMessageBox?.delete(messageId);
    } catch (e) {
      print('⚠️ Mesaj silinirken hata: $e');
    }
  }

  /// Konuşmayı sil
  static Future<void> deleteConversation(String userId1, String userId2) async {
    final conversationId = ChatMessageModel.createConversationId(userId1, userId2);

    try {
      // Tüm mesajları sil
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Konuşma dokümanını sil
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .delete();

      // Hive'dan da sil
      final messages = getMessagesFromHive(conversationId);
      for (final message in messages) {
        await _chatMessageBox?.delete(message.id);
      }
    } catch (e) {
      print('⚠️ Konuşma silinirken hata: $e');
    }
  }
}

