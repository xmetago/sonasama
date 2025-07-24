import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/profile_icons_row.dart';
import 'category_page.dart';
import 'gelen_davalar_kactane.dart';
import 'delilleri_incele_page.dart';
import '../widgets/my_checkbox_widget_yargila.dart';
import 'masraflar_page.dart';
import 'cezalar_page.dart';

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

/// Dava Açma Sayfası - Kullanıcı yeni bir dava başlatabilir
/// Seçilen alt kategori üstte gösterilir.
class DavaAcPage extends StatelessWidget {
  const DavaAcPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {},
                  ),
                  // Checkbox ve bilgi satırı
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
                  children: [
                    SizedBox(
                      width: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [//6row iconlar dava Aç---------------
                          Icon(Icons.gavel_outlined, size: 24, color: Colors.black,),
                          Icon(Icons.save, size: 24, color: Colors.black),
                          Icon(Icons.content_paste_search_outlined, size: 24, color: Colors.black),
                        Image.asset('lib/icons/sahidini_sec4040.png',width: 40, height:40),
                          Icon(Icons.edit_document, size: 24, color: Colors.black),
                          Image.asset('lib/icons/06_left_row_ahizelitelefon_icon.png',width: 24, height:24),
                        ],
                      ),
                    ),
                    Expanded(
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
                                    width: 60,
                                    padding: const EdgeInsets.all(2),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Davacı',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Image.asset(
                                          'lib/icons/07_profil_picture_davaci.png',
                                          width: 40,
                                          height: 50,
                                        ),
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
                                              'Dava Adı :',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: TextField(
                                                style: const TextStyle(fontSize: 12),
                                                decoration: const InputDecoration(
                                                  hintText: 'Şeytanın Hileleri',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Davalı
                                        Row(
                                          children: [
                                            const Text(
                                              'Davalı      :',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: TextField(
                                                style: const TextStyle(fontSize: 12),
                                                decoration: const InputDecoration(
                                                  hintText: 'Edip Yüksel',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Tarih
                                        Row(
                                          children: const [
                                            Text(
                                              'Tarih         :',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '27.03.1984',
                                              style: TextStyle(fontSize: 12, color: Colors.blue),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              Expanded(
                                child: TextField(
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: const InputDecoration(
                                    hintText: ""'              Kendini,   sevmediğin \n              birini   veya  bir    şeyi  \n              yargılatmak   için \n              dava açmak üzeresin...  '
                                        ''
                                        '\n \n              Dava   metnini   buraya \n              yaz ve ardından \n              soldaki siyah \n              TOKMAK-a basınız '"",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

// Stateful checkbox widget
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
        Checkbox(
          value: isChecked,
          onChanged: (bool? val) {
            setState(() {
              isChecked = val ?? false;
            });
          },
        ),
        const SizedBox(width: 19),
        const Text(
          'DAVA AÇ',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 19,color: Colors.green),
        ),
        // İstenirse yanına ek metin:
        // const SizedBox(width: 8),
        // const Text('Şartları kabul ediyorum'),
      ],
    );
  }
}