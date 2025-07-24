import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/profile_icons_row.dart';
import 'category_page.dart';
import 'gelen_davalar_page.dart';
import 'katildigim_davalar_page.dart';
import 'yargila_page.dart';
import 'actigim_davalar_page.dart';
import '../widgets/energy_bar.dart';
import 'davaci_unlulur_page.dart';
import 'trend_dava_page.dart';

// Model class for Dava
class Dava {
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;

  Dava({
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
  });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for two Dava instances
    final List<Dava> davaList = [
      Dava(
        adi: "Sample Case 1",
        davali: "John Doe",
        mevkii: "Istanbul",
        kalanSure: "2 days",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
      ),
      Dava(
        adi: "Sample Case 2",
        davali: "Jane Smith",
        mevkii: "Davalı Şahidi",
        kalanSure: "5 days",
        profilResmi: "lib/icons/03_haykir_ana_icon.png",
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
              ZeroWhoboomSearchMessage(),
              // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: OneFriendPhoneBellMenu(),
              ),
              // ROW 3: Profil Bölümü
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(),
              ),
              // ROW 4: Hamburger Iconu, Arama Çubuğu
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TreeMenuPageheadlines(),
              ),
              // ROW 5: 6 Icon Solda, Sağda Text Yazma Alanı (Scrollable with ListTile)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50, // Fixed width as in original code
                      child: FourLeftIcons(),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 900, // Adjust height to fit content or screen
                        child: ListView.builder(
                          itemCount: davaList.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: FiveCardCaseInformation(
                                dava: davaList[index],
                                onTap: () {
                                  print("Tapped on ${davaList[index].adi}");
                                },
                              ),
                            );
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
      ),
    );
  }
}

class ZeroWhoboomSearchMessage extends StatelessWidget {
  const ZeroWhoboomSearchMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  color: const Color(0xFF059669),
                ),
                child: Text(
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
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              print("Search button pressed");
            },
          ),
          Icon(
            MdiIcons.chatOutline,
            size: 24,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}

class OneFriendPhoneBellMenu extends StatelessWidget {
  const OneFriendPhoneBellMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: Icon(
                  MdiIcons.accountHeart,
                  size: 24,
                  color: Colors.black54,
                ),
              ),
              Flexible(
                child: Icon(
                  MdiIcons.phoneClassic,
                  size: 24,
                  color: Colors.black54,
                ),
              ),
              Flexible(
                child: Icon(
                  MdiIcons.bell,
                  size: 24,
                  color: Colors.black54,
                ),
              ),
              Flexible(
                child: Icon(
                  MdiIcons.menuOpen,
                  size: 24,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant extends StatelessWidget {
  const SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Icon(Icons.account_circle, size: 60),
          ],
        ),
        const SizedBox(width: 0.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nasrullah KESKİN',
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
              ),
              const ProfileIconsRow(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1.0),
              ),
              Row(
                children: [
                  const SizedBox(width: 1),
                  Icon(
                    MdiIcons.pictureInPictureTopRight,
                    size: 24,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 48),
                  Icon(
                    Icons.record_voice_over_sharp,
                    color: Colors.black54,
                    size: 24,
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
              onPressed: () {
                print("Haykir button pressed");
              },
            ),
          ],
        ),
      ],
    );
  }
}

class TreeMenuPageheadlines extends StatelessWidget {
  const TreeMenuPageheadlines({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Image.asset(
            'lib/icons/menu_red.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            print("Menu button pressed");
          },
        ),
        const Expanded(
          child: Center(
            child: Text(
              "SEYİR DEFTERİ",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class FourLeftIcons extends StatelessWidget {
  const FourLeftIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50, // Fixed width as in original code
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GelenDavalarPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
              child: Icon(
                MdiIcons.briefcaseArrowLeftRight,
                size: 24,
                color: Colors.black54,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const YargilaPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
              child: Image.asset('lib/icons/06_yargila_left_row_icon.png', width: 24, height: 24),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KatildigimDavalarPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
              child: Image.asset('lib/icons/06_left_row_katildigim_davalar_icon.png', width: 24, height: 24),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActigimDavalarPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
              child: Image.asset('lib/icons/06_left_row_actigim_davalar_icon.png', width: 24, height: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DavaciUnlulurPage(),
                  ),
                );
              },
              child: Image.asset('lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png', width: 24, height: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DavaciUnlulurPage(),
                  ),
                );
              },
              child: Image.asset('lib/icons/06_left_row_haykirislarim.png', width: 24, height: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrendDavaPage(),
                  ),
                );
              },
              child: Icon(
                MdiIcons.trendingUp,
                size: 24,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FiveCardCaseInformation extends StatelessWidget {
  final Dava dava;
  final VoidCallback? onTap;

  const FiveCardCaseInformation({super.key, required this.dava, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            MdiIcons.homeFlood,
                            size: 19,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Onayla',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Image.asset(dava.profilResmi, width: 60, height: 50),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            MdiIcons.giftOpen,
                            size: 19,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Onayla',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Dava Adı    :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Flexible(child: Text(dava.adi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Davalı         :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(child: Text(dava.davali, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                const Spacer(),
                                Icon(Icons.thumb_down_alt_outlined, size: 25, color: Colors.red),
                                Icon(Icons.thumb_up_alt_outlined, size: 25, color: Colors.green),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Görev        :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Flexible(child: Text(dava.mevkii, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(MdiIcons.timerAlertOutline, size: 19, color: Colors.green),
                          const SizedBox(width: 4),
                          const Text('Kalan Süre :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              dava.kalanSure,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Hükmüm  :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(Icons.insert_emoticon, size: 24, color: Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}