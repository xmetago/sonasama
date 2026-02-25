import '../services/hive_database_service.dart';
import '../models/registration_model.dart';
import '../models/friendship_model.dart';

/// Davet sistemi debug yardımcı fonksiyonları
class DebugDavetUtils {
  
  /// Belirli iki kullanıcı arasındaki takipçi ilişkisini kontrol et
  static void checkFollowerRelationship(String followerEmail, String followedEmail) {
    print('\n=== TAKİPÇİ İLİŞKİSİ ANALİZİ ===');
    print('Takipçi: $followerEmail');
    print('Takip edilen: $followedEmail');
    
    // Kullanıcıları getir
    final follower = HiveDatabaseService.getRegistrationByEmail(followerEmail);
    final followed = HiveDatabaseService.getRegistrationByEmail(followedEmail);
    
    if (follower == null) {
      print('❌ Takipçi kullanıcı bulunamadı: $followerEmail');
      return;
    }
    
    if (followed == null) {
      print('❌ Takip edilen kullanıcı bulunamadı: $followedEmail');
      return;
    }
    
    print('✅ Takipçi ID: ${follower.id}');
    print('✅ Takip edilen ID: ${followed.id}');
    
    // Takipçi ilişkisini kontrol et
    final isFollowing = HiveDatabaseService.isFollowing(follower.id, followed.id);
    print('Takip durumu: ${isFollowing ? "✅ Takip ediyor" : "❌ Takip etmiyor"}');
    
    // Tüm arkadaşlık kayıtlarını kontrol et
    final allFriendships = HiveDatabaseService.getAllFriendships();
    print('\nTüm arkadaşlık kayıtları:');
    
    var foundRelation = false;
    for (final friendship in allFriendships) {
      if ((friendship.requesterId == follower.id && friendship.recipientId == followed.id) ||
          (friendship.requesterId == followed.id && friendship.recipientId == follower.id)) {
        print('📋 İlişki bulundu:');
        print('   - Requester: ${friendship.requesterId}');
        print('   - Recipient: ${friendship.recipientId}');
        print('   - Status: ${friendship.status}');
        print('   - Created: ${friendship.createdAt}');
        foundRelation = true;
      }
    }
    
    if (!foundRelation) {
      print('❌ Bu iki kullanıcı arasında hiçbir arkadaşlık/takip ilişkisi bulunamadı');
    }
  }
  
  /// Belirli bir kullanıcının takipçilerini listele
  static void listFollowers(String userEmail) {
    print('\n=== TAKİPÇİ LİSTESİ ===');
    print('Kullanıcı: $userEmail');
    
    final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
    if (user == null) {
      print('❌ Kullanıcı bulunamadı: $userEmail');
      return;
    }
    
    print('✅ Kullanıcı ID: ${user.id}');
    
    final followers = HiveDatabaseService.getFollowers(user.id);
    print('Takipçi sayısı: ${followers.length}');
    
    if (followers.isEmpty) {
      print('❌ Hiç takipçi bulunamadı');
      return;
    }
    
    for (final follower in followers) {
      final followerUser = HiveDatabaseService.getAllRegistrations()
          .where((r) => r.id == follower.requesterId)
          .firstOrNull;
      
      if (followerUser != null) {
        print('👤 ${followerUser.email} (${followerUser.judgeName})');
        print('   - ID: ${followerUser.id}');
        print('   - Status: ${follower.status}');
      }
    }
  }
  
  /// Davet gönderme algoritmasını test et
  static Future<void> testInvitationAlgorithm(String openerEmail, String groupName) async {
    print('\n=== DAVET ALGORİTMASI TESTİ ===');
    print('Açan: $openerEmail');
    print('Grup: $groupName');
    
    try {
      final recipients = await HiveDatabaseService.pickInvitationRecipients(
        openerEmail,
        groupName,
        excludedEmails: [],
      );
      
      print('Seçilen alıcı sayısı: ${recipients.length}');
      
      if (recipients.isEmpty) {
        print('❌ Hiç alıcı seçilmedi');
        return;
      }
      
      print('Seçilen alıcılar:');
      for (final recipient in recipients) {
        print('📧 ${recipient.email} (${recipient.judgeName})');
      }
      
    } catch (e) {
      print('❌ Algoritma hatası: $e');
    }
  }
  
  /// Belirli bir kullanıcının davetlerini kontrol et
  static void checkUserInvitations(String userEmail) {
    print('\n=== KULLANICI DAVETLERİ ===');
    print('Kullanıcı: $userEmail');
    
    final invitations = HiveDatabaseService.getInvitations(userEmail);
    print('Davet sayısı: ${invitations.length}');
    
    if (invitations.isEmpty) {
      print('❌ Hiç davet bulunamadı');
      return;
    }
    
    for (final invitation in invitations) {
      print('📨 Davet:');
      print('   - ID: ${invitation['id']}');
      print('   - Dava: ${invitation['davaAdi']}');
      print('   - Grup: ${invitation['groupName']}');
      print('   - Tarih: ${invitation['invitedAt']}');
      print('   - Davacı: ${invitation['davaci']}');
    }
  }
  
  /// Takipçi ilişkisi oluştur (test için)
  static Future<void> createFollowerRelationship(String followerEmail, String followedEmail) async {
    print('\n=== TAKİPÇİ İLİŞKİSİ OLUŞTUR ===');
    
    final follower = HiveDatabaseService.getRegistrationByEmail(followerEmail);
    final followed = HiveDatabaseService.getRegistrationByEmail(followedEmail);
    
    if (follower == null || followed == null) {
      print('❌ Kullanıcılar bulunamadı');
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
    print('✅ Takipçi ilişkisi oluşturuldu: $followerEmail -> $followedEmail');
  }
  
  /// Tam davet sistemi testi
  static Future<void> fullInvitationSystemTest(String openerEmail, String followerEmail) async {
    print('\n🔍 TAM DAVET SİSTEMİ TESTİ BAŞLIYOR...\n');
    
    // 1. İlişki kontrolü
    checkFollowerRelationship(followerEmail, openerEmail);
    
    // 2. Takipçi listesi
    listFollowers(openerEmail);
    
    // 3. Algoritma testi
    await testInvitationAlgorithm(openerEmail, 'takipçiler');
    
    // 4. Mevcut davetleri kontrol et
    checkUserInvitations(followerEmail);
    
    print('\n✅ Test tamamlandı');
  }
}

extension on Iterable<RegistrationModel> {
  RegistrationModel? get firstOrNull {
    return isEmpty ? null : first;
  }
}
