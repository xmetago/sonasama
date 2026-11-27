import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../services/statistics_analytics_service.dart';
import '../services/dava_hukum_service.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/delil_surface.dart';
import 'home_page.dart';
import 'chat_page.dart';
import '../widgets/verified_users_management_dialog.dart';
import '../widgets/shared/shared.dart';

/// Dava istatistiklerini gösteren modern dashboard.
class StatisticsDashboardPage extends StatefulWidget {
  /// İsteğe bağlı kullanıcı e-postası.
  final String? userEmail;

  /// Widget testi: yükleme hatasını gösterir.
  final bool forceLoadError;

  /// Widget testi: ilk karedeki yükleme göstergesini sabitler.
  final bool forceLoading;

  /// Kurucu.
  const StatisticsDashboardPage({
    super.key,
    this.userEmail,
    this.forceLoadError = false,
    this.forceLoading = false,
  });

  @override
  State<StatisticsDashboardPage> createState() =>
      _StatisticsDashboardPageState();
}

class _StatisticsDashboardPageState extends State<StatisticsDashboardPage> {
  final _service = const StatisticsAnalyticsService();
  final _haykirService = const HaykirStatisticsAnalyticsService();
  final _davaSearchFocus = FocusNode();
  final _statsScroll = ScrollController();
  StatisticsAnalyticsResult? _result;
  HaykirStatisticsAnalyticsResult? _haykirResult;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _haykirSearchQuery = '';
  StatisticsQuickFilter _activeFilter = StatisticsQuickFilter.alphabetical;
  bool _showRecordBreakers = false;
  bool _isSupportRecord = false;

  @override
  void initState() {
    super.initState();
    if (widget.forceLoadError) {
      _isLoading = false;
      _error = 'İstatistikler yüklenemedi. Lütfen tekrar deneyin.';
      return;
    }
    if (widget.forceLoading) return;
    _loadData();
  }

  @override
  void dispose() {
    _davaSearchFocus.dispose();
    _statsScroll.dispose();
    super.dispose();
  }

  void _focusDavaSearch() {
    if (_statsScroll.hasClients) {
      _statsScroll.animateTo(
        0,
        duration: SeyirTokens.motion,
        curve: Curves.easeOut,
      );
    }
    _davaSearchFocus.requestFocus();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.load(userEmail: widget.userEmail);
      final haykirData = await _haykirService.load(userEmail: widget.userEmail);
      if (!mounted) return;
      setState(() {
        _result = data;
        _haykirResult = haykirData;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'İstatistikler yüklenemedi. Lütfen tekrar deneyin.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(
          'Dava İstatistikleri',
          style: palette.display(),
        ),
        elevation: 0,
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: _isLoading ? palette.textMuted : palette.textPrimary,
            ),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Yenile',
            style: delilIconButtonStyle(
              foreground: _isLoading ? palette.textMuted : palette.textPrimary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  /// Üst header widget'ını oluşturur.
  Widget _buildTopHeader() {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(userEmail: widget.userEmail),
                ),
              );
            },
            onLongPress: () {
              // Geliştiriciye özel gizli buton: WhoBoom logosuna uzun basınca verified users yönetimi açılır
              showDialog(
                context: context,
                builder: (context) => const VerifiedUsersManagementDialog(),
              );
            },
            child: Row(
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
                      fontSize: SeyirTokens.typeTitle,
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
                      fontSize: SeyirTokens.typeTitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search, size: 22, color: palette.textPrimary),
            tooltip: 'Aramaya git',
            onPressed: _focusDavaSearch,
            style: delilIconButtonStyle(foreground: palette.textPrimary),
          ),
          IconButton(
            tooltip: 'Sohbet',
            style: delilIconButtonStyle(foreground: palette.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(userEmail: widget.userEmail),
                ),
              );
            },
            icon: Icon(
              MdiIcons.chatOutline,
              size: 22,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingMessage(
        message: 'İstatistikler yükleniyor...',
      );
    }
    if (_error != null) {
      return DelilLoadError(
        message: _error!,
        onRetry: _loadData,
      );
    }
    final data = _result;
    final haykirPreview = _haykirResult;
    const Widget emptyStats = Padding(
      padding: EdgeInsets.all(SeyirTokens.space4),
      child: DelilSoftEmpty(
        title: 'Veri bulunamadı',
        message: 'Henüz istatistiğe dönüşecek dava veya haykırış yok.',
        icon: Icons.inbox_outlined,
      ),
    );
    if (data == null) return emptyStats;
    if (data.summary.totalCases == 0 &&
        (haykirPreview == null || haykirPreview.alphabetical.isEmpty)) {
      return emptyStats;
    }
    final filtered = _resolveFilteredList(data)
        .where((item) => item.matchesQuery(_searchQuery))
        .toList();
    assert(() {
      _preserveLegacyDashboardHooks(data, filtered);
      return true;
    }());
    final haykirData = _haykirResult;
    final haykirFiltered = haykirData == null
        ? <HaykirInsight>[]
        : haykirData.alphabetical
            .where((item) => item.matchesQuery(_haykirSearchQuery))
            .toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _SimplifiedStatisticsView(
        scrollController: _statsScroll,
        searchFocusNode: _davaSearchFocus,
        searchResults: filtered,
        todaysOpened: data.todaysOpened,
        searchQuery: _searchQuery,
        onQueryChanged: (value) => setState(() {
          _searchQuery = value;
          _showRecordBreakers = false;
        }),
        onCaseTap: _showCaseDetail,
        haykirSearchResults: haykirFiltered,
        haykirTodaysOpened: haykirData?.todaysOpened ?? const [],
        haykirSearchQuery: _haykirSearchQuery,
        onHaykirQueryChanged: (value) => setState(() {
          _haykirSearchQuery = value;
        }),
        onHaykirTap: _showHaykirDetail,
      ),
    );
  }

  /// Eski bileşenlerin referansını korur.
  void _preserveLegacyDashboardHooks(
    StatisticsAnalyticsResult data,
    List<CaseInsight> filtered,
  ) {
    _SummaryGrid(
      summary: data.summary,
      onCardTap: _handleCardTap,
    );
    _QuickFilterBar(
      active: _activeFilter,
      onSelected: (_) {},
    );
    AppAccentSectionHeader(
      title: _sectionTitleForFilter(_activeFilter),
      accentColor: Theme.of(context).primaryColor,
    );
    CaseInsight? sample;
    if (filtered.isNotEmpty) {
      sample = filtered.first;
    } else if (data.todaysOpened.isNotEmpty) {
      sample = data.todaysOpened.first;
    } else if (data.todaysFinished.isNotEmpty) {
      sample = data.todaysFinished.first;
    }
    if (sample != null) {
      _CaseTile(
        insight: sample,
        badge: 'legacy',
        onTap: () {},
      );
    }
  }

  List<CaseInsight> _resolveFilteredList(StatisticsAnalyticsResult data) {
    List<CaseInsight> baseList;
    switch (_activeFilter) {
      case StatisticsQuickFilter.mostSupported:
        baseList = data.mostSupported;
        break;
      case StatisticsQuickFilter.mostCondemned:
        baseList = data.mostCondemned;
        break;
      case StatisticsQuickFilter.todaysOpened:
        baseList = data.todaysOpened;
        break;
      case StatisticsQuickFilter.todaysFinished:
        baseList = data.todaysFinished;
        break;
      case StatisticsQuickFilter.alphabetical:
        baseList = data.alphabetical;
        break;
    }

    // Rekor kıran davalar filtresi aktifse
    if (_showRecordBreakers) {
      if (_isSupportRecord) {
        final recordValue = data.summary.supportRecord;
        return baseList.where((d) => d.supportCount == recordValue).toList();
      } else {
        final recordValue = data.summary.condemnRecord;
        return baseList.where((d) => d.opposeCount == recordValue).toList();
      }
    }

    return baseList;
  }

  String _sectionTitleForFilter(StatisticsQuickFilter filter) {
    switch (filter) {
      case StatisticsQuickFilter.mostSupported:
        return 'En Çok Desteklenen Davalar';
      case StatisticsQuickFilter.mostCondemned:
        return 'En Çok Kınanan Davalar';
      case StatisticsQuickFilter.todaysOpened:
        return 'Bugün Açılan Davalar';
      case StatisticsQuickFilter.todaysFinished:
        return 'Bugün Sonuçlanan Davalar';
      case StatisticsQuickFilter.alphabetical:
        return 'Dava Adına Göre Liste';
    }
  }

  /// Özet kartı tıklandığında çağrılır.
  void _handleCardTap(SummaryCardType cardType) {
    switch (cardType) {
      case SummaryCardType.hashtagSearch:
        // Hashtag arama moduna geç
        setState(() {
          _showRecordBreakers = false;
          _searchQuery = '';
        });
        _showSearchDialog(
          title: 'Hashtag Bazlı Dava Ara',
          hint: 'Hashtag girin (örn: #adalet)',
          onSearch: (query) {
            setState(() {
              _searchQuery = query.startsWith('#') ? query : '#$query';
              _showRecordBreakers = false;
            });
          },
        );
        break;
      case SummaryCardType.categorySearch:
        // Kategori arama moduna geç
        setState(() {
          _showRecordBreakers = false;
        });
        _showCategorySearchDialog();
        break;
      case SummaryCardType.todayOpened:
        // Bugün açılan davalar filtresine geç
        setState(() {
          _activeFilter = StatisticsQuickFilter.todaysOpened;
          _showRecordBreakers = false;
          _searchQuery = '';
        });
        break;
      case SummaryCardType.todayFinished:
        // Bugün sonuçlanan davalar filtresine geç
        setState(() {
          _activeFilter = StatisticsQuickFilter.todaysFinished;
          _showRecordBreakers = false;
          _searchQuery = '';
        });
        break;
      case SummaryCardType.supportRecord:
        // En çok desteklenen davalar filtresine geç ve rekor kıran davaları göster
        setState(() {
          _activeFilter = StatisticsQuickFilter.mostSupported;
          _showRecordBreakers = true;
          _isSupportRecord = true;
          _searchQuery = '';
        });
        break;
      case SummaryCardType.condemnRecord:
        // En çok kınanan davalar filtresine geç ve rekor kıran davaları göster
        setState(() {
          _activeFilter = StatisticsQuickFilter.mostCondemned;
          _showRecordBreakers = true;
          _isSupportRecord = false;
          _searchQuery = '';
        });
        break;
    }
  }

  /// Hashtag arama dialog'u gösterir.
  void _showSearchDialog({
    required String title,
    required String hint,
    required Function(String) onSearch,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: SeyirPalette.of(context).surfaceMuted,
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onSearch(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSearch(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ara'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  /// Kategori arama dialog'u gösterir.
  void _showCategorySearchDialog() {
    final categoryModels = HiveDatabaseService.getActiveCategories();
    if (categoryModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori bulunamadı'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final categoryList = categoryModels.map((c) => c.name).toList()..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Kategori Bazlı Dava Ara',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: categoryList.isEmpty
              ? const Text('Kategori bulunamadı')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: categoryList.length,
                  itemBuilder: (context, index) {
                    final category = categoryList[index];
                    return ListTile(
                      leading: const Icon(Icons.category_rounded),
                      title: Text(category),
                      onTap: () {
                        setState(() {
                          _searchQuery = category;
                          _showRecordBreakers = false;
                        });
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showHaykirDetail(HaykirInsight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final SeyirPalette sheet = SeyirPalette.of(context);
        return Container(
          decoration: BoxDecoration(
            color: sheet.card,
            borderRadius: SeyirTokens.sheetTop,
            boxShadow: sheet.cardShadow,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: SeyirPalette.of(context).border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: SeyirPalette.of(context).textPrimary,
                        ),
                  ),
                  if (insight.slogan.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      insight.slogan,
                      style: TextStyle(
                        fontSize: SeyirTokens.typeBody,
                        color: SeyirPalette.of(context).textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // İstatistik kartları
                  Row(
                    children: [
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.thumb_up_rounded,
                          label: 'Beğeni',
                          value: '${insight.likeCount}',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.thumb_down_rounded,
                          label: 'Kına',
                          value: '${insight.kinaCount}',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.comment_rounded,
                          label: 'Yorum',
                          value: '${insight.commentCount}',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.repeat_rounded,
                          label: 'Retweet',
                          value: '${insight.retweetCount}',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.share_rounded,
                          label: 'Paylaşım',
                          value: '${insight.shareCount}',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DetailRow(
                    icon: Icons.category_rounded,
                    label: 'Direme',
                    value: insight.direme,
                  ),
                  if ((insight.hashtag ?? '').isNotEmpty)
                    _DetailRow(
                      icon: Icons.tag_rounded,
                      label: 'Hashtag',
                      value: insight.hashtag!,
                    ),
                  const SizedBox(height: 16),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.event_available_rounded,
                    label: 'Oluşturulma Tarihi',
                    value: _formatDateTime(insight.createdAt),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: SeyirPalette.of(context).border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kapat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCaseDetail(CaseInsight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final SeyirPalette sheet = SeyirPalette.of(context);
        return Container(
          decoration: BoxDecoration(
            color: sheet.card,
            borderRadius: SeyirTokens.sheetTop,
            boxShadow: sheet.cardShadow,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: SeyirPalette.of(context).border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: SeyirPalette.of(context).textPrimary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  // İstatistik kartları
                  Row(
                    children: [
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.thumb_up_rounded,
                          label: 'Destek',
                          value: '${insight.supportCount}',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.thumb_down_rounded,
                          label: 'Kınama',
                          value: '${insight.opposeCount}',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.comment_rounded,
                          label: 'Yorum',
                          value: '${insight.commentCount}',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DetailRow(
                    icon: Icons.category_rounded,
                    label: 'Kategori',
                    value: insight.category,
                  ),
                  if ((insight.subCategory ?? '').isNotEmpty)
                    _DetailRow(
                      icon: Icons.subdirectory_arrow_right_rounded,
                      label: 'Alt Kategori',
                      value: insight.subCategory!,
                    ),
                  if ((insight.hashtag ?? '').isNotEmpty)
                    _DetailRow(
                      icon: Icons.tag_rounded,
                      label: 'Hashtag',
                      value: insight.hashtag!,
                    ),
                  const SizedBox(height: 16),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.event_available_rounded,
                    label: 'Açılış Tarihi',
                    value: _formatDateTime(insight.openedAt),
                  ),
                  _DetailRow(
                    icon: Icons.event_note_rounded,
                    label: 'Dava Sonucu Tarihi',
                    value: insight.resultAt == null
                        ? '${_formatDateTime(insight.openedAt.add(Duration(days: DavaHukumService.hukumSuresiGun)))} (-> ${DavaHukumService.hukumSuresiGun} gün sonra)'
                        : _formatDateTime(insight.resultAt!),
                    tooltip: insight.resultAt == null
                        ? 'Dava açılış tarihinden ${DavaHukumService.hukumSuresiGun} gün sonra sonuçlanır'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  // Seyir Defterine Ekle butonu
                  if (widget.userEmail != null && widget.userEmail!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            // Dava ID'sini al
                            final davaId = insight.id;
                            
                            // Seyir defterine ekle
                            await HiveDatabaseService.shareDava(davaId, widget.userEmail!);
                            
                            // Başarı mesajı göster
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('"${insight.title}" seyir defterinize eklendi'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                            
                            // Dialog'u kapat
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            // Hata mesajı göster
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Hata: ${e.toString()}'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Seyir Defterine Ekle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  if (widget.userEmail != null && widget.userEmail!.isNotEmpty)
                    const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: SeyirPalette.of(context).border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kapat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Basitleştirilmiş istatistik görünümü.
class _SimplifiedStatisticsView extends StatelessWidget {
  const _SimplifiedStatisticsView({
    required this.scrollController,
    required this.searchFocusNode,
    required this.searchResults,
    required this.todaysOpened,
    required this.searchQuery,
    required this.onQueryChanged,
    required this.onCaseTap,
    required this.haykirSearchResults,
    required this.haykirTodaysOpened,
    required this.haykirSearchQuery,
    required this.onHaykirQueryChanged,
    required this.onHaykirTap,
  });

  final ScrollController scrollController;
  final FocusNode searchFocusNode;
  final List<CaseInsight> searchResults;
  final List<CaseInsight> todaysOpened;
  final String searchQuery;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<CaseInsight> onCaseTap;
  final List<HaykirInsight> haykirSearchResults;
  final List<HaykirInsight> haykirTodaysOpened;
  final String haykirSearchQuery;
  final ValueChanged<String> onHaykirQueryChanged;
  final ValueChanged<HaykirInsight> onHaykirTap;

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = searchQuery.trim();
    final trimmedHaykirQuery = haykirSearchQuery.trim();
    final accent = Theme.of(context).primaryColor;
    final itemBuilders = <WidgetBuilder>[
      (_) => AppAccentSectionHeader(
            title: 'Genel Dava Arama',
            accentColor: accent,
          ),
      (_) => const SizedBox(height: 12),
      (context) => AppSearchField(
            hintText: 'Dava, kategori veya hashtag ara...',
            onChanged: onQueryChanged,
            focusNode: searchFocusNode,
            suffixIcon: Icon(
              Icons.tune_rounded,
              color: SeyirPalette.of(context).textMuted,
            ),
          ),
      (_) => const SizedBox(height: 16),
      (_) => AppAccentSectionHeader(
            title: trimmedQuery.isEmpty
                ? 'Tüm Davalar'
                : '"$trimmedQuery" için arama sonuçları',
            accentColor: accent,
          ),
      (_) => const SizedBox(height: 8),
    ];
    if (searchResults.isEmpty) {
      itemBuilders.add(
        (_) => AppEmptyResultCard(
          query: trimmedQuery,
          emptyMessage: 'Kayıt bulunamadı',
          icon: Icons.search_off_rounded,
        ),
      );
    } else {
      for (final caseInsight in searchResults) {
        itemBuilders.add(
          (_) => _CaseTile(
            insight: caseInsight,
            onTap: () => onCaseTap(caseInsight),
          ),
        );
      }
    }
    itemBuilders.addAll([
      (_) => const SizedBox(height: 24),
      (_) => AppAccentSectionHeader(
            title: 'Bugün Açılan Davalar',
            accentColor: accent,
          ),
      (_) => const SizedBox(height: 8),
    ]);
    if (todaysOpened.isEmpty) {
      itemBuilders.add(
        (_) => AppInfoBanner(
          icon: Icons.info_outline_rounded,
          message: 'Bugün açılan dava bulunamadı',
          backgroundColor:
              SeyirPalette.of(context).tint(const Color(0xFF1D4ED8)),
          borderColor:
              SeyirPalette.of(context).tintBorder(const Color(0xFF1D4ED8)),
          iconColor:
              SeyirPalette.of(context).foreground(const Color(0xFF1D4ED8)),
        ),
      );
    } else {
      for (final caseInsight in todaysOpened) {
        itemBuilders.add(
          (_) => _CaseTile(
            insight: caseInsight,
            dense: true,
            onTap: () => onCaseTap(caseInsight),
          ),
        );
      }
    }
    itemBuilders.addAll([
      (_) => const SizedBox(height: 32),
      (_) => const Divider(height: 32),
      (_) => AppAccentSectionHeader(
            title: 'Genel Haykır Arama',
            accentColor: accent,
          ),
      (_) => const SizedBox(height: 12),
      (_) => AppSearchField(
            hintText: 'Haykırış, direme veya hashtag ara...',
            onChanged: onHaykirQueryChanged,
          ),
      (_) => const SizedBox(height: 16),
      (_) => AppAccentSectionHeader(
            title: trimmedHaykirQuery.isEmpty
                ? 'Tüm Haykırışlar'
                : '"$trimmedHaykirQuery" için arama sonuçları',
            accentColor: accent,
          ),
      (_) => const SizedBox(height: 8),
    ]);
    if (haykirSearchResults.isEmpty) {
      itemBuilders.add(
        (_) => AppEmptyResultCard(
          query: trimmedHaykirQuery,
          emptyMessage: 'Kayıt bulunamadı',
          icon: Icons.search_off_rounded,
        ),
      );
    } else {
      for (final haykirInsight in haykirSearchResults) {
        itemBuilders.add(
          (_) => _HaykirTile(
            insight: haykirInsight,
            onTap: () => onHaykirTap(haykirInsight),
          ),
        );
      }
    }
    itemBuilders.addAll([
      (_) => const SizedBox(height: 24),
      (_) => AppAccentSectionHeader(
            title: 'Bugün Açılan Haykırışlar',
            accentColor: accent,
          ),
      (_) => const SizedBox(height: 8),
    ]);
    if (haykirTodaysOpened.isEmpty) {
      itemBuilders.add(
        (_) => AppInfoBanner(
          icon: Icons.info_outline_rounded,
          message: 'Bugün açılan haykırış bulunamadı',
          backgroundColor:
              SeyirPalette.of(context).tint(const Color(0xFF1D4ED8)),
          borderColor:
              SeyirPalette.of(context).tintBorder(const Color(0xFF1D4ED8)),
          iconColor:
              SeyirPalette.of(context).foreground(const Color(0xFF1D4ED8)),
        ),
      );
    } else {
      for (final haykirInsight in haykirTodaysOpened) {
        itemBuilders.add(
          (_) => _HaykirTile(
            insight: haykirInsight,
            dense: true,
            onTap: () => onHaykirTap(haykirInsight),
          ),
        );
      }
    }
    itemBuilders.add((_) => const SizedBox(height: 32));

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemBuilders.length,
      itemBuilder: (context, index) => itemBuilders[index](context),
    );
  }
}

/// Özet kartlarını grid olarak gösterir.
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.summary,
    required this.onCardTap,
  });

  final StatisticsSummary summary;
  final Function(SummaryCardType) onCardTap;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _SummaryTileData(
        title: 'Hashtag Bazlı Dava',
        value: summary.totalCases.toString(),
        color: const Color(0xFF6366F1), // Indigo
        type: SummaryCardType.hashtagSearch,
      ),
      _SummaryTileData(
        title: 'Kategori Bazlı Dava',
        value: summary.categoryCount.toString(),
        color: const Color(0xFF14B8A6), // Teal
        type: SummaryCardType.categorySearch,
      ),
      _SummaryTileData(
        title: 'Bugün Açılan Dava',
        value: summary.todaysOpened.toString(),
        color: const Color(0xFF3B82F6), // Blue
        type: SummaryCardType.todayOpened,
      ),
      _SummaryTileData(
        title: 'Bugün Sonuçlanan Dava',
        value: summary.todaysFinished.toString(),
        color: const Color(0xFFF59E0B), // Amber/Orange
        type: SummaryCardType.todayFinished,
      ),
      _SummaryTileData(
        title: 'Destek REKORU KIRAN Dava',
        value: summary.supportRecord.toString(),
        color: const Color(0xFF10B981), // Green
        type: SummaryCardType.supportRecord,
      ),
      _SummaryTileData(
        title: 'Kınama REKORU KIRAN Dava',
        value: summary.condemnRecord.toString(),
        color: const Color(0xFFEF4444), // Red
        type: SummaryCardType.condemnRecord,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return _SummaryCard(
          title: tile.title,
          value: tile.value,
          color: tile.color,
          type: tile.type,
          onTap: () => onCardTap(tile.type),
        );
      },
    );
  }
}

/// Özet kartı tipi enum'u.
enum SummaryCardType {
  hashtagSearch,
  categorySearch,
  todayOpened,
  todayFinished,
  supportRecord,
  condemnRecord,
}

/// Tek bir özet kartı.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.type,
    required this.onTap,
  });

  final String title;
  final String value;
  final Color color;
  final SummaryCardType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconForType(type),
                    color: color,
                    size: 24,
                  ),
                ),
                Icon(
                  Icons.search_rounded,
                  color: color.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: SeyirTokens.typeDisplay,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: SeyirPalette.of(context).textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(SummaryCardType type) {
    switch (type) {
      case SummaryCardType.hashtagSearch:
        return Icons.tag_rounded;
      case SummaryCardType.categorySearch:
        return Icons.category_rounded;
      case SummaryCardType.todayOpened:
        return Icons.today_rounded;
      case SummaryCardType.todayFinished:
        return Icons.check_circle_rounded;
      case SummaryCardType.supportRecord:
        return Icons.thumb_up_rounded;
      case SummaryCardType.condemnRecord:
        return Icons.thumb_down_rounded;
    }
  }
}

/// Quick filter bar'ı.
class _QuickFilterBar extends StatelessWidget {
  const _QuickFilterBar({
    required this.active,
    required this.onSelected,
  });

  final StatisticsQuickFilter active;
  final ValueChanged<StatisticsQuickFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = {
      StatisticsQuickFilter.mostSupported: ('En Çok Desteklenen', Icons.thumb_up_rounded),
      StatisticsQuickFilter.mostCondemned: ('En Çok Kınanan', Icons.thumb_down_rounded),
      StatisticsQuickFilter.todaysOpened: ('Bugün Açılan', Icons.today_rounded),
      StatisticsQuickFilter.todaysFinished: ('Bugün Sonuçlanan', Icons.check_circle_rounded),
      StatisticsQuickFilter.alphabetical: ('Alfabetik', Icons.sort_by_alpha_rounded),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries
            .map(
              (entry) => const Padding(
                padding: EdgeInsets.only(right: 10),

              ),
            )
            .toList(),
      ),
    );
  }
}

/// Tek bir dava kartı.
class _CaseTile extends StatelessWidget {
  const _CaseTile({
    required this.insight,
    this.onTap,
    this.dense = false,
    this.badge,
  });

  final CaseInsight insight;
  final VoidCallback? onTap;
  final bool dense;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AppOutlinedCard(
      onTap: onTap,
      child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: SeyirTokens.typeTitle,
                        color: SeyirPalette.of(context).textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 14,
                              color: SeyirPalette.of(context).textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              insight.category,
                              style: TextStyle(
                                fontSize: SeyirTokens.typeBody,
                                color: SeyirPalette.of(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: SeyirPalette.of(context).textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(insight.createdAt),
                              style: TextStyle(
                                fontSize: SeyirTokens.typeBody,
                                color: SeyirPalette.of(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: SeyirPalette.of(context).tint(SeyirTokens.accept),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up_rounded, size: 16, color: SeyirPalette.of(context).foreground(SeyirTokens.accept)),
                        const SizedBox(width: 4),
                        Text(
                          '${insight.supportCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SeyirPalette.of(context).foreground(SeyirTokens.accept),
                            fontSize: SeyirTokens.typeBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: SeyirPalette.of(context).tint(SeyirTokens.reject),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_down_rounded, size: 16, color: SeyirPalette.of(context).foreground(SeyirTokens.reject)),
                        const SizedBox(width: 4),
                        Text(
                          '${insight.opposeCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: SeyirPalette.of(context).foreground(SeyirTokens.reject),
                            fontSize: SeyirTokens.typeBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange[400]!,
                            Colors.orange[600]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
    );
  }
}

/// Detay satırı.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.tooltip,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget valueWidget = Flexible(
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: SeyirTokens.typeBody,
        ),
      ),
    );

    if (tooltip != null) {
      valueWidget = Tooltip(
        message: tooltip!,
        child: valueWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: SeyirPalette.of(context).textSecondary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: SeyirPalette.of(context).textSecondary,
                fontSize: SeyirTokens.typeBody,
              ),
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }
}

/// Detay modalındaki istatistik kartı.
class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: SeyirTokens.typeHeadline,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: SeyirPalette.of(context).textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Özet kartı veri modeli.
class _SummaryTileData {
  const _SummaryTileData({
    required this.title,
    required this.value,
    required this.color,
    required this.type,
  });

  final String title;
  final String value;
  final Color color;
  final SummaryCardType type;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day.$month.$year';
}

String _formatDateTime(DateTime date) {
  final datePart = _formatDate(date);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$datePart $hour:$minute';
}

/// Tek bir haykırış kartı.
class _HaykirTile extends StatelessWidget {
  const _HaykirTile({
    required this.insight,
    this.onTap,
    this.dense = false,
  });

  final HaykirInsight insight;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppOutlinedCard(
      onTap: onTap,
      child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: SeyirTokens.typeTitle,
                        color: SeyirPalette.of(context).textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (insight.slogan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        insight.slogan,
                        style: TextStyle(
                          fontSize: SeyirTokens.typeBody,
                          color: SeyirPalette.of(context).textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 14,
                              color: SeyirPalette.of(context).textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              insight.direme,
                              style: TextStyle(
                                fontSize: SeyirTokens.typeBody,
                                color: SeyirPalette.of(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: SeyirPalette.of(context).textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(insight.createdAt),
                              style: TextStyle(
                                fontSize: SeyirTokens.typeBody,
                                color: SeyirPalette.of(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: SeyirPalette.of(context).tint(SeyirTokens.accept),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up_rounded, size: 16, color: SeyirPalette.of(context).foreground(SeyirTokens.accept)),
                        const SizedBox(width: 4),
                        Text(
                          '${insight.likeCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SeyirPalette.of(context).foreground(SeyirTokens.accept),
                            fontSize: SeyirTokens.typeBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: SeyirPalette.of(context).tint(SeyirTokens.reject),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_down_rounded, size: 16, color: SeyirPalette.of(context).foreground(SeyirTokens.reject)),
                        const SizedBox(width: 4),
                        Text(
                          '${insight.kinaCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: SeyirPalette.of(context).foreground(SeyirTokens.reject),
                            fontSize: SeyirTokens.typeBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (insight.commentCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: SeyirPalette.of(context).tint(const Color(0xFF1D4ED8)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.comment_rounded, size: 16, color: SeyirPalette.of(context).foreground(const Color(0xFF1D4ED8))),
                          const SizedBox(width: 4),
                          Text(
                            '${insight.commentCount}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: SeyirPalette.of(context).foreground(const Color(0xFF1D4ED8)),
                              fontSize: SeyirTokens.typeBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
    );
  }
}

