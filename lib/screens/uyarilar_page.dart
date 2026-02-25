import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/hive_database_service.dart';
import '../services/local_notification_service.dart';
import '../utils/timeago_helper.dart';
import '../widgets/common_header_widgets.dart';
import 'test_notifications_page.dart';

/// Uyarılar/Bildirimler Sayfası
class UyarilarPage extends StatefulWidget {
  final String? userEmail;

  const UyarilarPage({super.key, this.userEmail});

  @override
  State<UyarilarPage> createState() => _UyarilarPageState();
}

class _UyarilarPageState extends State<UyarilarPage> {
  List<Map<String, dynamic>> _bildirimler = [];
  List<Map<String, dynamic>> _yerelBildirimler = [];
  String _aktifTab = 'hive'; // 'hive' veya 'yerel'

  @override
  void initState() {
    super.initState();
    _loadBildirimler();
  }

  void _loadBildirimler() {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return;
    }
    
    setState(() {
      // Hive bildirimleri
      _bildirimler = HiveDatabaseService.getBildirimler(widget.userEmail!);
      
      // Yerel bildirimler (LocalNotificationService)
      _yerelBildirimler = LocalNotificationService.getAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OneFriendPhoneBellMenu(
                userEmail: widget.userEmail,
                isBildirimlerPage: true, // Adım 1: Bildirimler sayfasında olduğumuzu belirt
              ),
            ),
            
            // Başlık ve Tab Seçimi
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        MdiIcons.bell,
                        size: 28,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'UYARILAR',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                  const Spacer(),
                  // Test butonu
                  IconButton(
                    icon: Icon(
                      MdiIcons.testTube,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    tooltip: 'Test Sayfası',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TestNotificationsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Toplam bildirim sayısı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_bildirimler.length + _yerelBildirimler.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tab Seçimi
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _aktifTab = 'hive';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _aktifTab == 'hive' 
                                  ? Colors.orange.shade700 
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Hive Bildirimleri (${_bildirimler.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _aktifTab == 'hive' 
                                      ? Colors.white 
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _aktifTab = 'yerel';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _aktifTab == 'yerel' 
                                  ? Colors.blue.shade700 
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Yerel Bildirimler (${_yerelBildirimler.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _aktifTab == 'yerel' 
                                      ? Colors.white 
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bildirimler Listesi
            Expanded(
              child: _aktifTab == 'hive'
                  ? _bildirimler.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                MdiIcons.bellOff,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz Hive uyarısı yok',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
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
                              final bildirim = _bildirimler[index];
                              return _buildBildirimCard(bildirim);
                            },
                          ),
                        )
                  : _yerelBildirimler.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                MdiIcons.bellOff,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz yerel bildirim yok',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
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
                              final bildirim = _yerelBildirimler[index];
                              return _buildYerelBildirimCard(bildirim);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBildirimCard(Map<String, dynamic> bildirim) {
    final uyariMesaji = bildirim['uyariMesaji'] as String? ?? '';
    final olusturmaTarihiStr = bildirim['olusturmaTarihi'] as String?;
    
    // Timeago ile tarih formatlama
    String tarihText = '';
    if (olusturmaTarihiStr != null) {
      tarihText = TimeAgoHelper.formatFromString(olusturmaTarihiStr);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.orange.shade200,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarih ve Sil butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tarihText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () async {
                      final bildirimId = bildirim['id'] as String?;
                      if (bildirimId != null && widget.userEmail != null) {
                        await HiveDatabaseService.deleteBildirim(
                          widget.userEmail!,
                          bildirimId,
                        );
                        _loadBildirimler();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Uyarı mesajı
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  uyariMesaji,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Dava bilgileri
              Row(
                children: [
                  Icon(
                    Icons.gavel,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bildirim['davaAdi'] as String? ?? 'Bilinmeyen Dava',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
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

  /// Yerel bildirim kartı widget'ı
  Widget _buildYerelBildirimCard(Map<String, dynamic> bildirim) {
    final title = bildirim['title'] as String? ?? '';
    final body = bildirim['body'] as String? ?? '';
    final timestampStr = bildirim['timestamp'] as String?;
    final isRead = bildirim['isRead'] as bool? ?? false;
    final notificationId = bildirim['id'] as int? ?? 0;
    final channelId = bildirim['channelId'] as String? ?? '';
    
    // Timeago ile tarih formatlama
    String tarihText = '';
    if (timestampStr != null) {
      tarihText = TimeAgoHelper.formatFromString(timestampStr);
    }

    // Kanal rengi belirleme
    Color kanalRengi = Colors.blue.shade700;
    IconData kanalIcon = MdiIcons.bell;
    
    if (channelId == 'mesaj_bildirimleri') {
      kanalRengi = Colors.green.shade700;
      kanalIcon = MdiIcons.message;
    } else if (channelId == 'dava_bildirimleri') {
      kanalRengi = Colors.orange.shade700;
      kanalIcon = MdiIcons.gavel;
    } else if (channelId == 'uyari_bildirimleri') {
      kanalRengi = Colors.blue.shade700;
      kanalIcon = MdiIcons.alert;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: kanalRengi.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kanalRengi.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarih, Okundu durumu ve Sil butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tarihText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
                  Row(
                    children: [
                      if (!isRead)
                        IconButton(
                          icon: Icon(
                            Icons.mark_email_read,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          tooltip: 'Okundu olarak işaretle',
                          onPressed: () async {
                            await LocalNotificationService.markAsRead(notificationId);
                            _loadBildirimler();
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () async {
                          await LocalNotificationService.deleteNotification(notificationId);
                          _loadBildirimler();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Kanal bilgisi
              Row(
                children: [
                  Icon(
                    kanalIcon,
                    size: 16,
                    color: kanalRengi,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    channelId.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kanalRengi,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Başlık
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isRead ? Colors.grey.shade700 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // İçerik
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kanalRengi.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isRead ? Colors.grey.shade600 : Colors.black87,
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

