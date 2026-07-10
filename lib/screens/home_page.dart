import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import 'chat_page.dart';
import 'gelen_davalar_page.dart';
import 'katildigim_davalar_page.dart' as katildigim_page;
import 'yargila_page.dart';
import 'actigim_davalar_page.dart';
import 'davaci_unlulur_page.dart';
import 'trend_insights_page.dart';
import 'statistics_dashboard_page.dart';
import 'haykirislarim_page.dart';
import 'database_debug_page.dart';
import 'saved_haykirlar_page.dart';
import 'saved_widgets_page.dart';
import 'admin_page.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../utils/map_safety.dart';
import '../models/dava.dart' as dava_model;
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../widgets/ilgililerin_seyir_defteri_widgeti.dart';
import '../widgets/expandable_comment_text.dart';
import '../utils/comment_utils.dart';
import '../utils/app_theme.dart';
import 'tutorial_case_page.dart';

import 'dava_ac_page.dart' as dava_ac; // New import for dava a�ma
import 'hesap_gizlilik_ayarlari_page.dart';
import 'davetler_page.dart' show ModernDavaCard;
import 'haykir_page.dart';
import 'category_page.dart';
import '../widgets/twitter_post_composer.dart';
import '../utils/constants.dart';
import '../utils/category_icon_utils.dart';

// Eski Dava modeli
class Dava {
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final bool isOpened;

  Dava({
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    this.isOpened = false,
  });
}

enum _PostSheetAction {
  text,
  dava,
  haykir,
  poll,
  admin,
  debug,
}

String _normalizeCategoryName(String? raw) {
  var s = (raw ?? '').trim();
  if (s.isEmpty) return '';
  s = s.replaceAll('"', '').replaceAll("'", '').trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Bazı metinler "X kategorisinde" gibi gelebilir.
  final lower = s.toLowerCase();
  const suffix = 'kategorisinde';
  final idx = lower.indexOf(suffix);
  if (idx > 0) {
    s = s.substring(0, idx).trim();
  }

  // Sonda kalan noktalama/ayraçları temizle.
  s = s.replaceAll(RegExp(r'[^\p{L}\p{N}]+$', unicode: true), '').trim();
  return s;
}

String _categoryKey(String? raw) {
  final s = _normalizeCategoryName(raw);
  return s.isEmpty ? '' : s.toLowerCase();
}

IconData _caseCategoryIconFromName(String? categoryName) {
  final needle = _categoryKey(categoryName);
  if (needle.isEmpty) return Icons.category;

  final rawNormalized = _normalizeCategoryName(categoryName);
  final numericId = int.tryParse(rawNormalized);

  // Önce Hive'daki kategorilerden bul (ikonlar sonradan değiştirilebilir).
  final categories = HiveDatabaseService.getAllCategories();
  dynamic hiveMatch;
  if (numericId != null) {
    hiveMatch = categories.cast<dynamic>().firstWhere(
          (c) => int.tryParse(c?.id?.toString() ?? '') == numericId,
          orElse: () => null,
        );
  }
  hiveMatch ??= categories.cast<dynamic>().firstWhere(
        (c) => _categoryKey(c?.name?.toString()) == needle,
        orElse: () => null,
      );
  hiveMatch ??= categories.cast<dynamic>().firstWhere(
        (c) {
          final k = _categoryKey(c?.name?.toString());
          if (k.isEmpty) return false;
          return needle.contains(k) || k.contains(needle);
        },
        orElse: () => null,
      );
  final hiveIconPath = hiveMatch?.iconPath?.toString();
  if (hiveIconPath != null && hiveIconPath.isNotEmpty) {
    return categoryIconFromPath(hiveIconPath);
  }

  // Fallback: sabit initialCategories listesi
  Map<String, dynamic>? match;
  if (numericId != null) {
    match = initialCategories.cast<Map<String, dynamic>?>().firstWhere(
          (c) => int.tryParse(c?['id']?.toString() ?? '') == numericId,
          orElse: () => null,
        );
  }
  match ??= initialCategories.cast<Map<String, dynamic>?>().firstWhere(
        (c) => _categoryKey(c?['name']?.toString()) == needle,
        orElse: () => null,
      );
  match ??= initialCategories.cast<Map<String, dynamic>?>().firstWhere(
        (c) {
          final k = _categoryKey(c?['name']?.toString());
          if (k.isEmpty) return false;
          return needle.contains(k) || k.contains(needle);
        },
        orElse: () => null,
      );
  return categoryIconFromPath(match?['icon']?.toString());
}

class HomePage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi
  final bool openHaykirOnStart; // Giriş sonrası haykır formunu aç
  final String? initialSeyirDefteriDavaId;
  final DateTime? initialSeyirDefteriOpenedAt;
  final String? initialSeyirDefteriDavaAdi;
  final String? initialSeyirDefteriDavaci;
  final String? initialSeyirDefteriDaval;
  final String? initialSeyirDefteriKategori;
  final String? initialSeyirDefteriDavaKonusu;

  const HomePage({
    super.key,
    this.userEmail,
    this.openHaykirOnStart = false,
    this.initialSeyirDefteriDavaId,
    this.initialSeyirDefteriOpenedAt,
    this.initialSeyirDefteriDavaAdi,
    this.initialSeyirDefteriDavaci,
    this.initialSeyirDefteriDaval,
    this.initialSeyirDefteriKategori,
    this.initialSeyirDefteriDavaKonusu,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showLeftIcons =
      false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
  bool isHeaderCollapsed =
      false; // Üst arayüzün küçültülüp küçültülmediğini kontrol eder
  List<Dava> davaList = []; // Kaydedilen davalar listesi
  String? _activeWatchPostId;
  bool _tutorialPromptShown = false;

  // Seyir Defteri akışında dava postları için collapse durumu (postId bazlı)
  final Map<String, bool> _davaShareCollapsedByPostId = <String, bool>{};

  // Home feed için sayfalama controller'ları
  static const int _homeFeedPageSize = 20;
  final PagingController<int, Map<String, dynamic>> _homeFeedPagingController =
      PagingController<int, Map<String, dynamic>>(firstPageKey: 0);
  final RefreshController _homeFeedRefreshController =
      RefreshController(initialRefresh: false);
  bool _highlightIncomingIcon = false; // Gelen davalar ikonu için yanıp sönme efekti
  bool _hasIncomingDavaForBlink = false; // Yanıp sönme gerektiren gelen dava var mı?
  Timer? _incomingIconBlinkTimer; // Gelen davalar ikonunun blink timer'ı

  @override
  void initState() {
    super.initState();
    // Provider initialize -> post-frame'e al, build sirasinda notifyListeners tetiklenmesin
    _homeFeedPagingController.addPageRequestListener(_fetchHomeFeedPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  /// Provider'ları başlat ve verileri yükle
  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final davaProvider = Provider.of<DavaProvider>(context, listen: false);

    // AuthProvider'ı başlat
    await authProvider.initialize();

    // Kullanıcı verilerini yükle
    if (widget.userEmail != null) {
      await davaProvider.loadUserData(widget.userEmail!);
    }

    // Eski veri yükleme metodlarını çağır (geçiş için)
    _loadSavedDavalar();

    if (widget.openHaykirOnStart) {
      await _maybeOpenHaykirAfterLogin();
    } else {
      // Onboarding: Günün Davası (sanal dava) - kullanıcı ilk girişte hüküm versin
      await _maybeShowTutorialCaseAfterLogin();
    }
  }

  Future<void> _maybeOpenHaykirAfterLogin() async {
    final email = (widget.userEmail ?? '').trim();
    if (email.isEmpty) return;

    // Haykır akışında tutorial'ı bu oturumda gösterme
    _tutorialPromptShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HaykirPage(
            userEmail: email,
            initialShowForm: true,
          ),
        ),
      );
    });
  }

  Future<void> _maybeShowTutorialCaseAfterLogin() async {
    if (_tutorialPromptShown) return;
    final email = (widget.userEmail ?? '').trim();
    if (email.isEmpty) return;

    // Aynı session içinde tekrar göstermeyi engelle
    _tutorialPromptShown = true;

    try {
      final completed = await TutorialCasePage.isCompletedForUser(email);
      if (completed) return;

      // Ekran hazır olduktan sonra aç
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TutorialCasePage(
              isAuthenticated: true,
              userEmail: email,
            ),
          ),
        );
      });
    } catch (_) {
      // Sessizce geç
    }
  }

  /// Home feed widget'�n� olu�turur
  Widget _buildHomeFeed(List<Map<String, dynamic>> homeFeedPosts) {
    if (homeFeedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Dava Aç',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.successColor, // Huzur verici yeşil
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ', ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'Haykır',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.calmGreenDark, // Koyu huzur verici yeşil
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ', ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'Kitlelere Ulaş',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.successLightColor, // Açık başarı yeşili
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ', ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'Sesini Duyur',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.calmGreen, // Huzur verici açık yeşil
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SmartRefresher(
      controller: _homeFeedRefreshController,
      enablePullDown: true,
      onRefresh: _onHomeFeedRefresh,
      child: PagedListView<int, Map<String, dynamic>>(
        pagingController: _homeFeedPagingController,
        padding: EdgeInsets.zero,
        builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
          itemBuilder: (context, item, index) {
            final davaProvider =
                Provider.of<DavaProvider>(context, listen: false);
            final postId = item['id']?.toString() ?? 'post_$index';
            return KeyedSubtree(
              key: ValueKey(postId),
              child: _buildHomeFeedPost(item, davaProvider),
            );
          },
          firstPageProgressIndicatorBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
          newPageProgressIndicatorBuilder: (context) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          noMoreItemsIndicatorBuilder: (context) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Hepsi bu kadar 🎉',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
          firstPageErrorIndicatorBuilder: (context) => _buildPagingError(
            onRetry: _homeFeedPagingController.refresh,
          ),
          newPageErrorIndicatorBuilder: (context) => _buildPagingError(
            onRetry: _homeFeedPagingController.retryLastFailedRequest,
          ),
        ),
      ),
    );
  }

  /// Home feed için yeni sayfa çeker
  Future<void> _fetchHomeFeedPage(int pageKey) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      final userEmail =
          (widget.userEmail ?? authProvider.currentUser?.email ?? '').trim();

      if (userEmail.isEmpty) {
        _homeFeedPagingController.error = 'Kullanıcı bulunamadı';
        return;
      }

      final newItems = davaProvider.fetchHomeFeedPaged(
        userEmail: userEmail,
        pageKey: pageKey,
        pageSize: _homeFeedPageSize,
      );

      final isLastPage = newItems.length < _homeFeedPageSize;
      if (isLastPage) {
        _homeFeedPagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _homeFeedPagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _homeFeedPagingController.error = error;
    }
  }

  /// Home feed'i yukarı çekerek tamamen yeniler
  Future<void> _onHomeFeedRefresh() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      final userEmail =
          (widget.userEmail ?? authProvider.currentUser?.email ?? '').trim();

      if (userEmail.isNotEmpty) {
        await davaProvider.refreshAll();
      }

      _homeFeedPagingController.refresh();
      _homeFeedRefreshController.refreshCompleted();
    } catch (_) {
      _homeFeedRefreshController.refreshFailed();
    }
  }

  /// Paged list hata widget'ı
  Widget _buildPagingError({required VoidCallback onRetry}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Veriler yüklenirken bir hata oluştu',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _incomingIconBlinkTimer?.cancel();
    _homeFeedPagingController.dispose();
    _homeFeedRefreshController.dispose();
    super.dispose();
  }

  /// Gelen dava varlığını baz alarak sol menü ikonunda yanıp sönmeyi yönetir.
  void _updateIncomingIconBlinkState(bool shouldBlink) {
    if (_hasIncomingDavaForBlink == shouldBlink) return;
    _hasIncomingDavaForBlink = shouldBlink;
    _incomingIconBlinkTimer?.cancel();

    if (!shouldBlink) {
      if (mounted) {
        setState(() {
          _highlightIncomingIcon = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _highlightIncomingIcon = true;
      });
    }

    _incomingIconBlinkTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_hasIncomingDavaForBlink) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _highlightIncomingIcon = false;
          });
        }
        return;
      }
      setState(() {
        _highlightIncomingIcon = !_highlightIncomingIcon;
      });
    });
  }

  /// Tek bir home feed post'unu olu�turur
  Widget _buildHomeFeedPost(
      Map<String, dynamic> post, DavaProvider davaProvider) {
    // G�venli okuma: d�� kaynaklardan gelen Map t�rleri _Map<dynamic,dynamic> olabilir
    final safePost = asStringDynamicMap(post);
    final type = safePost['type'] ?? '';
    final payload = asStringDynamicMap(safePost['payload']);
    final authorEmail = safePost['authorEmail'] ?? '';

    if (type == 'user_post') {
      // Twitter/X benzeri kullanıcı postu
      return TwitterPostCard(
        post: post,
        viewerEmail: widget.userEmail,
        onPostUpdated: () {
          if (mounted) {
            _homeFeedPagingController.refresh();
          }
        },
        onLike: () async {
          final updatedPost = Map<String, dynamic>.from(post);
          final currentLiked = updatedPost['payload']['userLiked'] ?? false;

          if (currentLiked) {
            updatedPost['payload']['likes'] =
                (updatedPost['payload']['likes'] ?? 1) - 1;
            updatedPost['payload']['userLiked'] = false;
          } else {
            updatedPost['payload']['likes'] =
                (updatedPost['payload']['likes'] ?? 0) + 1;
            updatedPost['payload']['userLiked'] = true;
          }

          await davaProvider.updateHomeFeedPost(post['id'], updatedPost);
          if (mounted) {
            _homeFeedPagingController.refresh();
          }
        },
        onRetweet: () async {
          final updatedPost = Map<String, dynamic>.from(post);
          final currentRetweeted =
              updatedPost['payload']['userRetweeted'] ?? false;

          if (currentRetweeted) {
            updatedPost['payload']['retweets'] =
                (updatedPost['payload']['retweets'] ?? 1) - 1;
            updatedPost['payload']['userRetweeted'] = false;
          } else {
            updatedPost['payload']['retweets'] =
                (updatedPost['payload']['retweets'] ?? 0) + 1;
            updatedPost['payload']['userRetweeted'] = true;
          }

          await davaProvider.updateHomeFeedPost(post['id'], updatedPost);
          if (mounted) {
            _homeFeedPagingController.refresh();
          }
        },
        onComment: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💬 Yorum özelliği yakında!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onShare: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📤 Paylaşım özelliği yakında!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    } else if (type == 'dava_share') {
      // Dava verilerini FiveCardCaseInformation için hazırla
      final davaId = (payload['davaId'] ?? payload['id'])?.toString() ?? '';
      final davaData = <String, dynamic>{
        'id': davaId,
        'davaId': davaId,
        'adi': payload['davaAdi'] ?? 'Dava Adı',
        'davaAdi': payload['davaAdi'] ?? 'Dava Adı',
        'davaci': payload['davaci']?.toString() ?? 'Davacı',
        'davali': payload['davali']?.toString() ?? 'Davalı',
        'kategori': payload['davaKategori']?.toString() ??
            payload['kategori']?.toString() ??
            payload['davaKategorisi']?.toString() ??
            '',
        'davaKonusu': payload['davaKonusu'] ?? 'Dava Konusu',
        'openedAt': payload['openedAt']?.toString(),
        'createdAt': payload['createdAt']?.toString(),
        'acceptedAt': payload['acceptedAt']?.toString(),
        'profilResmi':
            payload['profilResmi'] ?? 'lib/icons/07_profil_picture_davaci.png',
        'mevkii': payload['mevkii']?.toString() ?? 'Katılımcı',
        'userEmail': payload['userEmail'] ?? authorEmail,
      };

      final postId = safePost['id']?.toString() ?? '';
      final collapsed = _davaShareCollapsedByPostId[postId] ?? true;

      DateTime? openedAt;
      final openedAtStr = davaData['openedAt']?.toString();
      if (openedAtStr != null && openedAtStr.isNotEmpty) {
        openedAt = DateTime.tryParse(openedAtStr);
      }

      // Akışta post gibi görünüm + sağa kaydırınca sil
      return Dismissible(
        key: Key('dava_share_${postId.isEmpty ? post['id'] : postId}'),
        direction: DismissDirection.startToEnd, // Sağa kaydır (sil)
        dragStartBehavior: DragStartBehavior.down,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Sil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          // Onay dialogu göster
          return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Seyir Defterinden Kaldır'),
                    content: Text(
                        'Bu davayı seyir defterinizden kaldırmak istediğinize emin misiniz?\n\n"${davaData['davaAdi'] ?? 'Dava'}"'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('İptal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Kaldır'),
                      ),
                    ],
                  );
                },
              ) ??
              false;
        },
        onDismissed: (direction) async {
          // Dismissible kuralı: item UI listesinden anında kaldırılmalı.
          if (postId.isNotEmpty) {
            final current = List<Map<String, dynamic>>.from(
              _homeFeedPagingController.itemList ?? const <Map<String, dynamic>>[],
            );
            current.removeWhere((p) => (p['id']?.toString() ?? '') == postId);
            _homeFeedPagingController.itemList = current;
          }

          // Sonra kalıcı kayıttan sil (async).
          if (widget.userEmail != null) {
            try {
              final ok = await davaProvider.removeHomeFeedPost(postId.isNotEmpty ? postId : post['id']?.toString() ?? '');
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '✅ "${davaData['davaAdi'] ?? 'Dava'}" seyir defterinizden kaldırıldı'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              print('❌ Seyir defterinden kaldırma hatası: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Hata: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              // Hata durumunda listeyi tekrar yüklemek en güvenlisi
              _homeFeedPagingController.refresh();
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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
              davaId: davaId,
              userEmail: widget.userEmail,
              davaAdi: davaData['davaAdi']?.toString(),
              davaci: davaData['davaci']?.toString(),
              davali: davaData['davali']?.toString(),
              kategori: davaData['kategori']?.toString(),
              davaKonusu: davaData['davaKonusu']?.toString(),
              openedAt: openedAt,
              collapsed: collapsed,
              onToggleCollapse: postId.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _davaShareCollapsedByPostId[postId] = !collapsed;
                      });
                    },
              feedPostId: postId.isEmpty ? null : postId,
              sourceAuthorEmail: post['authorEmail']?.toString(),
              onRemove: postId.isEmpty
                  ? null
                  : () => _removeDavaShareFromFeed(
                        context: context,
                        postId: postId,
                        post: post,
                        davaData: davaData,
                        davaProvider: davaProvider,
                      ),
              onClose: () {},
            ),
          ),
        ),
      );
    } else if (type == 'dava_share_old') {
      // Eski ModernDavaCard widget'ı (yedek olarak tutuldu)
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ModernDavaCard(
          userEmail: payload['userEmail'] ?? authorEmail,
          displayName: payload['displayName'] ?? 'Bilinmeyen Kullan�c�',
          davaAdi: payload['davaAdi'] ?? 'Dava Ad�',
          davaKategori: payload['davaKategori']?.toString() ??
              payload['kategori']?.toString() ??
              '',
          davaKonusu: payload['davaKonusu'] ?? 'Dava Konusu',
          davaci: payload['davaci']?.toString(),
          davali: payload['davali']?.toString(),
          davaId: (payload['davaId'] ?? payload['id'])?.toString(),
          isOpened: payload['isOpened'] ?? false,
          yorumSayisi: payload['yorumSayisi'] ?? 0,
          retweetSayisi: payload['retweetSayisi'] ?? 0,
          begeniSayisi: payload['begeniSayisi'] ?? 0,
          begenmemeSayisi: payload['begenmemeSayisi'] ?? 0,
          userLiked: payload['userLiked'] ?? false,
          userDisliked: payload['userDisliked'] ?? false,
          yorumlar: asListOfStringDynamicMap(payload['yorumlar']),
          onSave: () async {
            // Paylaşımı bitir ve kaldır
            final davaId = payload['davaId'] ?? payload['id'];
            if (davaId != null && widget.userEmail != null) {
              // Home feed'den bu postu kaldır (isFinished işaretleyerek)
              final updatedPost = Map<String, dynamic>.from(post);
              updatedPost['payload']['isFinished'] = true;
              updatedPost['payload']['finishedAt'] =
                  DateTime.now().toIso8601String();

              await davaProvider.updateHomeFeedPost(post['id'], updatedPost);

              // Yenile
              await davaProvider.refreshAll();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '✅ Paylaşım bitirildi: ${payload['davaAdi'] ?? 'Dava'}'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          onOpen: () {
            // Dava detaylar�n� a�
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('? Dava detaylar� a��l�yor...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onDelilEkle: () {
            // Delil ekle
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('? Delil ekleme sayfas� a��l�yor...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onYorum: (yorumMetni,
              {String? parentCommentId, bool isGizliTanik = false}) async {
            final davaId = payload['davaId'] ?? payload['id'];
            final existingComments = CommentUtils.normalizeComments(
              post['payload']['yorumlar'] ?? [],
            );

            String userName = widget.userEmail ?? 'Bilinmeyen Kullanıcı';
            if (isGizliTanik) {
              userName = HiveDatabaseService.gizliTanikDisplayName;
            } else if (widget.userEmail != null) {
              final user =
                  HiveDatabaseService.getRegistrationByEmail(widget.userEmail!);
              userName = user?.judgeName ?? widget.userEmail!.split('@')[0];
            }

            final yeniYorum = {
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'userName': userName,
              'userEmail': widget.userEmail,
              'yorum': yorumMetni,
              'tarih': DateTime.now().toString().substring(0, 19),
              'begeniSayisi': 0,
              'isGizliTanik': isGizliTanik,
              'parentId': parentCommentId,
              'replies': <Map<String, dynamic>>[],
            };

            final updatedPost = Map<String, dynamic>.from(post);
            final updatedComments =
                CommentUtils.addComment(existingComments, yeniYorum);

            updatedPost['payload']['yorumlar'] = updatedComments;
            updatedPost['payload']['yorumSayisi'] =
                CommentUtils.countAllComments(updatedComments);

            // Veritabanına kaydet (HomeFeedPost)
            await davaProvider.updateHomeFeedPost(post['id'], updatedPost);

            // Eğer bu paylaşımın sahibi kullanıcıysa, invitation'ı da güncelle
            try {
              if (davaId != null && widget.userEmail != null) {
                // İlgili invitation'ı bul ve güncelle
                final invitations =
                    HiveDatabaseService.getInvitations(widget.userEmail!);
                final invitationIndex = invitations.indexWhere((inv) =>
                    (inv['davaId']?.toString() ?? inv['id']?.toString()) ==
                    davaId.toString());

                if (invitationIndex != -1) {
                  final invitation =
                      Map<String, dynamic>.from(invitations[invitationIndex]);
                  final invYorumlar = CommentUtils.normalizeComments(
                    invitation['yorumlar'] ?? [],
                  );
                  final updatedInvComments =
                      CommentUtils.addComment(invYorumlar, yeniYorum);
                  invitation['yorumlar'] = updatedInvComments;
                  invitation['yorumSayisi'] =
                      CommentUtils.countAllComments(updatedInvComments);

                  HiveDatabaseService.addInvitation(
                      widget.userEmail!, invitation);
                  print('✅ Yorum invitation\'da da güncellendi: $davaId');
                }
              }
            } catch (e) {
              print('⚠️ Invitation güncelleme hatası: $e');
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '💬 Yorum eklendi: "$yorumMetni"${isGizliTanik ? ' (Gizli Tanık olarak)' : ''}'),
                backgroundColor: Colors.green[600],
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onRetweet: () async {
            // Retweet say�s�n� art�r - Provider kullanarak
            final updatedPost = Map<String, dynamic>.from(post);
            final currentRetweeted =
                updatedPost['payload']['userRetweeted'] ?? false;

            if (currentRetweeted) {
              // Retweet kaldır
              updatedPost['payload']['retweetSayisi'] =
                  (updatedPost['payload']['retweetSayisi'] ?? 1) - 1;
              updatedPost['payload']['userRetweeted'] = false;
            } else {
              // Retweet ekle
              updatedPost['payload']['retweetSayisi'] =
                  (updatedPost['payload']['retweetSayisi'] ?? 0) + 1;
              updatedPost['payload']['userRetweeted'] = true;
            }

            await davaProvider.updateHomeFeedPost(post['id'], updatedPost);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('? Payla��m yeniden payla��ld�!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onBegeni: () async {
            // Be�eni say�s�n� art�r - Provider kullanarak
            final updatedPost = Map<String, dynamic>.from(post);
            final currentLiked = updatedPost['payload']['userLiked'] ?? false;
            final currentDisliked =
                updatedPost['payload']['userDisliked'] ?? false;

            if (currentLiked) {
              // Beğeniyi kaldır
              updatedPost['payload']['begeniSayisi'] =
                  (updatedPost['payload']['begeniSayisi'] ?? 1) - 1;
              updatedPost['payload']['userLiked'] = false;
            } else {
              // Beğeni ekle
              if (currentDisliked) {
                // Eğer daha önce beğenmeme seçilmişse, beğenmeme sayısını azalt
                updatedPost['payload']['begenmemeSayisi'] =
                    (updatedPost['payload']['begenmemeSayisi'] ?? 1) - 1;
                updatedPost['payload']['userDisliked'] = false;
              }
              updatedPost['payload']['begeniSayisi'] =
                  (updatedPost['payload']['begeniSayisi'] ?? 0) + 1;
              updatedPost['payload']['userLiked'] = true;
            }

            await davaProvider.updateHomeFeedPost(post['id'], updatedPost);

            // Invitation'ı da güncelle
            try {
              final davaId = payload['davaId'] ?? payload['id'];
              if (davaId != null && widget.userEmail != null) {
                final invitations =
                    HiveDatabaseService.getInvitations(widget.userEmail!);
                final invitationIndex = invitations.indexWhere((inv) =>
                    (inv['davaId']?.toString() ?? inv['id']?.toString()) ==
                    davaId.toString());

                if (invitationIndex != -1) {
                  final invitation =
                      Map<String, dynamic>.from(invitations[invitationIndex]);
                  invitation['begeniSayisi'] =
                      updatedPost['payload']['begeniSayisi'];
                  invitation['begenmemeSayisi'] =
                      updatedPost['payload']['begenmemeSayisi'];
                  invitation['userLiked'] = updatedPost['payload']['userLiked'];
                  invitation['userDisliked'] =
                      updatedPost['payload']['userDisliked'];

                  HiveDatabaseService.addInvitation(
                      widget.userEmail!, invitation);
                }
              }
            } catch (e) {
              print('⚠️ Invitation güncelleme hatası: $e');
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('? Be�enildi!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onBegenmeme: () async {
            // Be�enmeme say�s�n� art�r - Provider kullanarak
            final updatedPost = Map<String, dynamic>.from(post);
            final currentLiked = updatedPost['payload']['userLiked'] ?? false;
            final currentDisliked =
                updatedPost['payload']['userDisliked'] ?? false;

            if (currentDisliked) {
              // Beğenmeme kaldır
              updatedPost['payload']['begenmemeSayisi'] =
                  (updatedPost['payload']['begenmemeSayisi'] ?? 1) - 1;
              updatedPost['payload']['userDisliked'] = false;
            } else {
              // Beğenmeme ekle
              if (currentLiked) {
                // Eğer daha önce beğeni seçilmişse, beğeni sayısını azalt
                updatedPost['payload']['begeniSayisi'] =
                    (updatedPost['payload']['begeniSayisi'] ?? 1) - 1;
                updatedPost['payload']['userLiked'] = false;
              }
              updatedPost['payload']['begenmemeSayisi'] =
                  (updatedPost['payload']['begenmemeSayisi'] ?? 0) + 1;
              updatedPost['payload']['userDisliked'] = true;
            }

            await davaProvider.updateHomeFeedPost(post['id'], updatedPost);

            // Invitation'ı da güncelle
            try {
              final davaId = payload['davaId'] ?? payload['id'];
              if (davaId != null && widget.userEmail != null) {
                final invitations =
                    HiveDatabaseService.getInvitations(widget.userEmail!);
                final invitationIndex = invitations.indexWhere((inv) =>
                    (inv['davaId']?.toString() ?? inv['id']?.toString()) ==
                    davaId.toString());

                if (invitationIndex != -1) {
                  final invitation =
                      Map<String, dynamic>.from(invitations[invitationIndex]);
                  invitation['begeniSayisi'] =
                      updatedPost['payload']['begeniSayisi'];
                  invitation['begenmemeSayisi'] =
                      updatedPost['payload']['begenmemeSayisi'];
                  invitation['userLiked'] = updatedPost['payload']['userLiked'];
                  invitation['userDisliked'] =
                      updatedPost['payload']['userDisliked'];

                  HiveDatabaseService.addInvitation(
                      widget.userEmail!, invitation);
                }
              }
            } catch (e) {
              print('⚠️ Invitation güncelleme hatası: $e');
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('? Be�enilmedi!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    } else if (type == 'dava_watch') {
      return _buildDavaWatchCard(post, payload);
    } else if (type == 'haykir') {
      // ✅ Adım 3: Haykır tipini görüntüleme widget'ı
      return _buildHaykirCard(post, payload, davaProvider);
    }
    // Diğer post tipleri için varsayılan widget
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        'Bilinmeyen post tipi: $type',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildDavaWatchCard(
    Map<String, dynamic> post,
    Map<String, dynamic> payload,
  ) {
    final String rawState =
        (payload['watchState'] ?? '').toString().toLowerCase();
    final bool isWatching = rawState == 'on' || payload['isWatching'] == true;
    final String fallbackLabel = isWatching
        ? 'ON'
        : (rawState.isNotEmpty
            ? rawState
                .substring(0, rawState.length >= 2 ? 2 : rawState.length)
                .toUpperCase()
            : 'OF');
    final String stateLabel =
        (payload['watchStateLabel'] ?? fallbackLabel).toString();
    final String caseName =
        (payload['davaAdi'] ?? 'Dava Adı Belirtilmemiş').toString();
    final String dateText = _formatWatchDate(
      payload['openedAt']?.toString(),
      payload['stateChangedAt']?.toString(),
    );
    const Color accentColor = Color(0xFF9C27B0);
    final Color frameColor = isWatching ? accentColor : Colors.grey.shade400;
    final Color badgeFill =
        isWatching ? const Color(0xFFE8F5E9) : Colors.grey.shade100;
    final Color badgeBorder =
        isWatching ? const Color(0xFF66BB6A) : Colors.grey.shade300;
    final Color stateTextColor =
        isWatching ? const Color(0xFF2E7D32) : Colors.grey.shade600;
    // Kullanıcı email'ini al ve profil resmini Hive'dan oku
    final String? userEmail =
        payload['userEmail']?.toString() ?? widget.userEmail;
    final ImageProvider<Object> avatarProvider = _resolveAvatarImage(
      payload['profilResmi']?.toString(),
      userEmail: userEmail,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: frameColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: frameColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatarProvider,
            child: null, // backgroundImage varsa child gösterilmez
            onBackgroundImageError: (exception, stackTrace) {
              // Resim yüklenemezse varsayılan ikonu göster
              print('⚠️ Avatar resim yükleme hatası: $exception');
            },
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeBorder),
            ),
            child: Text(
              dateText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              caseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _handleWatchCloseIcon(post, payload),
            borderRadius: BorderRadius.circular(16),
            child: const Icon(
              Icons.close_sharp,
              color: Color(0xFFE53935),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _handleWatchCardToggle(post, payload),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isWatching ? const Color(0xFFFFF3E0) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isWatching
                      ? const Color(0xFFFFB74D)
                      : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: Text(
                stateLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: stateTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWatchCardToggle(
    Map<String, dynamic> post,
    Map<String, dynamic> payload,
  ) async {
    final postId = post['id']?.toString() ?? '';
    if (postId.isEmpty) return;

    final davaProvider = Provider.of<DavaProvider>(context, listen: false);
    final bool isCurrentlyWatching =
        (payload['watchState']?.toString().toLowerCase() == 'on') ||
            (payload['isWatching'] == true);

    if (isCurrentlyWatching) {
      await _setWatchState(davaProvider, post, payload, isWatching: false);
      if (_activeWatchPostId == postId) {
        _activeWatchPostId = null;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).maybePop();
        }
      }
      return;
    }

    await _setWatchState(davaProvider, post, payload, isWatching: true);
    _activeWatchPostId = postId;

    try {
      await _openWatchModal(payload);
    } finally {
      _activeWatchPostId = null;
      await _setWatchState(davaProvider, post, payload, isWatching: false);
    }
  }

  Future<void> _handleWatchCloseIcon(
    Map<String, dynamic> post,
    Map<String, dynamic> payload,
  ) async {
    final postId = post['id']?.toString() ?? '';
    if (postId.isEmpty) return;

    if (_activeWatchPostId == postId) {
      _activeWatchPostId = null;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _setWatchState(
    DavaProvider provider,
    Map<String, dynamic> post,
    Map<String, dynamic> payload, {
    required bool isWatching,
  }) async {
    final postId = post['id']?.toString();
    if (postId == null) return;

    final updatedPost = Map<String, dynamic>.from(post);
    final updatedPayload = Map<String, dynamic>.from(payload);

    final stateIso = DateTime.now().toIso8601String();
    updatedPayload['isWatching'] = isWatching;
    updatedPayload['watchState'] = isWatching ? 'on' : 'off';
    updatedPayload['watchStateLabel'] = isWatching ? 'ON' : 'OF';
    updatedPayload['stateChangedAt'] = stateIso;

    updatedPost['payload'] = updatedPayload;

    await provider.updateHomeFeedPost(postId, updatedPost);

    payload
      ..clear()
      ..addAll(updatedPayload);
  }

  Future<void> _removeDavaShareFromFeed({
    required BuildContext context,
    required String postId,
    required Map<String, dynamic> post,
    required Map<String, dynamic> davaData,
    required DavaProvider davaProvider,
  }) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Seyir Defterinden Kaldır'),
              content: Text(
                'Bu davayı seyir defterinizden kaldırmak istediğinize emin misiniz?\n\n"${davaData['davaAdi'] ?? 'Dava'}"',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kaldır'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) return;

    if (postId.isNotEmpty) {
      final current = List<Map<String, dynamic>>.from(
        _homeFeedPagingController.itemList ?? const <Map<String, dynamic>>[],
      );
      current.removeWhere((p) => (p['id']?.toString() ?? '') == postId);
      _homeFeedPagingController.itemList = current;
    }

    if (widget.userEmail != null) {
      try {
        final ok = await davaProvider.removeHomeFeedPost(
          postId.isNotEmpty ? postId : post['id']?.toString() ?? '',
        );
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ "${davaData['davaAdi'] ?? 'Dava'}" seyir defterinizden kaldırıldı',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('❌ Seyir defterinden kaldırma hatası: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          _homeFeedPagingController.refresh();
        }
      }
    }
  }

  Future<void> _openWatchModal(Map<String, dynamic> payload) async {
    final davaId = (payload['davaId'] ?? payload['id'])?.toString() ?? '';
    final String? userEmail =
        payload['userEmail']?.toString() ?? widget.userEmail;
    DateTime? openedAt;
    final openedAtStr = payload['openedAt']?.toString();
    if (openedAtStr != null && openedAtStr.isNotEmpty) {
      openedAt = DateTime.tryParse(openedAtStr);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (sheetContext, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: SingleChildScrollView(
                controller: scrollController,
                child: IlgililerinSeyirDefteriWidgeti(
                  davaId: davaId,
                  userEmail: userEmail,
                  davaAdi: payload['davaAdi']?.toString(),
                  davaci: payload['davaci']?.toString(),
                  davali: payload['davali']?.toString(),
                  kategori: payload['kategori']?.toString() ??
                      payload['davaKategori']?.toString(),
                  davaKonusu: payload['davaKonusu']?.toString(),
                  openedAt: openedAt,
                  onClose: () => Navigator.of(modalContext).maybePop(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  ImageProvider<Object> _resolveAvatarImage(String? path, {String? userEmail}) {
    // Önce Hive'dan kullanıcının profil resmi URL'sini kontrol et
    if (userEmail != null && userEmail.isNotEmpty) {
      final settings = HiveDatabaseService.getSettings(userEmail);
      final profileImageUrl = settings?.profileImageUrl;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        // Base64 string kontrolü (data:image/jpeg;base64,... formatı)
        if (profileImageUrl.startsWith('data:image')) {
          try {
            final parts = profileImageUrl.split(',');
            if (parts.length >= 2) {
              final base64String = parts[1];
              final bytes = base64Decode(base64String);
              if (bytes.isNotEmpty) {
                return MemoryImage(bytes) as ImageProvider<Object>;
              }
            }
          } catch (e) {
            print('⚠️ Base64 decode hatası: $e');
          }
        }
        // Network URL
        if (profileImageUrl.startsWith('http://') ||
            profileImageUrl.startsWith('https://')) {
          return NetworkImage(profileImageUrl) as ImageProvider<Object>;
        }
      }
    }

    // Eğer Hive'da profil resmi yoksa, path parametresini kullan
    if (path == null || path.isEmpty) {
      return const AssetImage('lib/icons/07_profil_picture_davaci.png');
    }
    if (path.startsWith('http') || path.startsWith('https')) {
      return NetworkImage(path) as ImageProvider<Object>;
    }
    return AssetImage(path) as ImageProvider<Object>;
  }

  String _formatWatchDate(String? primaryIso, String? fallbackIso) {
    DateTime? parsed;
    if (primaryIso != null && primaryIso.isNotEmpty) {
      parsed = DateTime.tryParse(primaryIso);
    }
    if (parsed == null && fallbackIso != null && fallbackIso.isNotEmpty) {
      parsed = DateTime.tryParse(fallbackIso);
    }
    parsed ??= DateTime.now();
    final String day = parsed.day.toString().padLeft(2, '0');
    final String month = parsed.month.toString().padLeft(2, '0');
    final String year = parsed.year.toString();
    return '$day.$month.$year';
  }

  // Kaydedilen davaları yükle
  void _loadSavedDavalar() {
    // Eski davaları yükle
    setState(() {
      davaList = [
        Dava(
          adi: "Örnek Dava 1",
          davali: "Örnek Davalı 1",
          mevkii: "Davalı",
          kalanSure: "27.03.2024",
          profilResmi: "lib/icons/07_profil_picture_davaci.png",
          isOpened: true,
        ),
        Dava(
          adi: "Örnek Dava 2",
          davali: "Örnek Davalı 2",
          mevkii: "Davalı",
          kalanSure: "26.03.2024",
          profilResmi: "lib/icons/07_profil_picture_davaci.png",
          isOpened: false,
        ),
      ];
    });
  }

  /// Kullanıcının admin yetkisi olup olmadığını kontrol eder

  /// Açtığım davalar dialog'unu göster
  // ignore: unused_element
  void _showActigimDavalarDialog() {
    // Açılan davaları ve beklemede davaları al
    final List<Map<String, dynamic>> openedDavalar =
        HiveDatabaseService.getOpenedDavalar();
    final List<Map<String, dynamic>> savedDavalar =
        HiveDatabaseService.getSavedDavalar();

    // Tüm davaları birleştir
    final List<Map<String, dynamic>> allDavalar = [
      ...openedDavalar,
      ...savedDavalar
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.green.withOpacity(0.05),
                  Colors.blue.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade600,
                        Colors.blue.shade600,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.gavel,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Açtığım Davalar',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${allDavalar.length} dava bulundu',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close Button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  child: allDavalar.isEmpty
                      ? _buildEmptyState()
                      : _buildDavalarList(context, allDavalar),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gavel_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz Dava Açmadınız',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDavalarList(
      BuildContext context, List<Map<String, dynamic>> davalar) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: davalar.length,
        itemBuilder: (context, index) {
          final dava = davalar[index];
          final isOpened = dava['isOpened'] ?? false;
          final isBeklemede = dava['davaAdi'] == 'Beklemede';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  isOpened
                      ? Colors.green.withOpacity(0.02)
                      : Colors.orange.withOpacity(0.02),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Sadece beklemede davalar için düzenleme moduna geç
                  if (isBeklemede && !isOpened) {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => dava_ac.DavaAcPage(
                          userEmail: widget.userEmail,
                          editDava: dava_model.Dava.fromMap(dava),
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Status Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isOpened
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isOpened ? Icons.check_circle : Icons.schedule,
                              color: isOpened
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Dava Adı
                          Expanded(
                            child: Text(
                              dava['davaAdi'] ?? 'Dava Adı Belirtilmemiş',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOpened
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOpened ? 'Açıldı' : 'Beklemede',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOpened
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Dava Details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            if (dava['davaci']?.isNotEmpty == true)
                              _buildDetailRow('👨‍⚖️ Davacı', dava['davaci']),
                            if (dava['davali']?.isNotEmpty == true)
                              _buildDetailRow('👤 Davalı', dava['davali']),
                            // Kategori için farklı alan isimlerini kontrol et
                            if ((dava['davaKategori']?.toString().isNotEmpty ==
                                    true) ||
                                (dava['kategori']?.toString().isNotEmpty ==
                                    true) ||
                                (dava['davaKategorisi']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true))
                              _buildDetailRow(
                                  '📋 Kategori',
                                  dava['davaKategori']?.toString() ??
                                      dava['kategori']?.toString() ??
                                      dava['davaKategorisi']?.toString() ??
                                      ''),
                          ],
                        ),
                      ),

                      if (isBeklemede && !isOpened) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Düzenlemek için tıklayın',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPostOptionsSheet({required bool isAdmin}) async {
    final selectedAction = await showModalBottomSheet<_PostSheetAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                _buildPostTypeOption(
                  icon: Icons.edit_outlined,
                  title: 'Paylaşım Yaz',
                  subtitle: 'Metin ile paylaşım oluştur',
                  onTap: () => Navigator.of(context).pop(_PostSheetAction.text),
                ),
                _buildPostTypeOption(
                  icon: Icons.gavel_outlined,
                  title: 'Dava Aç',
                  subtitle: 'Önce kategori seç, sonra dava aç',
                  onTap: () => Navigator.of(context).pop(_PostSheetAction.dava),
                ),
                _buildPostTypeOption(
                  icon: Icons.campaign_outlined,
                  title: 'Haykır',
                  subtitle: 'Haykırış oluştur ve yayınla',
                  onTap: () =>
                      Navigator.of(context).pop(_PostSheetAction.haykir),
                ),
                _buildPostTypeOption(
                  icon: Icons.poll_outlined,
                  title: 'Anket Paylaş',
                  subtitle: 'Takipçilerin için anket oluştur',
                  onTap: () => Navigator.of(context).pop(_PostSheetAction.poll),
                ),
                if (isAdmin)
                  _buildPostTypeOption(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Paneli',
                    subtitle: 'Yönetim ekranını aç',
                    onTap: () =>
                        Navigator.of(context).pop(_PostSheetAction.admin),
                  ),
                if (!isAdmin)
                  _buildPostTypeOption(
                    icon: Icons.storage_outlined,
                    title: 'Veritabanı Debug',
                    subtitle: 'Debug ekranını aç',
                    onTap: () =>
                        Navigator.of(context).pop(_PostSheetAction.debug),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedAction == null) return;

    if (selectedAction == _PostSheetAction.admin) {
      final adminEmail = widget.userEmail?.trim();
      if (adminEmail == null || adminEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin e-posta bilgisi bulunamadı.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AdminPage(adminEmail: adminEmail),
        ),
      );
      return;
    }

    if (selectedAction == _PostSheetAction.debug) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DatabaseDebugPage(),
        ),
      );
      return;
    }

    if (selectedAction == _PostSheetAction.dava) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CategoryPage(userEmail: widget.userEmail),
        ),
      );
      return;
    }

    if (selectedAction == _PostSheetAction.haykir) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HaykirPage(
            userEmail: widget.userEmail,
            initialShowForm: true,
          ),
        ),
      );
      return;
    }

    ComposerQuickAction quickAction = ComposerQuickAction.text;
    if (selectedAction == _PostSheetAction.poll) {
      quickAction = ComposerQuickAction.poll;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Yeni Paylaşım',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                TwitterPostComposer(
                  userEmail: widget.userEmail,
                  quickAction: quickAction,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF059669)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DavaProvider>(
      builder: (context, authProvider, davaProvider, child) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _showPostOptionsSheet(isAdmin: authProvider.isAdmin),
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            tooltip: 'Yeni paylaşım',
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Üst Arayüz Bölümü - Ok kapalıyken tek satır halinde küçülür
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isHeaderCollapsed ? 40 : null,
                  child: isHeaderCollapsed
                      ? // Tek satır halinde küçültülmüş görünüm - Kompakt UI
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Kompakt WhoBoom logosu
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HomePage(userEmail: widget.userEmail),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF059669), Colors.green],
                                    ),
                                  ),
                                  child: const Text(
                                    'WB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Kompakt arama ikonu
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.search, size: 16),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 4),
                              // Kompakt chat ikonu
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatPage(userEmail: widget.userEmail),
                                    ),
                                  );
                                },
                                child: Icon(
                                  MdiIcons.chatOutline,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Kompakt menü ikonu
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showLeftIcons = !showLeftIcons;
                                  });
                                },
                                child: Icon(
                                  MdiIcons.menuOpen,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Kompakt başlık
                              const Expanded(
                                child: Text(
                                  'SEYİR DEFTERİ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Aç/kapa ok butonu
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isHeaderCollapsed = !isHeaderCollapsed;
                                  });
                                },
                                tooltip: 'Arayüzü Aç',
                              ),
                            ],
                          ),
                        )
                      : // Normal görünüm
                      Column(
                          children: [
                            // ROW 1: WhoBoom, Arama Iconu, Chat Iconu - Adım 1: Padding azaltıldı
                            ZeroWhoboomSearchMessage(
                                userEmail: widget.userEmail),
                            // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu - Adım 2: Vertical padding azaltıldı
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: OneFriendPhoneBellMenu(
                                  userEmail: widget.userEmail),
                            ),
                            // ROW 3: Profil Bölümü - Adım 3: Padding optimize edildi
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 4.0),
                              child:
                                  SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                                userEmail: widget.userEmail,
                                onShowSavedDavalar: () {
                                  // Global utility fonksiyonunu kullan
                                  if (widget.userEmail != null) {
                                    showSavedDavalarDialog(
                                        context, widget.userEmail!);
                                  }
                                },
                              ),
                            ),
                            // ROW 4: Hamburger Iconu, Seyir Defteri Başlığı - Adım 4: Padding azaltıldı
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              child: dava_ac.TreeMenuPageheadlines(
                                title:
                                    " || SEYİR DEFTERİ ||", // HomePage için özel başlık
                                isCollapsed: isHeaderCollapsed,
                                onToggleCollapse: () {
                                  setState(() {
                                    isHeaderCollapsed = !isHeaderCollapsed;
                                  });
                                },
                                onMenuPressed: () {
                                  setState(() {
                                    showLeftIcons = !showLeftIcons;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                ),
                // ROW 5: 6 Icon Solda, Sağda Text Yazma Alanı (Scrollable with ListTile)
                Expanded(
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
                                    // Adım 5: Sol menü ikonlarının padding'leri optimize edildi
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  GelenDavalarPage(
                                                      userEmail:
                                                          widget.userEmail)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 8.0, 8.0, 8.0),
                                        child: Consumer<DavaProvider>(
                                          builder: (context, davaProvider, child) {
                                            final shouldBlink =
                                                davaProvider.incomingDavaCount > 0;
                                            if (_hasIncomingDavaForBlink !=
                                                shouldBlink) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                if (!mounted) return;
                                                _updateIncomingIconBlinkState(
                                                    shouldBlink);
                                              });
                                            }

                                            return AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: _highlightIncomingIcon ||
                                                        _hasIncomingDavaForBlink
                                                    ? Colors.blue.withOpacity(0.08)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _highlightIncomingIcon ||
                                                          _hasIncomingDavaForBlink
                                                      ? Colors.blueAccent
                                                      : Colors.transparent,
                                                  width: _highlightIncomingIcon
                                                      ? 3
                                                      : (_hasIncomingDavaForBlink
                                                          ? 1.5
                                                          : 0),
                                                ),
                                                boxShadow: _highlightIncomingIcon
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.blue
                                                              .withOpacity(0.45),
                                                          blurRadius: 10,
                                                          spreadRadius: 2,
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                              child: Icon(
                                                MdiIcons.briefcaseArrowLeftRight,
                                                size: 24,
                                                color: Colors.black54,
                                              ),
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
                                              builder: (context) => YargilaPage(
                                                  userEmail: widget.userEmail)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_yargila_left_row_icon.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  katildigim_page
                                                      .KatildigimDavalarPage(
                                                          userEmail: widget
                                                              .userEmail)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_left_row_katildigim_davalar_icon.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ActigimDavalarPage(
                                                      userEmail:
                                                          widget.userEmail)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_left_row_actigim_davalar_icon.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DavaciUnlulurPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                HaykirislarimPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_left_row_haykirislarim.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TrendInsightsPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.trendingUp,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SavedHaykirlarPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.bookmarkMultipleOutline,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StatisticsDashboardPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.chartBar,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                HesapGizlilikAyarlariPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.cog,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final shouldLogout =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              title: const Text(
                                                  'Uygulamadan Çıkış'),
                                              content: const Text(
                                                  'Çıkış yapmak istediğinize emin misiniz?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                          dialogContext)
                                                      .pop(false),
                                                  child: const Text('İptal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(
                                                          dialogContext)
                                                      .pop(true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                  child: const Text('Çıkış'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (shouldLogout != true) return;

                                        Provider.of<AuthProvider>(context,
                                                listen: false)
                                            .logout();

                                        if (!context.mounted) return;
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                                '/login', (route) => false);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.logout,
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
                      Expanded(
                        child: Column(
                          children: [
                            // Home feed içerikleri
                            Expanded(
                              child: _buildHomeFeed(davaProvider.homeFeedPosts),
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
        );
      },
    );
  }

  /// ✅ Adım 3: Haykır kartı widget'ı (görseldeki gibi)
  Widget _buildHaykirCard(
    Map<String, dynamic> post,
    Map<String, dynamic> payload,
    DavaProvider davaProvider,
  ) {
    final postId = post['id']?.toString() ??
        'haykir_${DateTime.now().millisecondsSinceEpoch}';
    return HaykirCardWidget(
      key: ValueKey('haykir_$postId'),
      post: post,
      payload: payload,
      davaProvider: davaProvider,
      userEmail: widget.userEmail,
      showCloseButton: true, // ✅ Seyir defterinde X close ikonu göster
      onPostUpdated: () {
        if (mounted) {
          _homeFeedPagingController.refresh();
        }
      },
    );
  }
}

// ✅ Haykır kartı için ayrı StatefulWidget (yorum sistemi için state gerekli)
// ✅ Public yapıldı - haykirislarim_page.dart sayfasında da kullanılacak
class HaykirCardWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final Map<String, dynamic> payload;
  final DavaProvider davaProvider;
  final String? userEmail;
  final bool showCloseButton; // ✅ X close ikonunu göster/gizle
  final VoidCallback? onPostUpdated;

  const HaykirCardWidget({
    super.key,
    required this.post,
    required this.payload,
    required this.davaProvider,
    this.userEmail,
    this.showCloseButton = true, // ✅ Varsayılan olarak göster
    this.onPostUpdated,
  });

  @override
  State<HaykirCardWidget> createState() => _HaykirCardWidgetState();
}

class _HaykirCardWidgetState extends State<HaykirCardWidget>
    with TickerProviderStateMixin {
  bool showComments = false; // ✅ Yorumları göster/gizle
  bool isExpanded = false; // ✅ Seyir defterinde açık/kapalı durumu
  bool _scoringChecked = false; // ✅ Puanlama kontrolü yapıldı mı?
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController =
      TextEditingController(); // ✅ Yorum yazma controller
  late AnimationController
      _hourglassController; // ✅ Hareketli kum saati animasyonu
  late AnimationController _expandController; // ✅ Açılma/kapanma animasyonu
  AnimationController?
      _groupIconController; // ✅ Grup ikonu animasyonu (nullable - hot reload için)

  @override
  void initState() {
    super.initState();
    // ✅ Kum saati animasyonu için controller
    _hourglassController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // ✅ Açılma/kapanma animasyonu için controller
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // ✅ Grup ikonu animasyonu için controller (yanıp sönme efekti)
    _groupIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Daha hızlı yanıp sönme
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _hourglassController.dispose(); // ✅ Dispose
    _expandController.dispose(); // ✅ Dispose
    _groupIconController
        ?.dispose(); // ✅ Dispose (nullable check - hot reload için)
    super.dispose();
  }

  Map<String, dynamic> _copyPostWithPayloadUpdates(
      Map<String, dynamic> payloadUpdates) {
    final updatedPost = Map<String, dynamic>.from(widget.post);
    final payload = Map<String, dynamic>.from(
      updatedPost['payload'] as Map? ?? widget.payload,
    );
    payload.addAll(payloadUpdates);
    updatedPost['payload'] = payload;
    return updatedPost;
  }

  Future<void> _persistPostPayload(Map<String, dynamic> payloadUpdates) async {
    final updatedPost = _copyPostWithPayloadUpdates(payloadUpdates);
    await widget.davaProvider.updateHomeFeedPost(
      widget.post['id']?.toString() ?? '',
      updatedPost,
    );
    widget.onPostUpdated?.call();
  }

  void _refreshInteractionUi({String? haykirId}) {
    if (!mounted) return;
    final id = haykirId ?? widget.payload['haykirId']?.toString() ?? '';
    if (showComments && id.isNotEmpty) {
      _comments = HiveDatabaseService.getHaykirComments(id);
    }
    setState(() {});
  }

  String _formatCommentTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Az önce';
      if (diff.inHours < 1) return '${diff.inMinutes} dk';
      if (diff.inDays < 1) return '${diff.inHours} sa';
      if (diff.inDays < 7) return '${diff.inDays} gün';
      return '${date.day}.${date.month}.${date.year}';
    } catch (_) {
      return '';
    }
  }

  // ✅ Retweet'in devre dışı olup olmadığını kontrol et
  bool _isRetweetDisabled(String haykirId) {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return false;

    final haykirData = HiveDatabaseService.getHaykir(haykirId);
    if (haykirData == null) return false;

    final retweetDisabledUsers =
        List<String>.from(haykirData['retweetDisabledUsers'] ?? []);
    return retweetDisabledUsers.contains(widget.userEmail!);
  }

  // ✅ Retweet'in kalıcı olup olmadığını kontrol et (Grup-19 ile yapılmışsa geri alınamaz)
  bool _isRetweetPermanent(String haykirId) {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return false;

    final haykirData = HiveDatabaseService.getHaykir(haykirId);
    if (haykirData == null) return false;

    final grup19Retweets =
        List<String>.from(haykirData['grup19Retweets'] ?? []);
    return grup19Retweets.contains(widget.userEmail!);
  }

  @override
  Widget build(BuildContext context) {
    final haykirId = widget.payload['haykirId']?.toString() ?? '';
    final adi = widget.payload['adi']?.toString() ?? 'Haykırış';
    final slogan = widget.payload['slogan']?.toString() ?? '';
    final direme = widget.payload['direme']?.toString() ?? '';
    final createdAt = widget.payload['createdAt']?.toString() ??
        widget.post['createdAt']?.toString() ??
        '';

    // Etkileşim istatistiklerini getir
    final stats = HiveDatabaseService.getHaykirInteractionStats(
      haykirId,
      userEmail: widget.userEmail,
    );

    final commentCount = stats['commentCount'] as int? ??
        widget.payload['commentCount'] as int? ??
        0;
    final retweetCount = stats['retweetCount'] as int? ??
        widget.payload['retweetCount'] as int? ??
        0;
    final likeCount =
        stats['likeCount'] as int? ?? widget.payload['likeCount'] as int? ?? 0;
    final kinaCount =
        stats['kinaCount'] as int? ?? widget.payload['kinaCount'] as int? ?? 0;
    final isLiked = stats['isLiked'] as bool? ??
        widget.payload['isLiked'] as bool? ??
        false;
    final isSaved = stats['isSaved'] as bool? ??
        widget.payload['isSaved'] as bool? ??
        false;
    final isKina = stats['isKina'] as bool? ??
        widget.payload['isKina'] as bool? ??
        false; // ✅ Kına durumu
    final isRetweeted =
        stats['isRetweeted'] as bool? ?? false; // ✅ Retweet durumu
    final isCommented =
        stats['isCommented'] as bool? ?? false; // ✅ Yorum durumu

    // ✅ Haykır süresi: 19 saat
    const int totalHours = 19;
    String kalanSure = '$totalHours saat 0 dakika';
    bool isExpired = false;

    if (createdAt.isNotEmpty) {
      try {
        final created = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(created);
        final totalMinutes = (totalHours * 60) - difference.inMinutes;

        if (totalMinutes <= 0) {
          kalanSure = 'Süre doldu';
          isExpired = true;

          // ✅ 19 saat sonunda puanlama kontrolü (sadece bir kez)
          if (!_scoringChecked) {
            _scoringChecked = true;
            _checkAndApplyHaykirScoring(
                    haykirId, likeCount, kinaCount, createdAt)
                .then((_) {
              if (mounted) {
                setState(
                    () {}); // ✅ Widget'ı yeniden build et ki badge görünsün
              }
            });
          }
        } else {
          final remainingHours = totalMinutes ~/ 60;
          final remainingMinutes = totalMinutes % 60;
          kalanSure = '$remainingHours saat $remainingMinutes dakika';
        }
      } catch (e) {
        kalanSure = '$totalHours saat 0 dakika';
      }
    }

    // ✅ Kullanıcının bu haykıra katılıp katılmadığını kontrol et
    bool isParticipated = false;
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      final katildigimHaykirler =
          HiveDatabaseService.getKatildigimHaykirler(widget.userEmail!);
      isParticipated = katildigimHaykirler.any((h) =>
          (h['haykirId']?.toString() ?? h['id']?.toString() ?? '') == haykirId);
    }

    // ✅ Grup ikonu pasif mi? (19 saat geçmişse veya kullanıcı zaten katılmışsa)
    final bool isGroupIconDisabled = isExpired || isParticipated;

    // ✅ Seyir defterinde collapsed durum (sadece Haykır adı)
    if (widget.showCloseButton && !isExpanded) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              isExpanded = true;
              _expandController.forward();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.campaign, size: 24, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adi,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Haykır başarı durumunu kontrol et
    final haykirData = HiveDatabaseService.getHaykir(haykirId);
    final scoringApplied = haykirData?['scoringApplied'] == 'true' ||
        haykirData?['scoringApplied'] == true;
    final isSuccessStr = haykirData?['isSuccess']?.toString();
    final isSuccess = isSuccessStr == 'true';
    final showSuccessBadge =
        isExpired && scoringApplied && isSuccessStr != null;

    return Stack(
      children: [
        Card(
          elevation: isExpanded ? 4 : 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Collapse butonu (seyir defterinde)
                if (widget.showCloseButton && isExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.expand_less, color: Colors.grey[600]),
                        onPressed: () {
                          setState(() {
                            isExpanded = false;
                            _expandController.reverse();
                          });
                        },
                        tooltip: 'Kapat',
                      ),
                      if (widget.showCloseButton)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await widget.davaProvider
                                .removeHomeFeedPost(widget.post['id']);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '✅ Haykır seyir defterinden kaldırıldı'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          tooltip: 'Seyir defterinden kaldır',
                        ),
                    ],
                  ),

                // Haykırış Bilgileri (Mavi arka plan)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign,
                              size: 30, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              adi,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // ✅ Modern Slogan Alanı (Gradient ve Shadow)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade50,
                              Colors.purple.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(MdiIcons.formatQuoteOpen,
                                size: 30, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                slogan,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ✅ Direme Alanı
                      Row(
                        children: [
                          const SizedBox(width: 36),
                          Icon(MdiIcons.flag, size: 28, color: Colors.red),
                          const SizedBox(width: 38),
                          Expanded(
                            child: Text(
                              direme,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 38),
                          // ✅ Belirgin ve hareketli grup ikonu (belirgin yanıp sönme efekti ile) - Tıklanabilir (pasif durumda değilse)
                          GestureDetector(
                            onTap: isGroupIconDisabled
                                ? null
                                : () async {
                                    // ✅ Grup ikonuna tıklandığında haykıra katıl
                                    await _onGroupIconTap(haykirId);
                                  },
                            child: isGroupIconDisabled
                                ? // ✅ Pasif durum: Gri, animasyonsuz, tıklanamaz
                                Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      MdiIcons.accountGroup,
                                      size: 32,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : _groupIconController != null
                                    ? AnimatedBuilder(
                                        animation: _groupIconController!,
                                        builder: (context, child) {
                                          // ✅ Belirgin yanıp sönme efekti için opacity hesaplama (0.2 - 1.0 arası)
                                          // Sinüs dalgası kullanarak daha yumuşak geçiş
                                          final animationValue =
                                              _groupIconController!.value;
                                          final opacity = 0.2 +
                                              (0.8 *
                                                  (0.5 +
                                                      0.5 *
                                                          (math.sin(
                                                              animationValue *
                                                                  2 *
                                                                  math.pi))));
                                          // ✅ Pulse efekti için scale (1.0 - 1.2 arası)
                                          final scale =
                                              1.0 + (animationValue * 0.2);

                                          return Opacity(
                                            opacity: opacity,
                                            child: Transform.scale(
                                              scale: scale,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.shade100,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.purple
                                                          .withOpacity(0.2 +
                                                              (animationValue *
                                                                  0.4)),
                                                      blurRadius: 6 +
                                                          (animationValue * 6),
                                                      spreadRadius: 1 +
                                                          (animationValue * 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  MdiIcons.accountGroup,
                                                  size: 32,
                                                  color: Colors.purple.shade700,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          MdiIcons.accountGroup,
                                          size: 32,
                                          color: Colors.purple.shade700,
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ETKİLEŞİM İSTATİSTİKLERİ (Mor gradient)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade50, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Başlık
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ✅ Dinamik icon: Başarılı için thumb up, Başarısız için thumb down, Henüz süre dolmadıysa chartLine
                          Icon(
                            showSuccessBadge
                                ? (isSuccess
                                    ? MdiIcons.thumbUp
                                    : Icons.thumb_down)
                                : MdiIcons.chartLine,
                            color: showSuccessBadge
                                ? (isSuccess
                                    ? Colors.yellow[800]
                                    : Colors.red[700])
                                : Colors.purple.shade700,
                            size: showSuccessBadge ? 40 : 20,
                          ),
                          const SizedBox(width: 19),
                          Flexible(
                            child: Text(
                              showSuccessBadge
                                  ? (isSuccess
                                      ? 'ETKİLEŞİM BAŞARILI'
                                      : 'ETKİLEŞİM BAŞARISIZ')
                                  : 'ETKİLEŞİM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                                letterSpacing: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 19),
                          // ✅ Süre doldu badge'i
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? (showSuccessBadge
                                      ? (isSuccess
                                          ? Colors.yellow[800]
                                          : Colors.grey
                                              .shade600) // ✅ Başarılı: beğen rengi (kırmızı), Başarısız: kına rengi (gri)
                                      : Colors.grey
                                          .shade600) // ✅ Henüz puanlama yapılmadıysa gri
                                  : Colors.orange
                                      .shade500, // ✅ Aktif durum: turuncu
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isExpired
                                      ? (showSuccessBadge
                                          ? (isSuccess
                                                  ? Colors.red
                                                  : Colors.grey)
                                              .withOpacity(
                                                  0.3) // ✅ Başarılı: kırmızı shadow, Başarısız: gri shadow
                                          : Colors.grey.withOpacity(0.3))
                                      : Colors.orange.withOpacity(
                                          0.3), // ✅ Aktif durum: turuncu shadow
                                  blurRadius: 6,
                                  spreadRadius: 0.5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isExpired)
                                  AnimatedBuilder(
                                    animation: _hourglassController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _hourglassController.value *
                                            2 *
                                            3.14159,
                                        child: const Icon(
                                          Icons.hourglass_empty,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                else
                                  // ✅ Kum saati üzerinde çarpı işareti
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.hourglass_empty,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(1),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  kalanSure,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ✅ Sağda başarılı/başarısız ikonu
                          if (showSuccessBadge) ...[
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // İkonlar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSocialIconButton(
                            icon: MdiIcons.commentOutline,
                            label: 'Yorum',
                            count: commentCount,
                            color: Colors.green,
                            isActive: isCommented ||
                                showComments, // ✅ Kullanıcı yorum yazdıysa veya yorumlar açıksa aktif
                            onTap: () {
                              setState(() {
                                showComments = !showComments;
                                if (showComments && haykirId.isNotEmpty) {
                                  _comments =
                                      HiveDatabaseService.getHaykirComments(
                                          haykirId);
                                }
                              });
                            },
                          ),
                          _buildSocialIconButton(
                            icon: MdiIcons.repeat,
                            label: 'Retw...',
                            count: retweetCount,
                            color: Colors.orange,
                            isActive:
                                isRetweeted, // ✅ Kullanıcı retweet yaptıysa aktif
                            isDisabled: _isRetweetDisabled(haykirId) ||
                                _isRetweetPermanent(haykirId),
                            onTap: (_isRetweetDisabled(haykirId) ||
                                    _isRetweetPermanent(haykirId))
                                ? null
                                : () {
                                    // ✅ Eğer daha önce retweet yapılmışsa
                                    if (isRetweeted) {
                                      // Grup-19 ile yapılmışsa geri alınamaz
                                      if (_isRetweetPermanent(haykirId)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '⚠️ Grup-19 ile yapılan retweet geri alınamaz!'),
                                            duration: Duration(seconds: 3),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }
                                      // Sadece ben ile yapılmışsa geri al
                                      _undoRetweet(haykirId);
                                    } else {
                                      // İlk retweet: Dialog aç
                                      _showRetweetDialog(haykirId);
                                    }
                                  },
                          ),
                          _buildSocialIconButton(
                            icon: isLiked
                                ? MdiIcons.heart
                                : MdiIcons.heartOutline,
                            label: 'Beğen',
                            count: likeCount,
                            color: Colors.red,
                            isActive: isLiked,
                            isDisabled:
                                isExpired, // ✅ Süre dolduğunda devre dışı
                            onTap: isExpired
                                ? null
                                : () async {
                                    if (haykirId.isEmpty ||
                                        widget.userEmail == null ||
                                        widget.userEmail!.isEmpty) {
                                      return;
                                    }

                                    final newIsLiked = !isLiked;

                                    if (newIsLiked && isKina) {
                                      await HiveDatabaseService
                                          .updateHaykirInteractionStats(
                                        haykirId: haykirId,
                                        userEmail: widget.userEmail!,
                                        action: 'kina',
                                      );
                                    }

                                    await HiveDatabaseService
                                        .updateHaykirInteractionStats(
                                      haykirId: haykirId,
                                      userEmail: widget.userEmail!,
                                      isLiked: newIsLiked,
                                    );

                                    final updatedLikeCount = newIsLiked
                                        ? likeCount + 1
                                        : (likeCount > 0 ? likeCount - 1 : 0);

                                    await _persistPostPayload({
                                      'isLiked': newIsLiked,
                                      'likeCount': updatedLikeCount,
                                      'isKina': newIsLiked ? false : isKina,
                                      if (newIsLiked && isKina)
                                        'kinaCount': kinaCount > 0
                                            ? kinaCount - 1
                                            : 0,
                                    });
                                    _refreshInteractionUi(haykirId: haykirId);
                                  },
                          ),
                          _buildSocialIconButton(
                            icon: MdiIcons.handWaveOutline,
                            label: 'Kına',
                            count: kinaCount,
                            color: Colors.grey, // ✅ Gri renk
                            isActive: isKina, // ✅ Aktif durumu
                            isDisabled:
                                isExpired, // ✅ Süre dolduğunda devre dışı
                            onTap: isExpired
                                ? null
                                : () async {
                                    if (haykirId.isEmpty ||
                                        widget.userEmail == null ||
                                        widget.userEmail!.isEmpty) {
                                      return;
                                    }

                                    final newIsKina = !isKina;

                                    if (newIsKina && isLiked) {
                                      await HiveDatabaseService
                                          .updateHaykirInteractionStats(
                                        haykirId: haykirId,
                                        userEmail: widget.userEmail!,
                                        isLiked: false,
                                      );
                                    }

                                    await HiveDatabaseService
                                        .updateHaykirInteractionStats(
                                      haykirId: haykirId,
                                      userEmail: widget.userEmail!,
                                      action: 'kina',
                                    );

                                    final updatedKinaCount = newIsKina
                                        ? kinaCount + 1
                                        : (kinaCount > 0 ? kinaCount - 1 : 0);
                                    final updatedLikeCount = newIsKina && isLiked
                                        ? (likeCount > 0 ? likeCount - 1 : 0)
                                        : likeCount;

                                    await _persistPostPayload({
                                      'isKina': newIsKina,
                                      'kinaCount': updatedKinaCount,
                                      'isLiked': newIsKina ? false : isLiked,
                                      'likeCount': updatedLikeCount,
                                    });
                                    _refreshInteractionUi(haykirId: haykirId);
                                  },
                          ),
                          // Kaydet - ✅ En sağa taşındı
                          _buildSocialIconButton(
                            icon: isSaved
                                ? MdiIcons.bookmark
                                : MdiIcons.bookmarkOutline,
                            label: 'Kaydet',
                            count: 0,
                            color: Colors.purple,
                            isActive: isSaved,
                            onTap: () async {
                              if (haykirId.isEmpty ||
                                  widget.userEmail == null ||
                                  widget.userEmail!.isEmpty) {
                                return;
                              }

                              final newIsSaved = !isSaved;
                              await HiveDatabaseService
                                  .updateHaykirInteractionStats(
                                haykirId: haykirId,
                                userEmail: widget.userEmail!,
                                isSaved: newIsSaved,
                              );

                              if (newIsSaved) {
                                try {
                                  final haykirData =
                                      HiveDatabaseService.getHaykir(haykirId);
                                  if (haykirData != null) {
                                    print(
                                        '✅ Haykır kaydedildi (haykirislarim_page için): $haykirId');
                                  }
                                } catch (e) {
                                  print('⚠️ Haykır kaydedilirken hata: $e');
                                }
                              }

                              const widgetId = 'home_page_Kaydet_bookmark';
                              final currentIcon = newIsSaved
                                  ? MdiIcons.bookmark
                                  : MdiIcons.bookmarkOutline;

                              if (newIsSaved) {
                                HiveDatabaseService.saveWidget(
                                  userEmail: widget.userEmail!,
                                  widgetId: widgetId,
                                  label: 'Kaydet',
                                  iconCodePoint:
                                      currentIcon.codePoint.toString(),
                                  colorValue: Colors.purple.value,
                                  count: 0,
                                  isActive: newIsSaved,
                                  isDisabled: false,
                                  sourcePage: 'home_page',
                                  additionalData: {
                                    'postId':
                                        widget.post['id']?.toString() ?? '',
                                    'haykirId': haykirId,
                                  },
                                );
                              } else {
                                HiveDatabaseService.deleteSavedWidget(
                                  userEmail: widget.userEmail!,
                                  widgetId: widgetId,
                                );
                              }

                              await _persistPostPayload({'isSaved': newIsSaved});
                              _refreshInteractionUi(haykirId: haykirId);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(newIsSaved
                                        ? '✅ Kaydedildi! Kaydedilenler arşivine eklendi.'
                                        : '❌ Kayıt kaldırıldı!'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.purple,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),

                      // ✅ Yorumlar bölümü
                      if (showComments) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: InputDecoration(
                                        hintText: 'Yorumunuzu yazın...',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.green),
                                    onPressed: () async {
                                      if (_commentController.text
                                          .trim()
                                          .isEmpty) {
                                        return;
                                      }
                                      if (haykirId.isEmpty ||
                                          widget.userEmail == null ||
                                          widget.userEmail!.isEmpty) {
                                        return;
                                      }

                                      final result =
                                          await HiveDatabaseService
                                              .addHaykirComment(
                                        haykirId: haykirId,
                                        userEmail: widget.userEmail!,
                                        commentText:
                                            _commentController.text.trim(),
                                      );

                                      if (!mounted) return;

                                      if (result['success'] == true) {
                                        _commentController.clear();
                                        final stats = HiveDatabaseService
                                            .getHaykirInteractionStats(
                                          haykirId,
                                          userEmail: widget.userEmail,
                                        );
                                        await _persistPostPayload({
                                          'commentCount':
                                              stats['commentCount'] ?? 0,
                                        });
                                        _refreshInteractionUi(
                                            haykirId: haykirId);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('✅ Yorum eklendi!'),
                                            duration: Duration(seconds: 1),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['error']?.toString() ??
                                                  'Yorum eklenemedi',
                                            ),
                                            duration:
                                                const Duration(seconds: 3),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_comments.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'Henüz yorum yok. İlk yorumu siz yapın!',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
                                    ),
                                  ),
                                )
                              else
                                ..._comments.map((comment) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor:
                                                  Colors.green.shade100,
                                              child: Text(
                                                (comment['userName']
                                                            ?.toString() ??
                                                        'U')
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                comment['userName']
                                                        ?.toString() ??
                                                    'Bilinmeyen',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatCommentTime(
                                                  comment['createdAt']
                                                      ?.toString()),
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ExpandableCommentText(
                                          text: comment['commentText']
                                                  ?.toString() ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 4,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ), // Card kapanıyor
      ],
    );
  }

  // ✅ Adım 1: Grup ikonuna tıklandığında haykıra katıl
  Future<void> _onGroupIconTap(String haykirId) async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Kullanıcı bilgisi bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Haykır verilerini al
      final haykirData = HiveDatabaseService.getHaykir(haykirId);
      if (haykirData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Haykır bulunamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Katıldığım haykır verilerini hazırla
      final katildigimHaykir = {
        'haykirId': haykirId,
        'id': haykirId,
        'adi': haykirData['adi'] ?? '',
        'slogan': haykirData['slogan'] ?? '',
        'direme': haykirData['direme'] ?? '',
        'detaylar': haykirData['detaylar'] ?? '',
        'createdAt':
            haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
        'participatedAt': DateTime.now().toIso8601String(),
        'userEmail': widget.userEmail,
        'displayName': widget.userEmail,
        'kalanSure': '19 saat 0 dakika', // Varsayılan süre
        'profilResmi': 'lib/icons/03_haykir_ana_icon.png',
      };

      // Katıldığım haykırları kaydet
      await HiveDatabaseService.addKatildigimHaykir(
          widget.userEmail!, katildigimHaykir);

      // ✅ State'i güncelle ki grup ikonu pasif hale gelsin
      if (mounted) {
        setState(() {
          // Widget yeniden build edilecek ve grup ikonu pasif olacak
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                '✅ Haykıra katıldınız! "KATILDIĞIM" sekmesinde görünecek.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.purple,
            action: SnackBarAction(
              label: 'Görüntüle',
              textColor: Colors.white,
              onPressed: () {
                // HaykirislarimPage'e yönlendir (opsiyonel)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HaykirislarimPage(userEmail: widget.userEmail),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Haykıra katılma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Adım 2: Retweet dialog'unu göster
  void _showRetweetDialog(String haykirId) {
    String? selectedOption; // 'grup19' veya 'sadece_ben'

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.red.withOpacity(0.05)
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign,
                              size: 24, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'DAVET GÖNDER',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Radio butonlar - Sadece "Grup 19" ve "Sadece ben"
                    Column(
                      children: [
                        _buildRetweetRadioOption(
                          dialogContext,
                          'grup19',
                          'Grup 19',
                          'Grup19 olarak kaydettiğiniz 19 kişiye davet gönder',
                          Icons.group,
                          Colors.purple,
                          selectedOption,
                          (value) {
                            setDialogState(() {
                              selectedOption = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildRetweetRadioOption(
                          dialogContext,
                          'sadece_ben',
                          'Sadece ben',
                          'Sadece kendi seyir defterinize yayınlamak için paylaş',
                          Icons.person,
                          Colors.blue,
                          selectedOption,
                          (value) {
                            setDialogState(() {
                              selectedOption = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'İPTAL',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedOption != null
                                ? () {
                                    Navigator.of(dialogContext).pop();
                                    _processRetweet(haykirId, selectedOption!);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedOption != null
                                  ? Colors.orange
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'DEVAM ET',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Radio seçenek widget'ı
  Widget _buildRetweetRadioOption(
    BuildContext context,
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String? selectedOption,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: selectedOption == value ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedOption == value ? color : Colors.grey[300]!,
          width: selectedOption == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedOption,
        onChanged: onChanged,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selectedOption == value ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ✅ Adım 2: Retweet işlemini gerçekleştir
  Future<void> _processRetweet(String haykirId, String selectedOption) async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Kullanıcı bilgisi bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final haykirData = HiveDatabaseService.getHaykir(haykirId);
      if (haykirData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Haykır bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ✅ Adım 1: Retweet istatistiğini güncelle
      await HiveDatabaseService.updateHaykirInteractionStats(
        haykirId: haykirId,
        userEmail: widget.userEmail!,
        action: 'retweet',
      );

      // ✅ Adım 2: Retweet basan kişinin seyir defterine haykır paylaşımı ekle (her zaman)
      try {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        final postId =
            'haykir_retweet_${haykirId}_${DateTime.now().millisecondsSinceEpoch}';
        final haykirPostData = {
          'id': postId,
          'type': 'haykir',
          'createdAt': DateTime.now().toIso8601String(),
          'authorEmail': widget.userEmail,
          'payload': {
            'haykirId': haykirId,
            'adi': haykirData['adi'] ?? '',
            'slogan': haykirData['slogan'] ?? '',
            'direme': haykirData['direme'] ?? '',
            'detaylar': haykirData['detaylar'] ?? '',
            'createdAt':
                haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
            'isRetweet': true,
            'shareCount': 0,
            'commentCount': 0,
            'retweetCount': 0,
            'likeCount': 0,
            'kinaCount': 0,
            'isSaved': false,
            'isLiked': false,
          },
        };
        await davaProvider.addHomeFeedPost(haykirPostData);
      } catch (e) {
        print('⚠️ Retweet seyir defterine eklenirken hata: $e');
      }

      // ✅ Adım 3: Seçeneğe göre işlem yap
      if (selectedOption == 'grup19') {
        // ✅ Grup 19 seçildi: Grup19 olarak kaydedilen kişilere davet gönder (davet gönderen kişi de dahil)
        final invitationRecipients =
            await HiveDatabaseService.pickInvitationRecipients(
          widget.userEmail!,
          'Grup19',
          excludedEmails: [], // ✅ Davet gönderen kişi de davet alır
        );

        // ✅ Kendine de davet gönder (Grup19 listesinde olmasa bile)
        final currentUserInvitation = {
          'id':
              'haykir_invitation_${DateTime.now().millisecondsSinceEpoch}_${widget.userEmail}',
          'haykirId': haykirId,
          'davaId': haykirId,
          'haykirAdi': haykirData['adi'] ?? '',
          'slogan': haykirData['slogan'] ?? '',
          'direme': haykirData['direme'] ?? '',
          'detaylar': haykirData['detaylar'] ?? '',
          'createdAt':
              haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
          'groupName': 'Grup19',
          'invitedAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'userEmail': widget.userEmail!,
          'displayName': widget.userEmail!,
          'type': 'haykir',
          'davaAdi': haykirData['adi'] ?? '',
          'davaKategori': 'Haykır',
          'davaKonusu': haykirData['slogan'] ?? '',
          'davaci': widget.userEmail!,
          'davali': '',
          'isOpened': false,
          'yorumSayisi': 0,
          'retweetSayisi': 0,
          'begeniSayisi': 0,
          'begenmemeSayisi': 0,
          'userLiked': false,
          'userDisliked': false,
          'userRetweeted': false,
          'yorumlar': <Map<String, dynamic>>[],
        };
        HiveDatabaseService.addInvitation(
            widget.userEmail!, currentUserInvitation);
        print('✅ Kendine davet gönderildi: ${widget.userEmail}');

        // ✅ Haykır başlatan kişiyi bul (authorEmail veya userEmail)
        final authorEmail = widget.post['authorEmail']?.toString() ??
            widget.payload['userEmail']?.toString() ??
            haykirData['userEmail']?.toString() ??
            '';

        print('🔍 DEBUG: Haykır başlatan kişi bulunuyor...');
        print(
            '🔍 DEBUG: widget.post[\'authorEmail\']: ${widget.post['authorEmail']}');
        print(
            '🔍 DEBUG: widget.payload[\'userEmail\']: ${widget.payload['userEmail']}');
        print(
            '🔍 DEBUG: haykirData[\'userEmail\']: ${haykirData['userEmail']}');
        print('🔍 DEBUG: Bulunan authorEmail: $authorEmail');
        print(
            '🔍 DEBUG: Davet gönderen kişi (widget.userEmail): ${widget.userEmail}');

        // ✅ Haykır başlatan kişi varsa ve davet gönderen kişiden farklıysa, ona da davet gönder
        // ✅ NOT: Haykır başlatan kişi Grup19 listesinde olsa bile ona ayrıca davet gönderilir
        bool authorAlreadyInList = false;
        if (authorEmail.isNotEmpty && authorEmail != widget.userEmail) {
          // Haykır başlatan kişi zaten Grup19 listesinde mi kontrol et (sadece bilgi için)
          authorAlreadyInList =
              invitationRecipients.any((r) => r.email == authorEmail);
          print(
              '🔍 DEBUG: Haykır başlatan kişi Grup19 listesinde mi? $authorAlreadyInList');

          // ✅ Haykır başlatan kişiye her zaman davet gönder (Grup19 listesinde olsa bile)
          final authorInvitation = {
            'id':
                'haykir_invitation_${DateTime.now().millisecondsSinceEpoch}_$authorEmail',
            'haykirId': haykirId,
            'davaId': haykirId, // ✅ addInvitation fonksiyonu için gerekli
            'haykirAdi': haykirData['adi'] ?? '',
            'slogan': haykirData['slogan'] ?? '',
            'direme': haykirData['direme'] ?? '',
            'detaylar': haykirData['detaylar'] ?? '',
            'createdAt':
                haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
            'groupName': 'Grup19',
            'invitedAt': DateTime.now().toIso8601String(),
            'isRead': false,
            'userEmail': authorEmail,
            'displayName': authorEmail, // Haykır başlatan kişinin adı
            // ✅ Davet sayfasında gösterilecek format
            'type': 'haykir',
            'davaAdi': haykirData['adi'] ?? '',
            'davaKategori': 'Haykır',
            'davaKonusu': haykirData['slogan'] ?? '',
            'davaci': widget.userEmail!,
            'davali': '',
            'isOpened': false,
            'yorumSayisi': 0,
            'retweetSayisi': 0,
            'begeniSayisi': 0,
            'begenmemeSayisi': 0,
            'userLiked': false,
            'userDisliked': false,
            'userRetweeted': false,
            'yorumlar': <Map<String, dynamic>>[],
          };

          // ✅ Haykır başlatan kişiye davet gönder
          HiveDatabaseService.addInvitation(authorEmail, authorInvitation);
          print(
              '✅ Haykır başlatan kişiye davet gönderildi: $authorEmail (Grup19 listesinde: $authorAlreadyInList)');
        } else {
          if (authorEmail.isEmpty) {
            print('⚠️ Haykır başlatan kişi bulunamadı!');
          } else if (authorEmail == widget.userEmail) {
            print(
                'ℹ️ Haykır başlatan kişi davet gönderen kişi ile aynı, davet gönderilmedi.');
          }
        }

        // ✅ Haykır davetlerini kaydet (davet gönderen kişi dahil)
        for (final recipient in invitationRecipients) {
          final haykirInvitation = {
            'id':
                'haykir_invitation_${DateTime.now().millisecondsSinceEpoch}_${recipient.email}',
            'haykirId': haykirId,
            'davaId': haykirId, // ✅ addInvitation fonksiyonu için gerekli
            'haykirAdi': haykirData['adi'] ?? '',
            'slogan': haykirData['slogan'] ?? '',
            'direme': haykirData['direme'] ?? '',
            'detaylar': haykirData['detaylar'] ?? '',
            'createdAt':
                haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
            'groupName': 'Grup19',
            'invitedAt': DateTime.now().toIso8601String(),
            'isRead': false,
            'userEmail': recipient.email,
            'displayName': recipient.judgeName.isNotEmpty
                ? recipient.judgeName
                : recipient.email,
            // ✅ Davet sayfasında gösterilecek format
            'type': 'haykir',
            'davaAdi': haykirData['adi'] ?? '',
            'davaKategori': 'Haykır',
            'davaKonusu': haykirData['slogan'] ?? '',
            'davaci': widget.userEmail!,
            'davali': '',
            'isOpened': false,
            'yorumSayisi': 0,
            'retweetSayisi': 0,
            'begeniSayisi': 0,
            'begenmemeSayisi': 0,
            'userLiked': false,
            'userDisliked': false,
            'userRetweeted': false,
            'yorumlar': <Map<String, dynamic>>[],
          };

          // ✅ Haykır davetini kaydet (invitation sistemi kullanarak)
          HiveDatabaseService.addInvitation(recipient.email, haykirInvitation);
        }

        final totalInvitations = invitationRecipients.length +
            (authorEmail.isNotEmpty &&
                    authorEmail != widget.userEmail &&
                    !authorAlreadyInList
                ? 1
                : 0);
        print(
            '✅ Haykır retweet: Grup19 için ${invitationRecipients.length} kişiye + haykır başlatan kişiye davet gönderildi (Toplam: $totalInvitations)');

        // ✅ Grup-19 ile retweet yapıldığında kalıcı hale getir (geri alınamaz)
        try {
          final grup19Retweets =
              List<String>.from(haykirData['grup19Retweets'] ?? []);
          if (!grup19Retweets.contains(widget.userEmail!)) {
            grup19Retweets.add(widget.userEmail!);
            haykirData['grup19Retweets'] = grup19Retweets;
            await HiveDatabaseService.updateHaykir(haykirId, haykirData);
            print(
                '✅ Grup-19 retweet kalıcı olarak işaretlendi: ${widget.userEmail}');
          }
        } catch (e) {
          print('⚠️ Grup-19 retweet kalıcı işaretleme hatası: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Grup19\'a gönderildi! $totalInvitations kişiye davet gönderildi (Grup19 + haykır başlatan kişi). Bu retweet geri alınamaz.'),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (selectedOption == 'sadece_ben') {
        // ✅ Sadece ben seçildi: Sadece kendi seyir defterine kaydet (zaten yukarıda yapıldı)
        // ✅ Bu kullanıcı için retweet'i devre dışı bırak
        try {
          // Haykır verisinde retweetDisabledUsers listesini güncelle
          final retweetDisabledUsers =
              List<String>.from(haykirData['retweetDisabledUsers'] ?? []);
          if (!retweetDisabledUsers.contains(widget.userEmail!)) {
            retweetDisabledUsers.add(widget.userEmail!);
            haykirData['retweetDisabledUsers'] = retweetDisabledUsers;
            await HiveDatabaseService.updateHaykir(haykirId, haykirData);
            print('✅ Retweet devre dışı bırakıldı: ${widget.userEmail}');
          }
        } catch (e) {
          print('⚠️ Retweet devre dışı bırakma hatası: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '✅ Seyir defterinize eklendi! Artık retweet yapamazsınız.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // ✅ Adım 4: Retweet sayısını güncelle
      final stats = HiveDatabaseService.getHaykirInteractionStats(
        haykirId,
        userEmail: widget.userEmail,
      );
      await _persistPostPayload({
        'retweetCount': stats['retweetCount'] ?? 0,
        'isRetweeted': true,
      });
      _refreshInteractionUi(haykirId: haykirId);
    } catch (e) {
      print('❌ Retweet hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Retweet'i geri al
  Future<void> _undoRetweet(String haykirId) async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return;

    // ✅ Grup-19 ile yapılmışsa geri alınamaz
    if (_isRetweetPermanent(haykirId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Grup-19 ile yapılan retweet geri alınamaz!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // ✅ Adım 1: Retweet istatistiğini geri al
      await HiveDatabaseService.updateHaykirInteractionStats(
        haykirId: haykirId,
        userEmail: widget.userEmail!,
        action: 'retweet', // Toggle işlemi
      );

      // ✅ Adım 2: Seyir defterindeki retweet post'unu bul ve kaldır
      try {
        final homeFeedPosts = widget.davaProvider.homeFeedPosts;

        // Kullanıcının bu haykır için retweet post'unu bul
        final retweetPost = homeFeedPosts.firstWhere(
          (post) =>
              post['type'] == 'haykir' &&
              post['authorEmail'] == widget.userEmail &&
              post['payload']?['haykirId'] == haykirId &&
              post['payload']?['isRetweet'] == true,
          orElse: () => <String, dynamic>{},
        );

        if (retweetPost.isNotEmpty && retweetPost['id'] != null) {
          await widget.davaProvider.removeHomeFeedPost(retweetPost['id']);
          print(
              '✅ Retweet post seyir defterinden kaldırıldı: ${retweetPost['id']}');
        }
      } catch (e) {
        print('⚠️ Retweet post kaldırılırken hata: $e');
      }

      // ✅ Adım 3: Post'u güncelle
      final stats = HiveDatabaseService.getHaykirInteractionStats(
        haykirId,
        userEmail: widget.userEmail,
      );
      await _persistPostPayload({
        'retweetCount': stats['retweetCount'] ?? 0,
        'isRetweeted': false,
      });
      _refreshInteractionUi(haykirId: haykirId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Retweet geri alındı'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Retweet geri alma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ 19 saat sonunda Haykır puanlama kontrolü
  Future<void> _checkAndApplyHaykirScoring(
    String haykirId,
    int destek, // likeCount
    int kinaMa, // kinaCount
    String createdAt,
  ) async {
    try {
      // Puanlama sadece bir kez yapılmalı (tekrar kontrolü)
      final haykirData = HiveDatabaseService.getHaykir(haykirId);
      if (haykirData == null) return;

      // Eğer puanlama zaten yapılmışsa tekrar yapma
      if (haykirData['scoringApplied'] == 'true' ||
          haykirData['scoringApplied'] == true) {
        return;
      }

      // Haykır başlatan kişi (authorEmail veya userEmail)
      final authorEmail = widget.post['authorEmail']?.toString() ??
          widget.payload['userEmail']?.toString() ??
          haykirData['userEmail']?.toString();

      if (authorEmail == null || authorEmail.isEmpty) {
        print('⚠️ Haykır başlatan kişi bulunamadı: $haykirId');
        return;
      }

      // ✅ TEST MODU: Geçici olarak DESTEK >= 1 (normalde 6.859)
      const double minDestek = 1.0; // ✅ TEST: 1 (normalde 6.859)
      final double destekDouble = destek.toDouble();

      bool isSuccess = false;

      if (destekDouble >= minDestek) {
        if (destekDouble > kinaMa) {
          // ✅ DESTEK >= 6.859 VE DESTEK > KINAma → Haykır başlatan kişi +19 puan
          isSuccess = true;
          await _addUserPoints(
              authorEmail, 19, 'Haykır başarılı (DESTEK > KINAma)');
          print(
              '✅ Haykır başarılı: $authorEmail +19 puan aldı (DESTEK: $destek, KINAma: $kinaMa)');
        } else {
          // ✅ DESTEK >= 6.859 AMA DESTEK < KINAma → Haykır LİDERi -19 puan
          // Not: "Haykır LİDERi" = Haykır başlatan kişi (aynı kişi)
          isSuccess = false;
          await _addUserPoints(
              authorEmail, -19, 'Haykır başarısız (DESTEK < KINAma)');
          print(
              '❌ Haykır başarısız: $authorEmail -19 puan aldı (DESTEK: $destek, KINAma: $kinaMa)');
        }
      } else {
        // ✅ DESTEK < minDestek durumunda da başarısız olarak işaretle (badge görünsün)
        isSuccess = false;
        print('❌ Haykır başarısız: DESTEK ($destek) < minDestek ($minDestek)');
      }

      // Puanlama yapıldığını işaretle ve başarı durumunu kaydet
      await HiveDatabaseService.updateHaykir(haykirId, {
        'scoringApplied': 'true',
        'scoringDate': DateTime.now().toIso8601String(),
        'finalDestek': destek.toString(),
        'finalKinaMa': kinaMa.toString(),
        'isSuccess':
            isSuccess.toString(), // ✅ Başarı durumu: 'true' veya 'false'
      });
    } catch (e) {
      print('❌ Haykır puanlama kontrolü hatası: $e');
    }
  }

  /// ✅ Kullanıcıya puan ekle/çıkar
  Future<void> _addUserPoints(
      String userEmail, int points, String reason) async {
    try {
      // Puanları kaydetmek için HiveDatabaseService'e kayıt ekle
      final box = HiveDatabaseService.getHaykirBox();
      final userPointsKey = 'user_points_$userEmail';

      // Mevcut puanları getir
      final existingData = box.get(userPointsKey);
      int currentPoints = 0;
      List<Map<String, dynamic>> pointHistory = [];

      if (existingData != null) {
        final data = Map<String, dynamic>.from(existingData as Map);
        currentPoints =
            int.tryParse(data['totalPoints']?.toString() ?? '0') ?? 0;
        pointHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
      }

      // Yeni puanı ekle
      final newPoints = currentPoints + points;

      // Puan geçmişine ekle
      pointHistory.add({
        'points': points.toString(),
        'reason': reason,
        'date': DateTime.now().toIso8601String(),
      });

      // Kaydet
      await box.put(userPointsKey, {
        'totalPoints': newPoints.toString(),
        'history': pointHistory,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      print(
          '✅ Kullanıcı puanı güncellendi: $userEmail -> $newPoints (${points > 0 ? '+' : ''}$points)');
    } catch (e) {
      print('❌ Kullanıcı puanı eklenirken hata: $e');
    }
  }

  Widget _buildSocialIconButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback? onTap,
    bool isActive = false,
    bool isDisabled = false, // ✅ Devre dışı durumu
  }) {
    // ✅ Kına için özel stil (gri arka plan, beyaz icon)
    final isKinaButton = label == 'Kına';
    final iconColor = isDisabled
        ? Colors.grey[400] // ✅ Devre dışı durumda açık gri
        : (isKinaButton && isActive
            ? Colors.white // ✅ Kına aktifken beyaz icon
            : (isActive ? color : Colors.grey[600]));
    final backgroundColor = isDisabled
        ? Colors.grey[50] // ✅ Devre dışı durumda çok açık gri
        : (isKinaButton && isActive
            ? Colors.grey[600] // ✅ Kına aktifken gri arka plan
            : (isActive ? color.withOpacity(0.2) : Colors.grey[100]));

    // ✅ Step-2: Widget ID oluştur (unique identifier)
    final widgetId = 'home_page_${label}_${icon.codePoint}';

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          onLongPress: isDisabled
              ? null
              : () {
                  // ✅ Step-2: Uzun basınca widget'ı kaydet
                  if (widget.userEmail != null &&
                      widget.userEmail!.isNotEmpty) {
                    final isAlreadySaved = HiveDatabaseService.isWidgetSaved(
                      userEmail: widget.userEmail!,
                      widgetId: widgetId,
                    );

                    if (isAlreadySaved) {
                      // Widget zaten kayıtlıysa sil
                      HiveDatabaseService.deleteSavedWidget(
                        userEmail: widget.userEmail!,
                        widgetId: widgetId,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ "$label" kayıttan kaldırıldı'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.grey[700],
                        ),
                      );
                    } else {
                      // Widget'ı kaydet
                      HiveDatabaseService.saveWidget(
                        userEmail: widget.userEmail!,
                        widgetId: widgetId,
                        label: label,
                        iconCodePoint: icon.codePoint.toString(),
                        colorValue: color.value,
                        count: count,
                        isActive: isActive,
                        isDisabled: isDisabled,
                        sourcePage: 'home_page',
                        additionalData: {
                          'postId': widget.post['id']?.toString() ?? '',
                          'haykirId':
                              widget.post['payload']?['haykirId']?.toString() ??
                                  '',
                        },
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('✅ "$label" kaydedilenler arşivine eklendi'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.purple,
                          action: SnackBarAction(
                            label: 'Görüntüle',
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SavedWidgetsPage(
                                      userEmail: widget.userEmail),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Kaydetmek için giriş yapmalısınız'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(
              vertical:
                  isActive && isKinaButton ? 14 : 12, // ✅ Kına aktifken büyüt
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              gradient: isActive && isKinaButton
                  ? LinearGradient(
                      colors: [
                        Colors.grey[600]!,
                        Colors.grey[700]!
                      ], // ✅ Kına için gri gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (isActive
                      ? LinearGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled
                    ? Colors.grey[200]! // ✅ Devre dışı durumda açık gri border
                    : (isActive && isKinaButton
                        ? Colors.grey[700]! // ✅ Kına aktifken gri border
                        : (isActive ? color : Colors.grey[300]!)),
                width: isActive && !isDisabled ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: isKinaButton
                            ? Colors.grey
                                .withOpacity(0.4) // ✅ Kına için gri shadow
                            : color.withOpacity(0.3),
                        blurRadius: isActive && isKinaButton
                            ? 12
                            : 8, // ✅ Kına aktifken daha büyük shadow
                        spreadRadius: isActive && isKinaButton ? 2 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: isActive && isKinaButton
                        ? 26
                        : 22, // ✅ Kına aktifken büyüt
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isActive && isKinaButton
                        ? 11
                        : 10, // ✅ Kına aktifken büyüt
                    color: isDisabled
                        ? Colors.grey[400] // ✅ Devre dışı durumda açık gri text
                        : (isActive && isKinaButton
                            ? Colors.white // ✅ Kına aktifken beyaz text
                            : (isActive ? color : Colors.grey[600])),
                    fontWeight: isActive && !isDisabled
                        ? FontWeight.bold
                        : FontWeight.w600,
                    letterSpacing: 0.5,
                    decoration: isDisabled
                        ? TextDecoration.lineThrough
                        : null, // ✅ Devre dışı durumda üstü çizili
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (count > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Dalgalı Estetik için Custom Clipper
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Üst dalga
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.2,
        size.width * 0.5, size.height * 0.3);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.4, size.width, size.height * 0.3);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    // Alt dalga
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.8,
        size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.6, size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ✅ Animasyonlu Dalga Çizimi için Custom Painter
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Üst dalga çizimi (yeşil tonları)
    final topPaint = Paint()
      ..color = Colors.green.shade300.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final topPath = Path();
    for (double i = 0; i <= size.width; i += 1) {
      final y = size.height * 0.25 +
          (size.height * 0.1) *
              math.sin((i / size.width * 3 * math.pi) +
                  (animationValue * 2 * math.pi));

      if (i == 0) {
        topPath.moveTo(i, y);
      } else {
        topPath.lineTo(i, y);
      }
    }
    canvas.drawPath(topPath, topPaint);

    // Alt dalga çizimi (yeşil tonları)
    final bottomPaint = Paint()
      ..color = Colors.lightGreen.shade300.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bottomPath = Path();
    for (double i = 0; i <= size.width; i += 1) {
      final y = size.height * 0.75 +
          (size.height * 0.1) *
              math.sin((i / size.width * 3 * math.pi) +
                  (animationValue * 2 * math.pi) +
                  math.pi);

      if (i == 0) {
        bottomPath.moveTo(i, y);
      } else {
        bottomPath.lineTo(i, y);
      }
    }
    canvas.drawPath(bottomPath, bottomPaint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
