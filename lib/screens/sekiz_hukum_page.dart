import 'package:flutter/material.dart';
import '../models/sekiz_hukum_arguments.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/left_navigation_column.dart';
import '../widgets/modern_hukum_card.dart';

/// Modern 8 Hüküm Sayfası
/// 
/// Bu sayfa modern widget yapısıyla yeniden tasarlandı
class SekizHukumPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi
  final SekizHukumArguments? arguments; // Seçilen davaya ait veriler

  const SekizHukumPage({
    super.key,
    this.userEmail,
    this.arguments,
  });

  @override
  State<SekizHukumPage> createState() => _SekizHukumPageState();
}

class _SekizHukumPageState extends State<SekizHukumPage> {
  bool showLeftIcons = false;
  String? _lastSavedHukumText; // Son kaydedilen hüküm metni
  DateTime? _lastSavedHukumTime; // Son kaydedilen hüküm zamanı

  @override
  Widget build(BuildContext context) {
    final SekizHukumArguments? currentArgs = widget.arguments;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
            ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
            // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
            ),
            // ROW 3: Profil Bölümü
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                userEmail: widget.userEmail,
                onShowSavedDavalar: () {
                  // 8 Hüküm sayfasında kaydedilen davalar dialog'u açılamaz
                  // Bu sayfa sadece hüküm işlemleri için
                },
              ),
            ),
            // ROW 4: Hamburger Menü ve Başlık
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Image.asset(
                      'lib/icons/menu_red.png',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        showLeftIcons = !showLeftIcons;
                      });
                    },
                  ),
                  const SizedBox(width: 68),
                  const Center(
                    child: Text(
                      '8 HÜKÜM',
                      style: TextStyle(
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ROW 5: Sol ikonlar + Modern Card
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: showLeftIcons ? 60 : 0,
                    child: showLeftIcons
                        ? SingleChildScrollView(
                            child: LeftNavigationColumn(
                              userEmail: widget.userEmail,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: ModernHukumCard(
                        userEmail: widget.userEmail,
                        davaId: currentArgs?.davaId,
                        openedAt: currentArgs?.openedAt,
                        davaAdi: currentArgs?.davaAdi ?? 'Dava adı belirtilmedi',
                        davaDavali: currentArgs?.davaDavali ?? 'Davalı bilgisi yok',
                        davaDavaci: currentArgs?.davaDavaci ?? 'Davacı bilgisi yok',
                        davaGorev: currentArgs?.davaGorev ?? 'Görev bilgisi yok',
                        kalanSure: currentArgs?.kalanSure ?? 'Süre bilgisi yok',
                        onHukumSave: (hukumText) {
                          // Hüküm kaydedildiğinde state'i güncelle
                          // Bu sayede icon ve metne erişilebilir
                          if (hukumText != null && hukumText.isNotEmpty) {
                            setState(() {
                              _lastSavedHukumText = hukumText;
                              _lastSavedHukumTime = DateTime.now();
                            });

                            // Hüküm kaydedildiğinde konsensüs değerlendirmesini tetikle
                            // ModernHukumCard zaten bunu yapıyor, burada sadece state güncelleniyor
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}