/// Performans İyileştirmeleri Kullanım Örnekleri
/// 
/// Bu dosya cached_network_image ve timeago kullanımını gösterir
/// Gerçek kodda bu dosyayı kullanmayın, sadece referans için
library;

import 'package:flutter/material.dart';
import '../widgets/cached_avatar_widget.dart';
import '../widgets/cached_avatar_widget.dart' as cached;
import 'timeago_helper.dart';

/// Örnek 1: CachedAvatarWidget kullanımı
/// Avatar görsellerini cache'leyerek performansı artırır
Widget example1_CachedAvatar() {
  return const CachedAvatarWidget(
    imageUrl: 'https://example.com/avatar.jpg',
    radius: 30,
    userName: 'Ahmet Yılmaz', // Avatar yoksa ilk harfi gösterir
    defaultIcon: Icons.person,
  );
}

/// Örnek 2: CachedNetworkImageWidget kullanımı
/// Büyük görseller için optimize edilmiş cache
Widget example2_CachedNetworkImage() {
  return cached.CachedNetworkImageWidget(
    imageUrl: 'https://example.com/large-image.jpg',
    width: 200,
    height: 200,
    fit: BoxFit.cover,
    borderRadius: BorderRadius.circular(12),
  );
}

/// Örnek 3: Timeago kullanımı - DateTime
String example3_TimeAgoDateTime() {
  final date = DateTime.now().subtract(const Duration(minutes: 5));
  return TimeAgoHelper.format(date);
  // Çıktı: "5 dakika önce"
}

/// Örnek 4: Timeago kullanımı - String tarih
String example4_TimeAgoString() {
  const dateString = '2024-01-15T10:30:00Z';
  return TimeAgoHelper.formatFromString(dateString);
  // Çıktı: "2 gün önce" (bugünün tarihine göre)
}

/// Örnek 5: Kısa format
String example5_TimeAgoShort() {
  final date = DateTime.now().subtract(const Duration(hours: 2));
  return TimeAgoHelper.formatShort(date);
  // Çıktı: "2sa önce"
}

/// Örnek 6: Gelecek tarihler için
String example6_TimeAgoFuture() {
  final futureDate = DateTime.now().add(const Duration(minutes: 10));
  return TimeAgoHelper.formatFuture(futureDate);
  // Çıktı: "10 dakika sonra"
}

/// Örnek 7: Chat sayfasında avatar kullanımı
Widget example7_ChatAvatar(String avatarUrl, String userName) {
  return CachedAvatarWidget(
    imageUrl: avatarUrl,
    radius: 25,
    userName: userName,
    backgroundColor: Colors.grey.shade200,
  );
}

/// Örnek 8: Profil resmi widget'ı
Widget example8_ProfileImage(String? imageUrl, String userName) {
  return CachedAvatarWidget(
    imageUrl: imageUrl,
    radius: 50,
    userName: userName,
    defaultIcon: Icons.person,
    iconColor: Colors.white,
    backgroundColor: Colors.blue.shade700,
  );
}

/// Örnek 9: Liste içinde avatar
Widget example9_ListAvatar(String avatarUrl) {
  return ListTile(
    leading: CachedAvatarWidget(
      imageUrl: avatarUrl,
      radius: 20,
    ),
    title: const Text('Kullanıcı Adı'),
    subtitle: Text(TimeAgoHelper.format(DateTime.now().subtract(const Duration(minutes: 5)))),
  );
}

/// Örnek 10: Bildirim kartında timeago
Widget example10_NotificationCard(Map<String, dynamic> bildirim) {
  final timestamp = bildirim['timestamp'] as String?;
  final title = bildirim['title'] as String? ?? '';
  
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        timestamp != null 
            ? TimeAgoHelper.formatFromString(timestamp)
            : 'Bilinmeyen tarih',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    ),
  );
}

