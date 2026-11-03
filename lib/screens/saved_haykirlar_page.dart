import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/hive_database_service.dart';
import '../widgets/common_header_widgets.dart';
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
    return Scaffold(
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const AppAccentSectionHeader(title: 'Kaydedilen Haykırlar'),
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
            )
          else
            ...filtered.map(
              (haykir) => _SavedHaykirTile(
                haykir: haykir,
                userEmail: widget.userEmail,
                onRefresh: _loadData,
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Kaydedilen haykır kartı
class _SavedHaykirTile extends StatelessWidget {
  const _SavedHaykirTile({
    required this.haykir,
    required this.userEmail,
    required this.onRefresh,
  });

  final Map<String, dynamic> haykir;
  final String? userEmail;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          // Haykır detayına git (home_page'deki gibi)
        },
        borderRadius: BorderRadius.circular(16),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (slogan.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            slogan,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (direme.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            direme,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
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
                    tooltip: 'Kaydı kaldır',
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
                    color: Colors.grey[600]!,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
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
