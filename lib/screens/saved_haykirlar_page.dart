import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/hive_database_service.dart';
import '../widgets/common_header_widgets.dart';

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Kaydedilenler Arşivi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
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
              'Kaydedilen haykırlar yükleniyor...',
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
          const _SectionHeader(title: 'Kaydedilen Haykırlar'),
          const SizedBox(height: 12),
          _SearchField(onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          }),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _EmptyResultCard(query: _searchQuery)
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

/// Arama alanı widget'ı
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
          hintText: 'Haykır ara...',
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

/// Bölüm başlığı
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
              color: Colors.purple,
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

/// Boş sonuç kartı
class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard({required this.query});

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
              Icons.bookmark_border_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasQuery ? 'Arama sonucuna ulaşılamadı' : 'Henüz kaydedilen haykır yok',
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
                            const SnackBar(
                              content: Text('❌ Kayıt kaldırıldı!'),
                              duration: Duration(seconds: 2),
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
                  _StatBadge(
                    icon: Icons.thumb_up_rounded,
                    count: likeCount,
                    color: Colors.green,
                  ),
                  _StatBadge(
                    icon: Icons.thumb_down_rounded,
                    count: kinaCount,
                    color: Colors.grey[600]!,
                  ),
                  _StatBadge(
                    icon: Icons.comment_rounded,
                    count: commentCount,
                    color: Colors.blue,
                  ),
                  _StatBadge(
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

/// İstatistik rozeti
class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

