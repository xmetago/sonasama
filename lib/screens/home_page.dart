import 'dart:convert';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:provider/provider.dart';
import '../widgets/home_page_chrome.dart';
import 'database_debug_page.dart';
import 'admin_page.dart';
import '../services/hive_database_service.dart';
import '../utils/map_safety.dart';
import '../models/dava.dart' as dava_model;
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../widgets/ilgililerin_seyir_defteri_widgeti.dart';
import '../widgets/home_haykir_card.dart';
export '../widgets/home_haykir_card.dart' show HaykirCardWidget, WaveClipper, WavePainter;
import '../utils/comment_utils.dart';
import '../utils/app_theme.dart';
import 'tutorial_case_page.dart';

import 'dava_ac_page.dart' as dava_ac; // New import for dava a�ma
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
    _homeFeedPagingController.dispose();
    _homeFeedRefreshController.dispose();
    super.dispose();
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

  String? _profileTargetEmail(AuthProvider authProvider) {
    final viewer = authProvider.userEmail?.trim();
    final viewed = widget.userEmail?.trim();
    if (viewer == null ||
        viewed == null ||
        viewer.isEmpty ||
        viewed.isEmpty ||
        viewer.toLowerCase() == viewed.toLowerCase()) {
      return null;
    }
    return viewed;
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
          body: HomePageChrome(
            userEmail: widget.userEmail,
            profileEmail: authProvider.userEmail ?? widget.userEmail,
            targetUserEmail: _profileTargetEmail(authProvider),
            feed: _buildHomeFeed(davaProvider.homeFeedPosts),
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
