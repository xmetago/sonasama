/// LocalNotificationService Kullanım Örnekleri
/// 
/// Bu dosya LocalNotificationService'in nasıl kullanılacağını gösterir
/// Gerçek kodda bu dosyayı kullanmayın, sadece referans için
library;

import 'package:its19/services/local_notification_service.dart';

/// Örnek 1: Basit bildirim göster
Future<void> example1_SimpleNotification() async {
  await LocalNotificationService.showNotification(
    title: 'Yeni Mesaj',
    body: 'Size yeni bir mesaj geldi',
    payload: 'mesaj_123',
  );
}

/// Örnek 2: Dava bildirimi göster
Future<void> example2_DavaNotification() async {
  await LocalNotificationService.showDavaNotification(
    title: 'Yeni Dava Daveti',
    body: 'Size yeni bir dava daveti geldi',
    davaId: 'dava_456',
  );
}

/// Örnek 3: Uyarı bildirimi göster
Future<void> example3_UyariNotification() async {
  await LocalNotificationService.showUyariNotification(
    title: 'Hatırlatma',
    body: 'Davanızın son günü yaklaşıyor',
    payload: 'uyari_789',
  );
}

/// Örnek 4: Zamanlanmış bildirim göster
Future<void> example4_ScheduledNotification() async {
  // 1 saat sonra bildirim göster
  final scheduledDate = DateTime.now().add(const Duration(hours: 1));
  
  await LocalNotificationService.scheduleNotification(
    title: 'Hatırlatma',
    body: 'Davanızın son günü bugün',
    scheduledDate: scheduledDate,
    payload: 'hatirlatma_123',
  );
}

/// Örnek 5: Tüm bildirimleri getir
void example5_GetAllNotifications() {
  final notifications = LocalNotificationService.getAllNotifications();
  
  for (final notification in notifications) {
    print('Bildirim: ${notification['title']}');
    print('İçerik: ${notification['body']}');
    print('Tarih: ${notification['timestamp']}');
    print('Okundu mu: ${notification['isRead']}');
  }
}

/// Örnek 6: Bildirimi okundu olarak işaretle
Future<void> example6_MarkAsRead() async {
  await LocalNotificationService.markAsRead(12345);
}

/// Örnek 7: Bildirimi sil
Future<void> example7_DeleteNotification() async {
  await LocalNotificationService.deleteNotification(12345);
}

/// Örnek 8: Tüm bildirimleri sil
Future<void> example8_DeleteAllNotifications() async {
  await LocalNotificationService.deleteAllNotifications();
}

/// Örnek 9: Bildirim izinlerini kontrol et
Future<void> example9_CheckPermissions() async {
  final hasPermission = await LocalNotificationService.checkPermissions();
  
  if (!hasPermission) {
    // İzin yoksa kullanıcıya bildir
    print('Bildirim izni verilmedi');
  } else {
    // İzin varsa bildirim göster
    await LocalNotificationService.showNotification(
      title: 'İzin Verildi',
      body: 'Bildirimler aktif',
    );
  }
}

/// Örnek 10: Mesaj geldiğinde bildirim göster
/// ChatService veya başka bir serviste kullanılabilir
Future<void> example10_OnMessageReceived(String senderName, String message) async {
  await LocalNotificationService.showNotification(
    title: 'Yeni Mesaj: $senderName',
    body: message,
    channelId: 'mesaj_bildirimleri',
    payload: 'chat_$senderName',
  );
}

/// Örnek 11: Dava daveti geldiğinde bildirim göster
Future<void> example11_OnDavaInvitation(String davaAdi, String davaId) async {
  await LocalNotificationService.showDavaNotification(
    title: 'Yeni Dava Daveti',
    body: 'Size "$davaAdi" davası için davet geldi',
    davaId: davaId,
  );
}

/// Örnek 12: Uyarı bildirimi göster (hediye uyarısı gibi)
Future<void> example12_OnUyari(String uyariMesaji, String davaId) async {
  await LocalNotificationService.showUyariNotification(
    title: 'Uyarı',
    body: uyariMesaji,
    payload: 'uyari_$davaId',
  );
}

