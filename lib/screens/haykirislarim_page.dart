import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../utils/map_safety.dart'; // âœ… asStringDynamicMap iÃ§in
import '../providers/dava_provider.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/katildigim_haykir_card.dart';
import '../widgets/home_haykir_card.dart';
import 'haykir_page.dart';

class HaykirislarimPage extends StatefulWidget {
  final String? userEmail; // KullanÄ±cÄ± e-posta adresi

  const HaykirislarimPage({super.key, this.userEmail});

  @override
  State<HaykirislarimPage> createState() => _HaykirislarimPageState();
}

class _HaykirislarimPageState extends State<HaykirislarimPage> {
  bool isHaykirislarim = true;

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

  void _openCreateForm() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => HaykirPage(
          userEmail: widget.userEmail,
          initialShowForm: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
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
      backgroundColor: palette.surface,
      body: SafeArea(
        child: AppExpandableIconMenu(
          expandBody: true,
          inset: const EdgeInsets.all(16),
          openGap: 16,
          keepGapWhenClosed: !isSmallScreen,
          items: [
            AppExpandableIconMenuItem(
              onTap: _openCreateForm,
              customChild: IconButton(
                tooltip: 'Ekle',
                style: IconButton.styleFrom(
                  minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                  fixedSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(Icons.campaign, size: 24, color: palette.textSecondary),
                onPressed: _openCreateForm,
              ),
            ),
            AppExpandableIconMenuItem(
              onTap: () {},
              customChild: Column(
                children: [
                  const SizedBox(height: 76),
                  Icon(Icons.save_as_outlined, size: 24, color: palette.textSecondary),
                  const SizedBox(height: 76),
                  Icon(Icons.edit_document, size: 24, color: palette.textSecondary),
                  const SizedBox(height: 76),
                  Image.asset('lib/icons/06_left_row_ahizelitelefon_icon.png', width: 24, height: 24),
                ],
              ),
            ),
          ],
          headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Header Section
            Container(
              color: palette.surface,
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
              color: palette.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Menü',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                      fixedSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: toggle,
                    icon: const Icon(
                      MdiIcons.menuOpen,
                      size: 28,
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
                                constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                decoration: BoxDecoration(
                                  gradient: isHaykirislarim
                                      ? LinearGradient(
                                          colors: [Colors.orange.shade600, Colors.orange.shade400],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isHaykirislarim ? null : palette.surfaceMuted,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  boxShadow: isHaykirislarim
                                      ? [
                                          BoxShadow(
                                            color: Colors.orange.withValues(alpha: 0.4),
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
                                      color: isHaykirislarim ? Colors.white : palette.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'HAYKIRIŞLARIM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isHaykirislarim ? Colors.white : palette.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: SeyirTokens.typeBody,
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
                                constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                decoration: BoxDecoration(
                                  gradient: !isHaykirislarim
                                      ? const LinearGradient(
                                          colors: [Color(0xFF1A1A1A), Color(0xFF374151)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: !isHaykirislarim ? null : palette.surfaceMuted,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  boxShadow: !isHaykirislarim
                                      ? [
                                          BoxShadow(
                                            color: palette.shadow,
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
                                      color: !isHaykirislarim ? Colors.white : palette.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'KATILDIĞIM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !isHaykirislarim ? Colors.white : palette.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: SeyirTokens.typeBody,
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

                          ],
            );
          },
          body: isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(SeyirTokens.space6),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isHaykirislarim
                                          ? Icons.campaign_outlined
                                          : Icons.group_outlined,
                                      size: 64,
                                      color: palette.textMuted,
                                    ),
                                    const SizedBox(height: SeyirTokens.space4),
                                    Text(
                                      isHaykirislarim
                                          ? 'Henüz haykırışınız yok!'
                                          : 'Henüz katıldığınız haykırış yok.',
                                      textAlign: TextAlign.center,
                                      style: palette.title(
                                        weight: FontWeight.w500,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: SeyirTokens.space2),
                                    Text(
                                      isHaykirislarim
                                          ? 'Yeni bir haykırış oluşturarak\nsesinizi duyurun!'
                                          : 'Haykırışlara katılarak\netkileşime geçin!',
                                      textAlign: TextAlign.center,
                                      style: palette.body(
                                        weight: FontWeight.w400,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                    if (isHaykirislarim) ...[
                                      const SizedBox(height: SeyirTokens.space4),
                                      FilledButton.icon(
                                        onPressed: _openCreateForm,
                                        icon: const Icon(Icons.campaign),
                                        label: const Text(
                                          'Haykır oluştur',
                                          style: TextStyle(
                                            fontSize: SeyirTokens.typeTitle,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.orange.shade600,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(0, SeyirTokens.tapTarget),
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }
}

