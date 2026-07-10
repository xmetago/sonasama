import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/sekiz_hukum_arguments.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/left_navigation_column.dart';
import '../widgets/modern_hukum_card.dart';
import 'gelen_davalar_kactane.dart';

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

  @override
  Widget build(BuildContext context) {
    final SekizHukumArguments? currentArgs = widget.arguments;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
            ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
            // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
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
            // ROW 4: Hamburger Menü
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      MdiIcons.menuOpen,
                      size: 34,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        showLeftIcons = !showLeftIcons;
                      });
                    },
                  ),
                  const SizedBox(width: 38),
                  MyCheckboxWidget(),
                ],
              ),
            ),
            // ROW 5: Sol ikonlar + Modern Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
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
                          davaAdi:
                              currentArgs?.davaAdi ?? 'Dava adı belirtilmedi',
                          davaDavali:
                              currentArgs?.davaDavali ?? 'Davalı bilgisi yok',
                          davaDavaci:
                              currentArgs?.davaDavaci ?? 'Davacı bilgisi yok',
                          davaGorev:
                              currentArgs?.davaGorev ?? 'Görev bilgisi yok',
                          kalanSure:
                              currentArgs?.kalanSure ?? 'Süre bilgisi yok',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
