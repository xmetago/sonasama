import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/profile_icons_row.dart';
import 'category_page.dart';
import 'gelen_davalar_kactane.dart';
import 'delilleri_incele_page.dart';
import '../widgets/my_checkbox_widget_yargila.dart';
import 'masraflar_page.dart';
import 'cezalar_page.dart';
import 'yargila_page.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';


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

// Masraflar Sayfası
class MasraflarPage extends StatefulWidget {
  const MasraflarPage({super.key});

  @override
  State<MasraflarPage> createState() => _MasraflarPageState();
}

class _MasraflarPageState extends State<MasraflarPage> {
  int _current = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  void _goToPrevious() {
    if (_current > 0) {
      _carouselController.previousPage();
    }
  }
  void _goToNext(int itemCount) {
    if (_current < itemCount - 1) {
      _carouselController.nextPage();
    }
  }

  /// İkon ve sayaç gösteren yardımcı widget
  Widget _buildIconCounter(IconData icon, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: Colors.black54),
          const SizedBox(height: 2),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
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

    // adData'yı Instagram reklam kartı formatına uygun şekilde güncelle
    // Reklam kodu sabit olarak '#reklamKodu' olacak şekilde ayarlanıyor
    final List<Map<String, String>> instaAdData = [
      {
        'profileImage': 'https://via.placeholder.com/40',
        'name': 'xmetago',
        'sponsoredText': 'Sponsorlu',
        'mainImage': 'https://via.placeholder.com/360x360',
        'buttonText': 'Şimdi Keşfet',
        'buttonUrl': 'https://www.xmetago.com',
        'caption': 'XMetaGo Dijital reklam kampanyalarınızı performansa dayalı büyütün. Daha fazla görünürlük ve etkileşim için hemen tıklayın!',
        'adTitle': 'XMetaGo Kampanyası',
        'adCode': '#reklamKodu',
      },
      {
        'profileImage': 'https://randomuser.me/api/portraits/men/32.jpg',
        'name': 'lawyerpro',
        'sponsoredText': 'Sponsorlu',
        'mainImage': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=360&q=80',
        'buttonText': 'Detaylı İncele',
        'buttonUrl': 'https://www.lawyerpro.com',
        'caption': 'LawyerPro ile davalarınızı dijital ortamda yönetin. Hemen keşfedin!',
        'adTitle': 'LawyerPro Dijital',
        'adCode': '#reklamKodu',
      },
      {
        'profileImage': 'https://randomuser.me/api/portraits/women/44.jpg',
        'name': 'kanitanaliz',
        'sponsoredText': 'Sponsorlu',
        'mainImage': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=360&q=80',
        'buttonText': 'Platforma Git',
        'buttonUrl': 'https://www.kanitanaliz.com',
        'caption': 'Kanıt Analiz Platformu ile yeni nesil yapay zeka destekli analizler!',
        'adTitle': 'Kanıt Analiz Platformu',
        'adCode': '#reklamKodu',
      },
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
                    Center(child: Text("MASRAFLAR ",style: TextStyle(fontSize: 19),),)
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
                            child: Icon(
                              Icons.gavel_outlined,
                              size: 24,
                              color: Colors.black54,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                            child: IconButton(
                              icon: Icon(MdiIcons.cartHeart, size: 24, color: Colors.black54),
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
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MasraflarPage()),
                                );
                              },
                              child: Icon(MdiIcons.giftOpenOutline, size: 24, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 165, // card burda kapladığı alan bitiyor , text burdan başlattıyorum
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
                         
                          const SizedBox(height: 8),
                          // Açıklama metni yerine CarouselSlider eklendi
                          Column(
                            children: [
                              CarouselSlider(
                                carouselController: _carouselController,
                                options: CarouselOptions(
                                  height: 566,
                                  autoPlay: false,
                                  enlargeCenterPage: true,
                                  viewportFraction: 0.95,
                                  scrollPhysics: const PageScrollPhysics(), // swipe ile geçiş aktif
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _current = index;
                                    });
                                  },
                                ),
                                items: instaAdData.map((ad) {
                                  return InstaAdCard(
                                    profileImage: ad['profileImage']!,
                                    name: ad['name']!,
                                    sponsoredText: ad['sponsoredText']!,
                                    mainImage: ad['mainImage']!,
                                    buttonText: ad['buttonText']!,
                                    buttonUrl: ad['buttonUrl']!,
                                    caption: ad['caption']!,
                                    adTitle: ad['adTitle'] ?? 'Reklam Başlığı',
                                    adCode: ad['adCode'] ?? 'AD-0001',
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios),
                                    onPressed: _current > 0 ? _goToPrevious : null,
                                  ),
                                  Text('${_current + 1} / ${instaAdData.length}'),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    onPressed: _current < instaAdData.length - 1 ? () => _goToNext(instaAdData.length) : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: const Text(
                                   '100 \$',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                             Icon(
                                MdiIcons.cartPlus, // Alternatif: MdiIcons.cartVariant, MdiIcons.cartPlus
                                size: 24,
                                color: Colors.green,
                              ),
                              TextButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  backgroundColor: Colors.lightGreen, // Buton arka plan rengi
                                  foregroundColor: Colors.white, // Yazı rengi
                                  textStyle: const TextStyle(fontSize: 12),
                                  minimumSize: const Size(60, 30),
                                ),
                                child: const Text('satınAL'),
                              ),
                            ],
                          ),
                          // SatınAl butonunun hemen altına yeni satır: Emoji ikonları
                          const SizedBox(height: 8),
                          // Delilleri İncele sayfasındaki gibi: Yorum, Beğen, Onay, Kalp ikonlu sayaçlar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildIconCounter(Icons.mode_comment_outlined, 0, () {}), // Yorum
                              _buildIconCounter(Icons.repeat, 0, () {}), // Onay/Paylaş
                              _buildIconCounter(Icons.favorite_border, 0, () {}), // Kalp/Beğen
                              _buildIconCounter(Icons.thumb_down_alt_outlined, 0, () {}), // Beğenme
                            ],
                          ),
                        ],
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
                            child:Icon(MdiIcons.giftOutline, size: 24, color: Colors.black54),
                          ),
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

// Instagram tarzı reklam kartı widget'ı
class InstaAdCard extends StatelessWidget {
  final String profileImage;
  final String name;
  final String sponsoredText;
  final String mainImage;
  final String buttonText;
  final String buttonUrl;
  final String caption;
  final String adTitle;
  final String adCode;

  const InstaAdCard({
    super.key,
    required this.profileImage,
    required this.name,
    required this.sponsoredText,
    required this.mainImage,
    required this.buttonText,
    required this.buttonUrl,
    required this.caption,
    required this.adTitle,
    required this.adCode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipOval(
                  child: Image.network(
                    profileImage,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(sponsoredText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      // Yeni eklenen Row: Reklam başlığı ve kodu
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              adTitle,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              adCode,
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              ],
            ),
          ),
          // Main Image
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              image: DecorationImage(
                image: NetworkImage(mainImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0095f6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () async {
                  final url = Uri.parse(buttonUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bağlantı açılamadı')),
                      );
                    }
                  }
                },
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(caption, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

