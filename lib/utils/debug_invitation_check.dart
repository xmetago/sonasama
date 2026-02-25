import '../services/hive_database_service.dart';

class DebugInvitationCheck {
  /// TestYargıç 40 ve TestYargıç 30 kullanıcılarının davet kutularını kontrol et
  static Future<void> checkTestUsers() async {
    print('🔍 TestYargıç kullanıcılarının davet kutularını kontrol ediliyor...\n');
    
    final testUsers = [
      'testyargic40@gmail.com',
      'testyargic30@gmail.com',
    ];
    
    for (final userEmail in testUsers) {
      print('📧 $userEmail kullanıcısının davetleri:');
      
      // Kullanıcı var mı kontrol et
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      if (user == null) {
        print('  ❌ Kullanıcı bulunamadı!');
        continue;
      }
      
      // Davetleri getir
      final invitations = HiveDatabaseService.getInvitations(userEmail);
      print('  📬 Toplam davet sayısı: ${invitations.length}');
      
      if (invitations.isEmpty) {
        print('  ⚠️ Hiç davet bulunamadı!');
      } else {
        for (int i = 0; i < invitations.length; i++) {
          final inv = invitations[i];
          print('  ${i + 1}. ${inv['davaAdi']} - ${inv['davaci']} (${inv['kategori']})');
        }
      }
      print('');
    }
  }
  
  /// whoboom@whoboom.com kullanıcısının son açtığı davayı kontrol et
  static Future<void> checkLastDava() async {
    print('🔍 whoboom@whoboom.com kullanıcısının son davası kontrol ediliyor...\n');
    
    const openerEmail = 'whoboom@whoboom.com';
    
    // Kullanıcının açtığı davaları getir
    final userDavalar = HiveDatabaseService.getIncomingDavalar(openerEmail);
    print('📋 Toplam dava sayısı: ${userDavalar.length}');
    
    if (userDavalar.isEmpty) {
      print('❌ Hiç dava bulunamadı!');
      return;
    }
    
    // En son davayı bul (tarihe göre)
    final sortedDavalar = List<Map<String, dynamic>>.from(userDavalar);
    sortedDavalar.sort((a, b) {
      final aTime = DateTime.tryParse(a['acilmaTarihi'] ?? '') ?? DateTime(1970);
      final bTime = DateTime.tryParse(b['acilmaTarihi'] ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    
    final lastDava = sortedDavalar.first;
    print('📄 Son dava: ${lastDava['adi'] ?? lastDava['davaAdi']}');
    print('📅 Açılma tarihi: ${lastDava['acilmaTarihi']}');
    print('👥 Seçilen gruplar: ${lastDava['selectedGroups']}');
    
    // Bu davaya ait davetleri kontrol et
    final davaId = lastDava['id'];
    await _checkInvitationsForDava(davaId);
  }
  
  /// Belirli bir davaya ait davetleri kontrol et
  static Future<void> _checkInvitationsForDava(String davaId) async {
    print('\n🎯 Dava ID: $davaId için gönderilen davetler kontrol ediliyor...');
    
    // Tüm kullanıcıları kontrol et
    final allUsers = HiveDatabaseService.getAllRegistrations();
    int totalInvitations = 0;
    
    for (final user in allUsers) {
      final invitations = HiveDatabaseService.getInvitations(user.email);
      final davaInvitations = invitations.where((inv) => inv['davaId'] == davaId).toList();
      
      if (davaInvitations.isNotEmpty) {
        totalInvitations += davaInvitations.length;
        print('  📧 ${user.email}: ${davaInvitations.length} davet');
      }
    }
    
    print('📊 Toplam gönderilen davet sayısı: $totalInvitations');
  }
  
  /// Hive veritabanı durumunu kontrol et
  static Future<void> checkHiveStatus() async {
    print('🔍 Hive veritabanı durumu kontrol ediliyor...\n');
    
    // Incoming dava box durumu
    try {
      final box = HiveDatabaseService.getIncomingDavaBox();
      if (box == null) {
        print('❌ Incoming dava box bulunamadı!');
      } else {
        print('✅ Incoming dava box aktif');
        print('📦 Box içindeki key sayısı: ${box.keys.length}');
        
        // Davet anahtarlarını kontrol et
        final invitationKeys = box.keys.where((key) => key.toString().contains('_invitations')).toList();
        print('📬 Davet anahtarı sayısı: ${invitationKeys.length}');
        
        for (final key in invitationKeys) {
          final data = box.get(key);
          if (data is List) {
            print('  - $key: ${data.length} davet');
          }
        }
      }
    } catch (e) {
      print('❌ Hive box kontrol hatası: $e');
    }
  }
  
  /// Hive box'a erişim fonksiyonu ekle
  static dynamic getIncomingDavaBox() {
    return HiveDatabaseService.getIncomingDavaBox();
  }
  
  /// Tam debug raporu
  static Future<void> fullDebugReport() async {
    print('🚀 TAM DEBUG RAPORU BAŞLATIYOR...\n');
    print('=' * 50);
    
    await checkHiveStatus();
    print('\n${'=' * 50}');
    
    await checkLastDava();
    print('\n${'=' * 50}');
    
    await checkTestUsers();
    print('\n${'=' * 50}');
    
    print('✅ Debug raporu tamamlandı!');
  }
}
