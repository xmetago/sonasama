import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import '../services/evidence_service.dart';
import '../services/hive_database_service.dart';
import '../models/evidence_model.dart';
import '../screens/delil_detay_page.dart';
import '../theme/seyir_tokens.dart';
import 'delil_surface.dart';

/// Modern ve yeniden kullanılabilir Delil Görüntüleme Widget'ı
/// Hem Seyir Defteri hem de Yargıla sayfasında kullanılabilir
/// 
/// Özellikler:
/// - 4 delil türü (Resim, Video, PDF, Link) için icon grid
/// - Veritabanından senkronize delil listesi
/// - Modern Material 3 tasarımı
/// - Responsive ve erişilebilir
class EvidenceViewerWidget extends StatefulWidget {
  /// Delillerin ait olduğu dava ID'si
  final String davaId;
  
  /// Kullanıcı e-posta adresi (opsiyonel)
  final String? userEmail;

  /// Kullanıcının bu davadaki rolü (opsiyonel)
  final String? userRole;
  
  /// Widget başlığı (opsiyonel)
  final String? title;
  
  /// Dava bilgilerini göster/gizle
  final bool showCaseInfo;
  
  /// Dava bilgileri card'ı (opsiyonel)
  final Widget? caseInfoCard;

  /// Test: sayılar yüklenemesin.
  final bool forceLoadError;

  const EvidenceViewerWidget({
    super.key,
    required this.davaId,
    this.userEmail,
    this.userRole,
    this.title,
    this.showCaseInfo = false,
    this.caseInfoCard,
    this.forceLoadError = false,
  });

  @override
  State<EvidenceViewerWidget> createState() => _EvidenceViewerWidgetState();
}

class _EvidenceViewerWidgetState extends State<EvidenceViewerWidget> {
  final EvidenceService _evidenceService = EvidenceService();
  Map<String, int> _evidenceCounts = {
    'image': 0,
    'video': 0,
    'text': 0,
    'link': 0,
  };
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadEvidenceCounts();
  }

  /// Widget güncellendiğinde davaId değişmişse delilleri yeniden yükle
  @override
  void didUpdateWidget(EvidenceViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // DavaId değiştiyse delilleri yeniden yükle
    if (oldWidget.davaId != widget.davaId) {
      _loadEvidenceCounts();
    }
  }

  /// Delil sayılarını veritabanından yükle
  Future<void> _loadEvidenceCounts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      if (widget.forceLoadError) {
        throw Exception('Delil sayıları yüklenemedi');
      }
      await _evidenceService.initialize();
      final counts = _evidenceService.loadEvidenceCounts(widget.davaId);
      setState(() {
        _evidenceCounts = counts;
        _isLoading = false;
      });
      
      // Sadece sorun varsa log
      if (counts.values.every((count) => count == 0)) {
        print('⚠️ DavaId: ${widget.davaId} - Delil bulunamadı');
      }
    } catch (e) {
      print('❌ Delil yükleme hatası: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Delil sayıları yüklenemedi';
      });
    }
  }

  /// Delil türü için icon bilgisi
  List<EvidenceTypeInfo> get evidenceTypes => [
    const EvidenceTypeInfo(
      label: "Resim",
      icon: Icons.camera_alt,
      type: "image",
      color: Colors.blue,
      iconAsset: 'lib/icons/13_delilleri_incele_foto_icon.png',
    ),
    const EvidenceTypeInfo(
      label: "Video",
      icon: Icons.videocam,
      type: "video",
      color: Colors.deepPurple,
      iconAsset: 'lib/icons/13_delilleri_incele_camera_icon.png',
    ),
    const EvidenceTypeInfo(
      label: "PDF",
      icon: Icons.picture_as_pdf,
      type: "text",
      color: Colors.red,
      iconAsset: 'lib/icons/13_delilleri_incele_text_icon.png',
    ),
    const EvidenceTypeInfo(
      label: "Link",
      icon: Icons.link,
      type: "link",
      color: Colors.green,
      iconAsset: 'lib/icons/13_delilleri_incele_link_icon.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Başlık (varsa)
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              widget.title!,
              style: SeyirPalette.of(context).headline(),
              textAlign: TextAlign.center,
            ),
          ),

        // Dava bilgisi kartı (varsa)
        if (widget.showCaseInfo && widget.caseInfoCard != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: widget.caseInfoCard!,
          ),

        // Delil türleri grid
        _buildEvidenceTypesGrid(),
      ],
    );
  }

  /// Delil türleri grid'i
  Widget _buildEvidenceTypesGrid() {
    final palette = SeyirPalette.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
        border: Border.all(
          color: palette.border,
          width: 1,
        ),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                MdiIcons.fileDocumentMultiple,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Delil Türlerini İncele',
                style: palette.title(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Icon grid
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _loadError != null
              ? DelilLoadError(
                  message: _loadError!,
                  onRetry: _loadEvidenceCounts,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: evidenceTypes.map((typeInfo) {
                    final count = _evidenceCounts[typeInfo.type] ?? 0;
                    return _buildEvidenceTypeIcon(typeInfo, count);
                  }).toList(),
                ),
          if (!_isLoading &&
              _loadError == null &&
              _evidenceCounts.values.every((count) => count == 0))
            const DelilSoftEmpty(
              title: 'Henüz delil yok',
              message: 'Bu davaya eklenen deliller burada görünür',
              icon: Icons.folder_open,
            ),
        ],
      ),
    );
  }

  /// Tek bir delil türü icon'u
  Widget _buildEvidenceTypeIcon(EvidenceTypeInfo typeInfo, int count) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openEvidenceList(typeInfo),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
              child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color: typeInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: typeInfo.color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon (önce asset'i dene, yoksa Material icon kullan)
                  _buildIcon(typeInfo),
                  
                  const SizedBox(height: 8),
                  
                  // Label
                  Text(
                    typeInfo.label,
                    style: TextStyle(
                      fontSize: SeyirTokens.typeBody,
                      fontWeight: FontWeight.w600,
                      color: typeInfo.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: typeInfo.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: SeyirTokens.typeCaption,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }

  /// Icon widget'ı oluştur (asset veya Material icon)
  Widget _buildIcon(EvidenceTypeInfo typeInfo) {
    return Image.asset(
      typeInfo.iconAsset,
      width: 36,
      height: 36,
      errorBuilder: (context, error, stackTrace) {
        // Asset bulunamazsa Material icon kullan
        return Icon(
          typeInfo.icon,
          size: 36,
          color: typeInfo.color,
        );
      },
    );
  }

  /// Delil listesi sayfasını aç
  void _openEvidenceList(EvidenceTypeInfo typeInfo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EvidenceListPage(
          typeInfo: typeInfo,
          davaId: widget.davaId,
          userEmail: widget.userEmail,
          userRole: widget.userRole,
        ),
      ),
    ).then((_) {
      // Geri dönüldüğünde sayıları yenile
      _loadEvidenceCounts();
    });
  }
}

/// Delil türü bilgileri
class EvidenceTypeInfo {
  final String label;
  final IconData icon;
  final String type;
  final Color color;
  final String iconAsset;

  const EvidenceTypeInfo({
    required this.label,
    required this.icon,
    required this.type,
    required this.color,
    required this.iconAsset,
  });
}

/// Delil listesi sayfası (dahili)
class _EvidenceListPage extends StatefulWidget {
  final EvidenceTypeInfo typeInfo;
  final String davaId;
  final String? userEmail;
  final String? userRole;

  const _EvidenceListPage({
    required this.typeInfo,
    required this.davaId,
    this.userEmail,
    this.userRole,
  });

  @override
  State<_EvidenceListPage> createState() => _EvidenceListPageState();
}

class _EvidenceListPageState extends State<_EvidenceListPage> {
  final EvidenceService _service = EvidenceService();
  List<EvidenceModel> _items = [];
  bool _loading = true;
  String? _loadError;
  bool _isVoteLockedByFinalizedHukum = false;
  bool _forcedValidVote = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _service.initialize();
      await _syncVoteLockWithFinalizedHukum();
      final all = _service.loadAllEvidence();
      final targetType = widget.typeInfo.type;
      
      // Filtreleme - trim ve case-insensitive karşılaştırma
      final normalizedDavaId = widget.davaId.trim().toLowerCase();
      final normalizedType = targetType.trim().toLowerCase();
      final filtered = all.where((e) {
        return e.davaId.trim().toLowerCase() == normalizedDavaId && 
               e.type.trim().toLowerCase() == normalizedType;
      }).toList();

      setState(() {
        _items = filtered;
        _loading = false;
        _loadError = null;
      });
      
      // Sadece sorun varsa log
      if (filtered.isEmpty && all.isNotEmpty) {
        print('⚠️ ${widget.typeInfo.label}: DavaId eşleşmedi (${widget.davaId})');
      }
    } catch (e) {
      print('❌ Hata: $e');
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
        _loadError = 'Delil sayıları yüklenemedi';
      });
    }
  }

  String _normalizeRole(String role) {
    final trimmed = role.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.endsWith('Kararı') ? trimmed : '$trimmed Kararı';
  }

  Future<void> _syncVoteLockWithFinalizedHukum() async {
    final userEmail = widget.userEmail?.trim() ?? '';
    final normalizedRole = _normalizeRole(widget.userRole ?? '');
    if (userEmail.isEmpty || normalizedRole.isEmpty || widget.davaId.trim().isEmpty) {
      _isVoteLockedByFinalizedHukum = false;
      return;
    }

    final hukum = await HiveDatabaseService.getHukumByDavaIdAndRole(
      widget.davaId.trim(),
      normalizedRole,
    );
    final isFinalized = (hukum?['isFinalized'] as bool?) ?? false;
    final sentiment = (hukum?['hukumSentiment'] as String?) ?? '';
    final isPositive = sentiment == 'positive';
    final isNegative = sentiment == 'negative';

    if (isFinalized && (isPositive || isNegative)) {
      await _service.applyForcedVoteForUser(
        widget.davaId,
        userEmail,
        isPositive: isPositive,
      );
      _isVoteLockedByFinalizedHukum = true;
      _forcedValidVote = isPositive;
      return;
    }

    _isVoteLockedByFinalizedHukum = false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final onBar = palette.onSolid(widget.typeInfo.color);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(
          '${widget.typeInfo.label} Delilleri',
          style: palette.headline(color: onBar),
        ),
        backgroundColor: widget.typeInfo.color,
        foregroundColor: onBar,
        iconTheme: IconThemeData(color: onBar),
        elevation: 0,
        actions: [
          IconButton(
            style: delilIconButtonStyle(foreground: onBar),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.tint(widget.typeInfo.color),
              palette.surface,
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? DelilLoadError(
                    message: _loadError!,
                    onRetry: _load,
                  )
                : _items.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
    );
  }

  /// Boş durum widget'ı
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SeyirTokens.space4),
        child: DelilSoftEmpty(
          title: 'Bu türde henüz delil yok',
          message: '${widget.typeInfo.label} delilleri eklendiğinde burada görünecek',
          icon: Icons.folder_off,
        ),
      ),
    );
  }

  /// Delil listesi
  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final evidence = _items[index];
        return _buildEvidenceCard(evidence);
      },
    );
  }

  /// Delil kartı
  Widget _buildEvidenceCard(EvidenceModel evidence) {
    final palette = SeyirPalette.of(context);
    return Card(
      elevation: 2,
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeyirTokens.radiusLg),
        side: BorderSide(color: palette.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => _openEvidenceDetail(evidence),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.typeInfo.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.typeInfo.icon,
                      size: 32,
                      color: widget.typeInfo.color,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Bilgiler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        Text(
                          evidence.title.isNotEmpty ? evidence.title : 'Başlıksız',
                          style: const TextStyle(
                            fontSize: SeyirTokens.typeTitle,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Açıklama
                        Text(
                          evidence.description,
                          style: SeyirPalette.of(context).body(
                            color: SeyirPalette.of(context).textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Tarih ve doğrulama durumu
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(evidence.createdAt),
                              style: TextStyle(
                                fontSize: SeyirTokens.typeCaption,
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            if (evidence.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Doğrulandı',
                                      style: TextStyle(
                                        fontSize: SeyirTokens.typeCaption,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Chevron
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          
          // Like/Dislike Butonları
          _buildEvidenceLikeBar(evidence),
        ],
      ),
    );
  }

  /// Seçimi kutuya yazar, çubuğu hemen günceller, sonra diske bırakır.
  Future<void> _castVote(String evidenceId, String userEmail, String vote) async {
    await _service.initialize();
    final updated = _service.mutateUserToggle(evidenceId, userEmail, vote);
    _showStoredVotes();
    if (updated != null) {
      await _service.persistEvidence(updated);
    }
  }

  /// Kayıtlı oyları kutudan yeniden okur. Detay sayfasından dönünce seçim kaybolmasın.
  void _showStoredVotes() {
    if (!mounted) return;
    final normalizedDavaId = widget.davaId.trim().toLowerCase();
    final normalizedType = widget.typeInfo.type.trim().toLowerCase();
    final filtered = _service.loadAllEvidence().where((e) {
      return e.davaId.trim().toLowerCase() == normalizedDavaId &&
          e.type.trim().toLowerCase() == normalizedType;
    }).toList();
    setState(() => _items = filtered);
  }

  /// Like/Dislike Bar
  Widget _buildEvidenceLikeBar(EvidenceModel evidence) {
    final userEmail = (widget.userEmail ?? '').trim();
    final vote = userEmail.isEmpty ? null : evidence.getUserVote(userEmail);
    final isLiked = vote == 'like';
    final isDisliked = vote == 'dislike';
    final isNeutral = vote == 'neutral';
    
    final palette = SeyirPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: palette.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLikeButton(
              icon: Icons.thumb_up_rounded,
              label: 'Geçerli',
              count: evidence.likeCount,
              color: Colors.blue,
              isDisabled: _isVoteLockedByFinalizedHukum,
              onTap: () async {
                if (_isVoteLockedByFinalizedHukum) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _forcedValidVote
                            ? 'Hükmünüz kesinleşti: deliller geçerli kabul edildi.'
                            : 'Hükmünüz kesinleşti: deliller geçersiz kabul edildi.',
                      ),
                      backgroundColor: Colors.blueGrey,
                    ),
                  );
                  return;
                }
                if (userEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geçerli için giriş yapmalısınız'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                await _castVote(evidence.id, userEmail, 'like');
              },
              isActive: isLiked,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildLikeButton(
              icon: Icons.remove,
              label: 'Nötr',
              count: evidence.neutralCount,
              color: Colors.grey,
              isDisabled: _isVoteLockedByFinalizedHukum,
              onTap: () async {
                if (_isVoteLockedByFinalizedHukum) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _forcedValidVote
                            ? 'Hükmünüz kesinleşti: deliller geçerli kabul edildi.'
                            : 'Hükmünüz kesinleşti: deliller geçersiz kabul edildi.',
                      ),
                      backgroundColor: Colors.blueGrey,
                    ),
                  );
                  return;
                }
                if (userEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nötr oy için giriş yapmalısınız'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                await _castVote(evidence.id, userEmail, 'neutral');
              },
              isActive: isNeutral,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildLikeButton(
              icon: Icons.thumb_down_rounded,
              label: 'Geçersiz',
              count: evidence.dislikeCount,
              color: Colors.red,
              isDisabled: _isVoteLockedByFinalizedHukum,
              onTap: () async {
                if (_isVoteLockedByFinalizedHukum) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _forcedValidVote
                            ? 'Hükmünüz kesinleşti: deliller geçerli kabul edildi.'
                            : 'Hükmünüz kesinleşti: deliller geçersiz kabul edildi.',
                      ),
                      backgroundColor: Colors.blueGrey,
                    ),
                  );
                  return;
                }
                if (userEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geçersiz  için giriş yapmalısınız'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                await _castVote(evidence.id, userEmail, 'dislike');
              },
              isActive: isDisliked,
            ),
          ),
        ],
      ),
    );
  }

  /// Like/Dislike Butonu
  Widget _buildLikeButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    final palette = SeyirPalette.of(context);
    return Semantics(
      button: true,
      selected: isActive,
      enabled: !isDisabled,
      label: label,
      child: InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? palette.surfaceMuted
              : isActive
                  ? color.withValues(alpha: 0.15)
                  : palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? palette.border
                : isActive
                    ? color
                    : color.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDisabled
                  ? Colors.grey[500]
                  : isActive
                      ? color
                      : color.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: SeyirTokens.typeCaption,
                    color: isDisabled
                        ? palette.textMuted
                        : isActive
                            ? color
                            : palette.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: SeyirTokens.typeTitle,
                    fontWeight: FontWeight.bold,
                    color: isDisabled
                        ? palette.textMuted
                        : isActive
                            ? color
                            : color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    ),
    );
  }

  /// Tarih formatlama
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Bugün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  /// Delil detay sayfasını aç
  void _openEvidenceDetail(EvidenceModel evidence) {
    final fresh = _service.getEvidenceById(evidence.id) ?? evidence;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DelilDetayPage(
          userEmail: widget.userEmail,
          evidence: fresh,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      _showStoredVotes();
    });
  }
}

