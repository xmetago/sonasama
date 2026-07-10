import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/evidence_service.dart';
import '../services/hive_database_service.dart';
import '../models/evidence_model.dart';
import '../screens/delil_detay_page.dart';

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

  const EvidenceViewerWidget({
    super.key,
    required this.davaId,
    this.userEmail,
    this.userRole,
    this.title,
    this.showCaseInfo = false,
    this.caseInfoCard,
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
    try {
      await _evidenceService.initialize();
      final counts = _evidenceService.getEvidenceCountsByDavaId(widget.davaId);
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
      setState(() => _isLoading = false);
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: evidenceTypes.map((typeInfo) {
                    final count = _evidenceCounts[typeInfo.type] ?? 0;
                    return _buildEvidenceTypeIcon(typeInfo, count);
                  }).toList(),
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
                      fontSize: 12,
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
                        fontSize: 11,
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
  final Map<String, bool> _userLikes = {}; // evidenceId -> isLiked
  final Map<String, bool> _userDislikes = {}; // evidenceId -> isDisliked
  final Map<String, bool> _userNeutral = {}; // evidenceId -> nötr oy
  bool _isVoteLockedByFinalizedHukum = false;
  bool _forcedValidVote = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _service.initialize();
      await _syncVoteLockWithFinalizedHukum();
      final all = _service.getAllEvidence();
      final targetType = widget.typeInfo.type;
      
      // Filtreleme - trim ve case-insensitive karşılaştırma
      final normalizedDavaId = widget.davaId.trim().toLowerCase();
      final normalizedType = targetType.trim().toLowerCase();
      final filtered = all.where((e) {
        return e.davaId.trim().toLowerCase() == normalizedDavaId && 
               e.type.trim().toLowerCase() == normalizedType;
      }).toList();
      
      // Kullanıcının oy durumunu yükle
      if (widget.userEmail != null) {
        for (var evidence in filtered) {
          final vote = evidence.getUserVote(widget.userEmail!);
          _userLikes[evidence.id] = vote == 'like';
          _userDislikes[evidence.id] = vote == 'dislike';
          _userNeutral[evidence.id] = vote == 'neutral';
        }
      }
      
      setState(() {
        _items = filtered;
        _loading = false;
      });
      
      // Sadece sorun varsa log
      if (filtered.isEmpty && all.isNotEmpty) {
        print('⚠️ ${widget.typeInfo.label}: DavaId eşleşmedi (${widget.davaId})');
      }
    } catch (e) {
      print('❌ Hata: $e');
      setState(() {
        _items = [];
        _loading = false;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.typeInfo.label} Delilleri'),
        backgroundColor: widget.typeInfo.color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
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
              widget.typeInfo.color.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
    );
  }

  /// Boş durum widget'ı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bu türde henüz delil yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.typeInfo.label} delilleri eklendiğinde burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Açıklama
                        Text(
                          evidence.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
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
                                fontSize: 11,
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
                                        fontSize: 10,
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

  /// Like/Dislike Bar
  Widget _buildEvidenceLikeBar(EvidenceModel evidence) {
    final userEmail = widget.userEmail ?? '';
    final isLiked = _userLikes[evidence.id] ?? false;
    final isDisliked = _userDislikes[evidence.id] ?? false;
    final isNeutral = _userNeutral[evidence.id] ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
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

                await _service.toggleLike(evidence.id, userEmail);

                setState(() {
                  _userLikes[evidence.id] = !isLiked;
                  if (_userLikes[evidence.id] == true) {
                    _userDislikes[evidence.id] = false;
                    _userNeutral[evidence.id] = false;
                  }
                });

                _load();
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

                await _service.toggleNeutral(evidence.id, userEmail);

                setState(() {
                  _userNeutral[evidence.id] = !isNeutral;
                  if (_userNeutral[evidence.id] == true) {
                    _userLikes[evidence.id] = false;
                    _userDislikes[evidence.id] = false;
                  }
                });

                _load();
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

                await _service.toggleDislike(evidence.id, userEmail);

                setState(() {
                  _userDislikes[evidence.id] = !isDisliked;
                  if (_userDislikes[evidence.id] == true) {
                    _userLikes[evidence.id] = false;
                    _userNeutral[evidence.id] = false;
                  }
                });

                _load();
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
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[200]
              : isActive
                  ? color.withValues(alpha: 0.15)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[400]!
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
                    fontSize: 11,
                    color: isDisabled
                        ? Colors.grey[600]
                        : isActive
                            ? color
                            : Colors.grey[600],
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDisabled
                        ? Colors.grey[600]
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DelilDetayPage(
          userEmail: widget.userEmail,
          evidence: evidence,
        ),
      ),
    );
  }
}

