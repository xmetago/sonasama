import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../services/statistics_analytics_service.dart';
import '../services/trend_engagement_service.dart';
import '../services/trending_insights_service.dart';
import 'actigim_davalar_page.dart';
import 'davaci_unlulur_page.dart';
import 'haykirislarim_page.dart';
import 'katildigim_davalar_page.dart';
import 'statistics_dashboard_page.dart';
import 'yargila_page.dart';
import '../widgets/common_header_widgets.dart';

/// Trend davalar ve haykırışlar ekranı.
class TrendInsightsPage extends StatefulWidget {
  /// İsteğe bağlı kullanıcı e-posta bilgisi.
  final String? userEmail;

  /// Varsayılan kurucu.
  const TrendInsightsPage({super.key, this.userEmail});

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
  bool _showNavMenu = false;

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
      final data = await _service.load(userEmail: widget.userEmail);
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
              ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
              // Başlık, Menü ve Yenile butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showNavMenu ? MdiIcons.close : MdiIcons.menuOpen,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          _showNavMenu = !_showNavMenu;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Trend Davalar & Haykırışlar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
                      ),
                      tooltip: 'Yenile',
                      onPressed: _isLoading ? null : _loadData,
                    ),
                  ],
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'Trend Davalar'),
                  Tab(text: 'Trend Haykırışlar'),
                ],
              ),
              // İçerik
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _showNavMenu ? 72 : 0,
                      child: _showNavMenu
                          ? _SideNavigationMenu(userEmail: widget.userEmail)
                          : null,
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _TrendList(
                              isLoading: _isLoading,
                              error: _error,
                              cases: _insights?.trendDavalar ?? const [],
                              userEmail: widget.userEmail,
                              emptyMessage:
                                  'Trend dava bulunamadı. Yeni davalar destek aldıkça burada görünecek.',
                            ),
                            _TrendList(
                              isLoading: _isLoading,
                              error: _error,
                              cases: _insights?.trendHaykirislar ?? const [],
                              userEmail: widget.userEmail,
                              emptyMessage:
                                  'Trend haykırış bulunamadı. Kaydedilen davalar destek aldıkça burada görünecek.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    required this.emptyMessage,
    required this.userEmail,
  });

  final List<CaseInsight> cases;
  final bool isLoading;
  final String? error;
  final String emptyMessage;
  final String? userEmail;

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
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: Colors.red[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (cases.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Column(
            children: [
              Icon(
                MdiIcons.trendingDown,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      if (!mounted) return;
      setState(() {
        _isEngagementLoading = false;
      });
    }
  }

  void _requireLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lütfen bu işlem için giriş yapın.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleReaction(bool isSupport) async {
    final email = widget.userEmail;
    if (email == null || email.isEmpty) {
      _requireLogin();
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
      if (!mounted) return;
      setState(() {
        _isEngagementLoading = false;
      });
    }
  }

  Future<void> _handleComment() async {
    final email = widget.userEmail;
    if (email == null || email.isEmpty) {
      _requireLogin();
      return;
    }

    final payload = await showModalBottomSheet<_CommentPayload>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CommentComposerSheet(
        comments: _snapshot?.comments ?? const [],
      ),
    );
    if (payload == null) return;

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
      if (!mounted) return;
      setState(() {
        _isEngagementLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hashtag = widget.insight.hashtag?.isNotEmpty == true
        ? widget.insight.hashtag!
        : _fallbackHashtag(widget.insight.title);

    final comments = _snapshot?.comments ?? const <TrendComment>[];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEngagementLoading)
            const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hashtag,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${widget.rank}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.insight.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _StatChip(
                      icon: Icons.thumb_up_alt_rounded,
                      color: Colors.green,
                      label: 'Destek',
                      value: _supportCount,
                    ),
                    _StatChip(
                      icon: Icons.thumb_down_alt_rounded,
                      color: Colors.red,
                      label: 'Kınama',
                      value: _condemnCount,
                    ),
                    _StatChip(
                      icon: Icons.comment_rounded,
                      color: Colors.blue,
                      label: 'Yorum',
                      value: _commentCount,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.insight.category,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TrendActionRow(
                  onSupport: () => _handleReaction(true),
                  onCondemn: () => _handleReaction(false),
                  onComment: _handleComment,
                  supportCount: _supportCount,
                  condemnCount: _condemnCount,
                  commentCount: _commentCount,
                  isSupportActive: _snapshot?.userSupported ?? false,
                  isCondemnActive: _snapshot?.userCondemned ?? false,
                ),
                if (_engagementError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _engagementError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (comments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  ...comments.take(2).map(
                    (comment) => _CommentTile(comment: comment),
                  ),
                  if (comments.length > 2)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _handleComment,
                        child: Text('Tüm yorumları gör (${comments.length})'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
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
            color: Colors.green,
            isActive: isSupportActive,
            onPressed: onSupport,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TrendActionButton(
            icon: Icons.thumb_down_alt_rounded,
            label: 'Kınama ($condemnCount)',
            color: Colors.red,
            isActive: isCondemnActive,
            onPressed: onCondemn,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TrendActionButton(
            icon: Icons.comment_rounded,
            label: 'Yorum ($commentCount)',
            color: Colors.blue,
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
    final displayColor = isActive ? color : Colors.grey[700];
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(isActive ? 0.6 : 0.2)),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: displayColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: displayColor,
          fontWeight: FontWeight.w600,
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

/// Yorum compose ve liste sheet'i.
class _CommentComposerSheet extends StatefulWidget {
  const _CommentComposerSheet({required this.comments});

  final List<TrendComment> comments;

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSend = _controller.text.trim().isNotEmpty;
    final comments = widget.comments;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yorumlar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (comments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk yorumu sen yaz',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.separated(
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return _CommentTile(comment: comments[index]);
                },
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Yorumunu yaz...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _anonymous,
            onChanged: (value) => setState(() => _anonymous = value),
            title: const Text('Gizli Tanık olarak paylaş'),
          ),
          const SizedBox(height: 8),
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
        backgroundColor: Colors.grey[200],
        child: Text(
          initials,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        subtitle,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(comment.message),
      trailing: Text(
        formattedDate,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
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
  final MaterialColor color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color.shade700,
              fontWeight: FontWeight.w600,
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
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
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
    final child = icon != null
        ? Icon(icon, size: 28, color: Colors.black54)
        : Image.asset(
            assetPath!,
            width: 28,
            height: 28,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

