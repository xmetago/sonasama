import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/local_notification_service.dart';
import '../utils/timeago_helper.dart';
import '../widgets/cached_avatar_widget.dart';
import '../widgets/cached_avatar_widget.dart' as cached;

/// Test Sayfası - Bildirimler ve Performans İyileştirmeleri
/// Bu sayfa yerel bildirimleri ve performans özelliklerini test etmek için kullanılır
class TestNotificationsPage extends StatefulWidget {
  const TestNotificationsPage({super.key});

  @override
  State<TestNotificationsPage> createState() => _TestNotificationsPageState();
}

class _TestNotificationsPageState extends State<TestNotificationsPage> {
  List<Map<String, dynamic>> _bildirimler = [];

  @override
  void initState() {
    super.initState();
    _loadBildirimler();
  }

  void _loadBildirimler() {
    setState(() {
      _bildirimler = LocalNotificationService.getAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sayfası'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      MdiIcons.testTube,
                      size: 48,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bildirimler ve Performans Testi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bildirim Testleri Bölümü
            _buildSectionTitle('🔔 Bildirim Testleri'),
            const SizedBox(height: 12),
            _buildNotificationTestButtons(),
            const SizedBox(height: 24),

            // Mevcut Bildirimler
            _buildSectionTitle('📋 Mevcut Bildirimler (${_bildirimler.length})'),
            const SizedBox(height: 12),
            if (_bildirimler.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          MdiIcons.bellOff,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz bildirim yok',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._bildirimler.map((bildirim) => _buildBildirimCard(bildirim)),
            const SizedBox(height: 24),

            // Performans Testleri Bölümü
            _buildSectionTitle('⚡ Performans Testleri'),
            const SizedBox(height: 12),
            _buildPerformanceTests(),
            const SizedBox(height: 24),

            // Timeago Testleri
            _buildSectionTitle('⏰ Timeago Testleri'),
            const SizedBox(height: 12),
            _buildTimeagoTests(),
            const SizedBox(height: 24),

            // Cached Image Testleri
            _buildSectionTitle('🖼️ Cached Image Testleri'),
            const SizedBox(height: 12),
            _buildCachedImageTests(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.orange.shade700,
      ),
    );
  }

  Widget _buildNotificationTestButtons() {
    return Column(
      children: [
        // Basit Bildirim
        ElevatedButton.icon(
          onPressed: () async {
            await LocalNotificationService.showNotification(
              title: 'Test Bildirimi',
              body: 'Bu bir test bildirimidir - ${DateTime.now().toString().substring(11, 19)}',
              payload: 'test_${DateTime.now().millisecondsSinceEpoch}',
            );
            _loadBildirimler();
            _showSuccess('Basit bildirim gösterildi!');
          },
          icon: const Icon(Icons.notifications),
          label: const Text('Basit Bildirim Göster'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Dava Bildirimi
        ElevatedButton.icon(
          onPressed: () async {
            await LocalNotificationService.showDavaNotification(
              title: 'Yeni Dava Daveti',
              body: 'Size yeni bir dava daveti geldi',
              davaId: 'test_dava_${DateTime.now().millisecondsSinceEpoch}',
            );
            _loadBildirimler();
            _showSuccess('Dava bildirimi gösterildi!');
          },
          icon: const Icon(Icons.gavel),
          label: const Text('Dava Bildirimi Göster'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Uyarı Bildirimi
        ElevatedButton.icon(
          onPressed: () async {
            await LocalNotificationService.showUyariNotification(
              title: 'Uyarı',
              body: 'Bu bir uyarı bildirimidir',
              payload: 'uyari_test',
            );
            _loadBildirimler();
            _showSuccess('Uyarı bildirimi gösterildi!');
          },
          icon: const Icon(Icons.warning),
          label: const Text('Uyarı Bildirimi Göster'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Zamanlanmış Bildirim (30 saniye sonra)
        ElevatedButton.icon(
          onPressed: () async {
            final scheduledDate = DateTime.now().add(const Duration(seconds: 30));
            await LocalNotificationService.scheduleNotification(
              title: 'Zamanlanmış Bildirim',
              body: 'Bu bildirim 30 saniye sonra gösterilecek',
              scheduledDate: scheduledDate,
              payload: 'scheduled_test',
            );
            _showSuccess('Zamanlanmış bildirim ayarlandı! (30 saniye sonra)');
          },
          icon: const Icon(Icons.schedule),
          label: const Text('Zamanlanmış Bildirim (30 sn)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Tüm Bildirimleri Sil
        OutlinedButton.icon(
          onPressed: () async {
            await LocalNotificationService.deleteAllNotifications();
            _loadBildirimler();
            _showSuccess('Tüm bildirimler silindi!');
          },
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Tüm Bildirimleri Sil'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBildirimCard(Map<String, dynamic> bildirim) {
    final title = bildirim['title'] as String? ?? '';
    final body = bildirim['body'] as String? ?? '';
    final timestampStr = bildirim['timestamp'] as String?;
    final isRead = bildirim['isRead'] as bool? ?? false;
    final notificationId = bildirim['id'] as int? ?? 0;
    final channelId = bildirim['channelId'] as String? ?? '';
    final isScheduled = bildirim['isScheduled'] as bool? ?? false;

    // Timeago ile tarih formatlama
    String tarihText = '';
    if (timestampStr != null) {
      tarihText = TimeAgoHelper.formatFromString(timestampStr);
    }

    Color kanalRengi = Colors.blue.shade700;
    if (channelId == 'mesaj_bildirimleri') {
      kanalRengi = Colors.green.shade700;
    } else if (channelId == 'dava_bildirimleri') {
      kanalRengi = Colors.orange.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kanalRengi,
          child: Icon(
            isScheduled ? Icons.schedule : Icons.notifications,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: isRead ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  tarihText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRead)
              IconButton(
                icon: const Icon(Icons.mark_email_read, size: 20),
                onPressed: () async {
                  await LocalNotificationService.markAsRead(notificationId);
                  _loadBildirimler();
                },
                tooltip: 'Okundu olarak işaretle',
              ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () async {
                await LocalNotificationService.deleteNotification(notificationId);
                _loadBildirimler();
              },
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performans İyileştirmeleri Aktif:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildCheckItem('✅ Cached Network Image aktif'),
            _buildCheckItem('✅ Timeago Türkçe dil desteği aktif'),
            _buildCheckItem('✅ Otomatik cache yönetimi'),
            _buildCheckItem('✅ Bellek optimizasyonu'),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildTimeagoTests() {
    final now = DateTime.now();
    final testDates = [
      {'date': now.subtract(const Duration(minutes: 5)), 'label': '5 dakika önce'},
      {'date': now.subtract(const Duration(hours: 2)), 'label': '2 saat önce'},
      {'date': now.subtract(const Duration(days: 3)), 'label': '3 gün önce'},
      {'date': now.subtract(const Duration(days: 7)), 'label': '7 gün önce'},
      {'date': now.add(const Duration(minutes: 10)), 'label': '10 dakika sonra'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeago Format Testleri:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...testDates.map((test) {
              final date = test['date'] as DateTime;
              final label = test['label'] as String;
              final formatted = TimeAgoHelper.format(date, allowFromNow: true);
              final shortFormatted = TimeAgoHelper.formatShort(date);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    Text(
                      formatted,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($shortFormatted)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedImageTests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cached Image Widget Testleri:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Column(
                  children: [
                    Text('Avatar Widget', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 8),
                    CachedAvatarWidget(
                      imageUrl: 'https://ui-avatars.com/api/?name=Test+User&size=128',
                      radius: 30,
                      userName: 'Test User',
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Network Image', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    cached.CachedNetworkImageWidget(
                      imageUrl: 'https://picsum.photos/100/100?random=1',
                      width: 60,
                      height: 60,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Not: İlk yüklemede placeholder gösterilir, sonraki yüklemelerde cache\'den gelir.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

