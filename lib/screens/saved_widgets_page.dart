import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/hive_database_service.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/shared/shared.dart';

/// ✅ Step-3: Kaydedilen widget'ları gösteren sayfa
/// ✅ Veritabanına kaydediliyor
/// ✅ Kalıcı olarak saklanıyor
/// ✅ Uygulama yeniden başlatıldığında korunuyor
class SavedWidgetsPage extends StatefulWidget {
  /// Kullanıcı e-postası
  final String? userEmail;

  /// Kurucu
  const SavedWidgetsPage({super.key, this.userEmail});

  @override
  State<SavedWidgetsPage> createState() => _SavedWidgetsPageState();
}

class _SavedWidgetsPageState extends State<SavedWidgetsPage> {
  List<Map<String, dynamic>> _savedWidgets = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Kaydedilen widget'ları yükle
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
      final data = HiveDatabaseService.getSavedWidgets(widget.userEmail!);
      if (!mounted) return;
      setState(() {
        _savedWidgets = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kaydedilen widget\'lar yüklenemedi. Lütfen tekrar deneyin.';
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
        message: 'Kaydedilen widget\'lar yükleniyor...',
      );
    }

    if (_error != null) {
      return AppErrorRetryView(
        message: _error!,
        onRetry: _loadData,
      );
    }

    final filtered = _savedWidgets.where((widget) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final label = widget['label']?.toString().toLowerCase() ?? '';
      final sourcePage = widget['sourcePage']?.toString().toLowerCase() ?? '';
      return label.contains(query) || sourcePage.contains(query);
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
                  const AppAccentSectionHeader(title: 'Kaydedilen Widget\'lar'),
                  const SizedBox(height: 12),
                  AppSearchField(
                    hintText: 'Widget ara...',
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
                      emptyMessage: 'Henüz kaydedilen widget yok',
                      icon: Icons.widgets_outlined,
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
                    final Map<String, dynamic> widgetData = filtered[index];
                    return _SavedWidgetTile(
                      widget: widgetData,
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

/// Kaydedilen widget kartı
class _SavedWidgetTile extends StatelessWidget {
  const _SavedWidgetTile({
    required this.widget,
    required this.userEmail,
    required this.onRefresh,
  });

  final Map<String, dynamic> widget;
  final String? userEmail;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final label = widget['label']?.toString() ?? 'Widget';
    final iconCodePoint = int.tryParse(widget['iconCodePoint']?.toString() ?? '0') ?? 0;
    final colorValue = widget['colorValue'] as int? ?? Colors.grey.value;
    final count = widget['count'] as int? ?? 0;
    final isActive = widget['isActive'] as bool? ?? false;
    final isDisabled = widget['isDisabled'] as bool? ?? false;
    final sourcePage = widget['sourcePage']?.toString() ?? 'unknown';
    final savedAt = widget['savedAt']?.toString() ?? '';
    final widgetId = widget['widgetId']?.toString() ?? '';

    final color = Color(colorValue);
    final icon = IconData(iconCodePoint, fontFamily: 'MaterialIcons');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          // Widget detayına git (isteğe bağlı)
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
                  // Widget görseli (küçük önizleme)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? color : Colors.grey[300]!,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? color : Colors.grey[600],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sourcePage.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Sayı: $count',
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
                        if (isActive) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isDisabled) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Devre Dışı',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                      if (widgetId.isNotEmpty && userEmail != null) {
                        HiveDatabaseService.deleteSavedWidget(
                          userEmail: userEmail!,
                          widgetId: widgetId,
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
              if (savedAt.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _formatDate(savedAt),
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
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Kaydedildi: $day.$month.$year $hour:$minute';
    } catch (e) {
      return '';
    }
  }
}

