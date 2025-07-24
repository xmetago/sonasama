import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/profile_icons_row.dart';
import 'category_page.dart';
import 'katildigim_davalar_kactane.dart';
import 'yargila_page.dart';

// Model for a case row
class Dava {
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  const Dava({
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
  });
}

class ActigimDavalarPage extends StatelessWidget {
  const ActigimDavalarPage({super.key});

  final List<Dava> davalar = const [
    Dava(
      adi: 'Şeytanın Hileleri',
      davali: 'Edip Yüksel',
      mevkii: 'Davalı Avukatı',
      kalanSure: '27.03.1984',
      profilResmi: 'lib/icons/07_profil_picture_davaci.png',
    ),
    Dava(
      adi: 'Adaletin Sesi',
      davali: 'Ali Veli',
      mevkii: 'Davacı',
      kalanSure: '01.01.2024',
      profilResmi: 'lib/icons/07_profil_picture_davaci.png',
    ),
    Dava(
      adi: 'Hak ve Hukuk',
      davali: 'Ayşe Fatma',
      mevkii: 'Şahit',
      kalanSure: '15.05.2023',
      profilResmi: 'lib/icons/07_profil_picture_davaci.png',
    ),
    Dava(
      adi: 'Gerçekler',
      davali: 'Mehmet Can',
      mevkii: 'Sanık',
      kalanSure: '10.10.2022',
      profilResmi: 'lib/icons/07_profil_picture_davaci.png',
    ),
    Dava(
      adi: 'İnsanlık Davası',
      davali: 'Zeynep Nur',
      mevkii: 'Avukat',
      kalanSure: '20.12.2021',
      profilResmi: 'lib/icons/07_profil_picture_davaci.png',
    ),
  ];

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
                  const SizedBox(width: 10),
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
                ),)
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
                        const Text('YARGIÇ ADI', style: TextStyle(fontWeight: FontWeight.normal)),
                        const ProfileIconsRow(),
                        Row(
                          children: [
                            const SizedBox(width: 18),
                            const Icon(
                              Icons.picture_in_picture,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 38),
                            const Icon(
                              Icons.record_voice_over_sharp,
                              color: Colors.red,
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
                  const MyCheckboxWidget(),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Image.asset('lib/icons/06_left_row_actigim_davalar_icon.png', width: 24, height: 24),

                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white30,
                        child: ListView.builder(
                          itemCount: davalar.length,
                          itemBuilder: (context, index) {
                            final dava = davalar[index];
                            return FiveCardCaseInformation(dava: dava);
                          },
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

// Stateful checkbox widget (dava_ac_page.dart ile aynı)
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
        SizedBox(width: 38),
        const Text(
          'AÇTIĞIM   DAVALAR ',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
        ),
        SizedBox(width: 4),
        const Text(
          ' [ 19 ]  ',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
        ),
      ],
    );
  }
}

class FiveCardCaseInformation extends StatelessWidget {
  final Dava dava;
  final VoidCallback? onTap;
  const FiveCardCaseInformation({Key? key, required this.dava, this.onTap}) : super(key: key);

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
                          MdiIcons.gift,
                          size: 34,
                          color: Colors.green,
                        ),
                        const Text('OK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(dava.profilResmi, width: 60, height: 50),
                    ),
                    Row(
                      children: [
                        Icon(
                          MdiIcons.handcuffs,
                          size: 34,
                          color: Colors.green,
                        ),
                        const Text('OK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                        const Text('Davalı         :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            children: [
                              Text(dava.davali, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                      children: [
                        const Text('Mevkii        :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(dava.mevkii, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(MdiIcons.timerAlertOutline, size: 19, color: Colors.green),
                        const Text('Kalan Süre :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 5),
                        Text(dava.kalanSure, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),

                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Dava Sonucu  :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.insert_emoticon, size: 24, color: Colors.green),
                        const SizedBox(width: 98),
                        Icon(Icons.info_outline_rounded, size: 24, color: Colors.blue),

                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Hediyeni/sini :',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            // ALDIM butonuna basıldığında yapılacaklar
                          },
                          child: const Text(
                            'ALDIM',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        TextButton(
                          onPressed: () {
                            // UYAR! butonuna basıldığında yapılacaklar
                          },
                          child: const Text(
                            'UYAR!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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