import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import '../providers/dava_provider.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/home_haykir_card.dart';
import '../widgets/shared/shared.dart';

/// ✅ Step-2: Kaydedilen haykırları gösteren sayfa
/// StatisticsDashboardPage benzeri yapı
class SavedHaykirlarPage extends StatefulWidget {
  /// Kullanıcı e-postası
  final String? userEmail;

  /// Kurucu
  const SavedHaykirlarPage({super.key, this.userEmail});

  @override
  State<SavedHaykirlarPage> createState() => _SavedHaykirlarPageState();
}

class _SavedHaykirlarPageState extends State<SavedHaykirlarPage> {
  List<Map<String, dynamic>> _savedHaykirlar = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Kaydedilen haykırları yükle
  Future<void> _loadData() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      setState(() {
        _error = 'Kullanıcı bilgisi bulunamadı';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = HiveDatabaseService.getSavedHaykirlar(widget.userEmail!);
      if (!mounted) return;
      setState(() {
        _savedHaykirlar = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kaydedilen haykırlar yüklenemedi. Lütfen tekrar deneyin.';
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
    final palette = SeyirPalette.of(context);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
            ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
            // Başlık ve Yenile butonu
            AppRefreshTitleBar(
              title: 'Kaydedilenler Arşivi',
              isLoading: _isLoading,
              onRefresh: _loadData,
            ),
            // İçerik
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingMessage(
        message: 'Kaydedilen haykırlar yükleniyor...',
      );
    }

    if (_error != null) {
      return AppErrorRetryView(
        message: _error!,
        onRetry: _loadData,
      );
    }

    final filtered = _savedHaykirlar.where((haykir) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final adi = haykir['adi']?.toString().toLowerCase() ?? '';
      final slogan = haykir['slogan']?.toString().toLowerCase() ?? '';
      final direme = haykir['direme']?.toString().toLowerCase() ?? '';
      return adi.contains(query) || slogan.contains(query) || direme.contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _SavedSectionHeader(title: 'Kaydedilen Haykırlar'),
                  const SizedBox(height: 12),
                  AppSearchField(
                    hintText: 'Haykır ara...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    AppEmptyResultCard(
                      query: _searchQuery,
                      emptyMessage: 'Henüz kaydedilen haykır yok',
                      icon: Icons.bookmark_border_rounded,
                    ),
                ],
              ),
            ),
          ),
          if (filtered.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final Map<String, dynamic> haykir = filtered[index];
                    return _SavedHaykirTile(
                      haykir: haykir,
                      userEmail: widget.userEmail,
                      onRefresh: _loadData,
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// Kaydedilen haykır kartı
class _SavedSectionHeader extends StatelessWidget {
  const _SavedSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: SeyirTokens.space3),
          Text(
            title,
            style: palette.headline(),
          ),
        ],
      ),
    );
  }
}

class _SavedHaykirTile extends StatelessWidget {
  const _SavedHaykirTile({
    required this.haykir,
    required this.userEmail,
    required this.onRefresh,
  });

  final Map<String, dynamic> haykir;
  final String? userEmail;
  final VoidCallback onRefresh;

  void _openDetail(BuildContext context) {
    final provider = Provider.of<DavaProvider>(context, listen: false);
    final haykirId = haykir['id']?.toString() ?? '';
    final stats = haykir['stats'] as Map<String, dynamic>? ?? {};
    final createdAt = haykir['createdAt']?.toString() ?? '';
    final author = haykir['userEmail']?.toString() ?? userEmail;
    final adi = haykir['adi']?.toString() ?? 'Haykır';
    final payload = <String, dynamic>{
      'haykirId': haykirId,
      'adi': adi,
      'slogan': haykir['slogan']?.toString() ?? '',
      'direme': haykir['direme']?.toString() ?? '',
      'detaylar': haykir['detaylar']?.toString() ?? '',
      'createdAt': createdAt,
      'shareCount': stats['shareCount'] ?? 0,
      'commentCount': stats['commentCount'] ?? 0,
      'retweetCount': stats['retweetCount'] ?? 0,
      'likeCount': stats['likeCount'] ?? 0,
      'kinaCount': stats['kinaCount'] ?? 0,
      'isSaved': true,
      'isLiked': false,
    };
    final post = <String, dynamic>{
      'id': 'haykir_$haykirId',
      'type': 'haykir',
      'createdAt': createdAt,
      'authorEmail': author,
      'payload': payload,
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final palette = SeyirPalette.of(context);
          return Scaffold(
            backgroundColor: palette.surface,
            appBar: AppBar(
              title: Text(adi, style: palette.headline()),
            ),
            body: ListView(
              padding: const EdgeInsets.all(SeyirTokens.space4),
              children: [
                HaykirCardWidget(
                  post: post,
                  payload: payload,
                  davaProvider: provider,
                  userEmail: userEmail,
                  showCloseButton: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final stats = haykir['stats'] as Map<String, dynamic>? ?? {};
    final likeCount = stats['likeCount'] ?? 0;
    final kinaCount = stats['kinaCount'] ?? 0;
    final commentCount = stats['commentCount'] ?? 0;
    final shareCount = stats['shareCount'] ?? 0;

    final adi = haykir['adi']?.toString() ?? 'Haykır';
    final slogan = haykir['slogan']?.toString() ?? '';
    final direme = haykir['direme']?.toString() ?? '';
    final createdAt = haykir['createdAt']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeyirTokens.radiusLg),
        side: BorderSide(color: palette.border, width: 1),
      ),
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(SeyirTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adi,
                          style: palette.title(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (slogan.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            slogan,
                            style: palette.body(color: palette.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (direme.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            direme,
                            style: palette.body(color: palette.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kaydı kaldır',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      MdiIcons.bookmark,
                      color: Colors.purple,
                      size: 24,
                    ),
                    onPressed: () async {
                      // Kaydı kaldır
                      final haykirId = haykir['id']?.toString() ?? '';
                      if (haykirId.isNotEmpty && userEmail != null) {
                        await HiveDatabaseService.updateHaykirInteractionStats(
                          haykirId: haykirId,
                          userEmail: userEmail!,
                          isSaved: false,
                        );
                        onRefresh();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('❌ Kayıt kaldırıldı!'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.purple,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // İstatistikler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AppStatBadge(
                    icon: Icons.thumb_up_rounded,
                    count: likeCount,
                    color: Colors.green,
                  ),
                  AppStatBadge(
                    icon: Icons.thumb_down_rounded,
                    count: kinaCount,
                    color: palette.isDark ? SeyirTokens.neutral400 : SeyirTokens.neutral500,
                  ),
                  AppStatBadge(
                    icon: Icons.comment_rounded,
                    count: commentCount,
                    color: Colors.blue,
                  ),
                  AppStatBadge(
                    icon: Icons.share_rounded,
                    count: shareCount,
                    color: Colors.orange,
                  ),
                ],
              ),
              if (createdAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _formatDate(createdAt),
                  style: palette.caption(color: palette.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day.$month.$year';
    } catch (e) {
      return '';
    }
  }
}
