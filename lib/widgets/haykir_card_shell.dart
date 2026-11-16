import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import '../theme/seyir_tokens.dart';
import '../utils/haykir_duration.dart';
import 'home_feed_card_shell.dart';

enum HaykirCardShellVariant { feed, katildigim }

/// Haykır kartlarının ortak estetik gövdesi (seyir defteri + katıldığım).
class HaykirCardShell extends StatelessWidget {
  final HaykirCardShellVariant variant;
  final bool isExpanded;
  final bool isExpired;
  final String adi;
  final String slogan;
  final String direme;
  final String createdAt;
  final String authorDisplayName;
  final String authorSubtitle;
  final bool showSuccessBadge;
  final bool isSuccess;
  final Widget? trailingAction;
  final VoidCallback? onHeaderTap;
  final List<Widget>? expandedChildren;

  const HaykirCardShell({
    super.key,
    required this.variant,
    required this.isExpanded,
    required this.isExpired,
    required this.adi,
    required this.slogan,
    required this.direme,
    required this.createdAt,
    required this.authorDisplayName,
    required this.authorSubtitle,
    this.showSuccessBadge = false,
    this.isSuccess = false,
    this.trailingAction,
    this.onHeaderTap,
    this.expandedChildren,
  });

  MaterialColor get _primary =>
      variant == HaykirCardShellVariant.feed ? Colors.orange : Colors.teal;

  Color get _secondary => variant == HaykirCardShellVariant.feed
      ? const Color(0xFFE65100)
      : const Color(0xFF5B4B8A);

  String get _typeBadge =>
      variant == HaykirCardShellVariant.feed ? 'HAYKIR' : 'Katıldın';

  ({bool isExpired, double progress, String label, Color accent}) _timeInfo() {
    final expired = HaykirDuration.isExpired(createdAt);
    final progress = HaykirDuration.remainingProgress(createdAt);
    final label = HaykirDuration.formatRemaining(createdAt);

    if (expired || isExpired) {
      return (
        isExpired: true,
        progress: 0.0,
        label: label,
        accent: Colors.grey,
      );
    }

    final accent = progress > 0.33
        ? _primary
        : progress > 0.15
            ? Colors.deepOrange
            : Colors.red;

    return (
      isExpired: false,
      progress: progress,
      label: label,
      accent: accent,
    );
  }

  String _feedTimeLabel() {
    final DateTime? parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return authorSubtitle;
    return seyirRelativeTime(parsed);
  }

  Widget _buildFeedCard(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final time = _timeInfo();
    final bool muted = isExpired || time.isExpired;
    final String initial = authorDisplayName.isNotEmpty
        ? authorDisplayName[0].toUpperCase()
        : '?';
    final Color ink = muted ? palette.textSecondary : palette.textPrimary;

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: SeyirTokens.space2,
          runSpacing: SeyirTokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SeyirTokens.space2,
                vertical: SeyirTokens.space1,
              ),
              decoration: BoxDecoration(
                color: SeyirTokens.brandDeep,
                borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
              ),
              child: Text(
                _typeBadge,
                style: palette.caption(
                  weight: FontWeight.w800,
                  color: palette.onSolid(SeyirTokens.brandDeep),
                ),
              ),
            ),
            Text(
              time.isExpired ? 'Süre doldu' : 'Aktif',
              style: palette.caption(
                weight: FontWeight.w700,
                color: time.isExpired
                    ? palette.textMuted
                    : palette.foreground(SeyirTokens.brandDeep),
              ),
            ),
            if (!time.isExpired)
              Text(
                time.label,
                style: palette.caption(
                  weight: FontWeight.w700,
                  color: palette.foreground(SeyirTokens.brandDeep),
                ),
              ),
            if (showSuccessBadge)
              Text(
                isSuccess ? 'Başarılı' : 'Başarısız',
                style: palette.caption(
                  weight: FontWeight.w800,
                  color: palette.foreground(
                    isSuccess ? SeyirTokens.accept : SeyirTokens.reject,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: SeyirTokens.space3),
        ClipRRect(
          borderRadius: SeyirTokens.radiusSmAll,
          child: LinearProgressIndicator(
            value: time.isExpired ? 0 : time.progress,
            minHeight: 5,
            backgroundColor: palette.surfaceMuted,
            color: time.isExpired ? palette.textMuted : SeyirTokens.brand,
          ),
        ),
        const SizedBox(height: SeyirTokens.space3),
        Text(adi, style: palette.headline(color: ink)),
        if (slogan.isNotEmpty) ...[
          const SizedBox(height: SeyirTokens.space2),
          Text(
            slogan,
            maxLines: isExpanded ? null : 2,
            overflow: isExpanded ? null : TextOverflow.ellipsis,
            style: palette.body(
              color: palette.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (direme.isNotEmpty) ...[
          const SizedBox(height: SeyirTokens.space2),
          Text(
            direme,
            maxLines: isExpanded ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: palette.body(
              weight: FontWeight.w700,
              color: palette.foreground(SeyirTokens.brandDeep),
            ),
          ),
        ],
      ],
    );

    final bool showActions = isExpanded &&
        (trailingAction != null ||
            (expandedChildren != null && expandedChildren!.isNotEmpty));

    return HomeFeedCardShell(
      name: authorDisplayName,
      timeLabel: _feedTimeLabel(),
      onHeaderTap: onHeaderTap,
      avatar: CircleAvatar(
        radius: 18,
        backgroundColor: palette.brandSoft,
        child: Text(
          initial,
          style: palette.title(
            color: palette.foreground(SeyirTokens.brandDeep),
          ),
        ),
      ),
      headerTrailing: onHeaderTap == null
          ? null
          : AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: SeyirTokens.motion,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: palette.textSecondary,
              ),
            ),
      body: body,
      actions: showActions
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (trailingAction != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: trailingAction!,
                  ),
                if (expandedChildren != null) ...expandedChildren!,
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (variant == HaykirCardShellVariant.feed) {
      return _buildFeedCard(context);
    }
    final palette = SeyirPalette.of(context);
    final time = _timeInfo();
    final muted = isExpired || time.isExpired;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SeyirTokens.radiusLg),
        gradient: LinearGradient(
          colors: muted
              ? [palette.surfaceMuted, palette.surface]
              : [
                  palette.tint(_primary),
                  palette.card,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: muted ? palette.border : palette.tintBorder(_primary),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: muted ? 0.05 : (isExpanded ? 0.16 : 0.08)),
            blurRadius: isExpanded ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onHeaderTap,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRow(context, time),
                    const SizedBox(height: 12),
                    _buildProgressBar(context, time),
                    const SizedBox(height: 14),
                    Text(
                      adi,
                      style: TextStyle(
                        fontSize: isExpanded
                            ? SeyirTokens.typeHeadline
                            : SeyirTokens.typeTitle,
                        fontWeight: FontWeight.bold,
                        color: muted ? palette.textSecondary : palette.textPrimary,
                      ),
                    ),
                    if (slogan.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSlogan(context, muted),
                    ],
                    const SizedBox(height: 12),
                    _buildAuthorRow(context, muted),
                    if (!isExpanded && direme.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDiremeChip(context, compact: true),
                    ],
                  ],
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                if (direme.isNotEmpty)
                  Row(
                    children: [
                      Expanded(child: _buildDiremeChip(context)),
                      if (trailingAction != null) ...[
                        const SizedBox(width: 8),
                        trailingAction!,
                      ],
                    ],
                  )
                else if (trailingAction != null) ...[
                  Align(alignment: Alignment.centerRight, child: trailingAction),
                ],
                if (expandedChildren != null) ...expandedChildren!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(
    BuildContext context,
    ({bool isExpired, double progress, String label, Color accent}) time,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_secondary, _primary.shade600]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                variant == HaykirCardShellVariant.feed
                    ? Icons.campaign
                    : Icons.group,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                _typeBadge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: time.isExpired
                ? SeyirPalette.of(context).surfaceMuted
                : time.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: time.isExpired ? Colors.grey.shade400 : time.accent,
            ),
          ),
          child: Text(
            time.isExpired ? 'Süre doldu' : 'Aktif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: time.isExpired
                  ? SeyirPalette.of(context).textSecondary
                  : time.accent,
            ),
          ),
        ),
        if (showSuccessBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.amber.shade100 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.thumb_up : Icons.thumb_down,
                  size: 12,
                  color: isSuccess ? Colors.amber.shade800 : Colors.red.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  isSuccess ? 'Başarılı' : 'Başarısız',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        isSuccess ? Colors.amber.shade900 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        if (!time.isExpired)
          Text(
            time.label,
            style: TextStyle(
              fontSize: SeyirTokens.typeCaption,
              fontWeight: FontWeight.w600,
              color: time.accent,
            ),
          ),
        if (onHeaderTap != null) ...[
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 280),
            child: Icon(Icons.keyboard_arrow_down, color: _primary.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    ({bool isExpired, double progress, String label, Color accent}) time,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: time.isExpired ? 0 : time.progress,
        minHeight: 5,
        backgroundColor: SeyirPalette.of(context).surfaceMuted,
        valueColor: AlwaysStoppedAnimation<Color>(
          time.isExpired ? Colors.grey.shade400 : time.accent,
        ),
      ),
    );
  }

  Widget _buildSlogan(BuildContext context, bool muted) {
    final palette = SeyirPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: muted ? palette.surfaceMuted : palette.tint(_secondary),
        borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
        border: Border.all(
          color: muted ? palette.border : palette.tintBorder(_secondary),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            MdiIcons.formatQuoteOpen,
            size: 20,
            color: muted ? palette.textMuted : palette.foreground(_secondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slogan,
              maxLines: isExpanded ? null : 1,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
              style: palette.body(
                color: muted ? palette.textMuted : palette.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context, bool muted) {
    final palette = SeyirPalette.of(context);
    final initial =
        authorDisplayName.isNotEmpty ? authorDisplayName[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: muted ? palette.surfaceMuted : palette.tint(_primary),
          child: Text(
            initial,
            style: palette.body(
              weight: FontWeight.w800,
              color: muted ? palette.textSecondary : palette.foreground(_primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorDisplayName,
                style: palette.body(
                  weight: FontWeight.w600,
                  color: muted ? palette.textSecondary : palette.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                authorSubtitle,
                style: palette.caption(color: palette.textMuted),
              ),
            ],
          ),
        ),
        Icon(
          Icons.campaign_outlined,
          size: 18,
          color: muted ? palette.textMuted : _primary.shade400,
        ),
      ],
    );
  }

  Widget _buildDiremeChip(BuildContext context, {bool compact = false}) {
    final palette = SeyirPalette.of(context);
    final ink = palette.foreground(SeyirTokens.reject);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: palette.tint(SeyirTokens.reject),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.tintBorder(SeyirTokens.reject)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MdiIcons.flag, size: compact ? 14 : 16, color: ink),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              direme,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? SeyirTokens.typeCaption : SeyirTokens.typeBody,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kompakt sosyal etkileşim satırı (ikon + sayaç).
class HaykirCompactSocialBar extends StatelessWidget {
  final List<HaykirSocialAction> actions;

  const HaykirCompactSocialBar({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions
          .map((action) => Expanded(child: _HaykirSocialButton(action: action)))
          .toList(),
    );
  }
}

class HaykirSocialAction {
  final IconData icon;
  final String tooltip;
  final int count;
  final Color color;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const HaykirSocialAction({
    required this.icon,
    required this.tooltip,
    required this.count,
    required this.color,
    this.isActive = false,
    this.isDisabled = false,
    this.onTap,
    this.onLongPress,
  });
}

class _HaykirSocialButton extends StatelessWidget {
  final HaykirSocialAction action;

  const _HaykirSocialButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final disabled = action.isDisabled;
    final color = disabled
        ? palette.textMuted
        : (action.isActive ? action.color : palette.textSecondary);

    return Tooltip(
      message: action.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : action.onTap,
          onLongPress: disabled ? null : action.onLongPress,
          borderRadius: SeyirTokens.radiusMdAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: SeyirTokens.tapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 22, color: color),
                  if (action.count > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${action.count}',
                      style: palette.caption(
                        weight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatHaykirPublishedAgo(String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) return 'Yayınlandı';
  try {
    final date = DateTime.parse(createdAt);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Az önce yayınlandı';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce yayınlandı';
    if (diff.inDays < 1) return '${diff.inHours} sa önce yayınlandı';
    if (diff.inDays < 7) return '${diff.inDays} gün önce yayınlandı';
    return '${date.day}.${date.month}.${date.year} tarihinde yayınlandı';
  } catch (_) {
    return 'Yayınlandı';
  }
}
