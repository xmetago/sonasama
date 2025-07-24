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

// Model class for Trend Dava
class TrendDava {
  final String baslik;
  final String hashtag;
  final String aciklama;
  final String profilResmi;
  final int yorumSayisi;
  final int oySayisi;
  final int begeniSayisi;
  final int begenmemeSayisi;

  TrendDava({
    required this.baslik,
    required this.hashtag,
    required this.aciklama,
    required this.profilResmi,
    required this.yorumSayisi,
    required this.oySayisi,
    required this.begeniSayisi,
    required this.begenmemeSayisi,
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

class TrendDavaPage extends StatefulWidget {
  const TrendDavaPage({super.key});

  @override
  State<TrendDavaPage> createState() => _TrendDavaPageState();
}

class _TrendDavaPageState extends State<TrendDavaPage> {
  bool isDavalar = true; // true: DAVALAR, false: HAYKIRLAR
  int? expandedCardIndex; // Hangi card'ın açık olduğunu takip eder

  @override
  Widget build(BuildContext context) {
    // Sample data for Trend Dava instances
    final List<TrendDava> davalarList = [
      TrendDava(
        baslik: "Geri Dön Aşkım Haykır",
        hashtag: "#Geri_Dön_Aşkım_Haykır",
        aciklama: "Bu dava, aşkın geri dönmesi için açılan bir haykırış davasıdır. Davacı, sevdiği kişinin geri dönmesini istiyor.",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
        yorumSayisi: 15,
        oySayisi: 42,
        begeniSayisi: 128,
        begenmemeSayisi: 8,
      ),
      TrendDava(
        baslik: "Yaşamın Kıyısında",
        hashtag: "#Yaşamın_Kıyısında",
        aciklama: "Hayatın zorluklarına karşı açılan bir dava. Davacı, yaşamın kıyısında kalmış insanların sesi olmak istiyor.",
        profilResmi: "lib/icons/03_haykir_ana_icon.png",
        yorumSayisi: 23,
        oySayisi: 67,
        begeniSayisi: 89,
        begenmemeSayisi: 12,
      ),
    ];

    final List<TrendDava> haykirList = [
      TrendDava(
        baslik: "Haykırış Davası",
        hashtag: "#Haykırış_Davası",
        aciklama: "Bu haykırış, toplumsal adaletsizliklere karşı bir ses yükseltmedir. Davacı, adalet için haykırıyor.",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
        yorumSayisi: 31,
        oySayisi: 89,
        begeniSayisi: 156,
        begenmemeSayisi: 5,
      ),
      TrendDava(
        baslik: "Özgürlük Haykırışı",
        hashtag: "#Özgürlük_Haykırışı",
        aciklama: "Özgürlük için açılan bir haykırış davası. Davacı, tüm insanların özgür olması gerektiğini savunuyor.",
        profilResmi: "lib/icons/03_haykir_ana_icon.png",
        yorumSayisi: 18,
        oySayisi: 54,
        begeniSayisi: 203,
        begenmemeSayisi: 7,
      ),
    ];

    final currentList = isDavalar ? davalarList : haykirList;

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
                                  isDavalar = true;
                                  expandedCardIndex = null; // Sekme değişince card'ları kapat
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: isDavalar ? Colors.green : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'DAVALAR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDavalar ? Colors.white : Colors.black,
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
                                  isDavalar = false;
                                  expandedCardIndex = null; // Sekme değişince card'ları kapat
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: !isDavalar ? Colors.green : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'HAYKIRLAR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !isDavalar ? Colors.white : Colors.black,
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
              // ROW 5: 6 Icon Solda, Sağda Trend Dava Başlıkları
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
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                // Trend Dava Başlığı ve Twitter İkonları
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Column(
                                      children: [
                                        // Hashtag Başlığı (Tıklanabilir)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              expandedCardIndex = expandedCardIndex == index ? null : index;
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  currentList[index].hashtag,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.purple,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                expandedCardIndex == index ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                color: Colors.grey[600],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Twitter Benzeri İkonlar
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildIconCounter(Icons.mode_comment_outlined, currentList[index].yorumSayisi, () {}),
                                            _buildIconCounter(Icons.repeat, currentList[index].oySayisi, () {}),
                                            _buildIconCounter(Icons.favorite_border, currentList[index].begeniSayisi, () {}),
                                            _buildIconCounter(Icons.thumb_down_alt_outlined, currentList[index].begenmemeSayisi, () {}),
                                            IconButton(
                                              icon: Icon(Icons.bookmark_border, color: Colors.grey[600]),
                                              onPressed: () {},
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Card açılır içerik alanı
                                if (expandedCardIndex == index)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: TrendDavaCard(
                                      trendDava: currentList[index],
                                      onTap: () {},
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

  Widget _buildIconCounter(IconData icon, int count, VoidCallback onPressed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.grey[600], size: 20),
          onPressed: onPressed,
        ),
        Text('$count', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

class TrendDavaCard extends StatelessWidget {
  final TrendDava trendDava;
  final VoidCallback? onTap;

  const TrendDavaCard({super.key, required this.trendDava, this.onTap});

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
                    Image.asset(trendDava.profilResmi, width: 60, height: 50),
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
                        const Text('Dava Başlığı:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(trendDava.baslik, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Hashtag:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(child: Text(trendDava.hashtag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple))),
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
                        const Text('Tür:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Flexible(child: Text("Trend Dava", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(MdiIcons.timerAlertOutline, size: 19, color: Colors.green),
                        const SizedBox(width: 4),
                        const Text('Durum:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "Aktif",
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