import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:convert';
import '../screens/home_page.dart';
import '../screens/chat_page.dart';
import '../screens/chat_detail_page.dart';
import '../screens/friendship_management_page.dart';
import '../screens/davetler_page.dart';
import '../screens/uyarilar_page.dart';
import '../screens/album_olustur_page.dart';
import '../services/hive_database_service.dart';
import '../services/local_notification_service.dart';
import '../widgets/timed_action_buttons.dart';
import '../widgets/profile_icons_row.dart';
import '../widgets/verified_users_management_dialog.dart';

// WhoBoom, Arama Iconu, Chat Iconu
class ZeroWhoboomSearchMessage extends StatelessWidget {
  final String? userEmail; // Kullanıcı e-posta adresi parametresi eklendi
  
  const ZeroWhoboomSearchMessage({super.key, this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Adım 1: Vertical padding azaltıldı (8.0 -> 4.0)
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(userEmail: userEmail), // userEmail geçirildi
                  ),
                );
              },
              onLongPress: () {
                // Geliştiriciye özel gizli buton: WhoBoom logosuna uzun basınca verified users yönetimi açılır
                showDialog(
                  context: context,
                  builder: (context) => const VerifiedUsersManagementDialog(),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      color: Color(0xFF059669),
                    ),
                    child: const Text(
                      'Who',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Boom',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(userEmail: userEmail),
                ),
              );
            },
            child: Icon(
              MdiIcons.chatOutline,
              size: 24,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
class OneFriendPhoneBellMenu extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi
  final bool isBildirimlerPage; // Adım 1: Bildirimler sayfasında mı? (bildirim ikonu turuncu ve büyük olacak)

  const OneFriendPhoneBellMenu({super.key, this.userEmail, this.isBildirimlerPage = false});

  @override
  State<OneFriendPhoneBellMenu> createState() => _OneFriendPhoneBellMenuState();
}

class _OneFriendPhoneBellMenuState extends State<OneFriendPhoneBellMenu> {
  int _bildirimSayisi = 0;
  int _yerelBildirimSayisi = 0;
  bool _menuAcik = false; // Adım 1: Menü açık/kapalı durumu

  @override
  void initState() {
    super.initState();
    _bildirimSayisiniYukle();
  }

  void _bildirimSayisiniYukle() {
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      // Hive'dan gelen bildirimler
      final bildirimler = HiveDatabaseService.getBildirimler(widget.userEmail!);
      
      // LocalNotificationService'den gelen bildirimler (okunmamış)
      final yerelBildirimler = LocalNotificationService.getAllNotifications();
      final okunmamisYerelBildirimler = yerelBildirimler.where((n) => n['isRead'] != true).toList();
      
      if (mounted) {
        setState(() {
          _bildirimSayisi = bildirimler.length;
          _yerelBildirimSayisi = okunmamisYerelBildirimler.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bildirim sayısını güncelle (her build'de kontrol et)
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      final bildirimler = HiveDatabaseService.getBildirimler(widget.userEmail!);
      final yerelBildirimler = LocalNotificationService.getAllNotifications();
      final okunmamisYerelBildirimler = yerelBildirimler.where((n) => n['isRead'] != true).toList();
      
      final toplamBildirimSayisi = bildirimler.length + okunmamisYerelBildirimler.length;
      final mevcutToplam = _bildirimSayisi + _yerelBildirimSayisi;
      
      if (toplamBildirimSayisi != mevcutToplam) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _bildirimSayisi = bildirimler.length;
              _yerelBildirimSayisi = okunmamisYerelBildirimler.length;
            });
          }
        });
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Adım 2: Vertical padding azaltıldı (8.0 -> 4.0)
      child: Row(
        children: [
          // Solda biraz boşluk bırak
          const SizedBox(width: 24),
          // Adım 2: Solundaki ikonları aç-kapa için - menü kapalıyken yer kaplamaz, açıkken eski konumlarında görünür
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _menuAcik ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_menuAcik,
                  child: _menuAcik ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Arkadaş ikonu
                      _buildIconButton(
                        icon: MdiIcons.accountHeart,
                        badgeCount: null,
                        onTap: () {
                          if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FriendshipManagementPage(userEmail: widget.userEmail!),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kullanıcı bilgisi bulunamadı. Lütfen giriş yapın.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8), // İkonlar arası mesafe
                      // Telefon ikonu
                      _buildIconButton(
                        icon: MdiIcons.phoneClassic,
                        badgeCount: _yerelBildirimSayisi > 0 ? _yerelBildirimSayisi : null,
                        badgeColor: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DavetlerPage(userEmail: widget.userEmail),
                            ),
                          ).then((_) {
                            _bildirimSayisiniYukle();
                          });
                        },
                      ),
                      const SizedBox(width: 8), // İkonlar arası mesafe
                      // Bildirim ikonu - Adım 2: Bildirimler sayfasındaysa turuncu ve büyük
                      widget.isBildirimlerPage
                          ? GestureDetector(
                              onTap: () {
                                // Bildirimler sayfasındayken tıklama işlemi yok (zaten bu sayfadayız)
                              },
                              child: Icon(
                                MdiIcons.bell,
                                size: 28,
                                color: Colors.orange.shade700,
                              ),
                            )
                          : _buildIconButton(
                              icon: MdiIcons.bell,
                              badgeCount: _bildirimSayisi > 0 ? _bildirimSayisi : null,
                              badgeColor: Colors.red,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UyarilarPage(userEmail: widget.userEmail),
                                  ),
                                ).then((_) {
                                  _bildirimSayisiniYukle();
                                });
                              },
                            ),
                    ],
                  ) : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Adım 1 & 3: Menü ikonu - tıklanınca aç-kapa yapar (ikon her zaman aynı kalır)
          GestureDetector(
            onTap: () {
              setState(() {
                _menuAcik = !_menuAcik;
              });
            },
            child: Icon(
              MdiIcons.menuOpen, // Menü ikonu her zaman aynı kalır
              size: 24,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Helper metod: İkon butonu oluşturur
  Widget _buildIconButton({
    required IconData icon,
    required int? badgeCount,
    Color badgeColor = Colors.red,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(19, 0, 24.0, 0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: Colors.black87),
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Profil Bölümü
class SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant extends StatefulWidget {
  final VoidCallback? onDavalaPressed;
  final VoidCallback? onHaykirPressed;
  final String? userEmail; // Kullanıcı e-postası eklendi
  final String? targetUserEmail; // Adım 1: Başka bir kullanıcının profilini göstermek için (opsiyonel)
  final Function(String)? onDateUpdate;
  final VoidCallback? onShowSavedDavalar; // Kaydedilen davalar dialog'u için callback

  const SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant({
    super.key,
    this.onDavalaPressed,
    this.onHaykirPressed,
    this.userEmail,
    this.targetUserEmail, // Adım 1: Başka bir kullanıcının profilini göstermek için
    this.onDateUpdate,
    this.onShowSavedDavalar, // Kaydedilen davalar dialog'u için callback
  });

  @override
  State<SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant> createState() => _SecondProfileJudgenameIconknifeEnergyPicturePokeSueChantState();
}

class _SecondProfileJudgenameIconknifeEnergyPicturePokeSueChantState extends State<SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant> {
  String? _profileImageUrl; // Profil resmi URL'si

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Profil resmini Hive'dan yükle
  void _loadProfileImage() {
    // Adım 1: targetUserEmail varsa onu kullan, yoksa userEmail'i kullan
    final emailToUse = widget.targetUserEmail ?? widget.userEmail;
    if (emailToUse != null && emailToUse.isNotEmpty) {
      final settings = HiveDatabaseService.getSettings(emailToUse);
      final profileImageUrl = settings?.profileImageUrl;
      // initState içinde mounted kontrolü gereksiz, direkt setState yapabiliriz
      setState(() {
        _profileImageUrl = profileImageUrl;
      });
    }
  }

  // Profil resmi için ImageProvider döndür (base64 veya network)
  ImageProvider<Object>? _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) return null;
    
    // Base64 string kontrolü (data:image/jpeg;base64,... formatı)
    if (imageUrl.startsWith('data:image')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length < 2) return null;
        final base64String = parts[1];
        final bytes = base64Decode(base64String);
        if (bytes.isEmpty) return null;
        return MemoryImage(bytes) as ImageProvider<Object>;
      } catch (e) {
        // Base64 decode hatası durumunda null döndür
        print('⚠️ Base64 decode hatası: $e');
        return null;
      }
    }
    
    // Network URL kontrolü
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl) as ImageProvider<Object>;
    }
    
    // Geçersiz format
    return null;
  }

  @override
  void didUpdateWidget(SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant oldWidget) {
    super.didUpdateWidget(oldWidget);
    // userEmail veya targetUserEmail değiştiğinde profil resmini yeniden yükle
    if (oldWidget.userEmail != widget.userEmail || oldWidget.targetUserEmail != widget.targetUserEmail) {
      _loadProfileImage();
    }
  }

  // Modern uyarı gösterme fonksiyonu
  void _showModernAlert({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon ve başlık
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                
                // Mesaj
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                
                // Buton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bu fonksiyon artık gerekli değil, TimedActionButtons widget'ı kendi uyarılarını gösteriyor

  // Bu fonksiyonlar artık gerekli değil, TimedActionButtons widget'ı kendi kontrolünü yapıyor

  // Dürtme alanı (SEYİR DEFTERİ) dialog'unu göster
  void _showDurtmeAlani(BuildContext context) {
    // Her kelime için ikon, renk ve font bilgileri
    final List<Map<String, dynamic>> kelimeData = [
      {
        'kelime': 'İyi',
        'icon': Icons.thumb_up,
        'color': Colors.green,
        'fontWeight': FontWeight.w600,
      },
      {
        'kelime': 'Kötü',
        'icon': Icons.thumb_down,
        'color': Colors.red,
        'fontWeight': FontWeight.w700,
      },
      {
        'kelime': 'Çirkin',
        'icon': Icons.sentiment_very_dissatisfied,
        'color': Colors.brown,
        'fontWeight': FontWeight.w500,
      },
      {
        'kelime': 'Özel',
        'icon': Icons.star,
        'color': Colors.amber,
        'fontWeight': FontWeight.w600,
      },
      {
        'kelime': 'Güzel',
        'icon': Icons.favorite,
        'color': Colors.pink,
        'fontWeight': FontWeight.w600,
      },
      {
        'kelime': 'Fena',
        'icon': Icons.warning,
        'color': Colors.orange,
        'fontWeight': FontWeight.w700,
      },
      {
        'kelime': 'Hoş',
        'icon': Icons.mood,
        'color': Colors.lightBlue,
        'fontWeight': FontWeight.w500,
      },
      {
        'kelime': 'Yakışıklı',
        'icon': Icons.face,
        'color': Colors.blue,
        'fontWeight': FontWeight.w600,
      },
      {
        'kelime': 'Boş ver',
        'icon': Icons.block,
        'color': Colors.grey,
        'fontWeight': FontWeight.w500,
      },
      {
        'kelime': 'İmkansız',
        'icon': Icons.cancel,
        'color': Colors.redAccent,
        'fontWeight': FontWeight.w700,
      },
      {
        'kelime': 'Aptal',
        'icon': Icons.sentiment_dissatisfied,
        'color': Colors.deepOrange,
        'fontWeight': FontWeight.w600,
      },
      {
        'kelime': 'Çılgın',
        'icon': Icons.bolt,
        'color': Colors.purple,
        'fontWeight': FontWeight.w700,
      },
      {
        'kelime': 'Deli',
        'icon': Icons.psychology,
        'color': Colors.indigo,
        'fontWeight': FontWeight.w600,
      },
      {
        'kelime': 'Olmaz',
        'icon': Icons.close,
        'color': Colors.red,
        'fontWeight': FontWeight.w700,
      },
      {
        'kelime': 'Belki',
        'icon': Icons.help_outline,
        'color': Colors.teal,
        'fontWeight': FontWeight.w500,
      },
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey[50]!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Modern başlık çubuğu (gradyan arka plan)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber[100]!,
                                  Colors.amber[50]!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Sol tarafta üç kırmızı çizgi (animasyonlu)
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 600),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Row(
                                        children: List.generate(3, (index) => Container(
                                          margin: const EdgeInsets.only(right: 3),
                                          width: 5,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.red[400]!,
                                                Colors.red[600]!,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.5),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        )),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                // Başlık yazısı
                                Expanded(
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 500),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 10 * (1 - value)),
                                          child: const Text(
                                            'Seni Dürtüyorum',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              letterSpacing: 1.2,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Sağ tarafta animasyonlu speaker ikonu
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 800),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[100],
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.amber.withOpacity(0.4),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.record_voice_over_sharp,
                                          color: Colors.amber[800],
                                          size: 22,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Modern kelimeler grid'i
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green[50]!,
                                    Colors.lightGreen[50]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green[200]!,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Sol üstte animasyonlu kalem ikonu
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 1000),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Positioned(
                                        left: -10,
                                        top: -10,
                                        child: Transform.rotate(
                                          angle: -0.3 * value,
                                          child: Transform.scale(
                                            scale: value,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blue[400]!,
                                                    Colors.blue[600]!,
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue.withOpacity(0.4),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Kelimeler grid'i (3 sütun)
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 2.1,
                                    ),
                                    itemCount: kelimeData.length,
                                    itemBuilder: (context, index) {
                                      final data = kelimeData[index];
                                      return TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 300 + (index * 50)),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        curve: Curves.easeOutBack,
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: Opacity(
                                              opacity: value,
                                              child: _ModernKelimeKart(
                                                kelime: data['kelime'] as String,
                                                icon: data['icon'] as IconData,
                                                color: data['color'] as Color,
                                                fontWeight: data['fontWeight'] as FontWeight,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Modern kapat butonu
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.grey[200]!,
                                            Colors.grey[300]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            child: const Text(
                                              'Kapat',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                                letterSpacing: 1,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adım 1: targetUserEmail varsa onu kullan, yoksa userEmail'i kullan
    final emailToUse = widget.targetUserEmail ?? widget.userEmail;
    
    // Her build'de profil resmini kontrol et (güncellemeler için)
    // İlk açılışta profil resmi yüklenmemişse hemen yükle
    String? displayProfileImageUrl = _profileImageUrl;
    if (emailToUse != null && emailToUse.isNotEmpty) {
      final settings = HiveDatabaseService.getSettings(emailToUse);
      final currentProfileImageUrl = settings?.profileImageUrl;
      
      // Eğer profil resmi yüklenmemişse veya değişmişse güncelle
      // İlk açılışta hemen yükle (postFrameCallback gecikme yaratır)
      if (_profileImageUrl != currentProfileImageUrl) {
        // build içinde direkt kullan (setState gereksiz, zaten rebuild olacak)
        displayProfileImageUrl = currentProfileImageUrl;
        // State'i de güncelle (sonraki build'ler için)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _profileImageUrl != currentProfileImageUrl) {
            setState(() {
              _profileImageUrl = currentProfileImageUrl;
            });
          }
        });
      }
    }

    // Kullanıcı bilgilerini al
    final targetUser = emailToUse != null 
        ? HiveDatabaseService.getRegistrationByEmail(emailToUse)
        : null;
    final judgeName = targetUser?.judgeName ?? 'Bilinmeyen Yargıç';
    final targetUserId = targetUser?.id;
    final targetUserEmail = emailToUse;
    final targetUserAvatarUrl = displayProfileImageUrl;

    // Adım 2 ve 3: CircleAvatar ve kullanıcı adına tıklama özellikleri
    final bool isTargetUser = widget.targetUserEmail != null; // Başka bir kullanıcının profili mi?

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Adım 3: Vertical padding azaltıldı (8.0 -> 4.0)
      child: Row(//PROFİL RESMİ ALANI
        children: [
          // Adım 2: CircleAvatar'a GestureDetector ekle - profil resmine tıklanınca profil sayfasına git
          GestureDetector(
            onTap: isTargetUser && targetUserEmail != null
                ? () {
                    // Başka bir kullanıcının profil sayfasına git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(userEmail: targetUserEmail),
                      ),
                    );
                  }
                : null, // Kendi profilini gösteriyorsa tıklama yok
            child: CircleAvatar( //PROFİL RESMİ ALANI //rengini değiştir
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: displayProfileImageUrl != null && displayProfileImageUrl.isNotEmpty
                  ? _getImageProvider(displayProfileImageUrl)
                  : null,
              onBackgroundImageError: displayProfileImageUrl != null && displayProfileImageUrl.isNotEmpty
                  ? (exception, stackTrace) {
                      // Resim yüklenemezse varsayılan ikonu göster
                      if (mounted) {
                        setState(() {
                          _profileImageUrl = null;
                        });
                      }
                    }
                  : null,
              child: displayProfileImageUrl != null && displayProfileImageUrl.isNotEmpty
                  ? null
                  : const Icon(Icons.account_circle, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adım 3: Kullanıcı adına GestureDetector ekle - tıklanınca sohbet başlat
                GestureDetector(
                  onTap: isTargetUser && targetUserId != null && targetUserEmail != null && widget.userEmail != null
                      ? () {
                          // Başka bir kullanıcıyla sohbet başlat
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailPage(
                                receiverId: targetUserId,
                                receiverEmail: targetUserEmail,
                                receiverName: judgeName,
                                receiverAvatarUrl: targetUserAvatarUrl,
                                userEmail: widget.userEmail,
                              ),
                            ),
                          );
                        }
                      : null, // Kendi profilini gösteriyorsa tıklama yok
                  child: Text(
                    judgeName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                      decoration: isTargetUser ? TextDecoration.underline : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const ProfileIconsRow(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // ✅ Step-5: Albüm oluşturma sayfasına git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumOlusturPage(
                              userEmail: widget.userEmail,
                            ),
                          ),
                        );
                      },
                      child: Icon(
                        MdiIcons.pictureInPictureTopRightOutline,
                        size: 24,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 38),
                    GestureDetector(
                      onTap: () {
                        _showDurtmeAlani(context);
                      },
                      child: const Icon(
                        Icons.record_voice_over_sharp,
                        color: Colors.black54,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Yeni TimedActionButtons widget'ı (sadece kendi profilinde göster)
          if (!isTargetUser)
            TimedActionButtons(
              userEmail: widget.userEmail,
              iconSize: 32,
              buttonSize: 40,
              onDateUpdate: widget.onDateUpdate,
              onShowSavedDavalar: widget.onShowSavedDavalar, // Kaydedilen davalar dialog'u için callback
            ),
        ],
      ),
    );
  }
}

// Modern kelime kartı widget'ı
class _ModernKelimeKart extends StatefulWidget {
  final String kelime;
  final IconData icon;
  final Color color;
  final FontWeight fontWeight;

  const _ModernKelimeKart({
    required this.kelime,
    required this.icon,
    required this.color,
    required this.fontWeight,
  });

  @override
  State<_ModernKelimeKart> createState() => _ModernKelimeKartState();
}

class _ModernKelimeKartState extends State<_ModernKelimeKart>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        // Haptic feedback
        // HapticFeedback.lightImpact();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                widget.color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: _isPressed ? 8 : 12,
                spreadRadius: _isPressed ? 1 : 2,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon container (gradyan arka plan)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.2),
                      widget.color.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              // Kelime metni
              Text(
                widget.kelime,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: widget.fontWeight,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsed (tek satır) üst başlık satırı — [DavaAcPage] ile aynı düzen.
class CollapsedWbHeaderRow extends StatelessWidget {
  final String title;
  final VoidCallback onExpandHeader;
  final VoidCallback onToggleLeftNav;

  const CollapsedWbHeaderRow({
    super.key,
    required this.title,
    required this.onExpandHeader,
    required this.onToggleLeftNav,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF059669), Colors.green],
                ),
              ),
              child: const Text(
                'WB',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.search, size: 16),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          Icon(MdiIcons.chatOutline, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggleLeftNav,
            child: Icon(MdiIcons.menuOpen, size: 16, color: Colors.black54),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.black,
            ),
            onPressed: onExpandHeader,
            tooltip: 'Arayüzü Aç',
          ),
        ],
      ),
    );
  }
}
