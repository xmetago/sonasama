import '../services/hive_database_service.dart';
import '../models/registration_model.dart';
import '../models/friendship_model.dart';
import 'package:its19/utils/app_logger.dart';

/// Davet sistemi debug yardımcı fonksiyonları
class DebugDavetUtils {
  
  /// Belirli iki kullanıcı arasındaki takipçi ilişkisini kontrol et
  static void checkFollowerRelationship(String followerEmail, String followedEmail) {
    appLog('\n=== TAKİPÇİ İLİŞKİSİ ANALİZİ ===');
    appLog('Takipçi: $followerEmail');
    appLog('Takip edilen: $followedEmail');
    
    // Kullanıcıları getir
    final follower = HiveDatabaseService.getRegistrationByEmail(followerEmail);
    final followed = HiveDatabaseService.getRegistrationByEmail(followedEmail);
    
    if (follower == null) {
      appLog('❌ Takipçi kullanıcı bulunamadı: $followerEmail');
      return;
    }
    
    if (followed == null) {
      appLog('❌ Takip edilen kullanıcı bulunamadı: $followedEmail');
      return;
    }
    
    appLog('✅ Takipçi ID: ${follower.id}');
    appLog('✅ Takip edilen ID: ${followed.id}');
    
    // Takipçi ilişkisini kontrol et
    final isFollowing = HiveDatabaseService.isFollowing(follower.id, followed.id);
    appLog('Takip durumu: ${isFollowing ? "✅ Takip ediyor" : "❌ Takip etmiyor"}');
    
    // Tüm arkadaşlık kayıtlarını kontrol et
    final allFriendships = HiveDatabaseService.getAllFriendships();
    appLog('\nTüm arkadaşlık kayıtları:');
    
    var foundRelation = false;
    for (final friendship in allFriendships) {
      if ((friendship.requesterId == follower.id && friendship.recipientId == followed.id) ||
          (friendship.requesterId == followed.id && friendship.recipientId == follower.id)) {
        appLog('📋 İlişki bulundu:');
        appLog('   - Requester: ${friendship.requesterId}');
        appLog('   - Recipient: ${friendship.recipientId}');
        appLog('   - Status: ${friendship.status}');
        appLog('   - Created: ${friendship.createdAt}');
        foundRelation = true;
      }
    }
    
    if (!foundRelation) {
      appLog('❌ Bu iki kullanıcı arasında hiçbir arkadaşlık/takip ilişkisi bulunamadı');
    }
  }
  
  /// Belirli bir kullanıcının takipçilerini listele
  static void listFollowers(String userEmail) {
    appLog('\n=== TAKİPÇİ LİSTESİ ===');
    appLog('Kullanıcı: $userEmail');
    
    final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
    if (user == null) {
      appLog('❌ Kullanıcı bulunamadı: $userEmail');
      return;
    }
    
    appLog('✅ Kullanıcı ID: ${user.id}');
    
    final followers = HiveDatabaseService.getFollowers(user.id);
    appLog('Takipçi sayısı: ${followers.length}');
    
    if (followers.isEmpty) {
      appLog('❌ Hiç takipçi bulunamadı');
      return;
    }
    
    for (final follower in followers) {
      final followerUser = HiveDatabaseService.getAllRegistrations()
          .where((r) => r.id == follower.requesterId)
          .firstOrNull;
      
      if (followerUser != null) {
        appLog('👤 ${followerUser.judgeName}');
        appLog('   - ID: ${followerUser.id}');
        appLog('   - Status: ${follower.status}');
      }
    }
  }
  
  /// Davet gönderme algoritmasını test et
  static Future<void> testInvitationAlgorithm(String openerEmail, String groupName) async {
    appLog('\n=== DAVET ALGORİTMASI TESTİ ===');
    appLog('Davet algoritması testi');
    appLog('Grup: $groupName');
    
    try {
      final recipients = await HiveDatabaseService.pickInvitationRecipients(
        openerEmail,
        groupName,
        excludedEmails: [],
      );
      
      appLog('Seçilen alıcı sayısı: ${recipients.length}');
      
      if (recipients.isEmpty) {
        appLog('❌ Hiç alıcı seçilmedi');
        return;
      }
      
      appLog('Seçilen alıcılar:');
      for (final recipient in recipients) {
        appLog('📧 ${recipient.judgeName}');
      }
      
    } catch (e) {
      appLog('❌ Algoritma hatası: $e');
    }
  }
  
  /// Belirli bir kullanıcının davetlerini kontrol et
  static void checkUserInvitations(String userEmail) {
    appLog('\n=== KULLANICI DAVETLERİ ===');
    
    final invitations = HiveDatabaseService.getInvitations(userEmail);
    appLog('Davet sayısı: ${invitations.length}');
    
    if (invitations.isEmpty) {
      appLog('❌ Hiç davet bulunamadı');
      return;
    }
    
    for (final invitation in invitations) {
      appLog('📨 Davet:');
      appLog('   - ID: ${invitation['id']}');
      appLog('   - Dava: ${invitation['davaAdi']}');
      appLog('   - Grup: ${invitation['groupName']}');
      appLog('   - Tarih: ${invitation['invitedAt']}');
      appLog('   - Davacı: ${invitation['davaci']}');
    }
  }
  
  /// Takipçi ilişkisi oluştur (test için)
  static Future<void> createFollowerRelationship(String followerEmail, String followedEmail) async {
    appLog('\n=== TAKİPÇİ İLİŞKİSİ OLUŞTUR ===');
    
    final follower = HiveDatabaseService.getRegistrationByEmail(followerEmail);
    final followed = HiveDatabaseService.getRegistrationByEmail(followedEmail);
    
    if (follower == null || followed == null) {
      appLog('❌ Kullanıcılar bulunamadı');
      return;
    }
    
    final friendship = FriendshipModel(
      id: 'follow_${DateTime.now().millisecondsSinceEpoch}',
      requesterId: follower.id,
      recipientId: followed.id,
      status: FriendshipStatus.following,
      createdAt: DateTime.now(),
    );
    
    await HiveDatabaseService.sendFriendshipRequest(friendship);
    appLog('✅ Takipçi ilişkisi oluşturuldu');
  }
  
  /// Tam davet sistemi testi
  static Future<void> fullInvitationSystemTest(String openerEmail, String followerEmail) async {
    appLog('\n🔍 TAM DAVET SİSTEMİ TESTİ BAŞLIYOR...\n');
    
    // 1. İlişki kontrolü
    checkFollowerRelationship(followerEmail, openerEmail);
    
    // 2. Takipçi listesi
    listFollowers(openerEmail);
    
    // 3. Algoritma testi
    await testInvitationAlgorithm(openerEmail, 'takipçiler');
    
    // 4. Mevcut davetleri kontrol et
    checkUserInvitations(followerEmail);
    
    appLog('\n✅ Test tamamlandı');
  }
}

extension on Iterable<RegistrationModel> {
  RegistrationModel? get firstOrNull {
    return isEmpty ? null : first;
  }
}
