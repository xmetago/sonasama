import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../utils/map_safety.dart'; // âœ… asStringDynamicMap iÃ§in
import '../providers/dava_provider.dart';
import '../widgets/katildigim_haykir_card.dart';
import 'home_page.dart'; // HaykirCardWidget iÃ§in

class HaykirislarimPage extends StatefulWidget {
  final String? userEmail; // KullanÄ±cÄ± e-posta adresi

  const HaykirislarimPage({super.key, this.userEmail});

  @override
  State<HaykirislarimPage> createState() => _HaykirislarimPageState();
}

class _HaykirislarimPageState extends State<HaykirislarimPage> {
  bool isHaykirislarim = true;
  bool showLeftIcons = false;

  /// KatÄ±ldÄ±ÄŸÄ±m haykÄ±r verisini seyir defteri post formatÄ±na dÃ¶nÃ¼ÅŸtÃ¼rÃ¼r
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
      'authorEmail': freshData?['userEmail']?.toString() ??
          source['authorEmail']?.toString(),
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

    // âœ… AdÄ±m 2: Seyir defterindeki haykÄ±r postlarÄ±nÄ± getir
    List<Map<String, dynamic>> haykirPostsFromFeed = [];
    if (isHaykirislarim && widget.userEmail != null) {
      // Seyir defterindeki haykÄ±r postlarÄ±nÄ± getir
      final allFeedPosts = HiveDatabaseService.getHomeFeedPosts(userEmail: widget.userEmail);
      haykirPostsFromFeed = allFeedPosts.where((post) {
        final type = post['type']?.toString() ?? '';
        return type == 'haykir';
      }).toList();
    }

    // âœ… VeritabanÄ±ndan gerÃ§ek haykÄ±rÄ±ÅŸlarÄ± Ã§ek (eski sistem iÃ§in geriye dÃ¶nÃ¼k uyumluluk)
    List<Map<String, dynamic>> haykirDataList;
    if (isHaykirislarim) {
      // HaykÄ±rÄ±ÅŸlarÄ±m sekmesi - kullanÄ±cÄ±nÄ±n kendi haykÄ±rÄ±ÅŸlarÄ±
      if (widget.userEmail != null) {
        haykirDataList = HiveDatabaseService.getUserHaykirislar(widget.userEmail!);
      } else {
        haykirDataList = [];
      }
    } else {
      // âœ… KatÄ±ldÄ±ÄŸÄ±m sekmesi - katÄ±ldÄ±ÄŸÄ±m haykÄ±rlarÄ± gÃ¶ster
      if (widget.userEmail != null) {
        haykirDataList = HiveDatabaseService.getKatildigimHaykirler(widget.userEmail!);
      } else {
        haykirDataList = [];
      }
    }

    // GÃ¶sterilecek haykÄ±r postlarÄ± (seyir defteri formatÄ±nda â€” HaykÄ±rÄ±ÅŸlarÄ±m sekmesi)
    final List<Map<String, dynamic>> haykirPostsToShow;
    if (isHaykirislarim) {
      haykirPostsToShow = haykirPostsFromFeed;
    } else {
      haykirPostsToShow = [];
    }

    final bool isEmpty = isHaykirislarim
        ? haykirPostsToShow.isEmpty
        : haykirDataList.isEmpty;

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
                  // MenÃ¼ ikonu - tÄ±klanabilir
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
                                      'HAYKIRIÅLARIM',
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
                                      'KATILDIÄIM',
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
                    // Left Icons (GÃ¶sterilme durumu kontrol ediliyor)
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
                                  // Megafon/ses iÅŸlevselliÄŸi
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
                      child: isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                margin: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isHaykirislarim
                                      ? Colors.orange.shade50
                                      : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isHaykirislarim
                                        ? Colors.orange.shade200
                                        : Colors.teal.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isHaykirislarim
                                              ? Colors.orange
                                              : Colors.teal)
                                          .withOpacity(0.15),
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
                                        color: isHaykirislarim
                                            ? Colors.orange.shade100
                                            : Colors.teal.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isHaykirislarim
                                            ? Icons.campaign_outlined
                                            : Icons.group_outlined,
                                        size: 64,
                                        color: isHaykirislarim
                                            ? Colors.orange.shade700
                                            : Colors.teal.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      isHaykirislarim
                                          ? 'HenÃ¼z haykÄ±rÄ±ÅŸÄ±nÄ±z yok!'
                                          : 'HenÃ¼z katÄ±ldÄ±ÄŸÄ±nÄ±z haykÄ±rÄ±ÅŸ yok.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isHaykirislarim
                                            ? Colors.orange.shade700
                                            : Colors.teal.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isHaykirislarim
                                          ? 'Yeni bir haykÄ±rÄ±ÅŸ oluÅŸturarak\nsesinizi duyurun!'
                                          : 'HaykÄ±rÄ±ÅŸlara katÄ±larak\netkileÅŸime geÃ§in!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isHaykirislarim
                                            ? Colors.orange.shade600
                                            : Colors.teal.shade600,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : isHaykirislarim
                              ? ListView.builder(
                                  itemCount: haykirPostsToShow.length,
                                  itemBuilder: (context, index) {
                                    final post = haykirPostsToShow[index];
                                    final safePost = asStringDynamicMap(post);
                                    final payload = asStringDynamicMap(
                                        safePost['payload'] ?? {});
                                    return HaykirCardWidget(
                                      post: safePost,
                                      payload: payload,
                                      davaProvider: davaProvider,
                                      userEmail: widget.userEmail,
                                      showCloseButton: false,
                                    );
                                  },
                                )
                              : ListView.builder(
                                  itemCount: haykirDataList.length,
                                  itemBuilder: (context, index) {
                                    final katildigimData = haykirDataList[index];
                                    final post =
                                        _katildigimHaykirToPost(katildigimData);
                                    final safePost = asStringDynamicMap(post);
                                    final payload = asStringDynamicMap(
                                        safePost['payload'] ?? {});
                                    final haykirId = katildigimData['haykirId']
                                            ?.toString() ??
                                        katildigimData['id']?.toString() ??
                                        '';
                                    return KatildigimHaykirCard(
                                      katildigimData: katildigimData,
                                      interactionsPanel: HaykirCardWidget(
                                        key: ValueKey(
                                            'katildigim_interactions_$haykirId'),
                                        post: safePost,
                                        payload: payload,
                                        davaProvider: davaProvider,
                                        userEmail: widget.userEmail,
                                        showCloseButton: false,
                                        interactionsOnly: true,
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

