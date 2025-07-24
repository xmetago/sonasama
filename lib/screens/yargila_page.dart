import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/profile_icons_row.dart';
import 'category_page.dart';
import 'delilleri_incele_page.dart';
import 'masraflar_page.dart';
import 'cezalar_page.dart';
import 'sekiz_hukum_page.dart';

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

// Yargıla Sayfası
class YargilaPage extends StatefulWidget {
  const YargilaPage({super.key});

  @override
  State<YargilaPage> createState() => _YargilaPageState();
}

class _YargilaPageState extends State<YargilaPage> {
  int commentCount = 0;
  int retweetCount = 0;
  int likeCount = 0;
  int dislikeCount = 0;
  bool isHukumExpanded = false; // 8-HÜKÜM butonunun açık/kapalı durumu

  Widget _buildIconCounter(IconData icon, int count, VoidCallback onPressed) {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.green),
          onPressed: onPressed,
        ),
        Text('$count', style: const TextStyle(color: Colors.green)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sample data for Dava instances
    final List<Dava> davaList = [
      Dava(
        adi: "Şeytanın Hileleri",
        davali: "Edip Yüksel",
        mevkii: "Davalı Avukatı",
        kalanSure: "72 saat (3 gün)",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
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
                    const SizedBox(width: 68),
                    Center(child: Text("YARGILA ",style: TextStyle(fontSize: 19),),)
                  ],
                ),
              ),
              // Arama Row'u
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    const SizedBox(width: 50), // Sol ikonlar için boşluk
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Ara...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey[600]),
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
              // ROW 5: 6 Icon Solda, Sağda Card ile Dava Bilgileri
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
                            child: Icon(Icons.save_outlined, size: 24,  color: Colors.black54),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                            child: IconButton(
                              icon: Icon(Icons.content_paste_search, size: 24,  color: Colors.black54),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DelilleriIncelePage()),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                            child: IconButton(
                              icon: Icon(MdiIcons.briefcaseEditOutline, size: 24, color: Colors.black54),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CezalarPage()),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                            child: IconButton(
                              icon: Icon(MdiIcons.handcuffs, size: 24, color: Colors.black54),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CezalarPage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SizedBox(
                        height: 500,
                        child: ListView.builder(
                          itemCount: davaList.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: FiveCardCaseInformation(
                                    dava: davaList[index],
                                    onTap: () {
                                      setState(() {
                                        isHukumExpanded = !isHukumExpanded;
                                      });
                                    },
                                  ),
                                ),
                                // 8-HÜKÜM açılır metin alanı
                                if (isHukumExpanded)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Hüküm Detayları',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const TextField(
                                            maxLines: 3,
                                            decoration: InputDecoration(
                                              hintText: "Hüküm detaylarını buraya yazın...",
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Delilleri incele sayfasındaki ikonlar
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _buildIconCounter(Icons.mode_comment_outlined, commentCount, () {
                                                setState(() => commentCount++);
                                              }),
                                              _buildIconCounter(Icons.repeat, retweetCount, () {
                                                setState(() => retweetCount++);
                                              }),
                                              _buildIconCounter(Icons.favorite_border, likeCount, () {
                                                setState(() => likeCount++);
                                              }),
                                              _buildIconCounter(Icons.thumb_down_alt_outlined, dislikeCount, () {
                                                setState(() => dislikeCount++);
                                              }),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
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

// Reused Widgets from GelenDavalarPage
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
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 19,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Haklı... ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                            Icons.thumb_down_off_alt_outlined,
                            size: 19,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Haksız ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                                MaterialPageRoute(builder: (context) => const SekizHukumPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              minimumSize: const Size(60, 30),
                            ),
                              // 8- HÜKÜM BUTONU, herhangi bir davada CARD 8-hüküm BUTONU tıklanılırsa , ilgili davanın 8 hüküm sayfası açılır.
                            child: Text("8 HÜKÜM ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),

                          const SizedBox(width: 8),
                          /*ElevatedButton(
                            onPressed: () {
                              print("Red button pressed for \\${dava.adi}");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              minimumSize: const Size(60, 30),
                            ),
                            child: const Text('Haksız'),
                          ),*/
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