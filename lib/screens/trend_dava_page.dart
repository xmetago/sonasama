import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/common_header_widgets.dart';
import 'gelen_davalar_page.dart';
import 'katildigim_davalar_page.dart';
import 'yargila_page.dart';
import 'actigim_davalar_page.dart';
import 'davaci_unlulur_page.dart';
import 'haykir_page.dart';
import '../utils/dialog_utils.dart';

// New import for dava açma

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



class TrendDavaPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  const TrendDavaPage({super.key, this.userEmail});

  @override
  State<TrendDavaPage> createState() => _TrendDavaPageState();
}

class _TrendDavaPageState extends State<TrendDavaPage> {
  bool isDavalar = true; // true: DAVALAR, false: HAYKIRLAR
  int? expandedCardIndex; // Hangi card'ın açık olduğunu takip eder
  bool showLeftIcons = false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder

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
                    // Global utility fonksiyonunu kullan
                    if (widget.userEmail != null) {
                      showSavedDavalarDialog(context, widget.userEmail!);
                    }
                  },
                ),
              ),
              // ROW 4: Hamburger Iconu ve Sekmeler
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                    const SizedBox(width: 19),
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
                          const SizedBox(width: 38),
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: showLeftIcons ? 60 : 0,
                      child: showLeftIcons
                          ? SingleChildScrollView(
                              child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => GelenDavalarPage(userEmail: widget.userEmail)),
                                    );
                                  },
                                  child:Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
                                    child: Icon(
                                      MdiIcons.trendingUp,
                                      size: 24,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => YargilaPage(userEmail: widget.userEmail)),
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
                                      MaterialPageRoute(builder: (context) => KatildigimDavalarPage(userEmail: widget.userEmail)),
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
                                      MaterialPageRoute(builder: (context) => ActigimDavalarPage(userEmail: widget.userEmail)),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                    child: Image.asset('lib/icons/06_left_row_actigim_davalar_icon.png', width: 24, height: 24),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DavaciUnlulurPage(userEmail: widget.userEmail),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                    child: Image.asset('lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png', width: 24, height: 24),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HaykirPage(userEmail: widget.userEmail),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                    child: Image.asset('lib/icons/06_left_row_haykirislarim.png', width: 24, height: 24),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TrendDavaPage(userEmail: widget.userEmail),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                    child: Icon(
                                      MdiIcons.trendingUp,
                                      size: 24,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : const SizedBox.shrink(),
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
                                            Flexible(
                                              child: IconButton(
                                                icon: Icon(Icons.bookmark_border, color: Colors.grey[600]),
                                                onPressed: () {},
                                              ),
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
                              const Icon(Icons.thumb_up_alt_outlined, size: 24, color: Colors.green),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tür:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Flexible(child: Text("Trend Dava", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
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
                        const Flexible(
                          child: Text(
                            "Aktif",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
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
                            child: const Text("DESTEK ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                            child: const Text("KINA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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