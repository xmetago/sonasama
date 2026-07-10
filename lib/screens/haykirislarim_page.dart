import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../utils/map_safety.dart'; // ✅ asStringDynamicMap için
import '../providers/dava_provider.dart';
import 'home_page.dart'; // ✅ HaykirCardWidget için

// Model class for Haykir
class Haykir {
  final String adi;
  final String slogan;
  final String direme;
  final String kalanSure;
  final String profilResmi;

  Haykir({
    required this.adi,
    required this.slogan,
    required this.direme,
    required this.kalanSure,
    required this.profilResmi,
  });
}

class HaykirislarimPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  const HaykirislarimPage({super.key, this.userEmail});

  @override
  State<HaykirislarimPage> createState() => _HaykirislarimPageState();
}

class _HaykirislarimPageState extends State<HaykirislarimPage> {
  bool isHaykirislarim = true; // true: Haykırışlarım, false: Katıldığım
  bool showLeftIcons = false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
  int? expandedCardIndex;

  // Kalan süreyi hesapla
  String _calculateRemainingTime(String? createdAt) {
    if (createdAt == null) return '76 saat 0 dakika';
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);
      final totalMinutes = (76 * 60) - difference.inMinutes;
      
      if (totalMinutes <= 0) {
        return 'Süre doldu';
      }
      
      final remainingHours = totalMinutes ~/ 60;
      final remainingMinutes = totalMinutes % 60;
      
      return '$remainingHours saat $remainingMinutes dakika';
    } catch (e) {
      return '76 saat 0 dakika';
    }
  }

  // Kullanıcı adını al
  String _getUserDisplayName(String? userEmail) {
    if (userEmail == null) return 'Bilinmeyen Kullanıcı';
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      return user?.judgeName ?? userEmail.split('@').first;
    } catch (e) {
      return userEmail.split('@').first;
    }
  }

  /// Katıldığım haykır verisini seyir defteri post formatına dönüştürür
  Map<String, dynamic> _katildigimHaykirToPost(Map<String, dynamic> haykir) {
    final haykirId =
        haykir['haykirId']?.toString() ?? haykir['id']?.toString() ?? '';
    final freshData =
        haykirId.isNotEmpty ? HiveDatabaseService.getHaykir(haykirId) : null;
    final source = freshData ?? haykir;

    return {
      'id': 'katildigim_$haykirId',
      'type': 'haykir',
      'createdAt': haykir['participatedAt']?.toString() ??
          source['createdAt']?.toString() ??
          DateTime.now().toIso8601String(),
      'authorEmail': source['userEmail']?.toString(),
      'payload': {
        'haykirId': haykirId,
        'adi': source['adi']?.toString() ?? 'Haykırış',
        'slogan': source['slogan']?.toString() ?? '',
        'direme': source['direme']?.toString() ?? '',
        'detaylar': source['detaylar']?.toString() ?? '',
        'createdAt': source['createdAt']?.toString() ??
            DateTime.now().toIso8601String(),
        'shareCount': 0,
        'commentCount': 0,
        'retweetCount': 0,
        'likeCount': 0,
        'kinaCount': 0,
        'isSaved': false,
        'isLiked': false,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final davaProvider = Provider.of<DavaProvider>(context, listen: false);

    // ✅ Adım 2: Seyir defterindeki haykır postlarını getir
    List<Map<String, dynamic>> haykirPostsFromFeed = [];
    if (isHaykirislarim && widget.userEmail != null) {
      // Seyir defterindeki haykır postlarını getir
      final allFeedPosts = HiveDatabaseService.getHomeFeedPosts(userEmail: widget.userEmail);
      haykirPostsFromFeed = allFeedPosts.where((post) {
        final type = post['type']?.toString() ?? '';
        return type == 'haykir';
      }).toList();
    }

    // ✅ Veritabanından gerçek haykırışları çek (eski sistem için geriye dönük uyumluluk)
    List<Map<String, dynamic>> haykirDataList;
    if (isHaykirislarim) {
      // Haykırışlarım sekmesi - kullanıcının kendi haykırışları
      if (widget.userEmail != null) {
        haykirDataList = HiveDatabaseService.getUserHaykirislar(widget.userEmail!);
      } else {
        haykirDataList = [];
      }
    } else {
      // ✅ Katıldığım sekmesi - katıldığım haykırları göster
      if (widget.userEmail != null) {
        haykirDataList = HiveDatabaseService.getKatildigimHaykirler(widget.userEmail!);
      } else {
        haykirDataList = [];
      }
    }

    // Gösterilecek haykır postları (seyir defteri formatında)
    final List<Map<String, dynamic>> haykirPostsToShow;
    if (isHaykirislarim) {
      haykirPostsToShow = haykirPostsFromFeed;
    } else {
      haykirPostsToShow =
          haykirDataList.map(_katildigimHaykirToPost).toList();
    }

    // Haykir model listesine dönüştür (eski sistem geriye dönük uyumluluk)
    final List<Haykir> haykirList = haykirDataList.map((data) {
      return Haykir(
        adi: data['adi']?.toString() ?? 'Haykırış',
        slogan: data['slogan']?.toString() ?? 'Slogan',
        direme: data['direme']?.toString() ?? 'Direme',
        kalanSure: _calculateRemainingTime(data['createdAt']?.toString()),
        profilResmi: "lib/icons/03_haykir_ana_icon.png",
      );
    }).toList();
    
    // Haykırış detaylarını saklamak için bir map (boolean değerleri String'e dönüştür)
    final Map<int, Map<String, dynamic>> haykirDetailsMap = {};
    for (int i = 0; i < haykirDataList.length; i++) {
      final originalData = haykirDataList[i];
      final cleanData = <String, dynamic>{};
      
      // Tüm değerleri güvenli şekilde kopyala ve boolean değerleri String'e dönüştür
      originalData.forEach((key, value) {
        if (value is bool) {
          cleanData[key] = value.toString();
        } else {
          cleanData[key] = value;
        }
      });
      
      haykirDetailsMap[i] = cleanData;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                  OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                                SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                userEmail: widget.userEmail,
                onShowSavedDavalar: () {
                  // Global utility fonksiyonunu kullan
                  if (widget.userEmail != null) {
                    showSavedDavalarDialog(context, widget.userEmail!);
                  }
                },
              ),
                ],
              ),
            ),
            
            // Tab Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Menü ikonu - tıklanabilir
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showLeftIcons = !showLeftIcons;
                      });
                    },
                    child: Icon(
                      MdiIcons.menuOpen,
                      size: 34,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isHaykirislarim = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                decoration: BoxDecoration(
                                  gradient: isHaykirislarim
                                      ? LinearGradient(
                                          colors: [Colors.orange.shade600, Colors.orange.shade400],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isHaykirislarim ? null : Colors.grey[300],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  boxShadow: isHaykirislarim
                                      ? [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.campaign,
                                      size: 18,
                                      color: isHaykirislarim ? Colors.white : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'HAYKIRIŞLARIM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isHaykirislarim ? Colors.white : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isHaykirislarim = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                decoration: BoxDecoration(
                                  gradient: !isHaykirislarim
                                      ? LinearGradient(
                                          colors: [Colors.black87, Colors.black54],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: !isHaykirislarim ? null : Colors.grey[300],
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  boxShadow: !isHaykirislarim
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: 18,
                                      color: !isHaykirislarim ? Colors.white : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'KATILDIĞIM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !isHaykirislarim ? Colors.white : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
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
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Icons (Gösterilme durumu kontrol ediliyor)
                    if (showLeftIcons || !isSmallScreen) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: showLeftIcons ? 60 : 0,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.campaign, size: 24, color: Colors.black54),
                                onPressed: () {
                                  // Megafon/ses işlevselliği
                                },
                              ),
                              const SizedBox(height: 76),
                              Icon(Icons.save_as_outlined, size: 24, color: Colors.black54),
                              const SizedBox(height: 76),
                              Icon(Icons.edit_document, size: 24, color: Colors.black54),
                              const SizedBox(height: 76),
                              Image.asset('lib/icons/06_left_row_ahizelitelefon_icon.png', width: 24, height: 24),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],

                    // Cards Section
                    Expanded(
                      child: haykirPostsToShow.isNotEmpty
                          ? ListView.builder(
                              itemCount: haykirPostsToShow.length,
                              itemBuilder: (context, index) {
                                final post = haykirPostsToShow[index];
                                final safePost = asStringDynamicMap(post);
                                final payload =
                                    asStringDynamicMap(safePost['payload'] ?? {});
                                return HaykirCardWidget(
                                  post: safePost,
                                  payload: payload,
                                  davaProvider: davaProvider,
                                  userEmail: widget.userEmail,
                                  showCloseButton: false,
                                );
                              },
                            )
                          : haykirList.isEmpty
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(32),
                                    margin: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.orange.shade200, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.15),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.campaign_outlined,
                                            size: 64,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          isHaykirislarim 
                                              ? 'Henüz haykırışınız yok!' 
                                              : 'Henüz katıldığınız haykırış yok.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isHaykirislarim 
                                              ? 'Yeni bir haykırış oluşturarak\nsesinizi duyurun!' 
                                              : 'Haykırışlara katılarak\netkileşime geçin!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.orange.shade600,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  // ✅ Eski sistem (geriye dönük uyumluluk)
                                  itemCount: haykirList.length,
                                  itemBuilder: (context, index) {
                                    final haykirData = haykirDetailsMap[index];
                                    final userEmail = haykirData?['userEmail']?.toString();
                                    final userDisplayName = _getUserDisplayName(userEmail);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: FiveCardCaseInformation(
                                        haykir: haykirList[index],
                                        haykirData: haykirData,
                                        userDisplayName: userDisplayName,
                                        isExpanded: expandedCardIndex == index,
                                        onTap: () {
                                          setState(() {
                                            if (expandedCardIndex == index) {
                                              expandedCardIndex = null;
                                            } else {
                                              expandedCardIndex = index;
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  },
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

class FiveCardCaseInformation extends StatefulWidget {
  final Haykir haykir;
  final Map<String, dynamic>? haykirData;
  final String userDisplayName;
  final bool isExpanded;
  final VoidCallback? onTap;

  const FiveCardCaseInformation({
    super.key, 
    required this.haykir,
    this.haykirData,
    this.userDisplayName = 'Bilinmeyen Kullanıcı',
    required this.isExpanded,
    this.onTap
  });

  @override
  State<FiveCardCaseInformation> createState() => _FiveCardCaseInformationState();
}

class _FiveCardCaseInformationState extends State<FiveCardCaseInformation> with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    if (widget.isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FiveCardCaseInformation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  /// Haykır başlangıç tarihini formatla (DD/MM/YYYY)
  String _formatHaykirBaslangicTarihi() {
    if (widget.haykirData == null) return 'Haykır açıldığı tarih';
    
    try {
      final createdAt = widget.haykirData!['createdAt']?.toString();
      if (createdAt == null || createdAt.isEmpty) return 'Haykır açıldığı tarih';
      
      final date = DateTime.tryParse(createdAt);
      if (date == null) return 'Haykır açıldığı tarih';
      
      // DD/MM/YYYY formatına çevir
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      
      return '$day/$month/$year';
    } catch (e) {
      return 'Haykır açıldığı tarih';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Teal (turkuaz) rengi kullanıyoruz - farklı ve uygun bir ton
    final primaryColor = Colors.teal;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: widget.isExpanded ? 6 : 2,
        margin: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 0 : 8, vertical: widget.isExpanded ? 8 : 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 12),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isExpanded ? primaryColor.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 12),
            border: Border.all(
              color: widget.isExpanded ? primaryColor.shade200 : Colors.grey.shade300,
              width: widget.isExpanded ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 12),
            onTap: widget.onTap,
            child: Padding(
              padding: EdgeInsets.all(widget.isExpanded ? 16.0 : 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Sadece Haykırış Adı göster (küçültülmüş)
                  if (!widget.isExpanded)
                    Row(
                      children: [
                        Icon(Icons.campaign, size: 20, color: primaryColor.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.haykir.adi,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryColor.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AnimatedRotation(
                          turns: widget.isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: primaryColor.shade600,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  
                  // ✅ Genişletilmiş içerik
                  if (widget.isExpanded) ...[
                    // Header Row
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.shade100,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.transparent,
                            child: Image.asset(
                              'lib/icons/03_haykir_ana_icon.png',
                              width: 38,
                              height: 38,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: primaryColor.shade200, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(MdiIcons.humanFemale, size: 14, color: primaryColor.shade700),
                                    const SizedBox(width: 4),
                                    Text('...', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryColor.shade700)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: primaryColor.shade200, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(MdiIcons.accountVoice, size: 14, color: primaryColor.shade700),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'HAYKIRAN KİŞİ --> ${widget.userDisplayName}',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor.shade700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: widget.isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: primaryColor.shade700,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Haykir Information - Teal tonlu kartlar
                    _buildInfoCard('Haykırış Adı', widget.haykir.adi, primaryColor, Icons.campaign),
                    const SizedBox(height: 10),
                    _buildInfoCard('Slogan', widget.haykir.slogan, primaryColor, MdiIcons.formatQuoteOpen),
                    const SizedBox(height: 10),
                    _buildInfoCard('Direme', widget.haykir.direme, primaryColor, MdiIcons.flag),
                    const SizedBox(height: 10),
                    _buildInfoCard('Kalan Süre', 'KalanSure: ${widget.haykir.kalanSure}, BaşlamaTarihi: ${_formatHaykirBaslangicTarihi()}', primaryColor, MdiIcons.timerAlertOutline),

                    // Expanded Content - Animasyonlu
                    SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: FadeTransition(
                      opacity: _expandAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.teal.shade200, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.15),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(MdiIcons.informationOutline, color: Colors.teal.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Haykırış Detayları',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.teal.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.teal.shade200, width: 1),
                                  ),
                                  child: Text(
                                    widget.haykirData?['detaylar']?.toString() ?? 'Detay bulunamadı',
                                    style: const TextStyle(fontSize: 13, height: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildSocialIcon(Icons.comment, 'Yorum', Colors.teal),
                                      _buildSocialIcon(Icons.repeat, 'Retweet', Colors.teal),
                                      _buildSocialIcon(Icons.thumb_up, 'Beğen', Colors.teal),
                                      _buildSocialIcon(Icons.thumb_down, 'Beğenme', Colors.teal),
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
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, MaterialColor color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade50, color.shade100.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label, MaterialColor color) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // İnteraktif özellikler eklenebilir
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color.shade700, size: 22),
                const SizedBox(height: 4),
                Text(
                  label, 
                  style: TextStyle(
                    fontSize: 10,
                    color: color.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 