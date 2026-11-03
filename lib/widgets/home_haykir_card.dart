import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/dava_provider.dart';
import '../screens/haykirislarim_page.dart';
import '../screens/saved_widgets_page.dart';
import '../services/hive_database_service.dart';
import '../utils/haykir_duration.dart';
import 'expandable_comment_text.dart';
import 'haykir_card_shell.dart';
import 'shared/app_snack.dart';

class HaykirCardWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final Map<String, dynamic> payload;
  final DavaProvider davaProvider;
  final String? userEmail;
  final bool showCloseButton; // ✅ X close ikonunu göster/gizle
  final bool interactionsOnly; // ✅ Yalnızca etkileşim paneli (katıldığım kartı için)
  final VoidCallback? onPostUpdated;

  const HaykirCardWidget({
    super.key,
    required this.post,
    required this.payload,
    required this.davaProvider,
    this.userEmail,
    this.showCloseButton = true, // ✅ Varsayılan olarak göster
    this.interactionsOnly = false,
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

  String _resolveAuthorDisplayName(String? email) {
    if (email == null || email.isEmpty) return 'Bilinmeyen';
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(email);
      return user?.judgeName ?? email.split('@').first;
    } catch (_) {
      return email.split('@').first;
    }
  }

  Widget _buildGroupJoinButton(String haykirId, bool isDisabled) {
    Widget iconChild(Widget child) => Padding(
          padding: const EdgeInsets.all(6),
          child: child,
        );

    if (isDisabled) {
      return iconChild(Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(MdiIcons.accountGroup, size: 26, color: Colors.grey.shade600),
      ));
    }

    if (_groupIconController == null) {
      return GestureDetector(
        onTap: () => _onGroupIconTap(haykirId),
        child: iconChild(Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(MdiIcons.accountGroup, size: 26, color: Colors.purple.shade700),
        )),
      );
    }

    return GestureDetector(
      onTap: () => _onGroupIconTap(haykirId),
      child: AnimatedBuilder(
        animation: _groupIconController!,
        builder: (context, child) {
          final animationValue = _groupIconController!.value;
          final opacity = 0.25 +
              (0.75 *
                  (0.5 + 0.5 * (math.sin(animationValue * 2 * math.pi))));
          final scale = 1.0 + (animationValue * 0.12);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: iconChild(Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(
                        alpha: 0.2 + (animationValue * 0.35),
                      ),
                      blurRadius: 6 + (animationValue * 4),
                    ),
                  ],
                ),
                child: Icon(
                  MdiIcons.accountGroup,
                  size: 26,
                  color: Colors.purple.shade700,
                ),
              )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHaykirCommentsPanel(String haykirId) {
    if (!showComments) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () async {
                    if (_commentController.text.trim().isEmpty) return;
                    if (haykirId.isEmpty ||
                        widget.userEmail == null ||
                        widget.userEmail!.isEmpty) {
                      return;
                    }

                    final result = await HiveDatabaseService.addHaykirComment(
                      haykirId: haykirId,
                      userEmail: widget.userEmail!,
                      commentText: _commentController.text.trim(),
                    );

                    if (!mounted) return;

                    if (result['success'] == true) {
                      _commentController.clear();
                      final stats = HiveDatabaseService.getHaykirInteractionStats(
                        haykirId,
                        userEmail: widget.userEmail,
                      );
                      await _persistPostPayload({
                        'commentCount': stats['commentCount'] ?? 0,
                      });
                      _refreshInteractionUi(haykirId: haykirId);
                      showAppSnack(context, '✅ Yorum eklendi!', backgroundColor: Colors.green, duration: Duration(seconds: 1));
                    } else {
                      showAppSnack(context, result['error']?.toString() ?? 'Yorum eklenemedi', backgroundColor: Colors.red, duration: const Duration(seconds: 3));
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              (comment['userName']?.toString() ?? 'U')
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
                              comment['userName']?.toString() ?? 'Bilinmeyen',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            _formatCommentTime(comment['createdAt']?.toString()),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ExpandableCommentText(
                        text: comment['commentText']?.toString() ?? '',
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
    );
  }

  Widget _buildHaykirInteractionsColumn({
    required String haykirId,
    required bool isExpired,
    required bool showSuccessBadge,
    required bool isSuccess,
    required int commentCount,
    required int retweetCount,
    required int likeCount,
    required int kinaCount,
    required bool isCommented,
    required bool isRetweeted,
    required bool isLiked,
    required bool isKina,
    required bool isSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSuccessBadge)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess ? Icons.thumb_up : Icons.thumb_down,
                  size: 16,
                  color: isSuccess ? Colors.amber.shade800 : Colors.red.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  isSuccess ? 'Etkileşim başarılı' : 'Etkileşim başarısız',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSuccess ? Colors.amber.shade900 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        HaykirCompactSocialBar(
          actions: [
            HaykirSocialAction(
              icon: MdiIcons.commentOutline,
              tooltip: 'Yorum',
              count: commentCount,
              color: Colors.green,
              isActive: isCommented || showComments,
              onTap: () {
                setState(() {
                  showComments = !showComments;
                  if (showComments && haykirId.isNotEmpty) {
                    _comments = HiveDatabaseService.getHaykirComments(haykirId);
                  }
                });
              },
            ),
            HaykirSocialAction(
              icon: MdiIcons.repeat,
              tooltip: 'Retweet',
              count: retweetCount,
              color: Colors.orange,
              isActive: isRetweeted,
              isDisabled: _isRetweetDisabled(haykirId) ||
                  _isRetweetPermanent(haykirId),
              onTap: (_isRetweetDisabled(haykirId) ||
                      _isRetweetPermanent(haykirId))
                  ? null
                  : () {
                      if (isRetweeted) {
                        if (_isRetweetPermanent(haykirId)) {
                          showAppSnack(context, '⚠️ Grup-19 ile yapılan retweet geri alınamaz!', backgroundColor: Colors.orange, duration: Duration(seconds: 3));
                          return;
                        }
                        _undoRetweet(haykirId);
                      } else {
                        _showRetweetDialog(haykirId);
                      }
                    },
            ),
            HaykirSocialAction(
              icon: isLiked ? MdiIcons.heart : MdiIcons.heartOutline,
              tooltip: 'Beğen',
              count: likeCount,
              color: Colors.red,
              isActive: isLiked,
              isDisabled: isExpired,
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
                        await HiveDatabaseService.updateHaykirInteractionStats(
                          haykirId: haykirId,
                          userEmail: widget.userEmail!,
                          action: 'kina',
                        );
                      }
                      await HiveDatabaseService.updateHaykirInteractionStats(
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
                          'kinaCount': kinaCount > 0 ? kinaCount - 1 : 0,
                      });
                      _refreshInteractionUi(haykirId: haykirId);
                    },
            ),
            HaykirSocialAction(
              icon: MdiIcons.handWaveOutline,
              tooltip: 'Kına',
              count: kinaCount,
              color: Colors.grey,
              isActive: isKina,
              isDisabled: isExpired,
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
                        await HiveDatabaseService.updateHaykirInteractionStats(
                          haykirId: haykirId,
                          userEmail: widget.userEmail!,
                          isLiked: false,
                        );
                      }
                      await HiveDatabaseService.updateHaykirInteractionStats(
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
            HaykirSocialAction(
              icon: isSaved ? MdiIcons.bookmark : MdiIcons.bookmarkOutline,
              tooltip: 'Kaydet',
              count: isSaved ? 1 : 0,
              color: Colors.purple,
              isActive: isSaved,
              onTap: () async {
                if (haykirId.isEmpty ||
                    widget.userEmail == null ||
                    widget.userEmail!.isEmpty) {
                  return;
                }
                final newIsSaved = !isSaved;
                await HiveDatabaseService.updateHaykirInteractionStats(
                  haykirId: haykirId,
                  userEmail: widget.userEmail!,
                  isSaved: newIsSaved,
                );
                const widgetId = 'home_page_Kaydet_bookmark';
                if (newIsSaved) {
                  HiveDatabaseService.saveWidget(
                    userEmail: widget.userEmail!,
                    widgetId: widgetId,
                    label: 'Kaydet',
                    iconCodePoint: MdiIcons.bookmark.codePoint.toString(),
                    colorValue: Colors.purple.value,
                    count: 0,
                    isActive: newIsSaved,
                    isDisabled: false,
                    sourcePage: 'home_page',
                    additionalData: {
                      'postId': widget.post['id']?.toString() ?? '',
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
                  showAppSnack(context, newIsSaved
                          ? '✅ Kaydedildi!'
                          : '❌ Kayıt kaldırıldı!', backgroundColor: Colors.purple, duration: const Duration(seconds: 2));
                }
              },
            ),
          ],
        ),
        _buildHaykirCommentsPanel(haykirId),
      ],
    );
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

    // ✅ Haykır süresi: 19 gün
    final kalanSure = HaykirDuration.formatRemaining(createdAt);
    final isExpired = HaykirDuration.isExpired(createdAt);

    if (isExpired && !_scoringChecked) {
      _scoringChecked = true;
      _checkAndApplyHaykirScoring(haykirId, likeCount, kinaCount, createdAt)
          .then((_) {
        if (mounted) setState(() {});
      });
    }

    // ✅ Kullanıcının bu haykıra katılıp katılmadığını kontrol et
    bool isParticipated = false;
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      final katildigimHaykirler =
          HiveDatabaseService.getKatildigimHaykirler(widget.userEmail!);
      isParticipated = katildigimHaykirler.any((h) =>
          (h['haykirId']?.toString() ?? h['id']?.toString() ?? '') == haykirId);
    }

    // ✅ Grup ikonu pasif mi? (19 gün geçmişse veya kullanıcı zaten katılmışsa)
    final bool isGroupIconDisabled = isExpired || isParticipated;

    final haykirData = HiveDatabaseService.getHaykir(haykirId);
    final scoringApplied = haykirData?['scoringApplied'] == 'true' ||
        haykirData?['scoringApplied'] == true;
    final isSuccessStr = haykirData?['isSuccess']?.toString();
    final isSuccess = isSuccessStr == 'true';
    final showSuccessBadge =
        isExpired && scoringApplied && isSuccessStr != null;

    final authorEmail = widget.post['authorEmail']?.toString() ??
        widget.payload['userEmail']?.toString() ??
        haykirData?['userEmail']?.toString();
    final authorName = _resolveAuthorDisplayName(authorEmail);
    final shellExpanded = !widget.showCloseButton || isExpanded;

    final interactions = _buildHaykirInteractionsColumn(
      haykirId: haykirId,
      isExpired: isExpired,
      showSuccessBadge: showSuccessBadge,
      isSuccess: isSuccess,
      commentCount: commentCount,
      retweetCount: retweetCount,
      likeCount: likeCount,
      kinaCount: kinaCount,
      isCommented: isCommented,
      isRetweeted: isRetweeted,
      isLiked: isLiked,
      isKina: isKina,
      isSaved: isSaved,
    );

    if (widget.interactionsOnly) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: interactions,
      );
    }

    Widget buildShell({required bool expanded}) {
      return HaykirCardShell(
        variant: HaykirCardShellVariant.feed,
        isExpanded: expanded,
        isExpired: isExpired,
        adi: adi,
        slogan: slogan,
        direme: direme,
        createdAt: createdAt,
        authorDisplayName: authorName,
        authorSubtitle: formatHaykirPublishedAgo(createdAt),
        showSuccessBadge: showSuccessBadge,
        isSuccess: isSuccess,
        trailingAction: _buildGroupJoinButton(haykirId, isGroupIconDisabled),
        onHeaderTap: widget.showCloseButton
            ? () {
                setState(() {
                  if (expanded) {
                    isExpanded = false;
                    _expandController.reverse();
                  } else {
                    isExpanded = true;
                    _expandController.forward();
                  }
                });
              }
            : null,
        expandedChildren: expanded ? [interactions] : null,
      );
    }

    if (widget.showCloseButton && !isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: buildShell(expanded: false),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showCloseButton && isExpanded)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.expand_less, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      isExpanded = false;
                      _expandController.reverse();
                    });
                  },
                  tooltip: 'Daralt',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    await widget.davaProvider
                        .removeHomeFeedPost(widget.post['id']);
                    if (mounted) {
                      showAppSnack(context, '✅ Haykır seyir defterinden kaldırıldı', duration: Duration(seconds: 2));
                    }
                  },
                  tooltip: 'Seyir defterinden kaldır',
                ),
              ],
            ),
          buildShell(expanded: shellExpanded),
        ],
      ),
    );
  }

  // ✅ Adım 1: Grup ikonuna tıklandığında haykıra katıl
  Future<void> _onGroupIconTap(String haykirId) async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      if (mounted) {
        showAppSnack(context, '❌ Kullanıcı bilgisi bulunamadı', backgroundColor: Colors.red);
      }
      return;
    }

    try {
      // Haykır verilerini al
      final haykirData = HiveDatabaseService.getHaykir(haykirId);
      if (haykirData == null) {
        if (mounted) {
          showAppSnack(context, '❌ Haykır bulunamadı', backgroundColor: Colors.red);
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
        'kalanSure': '${HaykirDuration.totalDays} gün 0 saat',
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

        showAppSnack(context, '✅ Haykıra katıldınız! "KATILDIĞIM" sekmesinde görünecek.', backgroundColor: Colors.purple, duration: const Duration(seconds: 3), action: SnackBarAction(
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
            ),);
      }
    } catch (e) {
      print('❌ Haykıra katılma hatası: $e');
      if (mounted) {
        showAppSnack(context, '❌ Hata: $e', backgroundColor: Colors.red);
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
      showAppSnack(context, '❌ Kullanıcı bilgisi bulunamadı', backgroundColor: Colors.red);
      return;
    }

    try {
      final haykirData = HiveDatabaseService.getHaykir(haykirId);
      if (haykirData == null) {
        showAppSnack(context, '❌ Haykır bulunamadı', backgroundColor: Colors.red);
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
          showAppSnack(context, '✅ Grup19\'a gönderildi! $totalInvitations kişiye davet gönderildi (Grup19 + haykır başlatan kişi). Bu retweet geri alınamaz.', backgroundColor: Colors.orange, duration: const Duration(seconds: 4));
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
          showAppSnack(context, '✅ Seyir defterinize eklendi! Artık retweet yapamazsınız.', backgroundColor: Colors.orange, duration: Duration(seconds: 3));
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
        showAppSnack(context, '❌ Hata: $e', backgroundColor: Colors.red);
      }
    }
  }

  // ✅ Retweet'i geri al
  Future<void> _undoRetweet(String haykirId) async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return;

    // ✅ Grup-19 ile yapılmışsa geri alınamaz
    if (_isRetweetPermanent(haykirId)) {
      if (mounted) {
        showAppSnack(context, '⚠️ Grup-19 ile yapılan retweet geri alınamaz!', backgroundColor: Colors.orange, duration: Duration(seconds: 3));
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
        showAppSnack(context, '✅ Retweet geri alındı', backgroundColor: Colors.orange, duration: Duration(seconds: 2));
      }
    } catch (e) {
      print('❌ Retweet geri alma hatası: $e');
      if (mounted) {
        showAppSnack(context, '❌ Hata: $e', backgroundColor: Colors.red);
      }
    }
  }

  /// ✅ 19 gün sonunda Haykır puanlama kontrolü
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
                      showAppSnack(context, '❌ "$label" kayıttan kaldırıldı', backgroundColor: Colors.grey[700], duration: const Duration(seconds: 2));
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
                      showAppSnack(context, '✅ "$label" kaydedilenler arşivine eklendi', backgroundColor: Colors.purple, duration: const Duration(seconds: 2), action: SnackBarAction(
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
                          ));
                    }
                  } else {
                    showAppSnack(context, '⚠️ Kaydetmek için giriş yapmalısınız', backgroundColor: Colors.orange, duration: Duration(seconds: 2));
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
