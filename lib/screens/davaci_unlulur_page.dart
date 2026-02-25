import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/common_header_widgets.dart';
import 'gelen_davalar_page.dart';
import 'katildigim_davalar_page.dart' as katildigim;
import 'yargila_page.dart';
import 'actigim_davalar_page.dart' as actigim;
import 'trend_insights_page.dart';
import 'haykir_page.dart';
import '../services/hive_database_service.dart';
import '../services/verified_users_service.dart';
import '../utils/dialog_utils.dart';
import 'delilleri_incele_page.dart';
import 'cezalar_page.dart';

class DavaciUnlulurPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  const DavaciUnlulurPage({super.key, this.userEmail});

  @override
  State<DavaciUnlulurPage> createState() => _DavaciUnlulurPageState();
}

class _DavaciUnlulurPageState extends State<DavaciUnlulurPage> {
  bool isUnluDavali = true; // true: Davacı Ünlü, false: Davalı Ünlü (sekme mantığı tersine çevrildi)
  bool showLeftIcons = false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
  List<Map<String, dynamic>> _davaList = []; // Gerçek veriler için

  @override
  void initState() {
    super.initState();
    _loadUnluDavalar();
  }

  /// Ünlü davaları yükle ve filtrele
  void _loadUnluDavalar() {
    // Tüm açılmış ve kaydedilmiş davaları al
    final openedDavalar = HiveDatabaseService.getOpenedDavalar();
    final savedDavalar = HiveDatabaseService.getSavedDavalar();
    final allDavalar = [...openedDavalar, ...savedDavalar];

    // Sekme durumuna göre filtrele
    final filteredDavalar = allDavalar.where((davaMap) {
      final davaci = (davaMap['davaci'] ?? '').toString().trim();
      final davali = (davaMap['davali'] ?? '').toString().trim();

      // ✅ Düzeltme: Email formatındaysa judgeName'e çevir
      final davaciJudgeName = _normalizeToJudgeName(davaci);
      final davaliJudgeName = _normalizeToJudgeName(davali);

      if (isUnluDavali) {
        // Davacı Ünlü sekmesi: davacı verified olmalı
        return davaciJudgeName.isNotEmpty && VerifiedUsersService.isVerified(davaciJudgeName);
      } else {
        // Davalı Ünlü sekmesi: sadece davalı verified ise, davacı verified değilse göster
        final bool davaciUnlu = davaciJudgeName.isNotEmpty && VerifiedUsersService.isVerified(davaciJudgeName);
        final bool davaliUnlu = davaliJudgeName.isNotEmpty && VerifiedUsersService.isVerified(davaliJudgeName);
        return davaliUnlu && !davaciUnlu;
      }
    }).toList();

    // Map'leri kart bileşeninin beklediği formata çevir
    setState(() {
      _davaList = filteredDavalar
          .map((davaMap) => _buildCaseData(Map<String, dynamic>.from(davaMap)))
          .toList();
    });
  }

  /// Email veya diğer formatları judgeName'e çevir
  String _normalizeToJudgeName(String value) {
    if (value.isEmpty) return '';
    
    // Eğer zaten judgeName formatındaysa (email değilse) direkt döndür
    if (!value.contains('@')) {
      // "Gizli Yargıç" gibi özel durumları kontrol et
      if (value == 'Gizli Yargıç') return '';
      return value;
    }
    
    // Email formatındaysa, email'den judgeName'i bul
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(value);
      return user?.judgeName ?? '';
    } catch (e) {
      return '';
    }
  }

  Map<String, dynamic> _buildCaseData(Map<String, dynamic> davaMap) {
    final nowIso = DateTime.now().toIso8601String();

    final String davaAdi = (davaMap['davaAdi'] ?? davaMap['adi'] ?? 'Bilinmeyen Dava').toString();
    final String davaci = (davaMap['davaci'] ?? '').toString();
    final String davali = (davaMap['davali'] ?? '').toString();
    final String profil = (davaMap['profilResmi'] ?? 'lib/icons/03_davala_ana_icon.png').toString();

    return {
      ...davaMap,
      'id': (davaMap['id'] ?? davaMap['davaId'] ?? 'dava_${davaAdi.hashCode}_${davali.hashCode}').toString(),
      'davaAdi': davaAdi,
      'adi': davaMap['adi'] ?? davaAdi,
      'davaci': davaci,
      'davali': davali,
      'profilResmi': profil,
      'mevkii': (davaMap['mevkii'] ?? (isUnluDavali ? 'Davacı' : 'Davalı')).toString(),
      'kalanSure': (davaMap['kalanSure'] ?? 'Bilinmiyor').toString(),
      'davaKonusu': (davaMap['davaKonusu'] ?? '').toString(),
      'acceptedAt': (davaMap['acceptedAt'] ??
              davaMap['openedAt'] ??
              davaMap['createdAt'] ??
              nowIso)
          .toString(),
      'isOpened': davaMap['isOpened'] ?? true,
    };
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
                                _loadUnluDavalar(); // Verileri yeniden yükle
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
                                _loadUnluDavalar(); // Verileri yeniden yükle
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
                                  child: const Padding(
                                    padding: EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
                                    child: Icon(Icons.save_outlined, size: 24,  color: Colors.black54),
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
                                    child: IconButton(
                                      icon: const Icon(Icons.content_paste_search, size: 24,  color: Colors.black54),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const DelilleriIncelePage()),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                                                      Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => katildigim.KatildigimDavalarPage(userEmail: widget.userEmail)),
                                  );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                    child: Icon(MdiIcons.briefcaseEditOutline, size: 24, color: Colors.black54),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                                                      Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => actigim.ActigimDavalarPage(userEmail: widget.userEmail)),
                                  );
                                  },
                                  child: Padding(
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
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const DavaciUnlulurPage(),
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
                    const SizedBox(

                    ),

                    Expanded(
                      child: _davaList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Henüz ünlü dava yok',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isUnluDavali
                                        ? 'Davacı ünlü olan dava bulunamadı'
                                        : 'Davalı ünlü olan dava bulunamadı',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _davaList.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: katildigim.FiveCardCaseInformation(
                                    davaData: _davaList[index],
                                    userEmail: widget.userEmail,
                                    onRefresh: _loadUnluDavalar,
                                  ),
                                );
                              },
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
