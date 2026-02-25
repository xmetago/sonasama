import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../services/statistics_analytics_service.dart';
import '../services/hive_database_service.dart';
import 'home_page.dart';
import 'chat_page.dart';
import '../widgets/verified_users_management_dialog.dart';

/// Dava istatistiklerini gösteren modern dashboard.
class StatisticsDashboardPage extends StatefulWidget {
  /// İsteğe bağlı kullanıcı e-postası.
  final String? userEmail;

  /// Kurucu.
  const StatisticsDashboardPage({super.key, this.userEmail});

  @override
  State<StatisticsDashboardPage> createState() =>
      _StatisticsDashboardPageState();
}

class _StatisticsDashboardPageState extends State<StatisticsDashboardPage> {
  final _service = const StatisticsAnalyticsService();
  final _haykirService = const HaykirStatisticsAnalyticsService();
  StatisticsAnalyticsResult? _result;
  HaykirStatisticsAnalyticsResult? _haykirResult;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _haykirSearchQuery = '';
  StatisticsQuickFilter _activeFilter = StatisticsQuickFilter.alphabetical;
  bool _showRecordBreakers = false;
  bool _isSupportRecord = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dava İstatistikleri',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
            ),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Yenile',
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
                      fontSize: 16,
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
                      fontSize: 16,
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
            icon: const Icon(Icons.search, size: 24),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(userEmail: widget.userEmail),
                ),
              );
            },
            child: Icon(
              MdiIcons.chatOutline,
              size: 24,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'İstatistikler yükleniyor...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final data = _result;
    if (data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Veri bulunamadı',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
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
    _SectionHeader(title: _sectionTitleForFilter(_activeFilter));
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
            fillColor: Colors.grey[50],
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
    );
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                  ),
                  if (insight.slogan.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      insight.slogan,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
                        side: BorderSide(color: Colors.grey[300]!),
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
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
                        ? '${_formatDateTime(insight.openedAt.add(const Duration(days: 76)))} (-> 76 gün sonra)'
                        : _formatDateTime(insight.resultAt!),
                    tooltip: insight.resultAt == null
                        ? 'Dava açılış tarihinden 76 gün sonra sonuçlanır'
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
                        side: BorderSide(color: Colors.grey[300]!),
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

/// Arama alanı widget'ı.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[600],
          ),
          suffixIcon: Icon(
            Icons.tune_rounded,
            color: Colors.grey[400],
          ),
          hintText: 'Dava, kategori veya hashtag ara...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Basitleştirilmiş istatistik görünümü.
class _SimplifiedStatisticsView extends StatelessWidget {
  const _SimplifiedStatisticsView({
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
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const _SectionHeader(title: 'Genel Dava Arama'),
        const SizedBox(height: 12),
        _SearchField(onChanged: onQueryChanged),
        const SizedBox(height: 16),
        _SectionHeader(
          title: trimmedQuery.isEmpty
              ? 'Tüm Davalar'
              : '"$trimmedQuery" için arama sonuçları',
        ),
        const SizedBox(height: 8),
        if (searchResults.isEmpty)
          _EmptySearchResultCard(query: trimmedQuery)
        else
          ...searchResults.map(
            (caseInsight) => _CaseTile(
              insight: caseInsight,
              onTap: () => onCaseTap(caseInsight),
            ),
          ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Bugün Açılan Davalar'),
        const SizedBox(height: 8),
        if (todaysOpened.isEmpty)
          const _InfoBanner(
            icon: Icons.info_outline_rounded,
            message: 'Bugün açılan dava bulunamadı',
            backgroundColor: Color(0xFFEFF6FF),
            borderColor: Color(0xFFBFDBFE),
            iconColor: Color(0xFF1D4ED8),
          )
        else
          ...todaysOpened.map(
            (caseInsight) => _CaseTile(
              insight: caseInsight,
              dense: true,
              onTap: () => onCaseTap(caseInsight),
            ),
          ),
        const SizedBox(height: 32),
        // HAYKIR İSTATİSTİKLERİ BÖLÜMÜ
        const Divider(height: 32),
        const _SectionHeader(title: 'Genel Haykır Arama'),
        const SizedBox(height: 12),
        _HaykirSearchField(onChanged: onHaykirQueryChanged),
        const SizedBox(height: 16),
        _SectionHeader(
          title: haykirSearchQuery.trim().isEmpty
              ? 'Tüm Haykırışlar'
              : '"${haykirSearchQuery.trim()}" için arama sonuçları',
        ),
        const SizedBox(height: 8),
        if (haykirSearchResults.isEmpty)
          _EmptySearchResultCard(query: haykirSearchQuery.trim())
        else
          ...haykirSearchResults.map(
            (haykirInsight) => _HaykirTile(
              insight: haykirInsight,
              onTap: () => onHaykirTap(haykirInsight),
            ),
          ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Bugün Açılan Haykırışlar'),
        const SizedBox(height: 8),
        if (haykirTodaysOpened.isEmpty)
          const _InfoBanner(
            icon: Icons.info_outline_rounded,
            message: 'Bugün açılan haykırış bulunamadı',
            backgroundColor: Color(0xFFEFF6FF),
            borderColor: Color(0xFFBFDBFE),
            iconColor: Color(0xFF1D4ED8),
          )
        else
          ...haykirTodaysOpened.map(
            (haykirInsight) => _HaykirTile(
              insight: haykirInsight,
              dense: true,
              onTap: () => onHaykirTap(haykirInsight),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Arama sonuçları boş olduğunda gösterilen kart.
class _EmptySearchResultCard extends StatelessWidget {
  const _EmptySearchResultCard({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasQuery ? 'Arama sonucuna ulaşılamadı' : 'Kayıt bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasQuery) ...[
            const SizedBox(height: 8),
            Text(
              '"$query" için eşleşme yok',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bilgilendirici banner.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  final IconData icon;
  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
                  fontSize: 28,
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
                  color: Colors.grey[700],
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

/// Bölüm başlığı.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey[800],
                ),
          ),
        ],
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: dense ? 15 : 16,
                        color: Colors.grey[900],
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
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              insight.category,
                              style: TextStyle(
                                fontSize: dense ? 12 : 13,
                                color: Colors.grey[600],
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
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(insight.createdAt),
                              style: TextStyle(
                                fontSize: dense ? 12 : 13,
                                color: Colors.grey[600],
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
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up_rounded, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${insight.supportCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: dense ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_down_rounded, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${insight.opposeCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                            fontSize: dense ? 13 : 14,
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
        ),
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
          fontSize: 14,
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
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
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

/// HAYKIR arama alanı widget'ı.
class _HaykirSearchField extends StatelessWidget {
  const _HaykirSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[600],
          ),
          hintText: 'Haykırış, direme veya hashtag ara...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: onChanged,
      ),
    );
  }
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: dense ? 15 : 16,
                        color: Colors.grey[900],
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
                          fontSize: dense ? 12 : 13,
                          color: Colors.grey[600],
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
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              insight.direme,
                              style: TextStyle(
                                fontSize: dense ? 12 : 13,
                                color: Colors.grey[600],
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
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(insight.createdAt),
                              style: TextStyle(
                                fontSize: dense ? 12 : 13,
                                color: Colors.grey[600],
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
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up_rounded, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${insight.likeCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: dense ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_down_rounded, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${insight.kinaCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                            fontSize: dense ? 13 : 14,
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
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.comment_rounded, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${insight.commentCount}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                              fontSize: dense ? 13 : 14,
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
        ),
      ),
    );
  }
}

