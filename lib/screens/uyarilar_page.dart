import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import '../services/hive_database_service.dart';
import '../services/local_notification_service.dart';
import '../theme/seyir_tokens.dart';
import '../utils/timeago_helper.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/delil_surface.dart';
import 'chat_detail_page.dart';
import 'delilleri_incele_page.dart';
import 'test_notifications_page.dart';

/// Uyarılar/Bildirimler Sayfası
class UyarilarPage extends StatefulWidget {
  final String? userEmail;

  const UyarilarPage({super.key, this.userEmail});

  @override
  State<UyarilarPage> createState() => _UyarilarPageState();
}

class _ChatTarget {
  const _ChatTarget({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;
}

class _UyarilarPageState extends State<UyarilarPage> {
  List<Map<String, dynamic>> _bildirimler = [];
  List<Map<String, dynamic>> _yerelBildirimler = [];
  String _aktifTab = 'uygulama';

  bool get _needsLogin {
    final email = widget.userEmail?.trim();
    return email == null || email.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadBildirimler();
  }

  void _loadBildirimler() {
    if (_needsLogin) {
      setState(() {
        _bildirimler = [];
        _yerelBildirimler = [];
      });
      return;
    }

    setState(() {
      _bildirimler = HiveDatabaseService.getBildirimler(widget.userEmail!);
      _yerelBildirimler = LocalNotificationService.getAllNotifications();
    });
  }

  Color _orange(SeyirPalette palette) {
    return palette.isDark ? const Color(0xFFFFB074) : Colors.orange.shade700;
  }

  Color _deviceAccent(SeyirPalette palette) {
    return palette.isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogPalette = SeyirPalette.of(ctx);
        return AlertDialog(
          backgroundColor: dialogPalette.card,
          shape: const RoundedRectangleBorder(borderRadius: SeyirTokens.radiusLgAll),
          title: Text(
            'Silmek istediğine emin misin?',
            style: dialogPalette.title(),
          ),
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

  bool _isChat(Map<String, dynamic> bildirim) {
    final type = bildirim['type']?.toString();
    if (type == 'durtme') return true;
    if (type == 'gelen_dava' || type == 'uyari') return false;
    final channel = bildirim['channelId']?.toString() ?? '';
    final payload = bildirim['payload']?.toString() ?? '';
    if (channel == 'mesaj_bildirimleri') return true;
    if (payload.startsWith('chat_') ||
        payload.startsWith('chat:') ||
        payload.startsWith('mesaj_')) {
      return true;
    }
    final sender = bildirim['senderEmail']?.toString();
    return sender != null &&
        sender.contains('@') &&
        (bildirim['davaId'] == null || bildirim['davaId'].toString().isEmpty);
  }

  _ChatTarget? _chatTarget(Map<String, dynamic> bildirim) {
    String? email = bildirim['senderEmail']?.toString();
    final payload = bildirim['payload']?.toString() ?? '';
    if ((email == null || !email.contains('@')) && payload.contains('@')) {
      final at = payload.indexOf('@');
      final start = payload.lastIndexOf(RegExp(r'[\s:_]'), at);
      email = payload.substring(start + 1).trim();
    }
    if (email == null || !email.contains('@')) return null;
    final user = HiveDatabaseService.getRegistrationByEmail(email);
    final name = bildirim['senderName']?.toString() ??
        user?.judgeName ??
        email.split('@').first;
    return _ChatTarget(
      id: user?.id ?? email,
      email: email,
      name: name,
    );
  }

  String? _davaIdOf(Map<String, dynamic> bildirim) {
    final direct = bildirim['davaId']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final payload = bildirim['payload']?.toString() ?? '';
    if (payload.isEmpty) return null;
    if (payload.startsWith('uyari_')) {
      final id = payload.substring('uyari_'.length);
      return id.isEmpty ? null : id;
    }
    if (payload.startsWith('dava:')) {
      final id = payload.substring('dava:'.length);
      return id.isEmpty ? null : id;
    }
    final channel = bildirim['channelId']?.toString() ?? '';
    if (channel == 'dava_bildirimleri' || payload.startsWith('dava_')) {
      return payload;
    }
    return null;
  }

  Future<void> _openRelated(Map<String, dynamic> bildirim) async {
    if (_isChat(bildirim)) {
      final chat = _chatTarget(bildirim);
      if (chat == null || !mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            receiverId: chat.id,
            receiverEmail: chat.email,
            receiverName: chat.name,
            userEmail: widget.userEmail,
          ),
        ),
      );
      return;
    }
    final davaId = _davaIdOf(bildirim);
    if (davaId == null || davaId.isEmpty || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DelilleriIncelePage(
          userEmail: widget.userEmail,
          davaId: davaId,
        ),
      ),
    );
  }

  String _kanalAdi(String channelId) {
    switch (channelId) {
      case 'mesaj_bildirimleri':
        return 'Mesaj';
      case 'dava_bildirimleri':
        return 'Dava';
      case 'uyari_bildirimleri':
        return 'Uyarı';
      default:
        return 'Bildirim';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final orange = _orange(palette);
    final device = _deviceAccent(palette);
    final showTestPage = HiveDatabaseService.isAdmin(widget.userEmail);
    final uygulama = _aktifTab == 'uygulama';

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: Column(
          children: [
            ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OneFriendPhoneBellMenu(
                userEmail: widget.userEmail,
                isBildirimlerPage: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        MdiIcons.bell,
                        size: 28,
                        color: orange,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'UYARILAR',
                        style: palette.headline(color: orange),
                      ),
                      const Spacer(),
                      if (showTestPage)
                        IconButton(
                          tooltip: 'Test Sayfası',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(
                              SeyirTokens.tapTarget,
                              SeyirTokens.tapTarget,
                            ),
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                          icon: Icon(
                            MdiIcons.testTube,
                            color: device,
                            size: 24,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TestNotificationsPage(),
                              ),
                            );
                          },
                        ),
                      if (showTestPage) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: palette.tint(orange),
                          borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
                          border: Border.all(color: palette.tintBorder(orange)),
                        ),
                        child: Text(
                          '${_bildirimler.length + _yerelBildirimler.length}',
                          style: TextStyle(
                            fontSize: SeyirTokens.typeBody,
                            fontWeight: FontWeight.bold,
                            color: orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTab(
                        label: 'Uygulama uyarıları (${_bildirimler.length})',
                        selected: uygulama,
                        accent: orange,
                        onTap: () => setState(() => _aktifTab = 'uygulama'),
                      ),
                      const SizedBox(width: 8),
                      _buildTab(
                        label: 'Cihaz bildirimleri (${_yerelBildirimler.length})',
                        selected: !uygulama,
                        accent: device,
                        onTap: () => setState(() => _aktifTab = 'cihaz'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _needsLogin
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: DelilSoftEmpty(
                        title: 'Giriş gerekli',
                        message: 'Uyarıları görmek için oturum aç.',
                        icon: Icons.lock_outline,
                      ),
                    )
                  : uygulama
                  ? _bildirimler.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: DelilSoftEmpty(
                            title: 'Henüz uygulama uyarısı yok',
                            message: 'Dava ve hediye uyarıları burada görünecek',
                            icon: MdiIcons.bellOff,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _loadBildirimler();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _bildirimler.length,
                            itemBuilder: (context, index) {
                              return _buildBildirimCard(_bildirimler[index]);
                            },
                          ),
                        )
                  : _yerelBildirimler.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: DelilSoftEmpty(
                            title: 'Henüz cihaz bildirimi yok',
                            message: 'Telefonuna gelen bildirimler burada görünecek',
                            icon: MdiIcons.bellOff,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _loadBildirimler();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _yerelBildirimler.length,
                            itemBuilder: (context, index) {
                              return _buildYerelBildirimCard(_yerelBildirimler[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final palette = SeyirPalette.of(context);
    return Expanded(
      child: Material(
        color: selected ? accent : palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusSmAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: SeyirTokens.radiusSmAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: SeyirTokens.typeBody,
                    fontWeight: FontWeight.bold,
                    color: selected ? palette.onSolid(accent) : palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBildirimCard(Map<String, dynamic> bildirim) {
    final palette = SeyirPalette.of(context);
    final orange = _orange(palette);
    final uyariMesaji = bildirim['uyariMesaji'] as String? ?? '';
    final olusturmaTarihiStr = bildirim['olusturmaTarihi'] as String?;
    final tarihText = olusturmaTarihiStr == null
        ? ''
        : TimeAgoHelper.formatFromString(olusturmaTarihiStr);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 0,
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusLgAll,
        side: BorderSide(color: palette.tintBorder(orange)),
      ),
      child: InkWell(
        borderRadius: SeyirTokens.radiusLgAll,
        onTap: () => _openRelated(bildirim),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: palette.textSecondary),
                      const SizedBox(width: 4),
                      Text(tarihText, style: palette.caption()),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Sil',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(
                        SeyirTokens.tapTarget,
                        SeyirTokens.tapTarget,
                      ),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    icon: Icon(Icons.close, size: 20, color: palette.textSecondary),
                    onPressed: () async {
                      final bildirimId = bildirim['id'] as String?;
                      if (bildirimId == null || widget.userEmail == null) return;
                      if (!await _confirmDelete()) return;
                      await HiveDatabaseService.deleteBildirim(
                        widget.userEmail!,
                        bildirimId,
                      );
                      _loadBildirimler();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: SeyirTokens.radiusMdAll,
                  border: Border.all(color: palette.tintBorder(orange)),
                ),
                child: Text(
                  uyariMesaji,
                  style: palette.body(weight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.gavel, size: 16, color: _deviceAccent(palette)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bildirim['davaAdi'] as String? ?? 'Bilinmeyen Dava',
                      style: palette.caption(
                        color: _deviceAccent(palette),
                        weight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYerelBildirimCard(Map<String, dynamic> bildirim) {
    final palette = SeyirPalette.of(context);
    final title = bildirim['title'] as String? ?? '';
    final body = bildirim['body'] as String? ?? '';
    final timestampStr = bildirim['timestamp'] as String?;
    final isRead = bildirim['isRead'] as bool? ?? false;
    final notificationId = bildirim['id'] as int? ?? 0;
    final channelId = bildirim['channelId'] as String? ?? '';
    final tarihText = timestampStr == null
        ? ''
        : TimeAgoHelper.formatFromString(timestampStr);

    Color kanalRengi = _deviceAccent(palette);
    IconData kanalIcon = MdiIcons.bell;
    if (channelId == 'mesaj_bildirimleri') {
      kanalRengi = palette.isDark ? SeyirTokens.brand : const Color(0xFF047857);
      kanalIcon = MdiIcons.message;
    } else if (channelId == 'dava_bildirimleri') {
      kanalRengi = _orange(palette);
      kanalIcon = MdiIcons.gavel;
    } else if (channelId == 'uyari_bildirimleri') {
      kanalRengi = _deviceAccent(palette);
      kanalIcon = MdiIcons.alert;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 0,
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusLgAll,
        side: BorderSide(color: palette.tintBorder(kanalRengi)),
      ),
      child: InkWell(
        borderRadius: SeyirTokens.radiusLgAll,
        onTap: () => _openRelated(bildirim),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: palette.textSecondary),
                      const SizedBox(width: 4),
                      Text(tarihText, style: palette.caption()),
                      if (!isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: kanalRengi,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (!isRead)
                        IconButton(
                          tooltip: 'Okundu olarak işaretle',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(
                              SeyirTokens.tapTarget,
                              SeyirTokens.tapTarget,
                            ),
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                          icon: Icon(
                            Icons.mark_email_read,
                            size: 20,
                            color: palette.textSecondary,
                          ),
                          onPressed: () async {
                            await LocalNotificationService.markAsRead(notificationId);
                            _loadBildirimler();
                          },
                        ),
                      IconButton(
                        tooltip: 'Sil',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(
                            SeyirTokens.tapTarget,
                            SeyirTokens.tapTarget,
                          ),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        icon: Icon(Icons.close, size: 20, color: palette.textSecondary),
                        onPressed: () async {
                          if (!await _confirmDelete()) return;
                          await LocalNotificationService.deleteNotification(notificationId);
                          _loadBildirimler();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(kanalIcon, size: 16, color: kanalRengi),
                  const SizedBox(width: 8),
                  Text(
                    _kanalAdi(channelId),
                    style: palette.caption(color: kanalRengi, weight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: palette.title(
                  color: isRead ? palette.textSecondary : palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: SeyirTokens.radiusMdAll,
                  border: Border.all(color: palette.tintBorder(kanalRengi)),
                ),
                child: Text(
                  body,
                  style: palette.body(
                    weight: FontWeight.w400,
                    color: isRead ? palette.textSecondary : palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
