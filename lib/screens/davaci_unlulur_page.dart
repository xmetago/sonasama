import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/profile_icons_row.dart';
import 'category_page.dart';
import 'gelen_davalar_kactane.dart';
import 'delilleri_incele_page.dart';
import '../widgets/my_checkbox_widget_yargila.dart';
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

// WhoBoom, Arama Iconu, Chat Iconu
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
            onPressed: () {},
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

// Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
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

// Profil Bölümü
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
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class DavaciUnlulurPage extends StatefulWidget {
  const DavaciUnlulurPage({super.key});

  @override
  State<DavaciUnlulurPage> createState() => _DavaciUnlulurPageState();
}

class _DavaciUnlulurPageState extends State<DavaciUnlulurPage> {
  int commentCount = 0;
  int retweetCount = 0;
  int likeCount = 0;
  int dislikeCount = 0;
  bool isUnluDavali = true; // true: Ünlü Davalı, false: Dava Açan Ünlü
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
        adi: "Ünlü Davası 1",
        davali: "Ünlü 1",
        mevkii: "Davalı",
        kalanSure: "72 saat (3 gün)",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
      ),
      Dava(
        adi: "Ünlü Davası 2",
        davali: "Ünlü 2",
        mevkii: "Davalı",
        kalanSure: "48 saat (2 gün)",
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
              // ROW 4: Hamburger Iconu ve Sekmeler
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
                    // İki sekme
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isUnluDavali = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: isUnluDavali ? Colors.green : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Davacı Ünlü',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isUnluDavali ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
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
                                  isUnluDavali = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: !isUnluDavali ? Colors.green : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Davalı Ünlü',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !isUnluDavali ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.5),
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
                          itemCount: davaList.length, // davaList.length kullan
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
                                          Text(
                                            'Hüküm Detayları - ${isUnluDavali ? "Ünlü Davalı" : "Dava Açan Ünlü"}',
                                            style: const TextStyle(
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

class FiveCardCaseInformation extends StatelessWidget {
  final Dava dava;
  final VoidCallback? onTap;

  const FiveCardCaseInformation({super.key, required this.dava, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                width: 80,
                padding: const EdgeInsets.all(9),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          MdiIcons.homeFlood,
                          size: 19,
                          color: Colors.green,
                        ),
                        const Text('Onayla', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ],
                    ),
                    Image.asset(dava.profilResmi, width: 60, height: 50),
                    Row(
                      children: [
                        Icon(
                          MdiIcons.giftOpen,
                          size: 19,
                          color: Colors.green,
                        ),
                        const Text('Onayla', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                  children: [
                    Row(
                      children: [
                        const Text('Dava Adı    :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(dava.adi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Bu buton tıklandığında açılır alan açılacak
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              minimumSize: const Size(60, 30),
                            ),
                            child: Text("DESTEK ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Bu buton tıklandığında açılır alan açılacak
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              minimumSize: const Size(60, 30),
                            ),
                            child: Text("KINA", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
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
    );
  }
} 