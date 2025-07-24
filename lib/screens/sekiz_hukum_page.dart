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
import '../widgets/energy_bar.dart';

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

class SekizHukumPage extends StatefulWidget {
  const SekizHukumPage({Key? key}) : super(key: key);

  @override
  State<SekizHukumPage> createState() => _SekizHukumPageState();
}

class _SekizHukumPageState extends State<SekizHukumPage> {
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
                    Center(child: Text("8 HÜKÜM ",style: TextStyle(fontSize: 19),),)
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
                            child: Icon(Icons.gavel_outlined, size: 24,  color: Colors.black54),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                            child: IconButton(
                              icon: Icon(Icons.save_as_outlined, size: 24,  color: Colors.black54),
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
                        child: Container(
                          color: Colors.grey[100],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 80,
                                      padding: const EdgeInsets.all(5),
                                      child: Column(
                                        children: [
                                          Icon(
                                            MdiIcons.emoticonHappyOutline,
                                            size: 30,
                                            color: Colors.orange,
                                          ),
                                          Image.asset(
                                            'lib/icons/07_profil_picture_davaci.png',
                                            width: 60,
                                            height:50,
                                          ),
                                          Row(
                                            children: [

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
                                          // Dava Adı
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Dava Adı    :',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Şeytanın Hileleri',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Davalı
                                          Row(
                                            children: [
                                              const Text(
                                                'Davalı         :',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Edip Yüksel',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                    const Spacer(),
                                                    Icon(Icons.thumb_down_alt_outlined, size: 25, color: Colors.red),
                                                    Icon(Icons.thumb_up_alt_outlined, size: 25, color: Colors.green),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Görev
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Görev        :',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Davalı Avukatı',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Kalan Süre
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(MdiIcons.timerAlertOutline, size: 19, color: Colors.green),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Kalan Süre :',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                '72 saat (3 gün)',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                              ),
                                            ],
                                          ),
                                          // 8-HÜKÜM Butonu
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
                                                  minimumSize: const Size(30,15),
                                                ),
                                                child: Text("8 HÜKÜM ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Hüküm yazma alanı
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Buraya hüküm yazınız...",
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                    maxLines: 1,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                // 8 adet profil+emoji+text+kahve satırı
                                const SizedBox(height: 20),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: 8,
                                    itemBuilder: (context, index) {
                                      final kararlar = [
                                        "Temyiz Hakimi  Kararı ",
                                        "Yargıç  Kararı ",
                                        "1. jüri Kararı ",
                                        "2. jüri Kararı ",
                                        "Davacı Avukatı Kararı ",
                                        "Davalı Avukatı Kararı ",
                                        "Davacı  Şahidi Kararı ",
                                        "Davalı  Şahidi Kararı ",
                                      ];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              MdiIcons.accountCircle,
                                              size: 60,
                                              color: Colors.black54,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                kararlar[index],
                                                style: const TextStyle(fontSize: 16),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Kahve ve emojiler
                                            Icon(
                                              MdiIcons.emoticonHappyOutline,
                                              size: 26,
                                              color: Colors.orange,
                                            ),
                                            Icon(
                                              MdiIcons.emoticonCryOutline,
                                              size: 26,
                                              color: Colors.blue,
                                            ),
                                            Icon(
                                              MdiIcons.fileCheckOutline,
                                              size: 40,
                                              color: Colors.brown,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
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