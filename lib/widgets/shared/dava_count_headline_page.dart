import 'package:flutter/material.dart';

import '../../screens/category_page.dart';
import '../profile_icons_row.dart';

/// Gelen ve katıldığım "kaç tane" sayfalarının ortak iskeleti.
/// Başlık satırı [headline] ile gelir; geri kalan piksel düzeni aynıdır.
class DavaCountHeadlinePage extends StatelessWidget {
  const DavaCountHeadlinePage({
    super.key,
    required this.iconCount,
    required this.headline,
  });

  final int iconCount;
  final Widget headline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Row(
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
                            fontSize: 19,
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
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
                ],
              ),
            ),
            // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(width: 21),
                  IconButton(icon: const Icon(Icons.home_rounded), onPressed: () {}),

                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(child: Image.asset('lib/icons/02_top_row_friends.png', width: 24, height: 24)),
                        Flexible(child: Image.asset('lib/icons/02_top_row_telefon_icon.png', width: 24, height: 24)),
                        Flexible(child: Image.asset('lib/icons/02_top_row_bildirim_icon.png', width: 24, height: 24)),
                        const Flexible(child: Icon(Icons.menu_open_rounded)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ROW 3: Profil Bölümü
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.account_circle, size: 60),
                    ],
                  ),
                  const SizedBox(width: 0.5),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YARGIÇ ADI', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        ProfileIconsRow(),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            SizedBox(width: 18),
                            Icon(
                              Icons.picture_in_picture,
                              color: Colors.lime,
                              size: 18,
                            ),
                            SizedBox(width: 38),
                            Icon(
                              Icons.record_voice_over_sharp,
                              color: Colors.lime,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          child: Image.asset(
                            'lib/icons/03_davala_ana_icon.png',
                            width: 38,
                            height: 38,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryPage(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          child: Image.asset(
                            'lib/icons/03_haykir_ana_icon.png',
                            width: 38,
                            height: 38,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ROW 4: Hamburger Iconu, Checkbox ve bilgi satırı
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
                    onPressed: () {},
                  ),
                  const SizedBox(width: 38),
                  headline,
                ],
              ),
            ),
            // ROW 5: 6 Icon Solda, Sağda Text Yazma Alanı ve detaylar
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          Image.asset('lib/icons/06_left_row_gelen_davalar_icon.png', width: 24, height: 24),
                          Image.asset('lib/icons/06_yargila_left_row_icon.png', width: 30, height: 30),
                          Image.asset('lib/icons/06_left_row_katildigim_davalar_icon.png', width: 24, height: 24),
                          Image.asset('lib/icons/06_left_row_actigim_davalar_icon.png', width: 24, height: 24),
                          Image.asset('lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png', width: 24, height: 24),
                          Image.asset('lib/icons/06_left_row_haykirislarim.png', width: 24, height: 24),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.grey[100],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                          child: Column(
                            children: [
                              GridView.count(
                                crossAxisCount: 5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: List.generate(iconCount, (index) => GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Icon #${index + 1} tıklandı')),
                                    );
                                  },
                                  child: const Icon(Icons.cases_outlined, size: 32),
                                )),
                              ),
                            ],
                          ),

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
