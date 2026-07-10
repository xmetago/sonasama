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
import '../utils/verified_party_utils.dart';
import '../utils/dialog_utils.dart';
import '../utils/dava_map_utils.dart';
import '../widgets/ilgililerin_seyir_defteri_widgeti.dart';
import 'delilleri_incele_page.dart';
import 'cezalar_page.dart';

class DavaciUnlulurPage extends StatefulWidget {
  final String? userEmail;

  const DavaciUnlulurPage({super.key, this.userEmail});

  @override
  State<DavaciUnlulurPage> createState() => _DavaciUnlulurPageState();
}

class _DavaciUnlulurPageState extends State<DavaciUnlulurPage> {
  /// true → Davacı Ünlü sekmesi, false → Davalı Ünlü sekmesi
  bool _isDavaciUnluTab = true;
  bool showLeftIcons = false;
  List<Map<String, dynamic>> _davaList = [];
  int _davaciUnluCount = 0;
  int _davaliUnluCount = 0;
  final Map<String, bool> _seyirDefteriCollapsedByDavaId = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _loadUnluDavalar();
  }

  /// Açılmış davaları tekilleştirerek döndürür (kaydedilmiş taslaklar hariç).
  List<Map<String, dynamic>> _getAllOpenedDavalar() {
    final openedDavalar = HiveDatabaseService.getOpenedDavalar();
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final raw in openedDavalar) {
      final davaMap = Map<String, dynamic>.from(raw);
      final id = (davaMap['id'] ?? davaMap['davaId'] ?? '').toString().trim();
      if (id.isNotEmpty) {
        if (seen.contains(id)) continue;
        seen.add(id);
      }
      result.add(davaMap);
    }
    return result;
  }

  bool _isVerifiedParty(Map<String, dynamic> davaMap, {required bool isDavaci}) {
    final field = isDavaci ? 'davaci' : 'davali';
    final judgeName =
        VerifiedPartyUtils.resolveToJudgeName((davaMap[field] ?? '').toString());
    return judgeName.isNotEmpty && VerifiedUsersService.isVerified(judgeName);
  }

  /// Davalı Ünlü: mavi tikli davalıya yalnızca mavi tikli davacı dava açabilir.
  bool _matchesDavaliUnluTab(Map<String, dynamic> davaMap) {
    return _isVerifiedParty(davaMap, isDavaci: false) &&
        _isVerifiedParty(davaMap, isDavaci: true);
  }

  String _verifiedPartyName(Map<String, dynamic> davaMap) {
    final field = _isDavaciUnluTab ? 'davaci' : 'davali';
    return VerifiedPartyUtils.resolveToJudgeName((davaMap[field] ?? '').toString());
  }

  void _loadUnluDavalar() {
    final allOpened = _getAllOpenedDavalar();

    final davaciUnluList = allOpened
        .where((d) => _isVerifiedParty(d, isDavaci: true))
        .toList();
    final davaliUnluList =
        allOpened.where(_matchesDavaliUnluTab).toList();

    final activeList = _isDavaciUnluTab ? davaciUnluList : davaliUnluList;

    activeList.sort((a, b) {
      final aDate = _parseDate(a);
      final bDate = _parseDate(b);
      return bDate.compareTo(aDate);
    });

    setState(() {
      _davaciUnluCount = davaciUnluList.length;
      _davaliUnluCount = davaliUnluList.length;
      _davaList = activeList
          .map((d) => _buildCaseData(Map<String, dynamic>.from(d)))
          .toList();
    });
  }

  DateTime _parseDate(Map<String, dynamic> davaMap) {
    for (final key in ['openedAt', 'acceptedAt', 'createdAt']) {
      final raw = davaMap[key]?.toString();
      if (raw != null && raw.isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> _buildCaseData(Map<String, dynamic> davaMap) {
    final nowIso = DateTime.now().toIso8601String();
    final String davaAdi =
        (davaMap['davaAdi'] ?? davaMap['adi'] ?? 'Bilinmeyen Dava').toString();
    final String davaci = (davaMap['davaci'] ?? '').toString();
    final String davali = (davaMap['davali'] ?? '').toString();
    final String profil =
        (davaMap['profilResmi'] ?? 'lib/icons/03_davala_ana_icon.png').toString();

    return {
      ...davaMap,
      'id': (davaMap['id'] ??
              davaMap['davaId'] ??
              'dava_${davaAdi.hashCode}_${davali.hashCode}')
          .toString(),
      'davaAdi': davaAdi,
      'adi': davaMap['adi'] ?? davaAdi,
      'davaci': davaci,
      'davali': davali,
      'profilResmi': profil,
      'mevkii': (davaMap['mevkii'] ?? (_isDavaciUnluTab ? 'Davacı' : 'Davalı'))
          .toString(),
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

  Widget _buildUnluSeyirDefteriCard(Map<String, dynamic> davaData) {
    final String davaId =
        (davaData['id'] ?? davaData['davaId'] ?? '').toString().trim();
    final String? openedAtRaw =
        (davaData['openedAt'] ?? davaData['createdAt'] ?? davaData['acceptedAt'])
            ?.toString();
    DateTime? openedAt;
    if (openedAtRaw != null && openedAtRaw.isNotEmpty) {
      openedAt = DateTime.tryParse(openedAtRaw);
    }
    final bool collapsed = _seyirDefteriCollapsedByDavaId[davaId] ?? true;
    final String verifiedName = _verifiedPartyName(davaData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (verifiedName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4, top: 2),
            child: Row(
              children: [
                Icon(Icons.verified, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  verifiedName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    _isDavaciUnluTab ? 'Davacı Ünlü' : 'Davalı Ünlü',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E6E6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: IlgililerinSeyirDefteriWidgeti(
              davaId: davaId.isEmpty ? null : davaId,
              userEmail: widget.userEmail,
              davaAdi: (davaData['davaAdi'] ?? davaData['adi'])?.toString(),
              davaci: davaData['davaci']?.toString(),
              davali: davaData['davali']?.toString(),
              kategori: resolveDavaKategoriFromMap(davaData),
              davaKonusu: davaData['davaKonusu']?.toString(),
              openedAt: openedAt,
              collapsed: collapsed,
              onToggleCollapse: davaId.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _seyirDefteriCollapsedByDavaId[davaId] = !collapsed;
                      });
                    },
              onClose: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required bool isActive,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: isActive ? Colors.blue.shade700 : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive ? Colors.blue.shade900 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count dava',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.blue.shade800 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(

    );
  }

  Widget _buildPageHeadline() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),

    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.verified_outlined, size: 72, color: Colors.blue.shade100),
          const SizedBox(height: 16),
          Text(
            'Henüz ünlü dava yok',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isDavaciUnluTab
                ? 'Mavi tikli (ünlü) kullanıcıların açtığı davalar burada görünür.'
                : 'Mavi tikli ünlülere, yalnızca mavi tikli kullanıcıların açtığı davalar burada görünür.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftIconMenu() {
    return SingleChildScrollView(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GelenDavalarPage(userEmail: widget.userEmail),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
              child: Icon(Icons.save_outlined, size: 24, color: Colors.black54),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YargilaPage(userEmail: widget.userEmail),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
              child: IconButton(
                icon: const Icon(Icons.content_paste_search, size: 24, color: Colors.black54),
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
                MaterialPageRoute(
                  builder: (context) =>
                      katildigim.KatildigimDavalarPage(userEmail: widget.userEmail),
                ),
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
                MaterialPageRoute(
                  builder: (context) =>
                      actigim.ActigimDavalarPage(userEmail: widget.userEmail),
                ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: Image.asset(
              'lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png',
              width: 24,
              height: 24,
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
              child: Icon(MdiIcons.trendingUp, size: 24, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadUnluDavalar(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                    userEmail: widget.userEmail,
                    onShowSavedDavalar: () {
                      if (widget.userEmail != null) {
                        showSavedDavalarDialog(context, widget.userEmail!);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(MdiIcons.menuOpen, size: 34, color: Colors.red),
                        onPressed: () {
                          setState(() => showLeftIcons = !showLeftIcons);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildTabButton(
                                isActive: _isDavaciUnluTab,
                                label: 'Davacı Ünlü',
                                count: _davaciUnluCount,
                                onTap: () {
                                  if (_isDavaciUnluTab) return;
                                  setState(() => _isDavaciUnluTab = true);
                                  _loadUnluDavalar();
                                },
                              ),
                              _buildTabButton(
                                isActive: !_isDavaciUnluTab,
                                label: 'Davalı Ünlü',
                                count: _davaliUnluCount,
                                onTap: () {
                                  if (!_isDavaciUnluTab) return;
                                  setState(() => _isDavaciUnluTab = false);
                                  _loadUnluDavalar();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPageHeadline(),
                _buildInfoBanner(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: showLeftIcons ? 60 : 0,
                        child: showLeftIcons ? _buildLeftIconMenu() : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: _davaList.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _davaList.length,
                                itemBuilder: (context, index) {
                                  return _buildUnluSeyirDefteriCard(_davaList[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
