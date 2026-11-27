import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import 'chat_service_firestore.dart';
import 'friend_category_service.dart';
import 'hive_database_service.dart';
import 'user_session_service.dart';
import 'user_star_balance_store.dart';

/// Hesap silme sonucu. Firebase Auth silme adımı henüz bağlı değil.
class AccountDeletionResult {
  const AccountDeletionResult({
    required this.hiveDeleted,
    this.remoteErrors = const <String>[],
  });

  final bool hiveDeleted;
  final List<String> remoteErrors;

  bool get succeeded => hiveDeleted;
}

/// Kullanıcının yerel ve ulaşılabilen uzak verisini siler.
///
/// Firebase Authentication kullanıcı silme bu sınıfa sonra eklenecek.
/// Şimdilik [deleteAuthUserIfPresent] boş bırakıldı.
class AccountDeletionService {
  AccountDeletionService._();

  static const int _firestoreBatchLimit = 450;

  static Future<AccountDeletionResult> deleteAccount({
    required String userId,
    required String email,
  }) async {
    final conversationIds = ChatServiceFirestore.conversationIdsForUser(userId);
    await deleteHiveData(userId: userId, email: email);
    await ChatServiceFirestore.deleteLocalMessagesForUser(userId);
    await _clearLocalPreferences(email);

    final remoteErrors = <String>[];
    await _deleteRemoteChat(
      userId: userId,
      conversationIds: conversationIds,
      errors: remoteErrors,
    );
    await deleteAuthUserIfPresent();
    UserSessionService.clearCurrentUser();
    return AccountDeletionResult(hiveDeleted: true, remoteErrors: remoteErrors);
  }

  /// Yalnızca Hive tarafı. Testler uzak servis olmadan bunu çağırır.
  static Future<void> deleteHiveData({
    required String userId,
    required String email,
  }) async {
    await HiveDatabaseService.deleteUserOwnedData(userId: userId, email: email);
    await FriendCategoryService.deleteInvolvingUser(userId);
  }

  /// Kimlik sağlayıcı bağlandığında Firebase Auth kullanıcısı burada silinir.
  static Future<void> deleteAuthUserIfPresent() async {}

  static Future<void> _clearLocalPreferences(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remembered_password');
      await prefs.remove('remembered_email');
      await prefs.setBool('remember_me', false);
      await UserStarBalanceStore.clearForEmail(email);
    } catch (e) {
      appLog('Yerel tercihler temizlenemedi: $e');
    }
  }

  static Future<void> _deleteRemoteChat({
    required String userId,
    required Set<String> conversationIds,
    required List<String> errors,
  }) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final sent = await firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      final received = await firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .get();
      final messageRefs = <DocumentReference<Map<String, dynamic>>>[
        ...sent.docs.map((doc) => doc.reference),
        ...received.docs.map((doc) => doc.reference),
      ];
      await _deleteDocs(firestore, messageRefs);

      final conversations = await firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();
      for (final doc in conversations.docs) {
        conversationIds.add(doc.id);
      }
      await _deleteDocs(
        firestore,
        conversations.docs.map((doc) => doc.reference).toList(),
      );
    } catch (e) {
      errors.add('Sohbet kayıtları silinemedi.');
      appLog('Firestore hesap silme hatası: $e');
    }

    try {
      final storage = FirebaseStorage.instance;
      for (final conversationId in conversationIds) {
        await _deleteStoragePrefix(storage.ref('chat_files/$conversationId'));
        await _deleteStoragePrefix(
          storage.ref('audio_messages/$conversationId'),
        );
      }
    } catch (e) {
      errors.add('Dosyalar silinemedi.');
      appLog('Storage hesap silme hatası: $e');
    }
  }

  static Future<void> _deleteDocs(
    FirebaseFirestore firestore,
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    for (var start = 0; start < refs.length; start += _firestoreBatchLimit) {
      final end = start + _firestoreBatchLimit < refs.length
          ? start + _firestoreBatchLimit
          : refs.length;
      final batch = firestore.batch();
      for (var i = start; i < end; i++) {
        batch.delete(refs[i]);
      }
      await batch.commit();
    }
  }

  static Future<void> _deleteStoragePrefix(Reference ref) async {
    final ListResult listed = await ref.listAll();
    for (final Reference item in listed.items) {
      await item.delete();
    }
    for (final Reference prefix in listed.prefixes) {
      await _deleteStoragePrefix(prefix);
    }
  }
}
