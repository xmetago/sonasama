import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'dart:convert';
import '../screens/home_page.dart';
import '../screens/chat_page.dart';
import '../screens/chat_detail_page.dart';
import '../screens/user_gamified_score_page.dart';
import '../screens/friendship_management_page.dart';
import '../screens/davetler_page.dart';
import '../screens/uyarilar_page.dart';
import '../services/durtme_service.dart';
import '../services/hive_database_service.dart';
import '../services/local_notification_service.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/durt_wheel_sheet.dart';
import '../widgets/timed_action_buttons.dart';
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          const SizedBox(width: 90),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final SeyirPalette palette = SeyirPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(19, 0, 24.0, 0),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: palette.textPrimary),
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
  ActiveDurtmeOnProfile? _activeDurtmeOnProfile;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadActiveDurtmeOnProfile();
  }

  @override
  void didUpdateWidget(
    covariant SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userEmail != widget.userEmail ||
        oldWidget.targetUserEmail != widget.targetUserEmail) {
      _loadProfileImage();
      setState(_loadActiveDurtmeOnProfile);
    }
  }

  void _loadActiveDurtmeOnProfile() {
    final profileEmail = widget.targetUserEmail ?? widget.userEmail;
    if (profileEmail == null || profileEmail.isEmpty) {
      _activeDurtmeOnProfile = null;
      return;
    }

    _activeDurtmeOnProfile = DurtmeService.getActiveDurtmeForProfile(
      profileEmail: profileEmail,
    );
  }

  bool _isKotuKelime(String kelime) {
    return kelime.trim().toLowerCase() == 'kötü';
  }

  void _showDurtmeSenderName(String senderName) {
    final name = senderName.trim().isEmpty ? 'Bilinmeyen' : senderName.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dürten: $name'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildActiveDurtmeKelimeLabel(ActiveDurtmeOnProfile info) {
    final label = DurtmeService.formatKelimeLabel(info.kelime);
    final isKotu = _isKotuKelime(info.kelime);
    final senderName =
        info.senderName.trim().isEmpty ? 'Bilinmeyen' : info.senderName.trim();

    final text = Text(
      label,
      style: SeyirPalette.of(context).caption(
        weight: FontWeight.w800,
        color: SeyirPalette.of(context).foreground(
          isKotu ? SeyirTokens.reject : SeyirTokens.warning,
        ),
      ),
    );

    return Tooltip(
      message: senderName,
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 150),
      showDuration: const Duration(seconds: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDurtmeSenderName(senderName),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: text,
          ),
        ),
      ),
    );
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

  bool get _isOwnProfile {
    final String? target = widget.targetUserEmail?.trim().toLowerCase();
    final String? mine = widget.userEmail?.trim().toLowerCase();
    if (target == null || target.isEmpty) return true;
    return mine != null && mine == target;
  }

  void _openPuanKarti({required bool readOnly}) {
    final String? email = widget.targetUserEmail ?? widget.userEmail;
    if (email == null || email.isEmpty) return;
    final user = HiveDatabaseService.getRegistrationByEmail(email);
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserGamifiedScorePage(
          targetUser: user,
          readOnly: readOnly,
        ),
      ),
    );
  }

  Widget _buildProfileActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool emphasized = true,
  }) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color color =
        emphasized ? palette.textPrimary : palette.textSecondary;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: palette.caption(color: color, weight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space3),
        minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
        tapTargetSize: MaterialTapTargetSize.padded,
        foregroundColor: color,
        side: BorderSide(color: palette.border),
        shape: const RoundedRectangleBorder(
          borderRadius: SeyirTokens.radiusLgAll,
        ),
      ),
    );
  }

  void _showDurtmeAlani(
    BuildContext context, {
    required String targetJudgeName,
    required String targetUserId,
    required String targetUserEmail,
    required String senderEmail,
    required bool isSelfDurtme,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DurtWheelSheet(
          subtitle: isSelfDurtme
              ? '...'
              : '$targetJudgeName\'e hızlı tepki gönder',
          onClose: () => Navigator.pop(sheetContext),
          onSend: (kelime) => _onDurtmeKelimeSelected(
            sheetContext,
            kelime: kelime,
            targetJudgeName: targetJudgeName,
            targetUserId: targetUserId,
            targetUserEmail: targetUserEmail,
            senderEmail: senderEmail,
            isSelfDurtme: isSelfDurtme,
          ),
        );
      },
    );
  }

  Future<void> _onDurtmeKelimeSelected(
    BuildContext sheetContext, {
    required String kelime,
    required String targetJudgeName,
    required String targetUserId,
    required String targetUserEmail,
    required String senderEmail,
    required bool isSelfDurtme,
  }) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.maybeOf(sheetContext);

    final result = await DurtmeService.sendDurtme(
      senderEmail: senderEmail,
      receiverId: targetUserId,
      receiverEmail: targetUserEmail,
      kelime: kelime,
    );

    if (!sheetContext.mounted) return;
    Navigator.of(sheetContext).pop();

    if (messenger == null) return;

    switch (result.result) {
      case DurtmeSendResult.success:
        if (mounted) {
          setState(_loadActiveDurtmeOnProfile);
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSelfDurtme
                  ? 'Kendine "$kelime" dürtmesi gönderildi'
                  : '$targetJudgeName\'e "$kelime" dürtmesi gönderildi',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      case DurtmeSendResult.cooldown:
        final message = result.remaining != null && result.reason != null
            ? DurtmeService.cooldownMessage(
                reason: result.reason!,
                remaining: result.remaining!,
              )
            : 'Tekrar dürtmek için 19 sa bekleyin';
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case DurtmeSendResult.noSession:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Oturum bulunamadı, dürtme gönderilemedi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case DurtmeSendResult.error:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Dürtme gönderilemedi, lütfen tekrar deneyin'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
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
            onTap: targetUser != null
                ? () => _openPuanKarti(readOnly: !_isOwnProfile)
                : null,
            child: CircleAvatar( //PROFİL RESMİ ALANI //rengini değiştir
              radius: 30,
              backgroundColor: SeyirPalette.of(context).surfaceMuted,
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
                  : Icon(
                      Icons.account_circle,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _isOwnProfile && targetUser != null
                      ? () => _openPuanKarti(readOnly: false)
                      : null,
                  child: Text(
                    judgeName,
                    style: SeyirPalette.of(context).title(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (targetUserId != null &&
                    targetUserEmail != null &&
                    widget.userEmail != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (isTargetUser) ...[
                        _buildProfileActionChip(
                          icon: Icons.chat_bubble_outline,
                          label: 'Sohbet',
                          emphasized: true,
                          onPressed: () {
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
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildProfileActionChip(
                        icon: Icons.waving_hand,
                        label: 'Dürt',
                        emphasized: true,
                        onPressed: () {
                          _showDurtmeAlani(
                            context,
                            targetJudgeName: judgeName,
                            targetUserId: targetUserId,
                            targetUserEmail: targetUserEmail,
                            senderEmail: widget.userEmail!,
                            isSelfDurtme: !isTargetUser,
                          );
                        },
                      ),
                      if (_activeDurtmeOnProfile != null) ...[
                        const SizedBox(width: 8),
                        _buildActiveDurtmeKelimeLabel(_activeDurtmeOnProfile!),
                      ],
                    ],
                  ),
                ],
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

/// Collapsed (tek satır) üst başlık satırı — [DavaAcPage] ile aynı düzen.
class CollapsedWbHeaderRow extends StatelessWidget {
  final String title;
  final VoidCallback onExpandHeader;
  final VoidCallback onToggleLeftNav;
  final TextStyle? titleStyle;

  const CollapsedWbHeaderRow({
    super.key,
    required this.title,
    required this.onExpandHeader,
    required this.onToggleLeftNav,
    this.titleStyle,
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
            icon: Icon(Icons.search, size: 16, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          Icon(MdiIcons.chatOutline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggleLeftNav,
            child: Icon(MdiIcons.menuOpen, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: titleStyle ??
                  TextStyle(
                    fontSize: SeyirTokens.typeCaption,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: onExpandHeader,
            tooltip: 'Arayüzü Aç',
          ),
        ],
      ),
    );
  }
}
