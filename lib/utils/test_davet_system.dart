import '../services/hive_database_service.dart';
import '../models/registration_model.dart';
import '../utils/debug_davet_utils.dart';

/// Test senaryosu: whoboom@whoboom.com ve fatih@whoboom.com arasındaki davet sistemi
class TestDavetSystem {
  
  /// Test senaryosunu çalıştır
  static Future<void> runTest() async {
    print('🧪 DAVET SİSTEMİ TEST SENARYOSU BAŞLIYOR...\n');
    
    const openerEmail = 'whoboom@whoboom.com';
    const followerEmail = 'fatih@whoboom.com';
    
    // 1. Kullanıcıları kontrol et
    await _checkUsers(openerEmail, followerEmail);
    
    // 2. Takipçi ilişkisini kontrol et
    await _checkFollowerRelation(followerEmail, openerEmail);
    
    // 3. Takipçi ilişkisi yoksa oluştur
    await _ensureFollowerRelation(followerEmail, openerEmail);
    
    // 4. Davet algoritmasını test et
    await _testInvitationAlgorithm(openerEmail);
    
    // 5. Tam sistem testini çalıştır
    await DebugDavetUtils.fullInvitationSystemTest(openerEmail, followerEmail);
    
    print('\n✅ TEST SENARYOSU TAMAMLANDI');
  }
  
  static Future<void> _checkUsers(String email1, String email2) async {
    print('👥 Kullanıcıları kontrol ediliyor...');
    
    final user1 = HiveDatabaseService.getRegistrationByEmail(email1);
    final user2 = HiveDatabaseService.getRegistrationByEmail(email2);
    
    if (user1 == null) {
      print('❌ $email1 kullanıcısı bulunamadı - oluşturuluyor...');
      await _createUser(email1, 'WhoBoom User');
    } else {
      print('✅ $email1 kullanıcısı mevcut (ID: ${user1.id})');
    }
    
    if (user2 == null) {
      print('❌ $email2 kullanıcısı bulunamadı - oluşturuluyor...');
      await _createUser(email2, 'Fatih User');
    } else {
      print('✅ $email2 kullanıcısı mevcut (ID: ${user2.id})');
    }
  }
  
  static Future<void> _createUser(String email, String name) async {
    final now = DateTime.now();
    final user = RegistrationModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}_${email.hashCode}',
      email: email,
      password: '123456',
      judgeName: name,
      country: 'Türkiye',
      oath: true, // Varsayılan olarak true
      createdAt: now,
      lastLoginAt: now,
      isActive: true,
      isEmailVerified: true,
      isAdmin: false,
    );
    
    await HiveDatabaseService.addRegistration(user);
    print('✅ Kullanıcı oluşturuldu: $email');
  }
  
  static Future<void> _checkFollowerRelation(String followerEmail, String followedEmail) async {
    print('\n🔗 Kişisel kategori listesi kontrol ediliyor...');
    
    final categories = HiveDatabaseService.getFriendCategories(followedEmail);
    print('$followedEmail kullanıcısının kategori listesi:');
    
    if (categories.isEmpty) {
      print('❌ Hiç kategori bulunamadı');
    } else {
      for (final entry in categories.entries) {
        print('  - ${entry.key} -> ${entry.value}');
      }
    }
    
    final followerCategory = HiveDatabaseService.getFriendCategory(
      ownerEmail: followedEmail,
      friendEmail: followerEmail,
    );
    
    if (followerCategory != null) {
      print('✅ $followerEmail kategorisi: $followerCategory');
    } else {
      print('❌ $followerEmail henüz kategorize edilmemiş');
    }
  }
  
  static Future<void> _ensureFollowerRelation(String followerEmail, String followedEmail) async {
    print('📎 Kişisel kategori listesini kontrol ediliyor...');
    
    // Kişisel kategori listesini kontrol et
    final currentCategory = HiveDatabaseService.getFriendCategory(
      ownerEmail: followedEmail,
      friendEmail: followerEmail,
    );
    
    if (currentCategory == null || currentCategory.toLowerCase() != 'takipçi') {
      print('📝 $followerEmail kullanıcısını $followedEmail\'in takipçi listesine ekleniyor...');
      await HiveDatabaseService.setFriendCategory(
        ownerEmail: followedEmail,
        friendEmail: followerEmail,
        category: 'takipçi',
      );
      print('✅ Kategori eklendi: $followerEmail -> takipçi');
    } else {
      print('✅ $followerEmail zaten $followedEmail\'in takipçi listesinde');
    }
  }
  
  static Future<void> _testInvitationAlgorithm(String openerEmail) async {
    print('\n🎯 Davet algoritması test ediliyor...');
    await DebugDavetUtils.testInvitationAlgorithm(openerEmail, 'takipçiler');
  }
  
  /// Hızlı test - sadece temel kontroller
  static Future<void> quickTest() async {
    print('⚡ HIZLI TEST BAŞLIYOR...\n');
    
    const openerEmail = 'whoboom@whoboom.com';
    const followerEmail = 'fatih@whoboom.com';
    
    // Kullanıcıları kontrol et
    final opener = HiveDatabaseService.getRegistrationByEmail(openerEmail);
    final follower = HiveDatabaseService.getRegistrationByEmail(followerEmail);
    
    print('Opener: ${opener?.email} (ID: ${opener?.id})');
    print('Follower: ${follower?.email} (ID: ${follower?.id})');
    
    if (opener != null && follower != null) {
      // Kişisel kategori listesini kontrol et
      final categories = HiveDatabaseService.getFriendCategories(openerEmail);
      print('${opener.email} kullanıcısının kategori listesi:');
      
      if (categories.isEmpty) {
        print('❌ Hiç kategori bulunamadı');
      } else {
        for (final entry in categories.entries) {
          print('  - ${entry.key} -> ${entry.value}');
        }
      }
      
      // Takipçi kategorisindeki kişileri kontrol et
      final takipciEmails = categories.entries
          .where((entry) => entry.value.toLowerCase() == 'takipçi')
          .map((entry) => entry.key)
          .toList();
      print('Takipçi kategorisindeki kişiler: $takipciEmails');
      
      // Davet algoritmasını test et
      final recipients = await HiveDatabaseService.pickInvitationRecipients(
        openerEmail,
        'takipçiler',
        excludedEmails: [],
      );
      print('Takipçiler kategorisinden seçilen kişi sayısı: ${recipients.length}');
      
      for (final recipient in recipients) {
        print('  - ${recipient.email}');
      }
    }
    
    print('\n✅ HIZLI TEST TAMAMLANDI');
  }
}
