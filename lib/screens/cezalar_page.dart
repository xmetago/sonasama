import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/common_header_widgets.dart';
import 'gelen_davalar_page.dart';
import 'yargila_page.dart';
import 'katildigim_davalar_page.dart';
import 'actigim_davalar_page.dart';
import 'davaci_unlulur_page.dart';
import 'haykir_page.dart';
import 'trend_insights_page.dart';
import 'delilleri_incele_page.dart';

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

class CezalarPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  const CezalarPage({super.key, this.userEmail});

  @override
  State<CezalarPage> createState() => _CezalarPageState();
}

class _CezalarPageState extends State<CezalarPage> {
  bool showLeftIcons = false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
  int commentCount = 0;
  int retweetCount = 0;
  int likeCount = 0;
  int dislikeCount = 0;

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
                    // Cezalar sayfasında kaydedilen davalar dialog'u açılamaz
                    // Bu sayfa sadece ceza işlemleri için
                  },
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
                      onPressed: () {
                        setState(() {
                          showLeftIcons = !showLeftIcons;
                        });
                      },
                    ),
                    const SizedBox(width: 68),
                    const Center(child: Text("CEZALAR ",style: TextStyle(fontSize: 19),),)
                  ],
                ),
              ),
              // ROW 5: 6 Icon Solda, Sağda Card ile Dava Bilgileri
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
                                        builder: (context) => TrendInsightsPage(userEmail: widget.userEmail),
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
                    SizedBox(
                      width: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
                            child: Icon(Icons.gavel_outlined, size: 24,  color: Colors.black54),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.save_as_outlined, size: 24,  color: Colors.black54),
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

                    Expanded(        // card orta plalet uzunluğu heighttir.
                      child: SizedBox(
                        height: 500,
                        child: ListView.builder(
                          itemCount: 1, // örnek veri için 1, isterseniz davaList.length yapabilirsiniz
                          itemBuilder: (context, index) {
                            final davaList = [
                              Dava(
                                adi: "Şeytanın Hileleri",
                                davali: "Edip Yüksel",
                                mevkii: "Davalı Avukatı",
                                kalanSure: "72 saat (3 gün)",
                                profilResmi: "lib/icons/03_davala_ana_icon.png",
                              ),
                            ];
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: FiveCardCaseInformation(
                                dava: davaList[index],
                                onTap: () {
                                      print("Tapped on ${davaList[index].adi}");
                                    },
                                  ),
                                ),
                                // Card'ın altına 4 adet row ekle
                                // 1. Row: Ceza Başlığı ve #cezakkodu
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 8,
                                        child: Text(
                                          "Ceza Başlığı buraya gelecek",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "#cezakkodu",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 2. Row: Temyiz Hakimi ve Text Input
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: const Text(
                                          "Temyiz Hakimi :",
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: "Buraya uygun cezayı yazınız ve cezalar card alanında ceza iconuna tıklayıp onaylayın",
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                          ),
                                          maxLines: 3,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 3. Row: Animasyonlu mezar ikonu ve #whoBOOM
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                  child: Row(
                                    children: [
                                      // Animasyonlu mezar ikonu container
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0, end: 1),
                                            duration: const Duration(seconds: 2),
                                            builder: (context, value, child) {
                                              return Transform.rotate(
                                                angle: value * 6.28, // 2*PI
                                                child: Icon(
                                                  MdiIcons.coffin,
                                                  size: 70,
                                                  color: Colors.black54,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // #whoBOOM container
                                      Expanded(
                                        child: Container(
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.arrow_left, color: Colors.green, size: 32),
                                                onPressed: () {},
                                              ),
                                              const Expanded(
                                                child: Center(
                                                  child: Text('#whoBOOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.arrow_right, color: Colors.green, size: 32),
                                                onPressed: () {},
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 4. Row: 3 text buton
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text(
                                          'Üyelerden',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text(
                                          'Ağır',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text(
                                          'Hafif',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                        ),
                                      ),
                                    ],
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
              // Ana Expanded Row'un hemen altına ekle:
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Row(
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
                const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 19,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
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
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                    children: [
                          Icon(
                            Icons.thumb_down_off_alt_outlined,
                            size: 19,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
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
                                const Icon(Icons.thumb_up_alt_outlined, size: 25, color: Colors.green),
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
                                // 8-HÜKÜM sayfası kaldırıldı - hüküm detayları yargıla sayfasında "Göreviniz" rozetine tıklanarak açılabilir
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hüküm yazmak için Yargıla sayfasında "Göreviniz" rozetine dokunun.'),
                                    duration: Duration(seconds: 2),
                                  ),
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
                              child: const Text("8 HÜKÜM ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),

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