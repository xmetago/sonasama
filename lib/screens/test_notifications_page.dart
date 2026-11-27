import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import '../services/hive_database_service.dart';
import '../services/local_notification_service.dart';
import '../theme/seyir_tokens.dart';
import '../utils/timeago_helper.dart';
import '../widgets/cached_avatar_widget.dart';
import '../widgets/cached_avatar_widget.dart' as cached;
import '../widgets/delil_surface.dart';

/// Test Sayfası - Bildirimler ve Performans İyileştirmeleri
/// Bu sayfa yerel bildirimleri ve performans özelliklerini test etmek için kullanılır
class TestNotificationsPage extends StatefulWidget {
  const TestNotificationsPage({super.key, this.userEmail});

  final String? userEmail;

  @override
  State<TestNotificationsPage> createState() => _TestNotificationsPageState();
}

class _TestNotificationsPageState extends State<TestNotificationsPage> {
  List<Map<String, dynamic>> _bildirimler = [];

  bool get _authorized =>
      kDebugMode && HiveDatabaseService.isAdmin(widget.userEmail);

  @override
  void initState() {
    super.initState();
    if (_authorized) {
      _loadBildirimler();
    }
  }

  void _loadBildirimler() {
    if (!_authorized) return;
    setState(() {
      _bildirimler = LocalNotificationService.getAllNotifications();
    });
  }

  Color _orange(SeyirPalette palette) {
    return palette.isDark ? const Color(0xFFFFB074) : Colors.orange.shade700;
  }

  ButtonStyle _filledButton(Color background) {
    final inherited = Theme.of(context).textTheme.labelLarge;
    return ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, SeyirTokens.tapTarget),
      padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
      textStyle: TextStyle(
        fontSize: SeyirTokens.typeBody,
        fontWeight: FontWeight.w700,
        fontFamily: inherited?.fontFamily,
        fontFamilyFallback: inherited?.fontFamilyFallback,
      ),
    );
  }

  Future<bool> _confirm({required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogPalette = SeyirPalette.of(ctx);
        return AlertDialog(
          backgroundColor: dialogPalette.card,
          shape: const RoundedRectangleBorder(borderRadius: SeyirTokens.radiusLgAll),
          title: Text(title, style: dialogPalette.title()),
          content: Text(message, style: dialogPalette.body(weight: FontWeight.w400)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                foregroundColor: dialogPalette.textPrimary,
              ),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                foregroundColor: SeyirTokens.reject,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
    return result == true && mounted;
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final orange = _orange(palette);
    if (!_authorized) {
      return Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(
          title: Text('Test Sayfası', style: palette.headline(color: Colors.white)),
          backgroundColor: orange,
          foregroundColor: palette.onSolid(orange),
        ),
        body: const Padding(
          padding: EdgeInsets.all(SeyirTokens.space4),
          child: DelilSoftEmpty(
            title: 'Yetkiniz yok',
            message: 'Bu sayfayı yalnızca yöneticiler kullanabilir.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text('Test Sayfası', style: palette.headline(color: Colors.white)),
        backgroundColor: orange,
        foregroundColor: palette.onSolid(orange),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SeyirTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: palette.tint(orange),
              shape: RoundedRectangleBorder(
                borderRadius: SeyirTokens.radiusMdAll,
                side: BorderSide(color: palette.tintBorder(orange)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(SeyirTokens.space4),
                child: Column(
                  children: [
                    Icon(
                      MdiIcons.testTube,
                      size: 48,
                      color: orange,
                    ),
                    const SizedBox(height: SeyirTokens.space2),
                    Text(
                      'Bildirimler ve Performans Testi',
                      textAlign: TextAlign.center,
                      style: palette.headline(color: orange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SeyirTokens.space6),

            _buildSectionTitle('🔔 Bildirim Testleri', orange),
            const SizedBox(height: SeyirTokens.space3),
            _buildNotificationTestButtons(palette, orange),
            const SizedBox(height: SeyirTokens.space6),

            _buildSectionTitle('📋 Mevcut Bildirimler (${_bildirimler.length})', orange),
            const SizedBox(height: SeyirTokens.space3),
            if (_bildirimler.isEmpty)
              const DelilSoftEmpty(
                title: 'Henüz bildirim yok',
                message: 'Gösterilecek bir test bildirimi bulunmuyor.',
                icon: MdiIcons.bellOff,
              )
            else
              ..._bildirimler.map((bildirim) => _buildBildirimCard(bildirim, palette)),
            const SizedBox(height: SeyirTokens.space6),

            _buildSectionTitle('⚡ Performans Testleri', orange),
            const SizedBox(height: SeyirTokens.space3),
            _buildPerformanceTests(palette),
            const SizedBox(height: SeyirTokens.space6),

            _buildSectionTitle('⏰ Timeago Testleri', orange),
            const SizedBox(height: SeyirTokens.space3),
            _buildTimeagoTests(palette),
            const SizedBox(height: SeyirTokens.space6),

            _buildSectionTitle('🖼️ Cached Image Testleri', orange),
            const SizedBox(height: SeyirTokens.space3),
            _buildCachedImageTests(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color orange) {
    return Text(
      title,
      style: SeyirPalette.of(context).headline(color: orange),
    );
  }

  Widget _buildNotificationTestButtons(SeyirPalette palette, Color orange) {
    return Column(
      children: [
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
          style: _filledButton(const Color(0xFF1D4ED8)),
        ),
        const SizedBox(height: SeyirTokens.space2),

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
          style: _filledButton(orange),
        ),
        const SizedBox(height: SeyirTokens.space2),

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
          style: _filledButton(SeyirTokens.reject),
        ),
        const SizedBox(height: SeyirTokens.space2),

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
          style: _filledButton(SeyirTokens.accept),
        ),
        const SizedBox(height: SeyirTokens.space2),

        OutlinedButton.icon(
          onPressed: () async {
            final ok = await _confirm(
              title: 'Tüm bildirimleri sil',
              message: 'Tüm bildirimleri silmek istediğine emin misin?',
            );
            if (!ok) return;
            await LocalNotificationService.deleteAllNotifications();
            _loadBildirimler();
            _showSuccess('Tüm bildirimler silindi!');
          },
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Tüm Bildirimleri Sil'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SeyirTokens.reject,
            minimumSize: const Size(double.infinity, SeyirTokens.tapTarget),
            padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
            side: const BorderSide(color: SeyirTokens.reject),
            textStyle: TextStyle(
              fontSize: SeyirTokens.typeBody,
              fontWeight: FontWeight.w700,
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
              fontFamilyFallback:
                  Theme.of(context).textTheme.labelLarge?.fontFamilyFallback,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBildirimCard(Map<String, dynamic> bildirim, SeyirPalette palette) {
    final title = bildirim['title'] as String? ?? '';
    final body = bildirim['body'] as String? ?? '';
    final timestampStr = bildirim['timestamp'] as String?;
    final isRead = bildirim['isRead'] as bool? ?? false;
    final notificationId = bildirim['id'] as int? ?? 0;
    final channelId = bildirim['channelId'] as String? ?? '';
    final isScheduled = bildirim['isScheduled'] as bool? ?? false;

    String tarihText = '';
    if (timestampStr != null) {
      tarihText = TimeAgoHelper.formatFromString(timestampStr);
    }

    Color kanalRengi = const Color(0xFF1D4ED8);
    if (channelId == 'mesaj_bildirimleri') {
      kanalRengi = SeyirTokens.accept;
    } else if (channelId == 'dava_bildirimleri') {
      kanalRengi = _orange(palette);
    }

    return Card(
      color: palette.card,
      margin: const EdgeInsets.only(bottom: SeyirTokens.space2),
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusMdAll,
        side: BorderSide(color: palette.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kanalRengi,
          child: Icon(
            isScheduled ? Icons.schedule : Icons.notifications,
            color: palette.onSolid(kanalRengi),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: palette.body(
            weight: isRead ? FontWeight.w500 : FontWeight.w700,
            color: isRead ? palette.textSecondary : palette.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SeyirTokens.space1),
            Text(body, style: palette.body(weight: FontWeight.w400)),
            const SizedBox(height: SeyirTokens.space1),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: palette.textMuted),
                const SizedBox(width: SeyirTokens.space1),
                Text(tarihText, style: palette.caption()),
                if (!isRead) ...[
                  const SizedBox(width: SeyirTokens.space2),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D4ED8),
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
                style: delilIconButtonStyle(foreground: palette.textSecondary),
                icon: const Icon(Icons.mark_email_read, size: 20),
                onPressed: () async {
                  await LocalNotificationService.markAsRead(notificationId);
                  _loadBildirimler();
                },
                tooltip: 'Okundu olarak işaretle',
              ),
            IconButton(
              style: delilIconButtonStyle(foreground: SeyirTokens.reject),
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () async {
                final ok = await _confirm(
                  title: 'Bildirimi sil',
                  message: 'Bu bildirimi silmek istediğine emin misin?',
                );
                if (!ok) return;
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

  Widget _buildPerformanceTests(SeyirPalette palette) {
    return Card(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusMdAll,
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SeyirTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performans İyileştirmeleri Aktif:',
              style: palette.body(weight: FontWeight.w700),
            ),
            const SizedBox(height: SeyirTokens.space2),
            _buildCheckItem('✅ Cached Network Image aktif', palette),
            _buildCheckItem('✅ Timeago Türkçe dil desteği aktif', palette),
            _buildCheckItem('✅ Otomatik cache yönetimi', palette),
            _buildCheckItem('✅ Bellek optimizasyonu', palette),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text, SeyirPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space1),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: SeyirTokens.accept),
          const SizedBox(width: SeyirTokens.space2),
          Expanded(child: Text(text, style: palette.body(weight: FontWeight.w400))),
        ],
      ),
    );
  }

  Widget _buildTimeagoTests(SeyirPalette palette) {
    final now = DateTime.now();
    final testDates = [
      {'date': now.subtract(const Duration(minutes: 5)), 'label': '5 dakika önce'},
      {'date': now.subtract(const Duration(hours: 2)), 'label': '2 saat önce'},
      {'date': now.subtract(const Duration(days: 3)), 'label': '3 gün önce'},
      {'date': now.subtract(const Duration(days: 7)), 'label': '7 gün önce'},
      {'date': now.add(const Duration(minutes: 10)), 'label': '10 dakika sonra'},
    ];

    return Card(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusMdAll,
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SeyirTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeago Format Testleri:',
              style: palette.body(weight: FontWeight.w700),
            ),
            const SizedBox(height: SeyirTokens.space3),
            ...testDates.map((test) {
              final date = test['date'] as DateTime;
              final label = test['label'] as String;
              final formatted = TimeAgoHelper.format(date, allowFromNow: true);
              final shortFormatted = TimeAgoHelper.formatShort(date);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: palette.body(
                          color: palette.textSecondary,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(formatted, style: palette.body(weight: FontWeight.w700)),
                    const SizedBox(width: SeyirTokens.space2),
                    Text('($shortFormatted)', style: palette.caption()),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedImageTests(SeyirPalette palette) {
    return Card(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusMdAll,
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SeyirTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cached Image Widget Testleri:',
              style: palette.body(weight: FontWeight.w700),
            ),
            const SizedBox(height: SeyirTokens.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Avatar Widget', style: palette.caption()),
                    const SizedBox(height: SeyirTokens.space2),
                    const CachedAvatarWidget(
                      imageUrl: 'https://ui-avatars.com/api/?name=Test+User&size=128',
                      radius: 30,
                      userName: 'Test User',
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Network Image', style: palette.caption()),
                    const SizedBox(height: SeyirTokens.space2),
                    const cached.CachedNetworkImageWidget(
                      imageUrl: 'https://picsum.photos/100/100?random=1',
                      width: 60,
                      height: 60,
                      borderRadius: SeyirTokens.radiusSmAll,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: SeyirTokens.space4),
            Text(
              'Not: İlk yüklemede placeholder gösterilir, sonraki yüklemelerde cache\'den gelir.',
              style: palette.caption(fontStyle: FontStyle.italic),
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
        backgroundColor: SeyirTokens.accept,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
