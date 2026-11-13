import 'package:flutter/material.dart';
import '../models/sekiz_hukum_arguments.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
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
  @override
  Widget build(BuildContext context) {
    final SekizHukumArguments? currentArgs = widget.arguments;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AppExpandableIconMenu(
          expandBody: true,
          inset: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          items: [
            AppExpandableIconMenuItem(
              onTap: () {},
              customChild: LeftNavigationColumn(userEmail: widget.userEmail),
            ),
          ],
          headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                    userEmail: widget.userEmail,
                    onShowSavedDavalar: () {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      menuButton,
                      const SizedBox(width: 38),
                      MyCheckboxWidget(),
                    ],
                  ),
                ),
              ],
            );
          },
          body: SingleChildScrollView(
            child: ModernHukumCard(
              userEmail: widget.userEmail,
              davaId: currentArgs?.davaId,
              openedAt: currentArgs?.openedAt,
              davaAdi: currentArgs?.davaAdi ?? 'Dava adı belirtilmedi',
              davaDavali: currentArgs?.davaDavali ?? 'Davalı bilgisi yok',
              davaDavaci: currentArgs?.davaDavaci ?? 'Davacı bilgisi yok',
              davaGorev: currentArgs?.davaGorev ?? 'Görev bilgisi yok',
              kalanSure: currentArgs?.kalanSure ?? 'Süre bilgisi yok',
            ),
          ),
        ),
      ),
    );
  }
}
