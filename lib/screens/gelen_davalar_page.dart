import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/profile_icons_row.dart';
import 'category_page.dart';
import 'gelen_davalar_kactane.dart';
import 'yargila_page.dart';
import 'katildigim_davalar_page.dart';
import 'actigim_davalar_page.dart';
import '../widgets/energy_bar.dart';

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

class GelenDavalarPage extends StatelessWidget {
  const GelenDavalarPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for Dava instances
    final List<Dava> davaList = [
      Dava(
        adi: "Şeytanın Hileleri",
        davali: "Edip Yüksel",
        mevkii: "Davalı Avukatı",
        kalanSure: "27.03.1984",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
      ),
      Dava(
        adi: "Kayıp Kitaplar",
        davali: "Ali Veli",
        mevkii: "Temyiz Hakimi",
        kalanSure: "5 gün",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
      ),
      Dava(
        adi: "Gizli Tanık",
        davali: "Mehmet Can",
        mevkii: "Savcı",
        kalanSure: "12 saat",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
      ),
      Dava(
        adi: "Büyük Yargı",
        davali: "Ayşe Demir",
        mevkii: "Davalı",
        kalanSure: "2 gün",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
      ),
      Dava(
        adi: "Son Karar",
        davali: "Fatma Yılmaz",
        mevkii: "Hakim Yardımcısı",
        kalanSure: "1 hafta",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
      ),
    ];

    return Scaffold(
      body: SafeArea(
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
                    onPressed: () {
                      print("Menu button pressed");
                    },
                  ),
                  const SizedBox(width: 38),
                  const MyCheckboxWidget(),
                ],
              ),
            ),
            // ROW 5: 6 Icon Solda, Sağda Text Yazma Alanı
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50,
                      child: FourLeftIcons(),
                    ),
                    Expanded(
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

class FourLeftIcons extends StatelessWidget {
  const FourLeftIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GelenDavalarPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
              child: Icon(
                MdiIcons.briefcaseArrowLeftRight,
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
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Image.asset(dava.profilResmi, width: 60, height: 50),
                      ),
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
                          const Text('Davalı :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(child: Text(dava.davali, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                const Spacer(),
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const YargilaPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              minimumSize: const Size(60, 30),
                            ),
                            child: const Text('KABUL'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              print("Red button pressed for ${dava.adi}");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              minimumSize: const Size(60, 30),
                            ),
                            child: const Text('RED'),
                          ),
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

class MyCheckboxWidget extends StatefulWidget {
  const MyCheckboxWidget({super.key});

  @override
  State<MyCheckboxWidget> createState() => _MyCheckboxWidgetState();
}

class _MyCheckboxWidgetState extends State<MyCheckboxWidget> {
  bool isChecked = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 38),
        const Text(
          'GELEN DAVALAR',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
        ),
        const SizedBox(width: 19),
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GelenDavalarKactanePage(),
                  ),
                );
              },
              child:  Icon(
                MdiIcons.briefcaseArrowLeftRightOutline
                ,
                size: 24,
                color: Colors.black54,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: const Text(
                  '19',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}