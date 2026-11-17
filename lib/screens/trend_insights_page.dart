import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../models/sekiz_hukum_arguments.dart';
import '../services/hive_database_service.dart';
import '../services/statistics_analytics_service.dart';
import '../services/trend_engagement_service.dart';
import '../services/trending_insights_service.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/delil_surface.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import 'actigim_davalar_page.dart';
import 'davaci_unlulur_page.dart';
import 'haykirislarim_page.dart';
import 'katildigim_davalar_page.dart';
import 'sekiz_hukum_page.dart';
import 'statistics_dashboard_page.dart';
import 'yargila_page.dart';

/// Trend davalar ve haykırışlar ekranı.
class TrendInsightsPage extends StatefulWidget {
  /// İsteğe bağlı kullanıcı e-posta bilgisi.
  final String? userEmail;

  /// Testlerde sahte trend verisi veya hata üretmek için.
  final Future<TrendingInsights> Function({String? userEmail})? insightsLoader;

  /// Varsayılan kurucu.
  const TrendInsightsPage({
    super.key,
    this.userEmail,
    this.insightsLoader,
  });

  @override
  State<TrendInsightsPage> createState() => _TrendInsightsPageState();
}

class _TrendInsightsPageState extends State<TrendInsightsPage>
    with SingleTickerProviderStateMixin {
  final _service = const TrendingInsightsService();
  late final TabController _tabController;
  TrendingInsights? _insights;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Trend verilerini yükler.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final loader = widget.insightsLoader;
      final data = loader != null
          ? await loader(userEmail: widget.userEmail)
          : await _service.load(userEmail: widget.userEmail);
      if (!mounted) return;
      setState(() {
        _insights = data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Trend verileri alınamadı. Lütfen tekrar deneyin.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: palette.surface,
        body: SafeArea(
          child: AppExpandableIconMenu(
            expandBody: true,
            panelWidth: 72,
            duration: const Duration(milliseconds: 250),
            items: [
              AppExpandableIconMenuItem(
                onTap: () {},
                customChild: _SideNavigationMenu(userEmail: widget.userEmail),
              ),
            ],
            headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
              ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
              // Başlık, Menü ve Yenile butonu
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SeyirTokens.space4,
                  vertical: SeyirTokens.space2,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: isOpen ? 'Menüyü kapat' : 'Menü',
                      style: delilIconButtonStyle(foreground: SeyirTokens.reject),
                      icon: Icon(
                        isOpen ? MdiIcons.close : MdiIcons.menuOpen,
                        color: SeyirTokens.reject,
                      ),
                      onPressed: toggle,
                    ),
                    const SizedBox(width: SeyirTokens.space2),
                    Expanded(
                      child: Text(
                        'Trend Davalar & Haykırışlar',
                        style: palette.headline(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: _isLoading
                            ? palette.textMuted
                            : Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Yenile',
                      style: delilIconButtonStyle(
                        foreground: _isLoading
                            ? palette.textMuted
                            : Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _isLoading ? null : _loadData,
                    ),
                  ],
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                labelColor: palette.textPrimary,
                unselectedLabelColor: palette.textSecondary,
                indicatorColor: SeyirTokens.brand,
                dividerColor: palette.border,
                labelStyle: palette.title(),
                unselectedLabelStyle: palette.title(weight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Trend Davalar'),
                  Tab(text: 'Trend Haykırışlar'),
                ],
              ),
              ],
              );
            },
            body: RefreshIndicator(
                        onRefresh: _loadData,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _TrendList(
                              isLoading: _isLoading,
                              error: _error,
                              cases: _insights?.trendDavalar ?? const [],
                              userEmail: widget.userEmail,
                              emptyTitle: 'Trend dava bulunamadı',
                              emptyMessage:
                                  'Yeni davalar destek aldıkça burada görünecek.',
                              onRetry: _loadData,
                            ),
                            _TrendList(
                              isLoading: _isLoading,
                              error: _error,
                              cases: _insights?.trendHaykirislar ?? const [],
                              userEmail: widget.userEmail,
                              emptyTitle: 'Trend haykırış bulunamadı',
                              emptyMessage:
                                  'Kaydedilen davalar destek aldıkça burada görünecek.',
                              onRetry: _loadData,
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

/// Trend listelerini gösteren widget.
class _TrendList extends StatelessWidget {
  const _TrendList({
    required this.cases,
    required this.isLoading,
    required this.error,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.userEmail,
    required this.onRetry,
  });

  final List<CaseInsight> cases;
  final bool isLoading;
  final String? error;
  final String emptyTitle;
  final String emptyMessage;
  final String? userEmail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(SeyirTokens.space6),
        children: [
          _TrendErrorCard(
            message: error!,
            onRetry: onRetry,
          ),
        ],
      );
    }

    if (cases.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(SeyirTokens.space6),
        children: [
          DelilSoftEmpty(
            title: emptyTitle,
            message: emptyMessage,
            icon: MdiIcons.trendingDown,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(SeyirTokens.space4),
      itemCount: cases.length,
      separatorBuilder: (_, __) => const SizedBox(height: SeyirTokens.space3),
      itemBuilder: (context, index) {
        final insight = cases[index];
        return _TrendCaseCard(
          key: ValueKey('trend-card-${insight.id}-$index'),
          insight: insight,
          rank: index + 1,
          userEmail: userEmail,
        );
      },
    );
  }
}

/// Kırmızı hata kartı. Kenarlık koyu temada da seçilir; yeniden deneme vardır.
class _TrendErrorCard extends StatelessWidget {
  const _TrendErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    const Color accent = SeyirTokens.reject;
    final Color ink = palette.foreground(accent);
    final Color borderColor = palette.isDark
        ? Color.lerp(accent, SeyirTokens.neutral0, 0.45)!
        : accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SeyirTokens.space6),
      decoration: BoxDecoration(
        color: palette.tint(accent),
        borderRadius: SeyirTokens.radiusLgAll,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.error_outline,
            color: ink,
            size: 48,
          ),
          const SizedBox(height: SeyirTokens.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: palette.title(color: ink),
          ),
          const SizedBox(height: SeyirTokens.space4),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                SeyirTokens.tapTarget,
                SeyirTokens.tapTarget,
              ),
              foregroundColor: ink,
              side: BorderSide(color: borderColor),
            ),
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

/// Tekil trend kartını yönetir.
class _TrendCaseCard extends StatefulWidget {
  const _TrendCaseCard({
    super.key,
    required this.insight,
    required this.rank,
    required this.userEmail,
  });

  final CaseInsight insight;
  final int rank;
  final String? userEmail;

  @override
  State<_TrendCaseCard> createState() => _TrendCaseCardState();
}

class _TrendCaseCardState extends State<_TrendCaseCard> {
  final _engagementService = const TrendEngagementService();
  TrendEngagementSnapshot? _snapshot;
  bool _isEngagementLoading = false;
  String? _engagementError;

  int get _supportCount =>
      _snapshot?.supportCount ?? widget.insight.supportCount;

  int get _condemnCount =>
      _snapshot?.condemnCount ?? widget.insight.opposeCount;

  int get _commentCount =>
      _snapshot?.commentCount ?? widget.insight.commentCount;

  bool get _loggedIn {
    final email = widget.userEmail;
    return email != null && email.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadEngagement();
  }

  Future<void> _loadEngagement() async {
    setState(() {
      _isEngagementLoading = true;
      _engagementError = null;
    });
    try {
      final snapshot = await _engagementService.load(
        caseId: widget.insight.id,
        userEmail: widget.userEmail,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _engagementError = 'Etkileşim verileri getirilemedi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEngagementLoading = false;
        });
      }
    }
  }

  void _requireLogin(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleReaction(bool isSupport) async {
    final email = widget.userEmail;
    if (email == null || email.isEmpty) {
      _requireLogin('Lütfen bu işlem için giriş yapın.');
      return;
    }
    setState(() {
      _isEngagementLoading = true;
      _engagementError = null;
    });
    try {
      final snapshot = await _engagementService.toggleReaction(
        caseId: widget.insight.id,
        userEmail: email,
        isSupport: isSupport,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _engagementError = 'Aksiyon tamamlanamadı. Lütfen tekrar deneyin.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEngagementLoading = false;
        });
      }
    }
  }

  /// Yorum listesini girişsiz açar. Yazma formu yalnızca girişliyken gelir.
  Future<void> _openComments() async {
    final email = widget.userEmail;
    final payload = await showModalBottomSheet<_CommentPayload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentComposerSheet(
        comments: _snapshot?.comments ?? const [],
        canWrite: _loggedIn,
      ),
    );
    if (payload == null || email == null || email.isEmpty) return;

    setState(() {
      _isEngagementLoading = true;
      _engagementError = null;
    });
    try {
      final snapshot = await _engagementService.addComment(
        caseId: widget.insight.id,
        userEmail: email,
        message: payload.message,
        isAnonymous: payload.isAnonymous,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum gönderildi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _engagementError = 'Yorum gönderilemedi. Lütfen tekrar deneyin.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEngagementLoading = false;
        });
      }
    }
  }

  /// Yargıla ve katıldığım kartlarıyla aynı: 8-Hüküm dava sayfası.
  Future<void> _openRelatedCase() async {
    final String id = widget.insight.id;
    Map<String, dynamic>? raw;
    try {
      raw = HiveDatabaseService.getOpenedDavaById(id);
    } catch (_) {}
    if (raw == null) {
      try {
        raw = _findDava(HiveDatabaseService.getSavedDavalar(), id);
      } catch (_) {}
    }
    if (raw == null) {
      try {
        raw = await HiveDatabaseService.getAcceptedDavaById(id);
      } catch (_) {}
    }
    if (!mounted) return;

    final String title = _field(
      raw,
      const ['davaAdi', 'adi', 'title'],
      widget.insight.title,
    );
    final String davali = _field(raw, const ['davali'], '');
    final String davaci = _field(raw, const ['davaci'], '');
    final String gorev = _field(raw, const ['mevkii', 'userRole'], '');
    final String kalan = _field(raw, const ['kalanSure'], '');

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SekizHukumPage(
          userEmail: widget.userEmail,
          arguments: SekizHukumArguments(
            davaId: id.isNotEmpty ? id : null,
            davaAdi: title.isNotEmpty ? title : 'Dava adı belirtilmedi',
            davaDavali: davali.isNotEmpty ? davali : 'Davalı bilgisi yok',
            davaDavaci: davaci.isNotEmpty ? davaci : 'Davacı bilgisi yok',
            davaGorev: gorev.isNotEmpty ? gorev : 'Görev bilgisi yok',
            kalanSure: kalan.isNotEmpty ? kalan : 'Süre bilgisi yok',
            openedAt: widget.insight.openedAt,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _findDava(
    List<Map<String, dynamic>> list,
    String id,
  ) {
    for (final Map<String, dynamic> item in list) {
      final String itemId = (item['id'] ?? item['davaId'] ?? '').toString();
      if (itemId == id) return item;
    }
    return null;
  }

  String _field(
    Map<String, dynamic>? raw,
    List<String> keys,
    String fallback,
  ) {
    if (raw != null) {
      for (final String key in keys) {
        final String value = raw[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return fallback.trim();
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final hashtag = widget.insight.hashtag?.isNotEmpty == true
        ? widget.insight.hashtag!
        : _fallbackHashtag(widget.insight.title);

    final comments = _snapshot?.comments ?? const <TrendComment>[];

    return Card(
      elevation: 0,
      color: palette.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusLgAll,
        side: BorderSide(color: palette.border, width: 1),
      ),
      child: InkWell(
        onTap: _openRelatedCase,
        borderRadius: SeyirTokens.radiusLgAll,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEngagementLoading)
            const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(SeyirTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SeyirTokens.space3,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.tint(SeyirTokens.brand),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: palette.tintBorder(SeyirTokens.brand),
                        ),
                      ),
                      child: Text(
                        hashtag,
                        style: palette.body(
                          weight: FontWeight.w700,
                          color: palette.foreground(SeyirTokens.brandDeep),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${widget.rank}',
                      style: palette.body(
                        weight: FontWeight.w700,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SeyirTokens.space3),
                Text(
                  widget.insight.title,
                  style: palette.title(),
                ),
                const SizedBox(height: SeyirTokens.space2),
                Wrap(
                  spacing: SeyirTokens.space3,
                  runSpacing: SeyirTokens.space1,
                  children: [
                    _StatChip(
                      icon: Icons.thumb_up_alt_rounded,
                      color: SeyirTokens.accept,
                      label: 'Destek',
                      value: _supportCount,
                    ),
                    _StatChip(
                      icon: Icons.thumb_down_alt_rounded,
                      color: SeyirTokens.reject,
                      label: 'Kınama',
                      value: _condemnCount,
                    ),
                    _StatChip(
                      icon: Icons.comment_rounded,
                      color: SeyirTokens.engageComment,
                      label: 'Yorum',
                      value: _commentCount,
                    ),
                  ],
                ),
                const SizedBox(height: SeyirTokens.space3),
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.insight.category,
                        style: palette.body(
                          weight: FontWeight.w500,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SeyirTokens.space4),
                _TrendActionRow(
                  onSupport: () => _handleReaction(true),
                  onCondemn: () => _handleReaction(false),
                  onComment: _openComments,
                  supportCount: _supportCount,
                  condemnCount: _condemnCount,
                  commentCount: _commentCount,
                  isSupportActive: _snapshot?.userSupported ?? false,
                  isCondemnActive: _snapshot?.userCondemned ?? false,
                ),
                if (_engagementError != null) ...[
                  const SizedBox(height: SeyirTokens.space3),
                  Text(
                    _engagementError!,
                    style: palette.body(
                      weight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (comments.isNotEmpty) ...[
                  const SizedBox(height: SeyirTokens.space3),
                  Divider(color: palette.border),
                  const SizedBox(height: SeyirTokens.space3),
                  ...comments.take(2).map(
                    (comment) => _CommentTile(comment: comment),
                  ),
                  if (comments.length > 2)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _openComments,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            SeyirTokens.tapTarget,
                            SeyirTokens.tapTarget,
                          ),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        child: Text(
                          'Tüm yorumları gör (${comments.length})',
                          style: palette.body(weight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Hashtag boşsa başlıktan üretir.
  String _fallbackHashtag(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '#Dava';
    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), '');
    return '#$collapsed';
  }
}

/// Kart altındaki aksiyon satırı.
class _TrendActionRow extends StatelessWidget {
  const _TrendActionRow({
    required this.onSupport,
    required this.onCondemn,
    required this.onComment,
    required this.supportCount,
    required this.condemnCount,
    required this.commentCount,
    required this.isSupportActive,
    required this.isCondemnActive,
  });

  final VoidCallback onSupport;
  final VoidCallback onCondemn;
  final VoidCallback onComment;
  final int supportCount;
  final int condemnCount;
  final int commentCount;
  final bool isSupportActive;
  final bool isCondemnActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TrendActionButton(
            icon: Icons.thumb_up_alt_rounded,
            label: 'Destek ($supportCount)',
            color: SeyirTokens.accept,
            isActive: isSupportActive,
            onPressed: onSupport,
          ),
        ),
        const SizedBox(width: SeyirTokens.space2),
        Expanded(
          child: _TrendActionButton(
            icon: Icons.thumb_down_alt_rounded,
            label: 'Kınama ($condemnCount)',
            color: SeyirTokens.reject,
            isActive: isCondemnActive,
            onPressed: onCondemn,
          ),
        ),
        const SizedBox(width: SeyirTokens.space2),
        Expanded(
          child: _TrendActionButton(
            icon: Icons.comment_rounded,
            label: 'Yorum ($commentCount)',
            color: SeyirTokens.engageComment,
            onPressed: onComment,
          ),
        ),
      ],
    );
  }
}

/// Tek aksiyon butonu.
class _TrendActionButton extends StatelessWidget {
  const _TrendActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color displayColor =
        isActive ? palette.foreground(color) : palette.textSecondary;
    final Color borderColor = color.withValues(alpha: isActive ? 0.75 : 0.55);
    return TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(
          horizontal: SeyirTokens.space1,
          vertical: SeyirTokens.space2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: SeyirTokens.radiusMdAll,
          side: BorderSide(color: borderColor),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: displayColor,
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: palette.caption(
          weight: FontWeight.w600,
          color: displayColor,
        ),
      ),
    );
  }
}

/// Bottom sheet'ten dönen payload.
class _CommentPayload {
  const _CommentPayload(this.message, this.isAnonymous);

  final String message;
  final bool isAnonymous;
}

/// Yorum listesi. Yazma alanı yalnızca giriş yapılmışsa gösterilir.
class _CommentComposerSheet extends StatefulWidget {
  const _CommentComposerSheet({
    required this.comments,
    required this.canWrite,
  });

  final List<TrendComment> comments;
  final bool canWrite;

  @override
  State<_CommentComposerSheet> createState() => _CommentComposerSheetState();
}

class _CommentComposerSheetState extends State<_CommentComposerSheet> {
  late final TextEditingController _controller;
  bool _anonymous = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSend = widget.canWrite && _controller.text.trim().isNotEmpty;
    final comments = widget.comments;

    return Padding(
      padding: const EdgeInsets.only(top: SeyirTokens.space6),
      child: Material(
        color: palette.card,
        borderRadius: SeyirTokens.sheetTop,
        child: Padding(
          padding: EdgeInsets.only(
            left: SeyirTokens.space4,
            right: SeyirTokens.space4,
            top: SeyirTokens.space4,
            bottom: SeyirTokens.space4 + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: SeyirTokens.space4),
              Text(
                'Yorumlar',
                style: palette.headline(),
              ),
              const SizedBox(height: SeyirTokens.space4),
              if (comments.isEmpty)
                DelilSoftEmpty(
                  title: widget.canWrite ? 'İlk yorumu sen yaz' : 'Henüz yorum yok',
                  message: widget.canWrite
                      ? 'Bu dava için ilk yorumu sen bırakabilirsin.'
                      : 'Yorumlar giriş yapmadan da okunur.',
                  icon: Icons.chat_bubble_outline_rounded,
                )
              else
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => Divider(color: palette.border),
                    itemBuilder: (context, index) {
                      return _CommentTile(comment: comments[index]);
                    },
                  ),
                ),
              const SizedBox(height: SeyirTokens.space4),
              if (!widget.canWrite)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space2),
                  child: Text(
                    'Yorum yazmak için giriş yapın.',
                    textAlign: TextAlign.center,
                    style: palette.body(
                      weight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                )
              else ...[
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  style: palette.body(),
                  decoration: InputDecoration(
                    hintText: 'Yorumunu yaz...',
                    hintStyle: palette.body(
                      weight: FontWeight.w400,
                      color: palette.textMuted,
                    ),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: SeyirTokens.radiusMdAll,
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: SeyirTokens.radiusMdAll,
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: SeyirTokens.radiusMdAll,
                      borderSide: BorderSide(
                        color: palette.foreground(SeyirTokens.brand),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SeyirTokens.space2),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _anonymous,
                  onChanged: (value) => setState(() => _anonymous = value),
                  title: Text(
                    'Gizli Tanık olarak paylaş',
                    style: palette.body(),
                  ),
                ),
                const SizedBox(height: SeyirTokens.space2),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: canSend
                        ? () => Navigator.pop(
                              context,
                              _CommentPayload(_controller.text.trim(), _anonymous),
                            )
                        : null,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Gönder'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kart içindeki yorum görünümü.
class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final TrendComment comment;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final initials = comment.author.isNotEmpty
        ? comment.author.characters.first.toUpperCase()
        : '?';
    final subtitle = comment.isAnonymous
        ? '${comment.author} • Gizli Tanık'
        : comment.author;
    final formattedDate = _formatDate(comment.timestamp);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: palette.surfaceMuted,
        child: Text(
          initials,
          style: palette.body(weight: FontWeight.w700),
        ),
      ),
      title: Text(
        subtitle,
        style: palette.body(weight: FontWeight.w600),
      ),
      subtitle: Text(
        comment.message,
        style: palette.body(
          weight: FontWeight.w400,
          color: palette.textSecondary,
        ),
      ),
      trailing: Text(
        formattedDate,
        textAlign: TextAlign.end,
        style: palette.caption(color: palette.textMuted),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year\n$hour:$minute';
  }
}

/// Tek bir istatistik etiketi.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color ink = palette.foreground(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.tint(color),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.tintBorder(color)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ink),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: palette.caption(
              weight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sol navigasyon ikonlarını gösteren menü.
class _SideNavigationMenu extends StatelessWidget {
  const _SideNavigationMenu({required this.userEmail});

  final String? userEmail;

  void _push(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Container(
      color: palette.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space6),
        children: [
          _NavIconButton(
            icon: Icons.gavel_rounded,
            tooltip: 'Yargıla',
            onTap: () => _push(context, YargilaPage(userEmail: userEmail)),
          ),
          _NavIconButton(
            assetPath: 'lib/icons/06_left_row_katildigim_davalar_icon.png',
            tooltip: 'Katıldığım Davalar',
            onTap: () => _push(
              context,
              KatildigimDavalarPage(userEmail: userEmail),
            ),
          ),
          _NavIconButton(
            assetPath: 'lib/icons/06_left_row_actigim_davalar_icon.png',
            tooltip: 'Açtığım Davalar',
            onTap: () => _push(
              context,
              ActigimDavalarPage(userEmail: userEmail),
            ),
          ),
          _NavIconButton(
            assetPath: 'lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png',
            tooltip: 'Davacı Ünlüler',
            onTap: () => _push(
              context,
              DavaciUnlulurPage(userEmail: userEmail),
            ),
          ),
          _NavIconButton(
            assetPath: 'lib/icons/06_left_row_haykirislarim.png',
            tooltip: 'Haykırışlarım',
            onTap: () => _push(
              context,
              HaykirislarimPage(userEmail: userEmail),
            ),
          ),
          _NavIconButton(
            icon: MdiIcons.chartBar,
            tooltip: 'Dava İstatistikleri',
            onTap: () => _push(
              context,
              StatisticsDashboardPage(userEmail: userEmail),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigasyon ikon kartı.
class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    this.icon,
    this.assetPath,
    required this.tooltip,
    required this.onTap,
  });

  final IconData? icon;
  final String? assetPath;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final child = icon != null
        ? Icon(icon, size: 28, color: palette.textSecondary)
        : Image.asset(
            assetPath!,
            width: 28,
            height: 28,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
      child: InkWell(
        onTap: onTap,
        borderRadius: SeyirTokens.radiusLgAll,
        child: Tooltip(
          message: tooltip,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: SeyirTokens.tapTarget,
              minHeight: SeyirTokens.tapTarget,
            ),
            child: Container(
              padding: const EdgeInsets.all(SeyirTokens.space4),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: SeyirTokens.radiusLgAll,
                border: Border.all(color: palette.border),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
