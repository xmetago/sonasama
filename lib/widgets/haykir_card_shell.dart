import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../utils/haykir_duration.dart';

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

  @override
  Widget build(BuildContext context) {
    final time = _timeInfo();
    final muted = isExpired || time.isExpired;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: muted
              ? [Colors.grey.shade100, Colors.grey.shade50]
              : isExpanded
                  ? [_primary.shade50, _secondary.withValues(alpha: 0.06)]
                  : [Colors.white, _primary.shade50.withValues(alpha: 0.35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: muted
              ? Colors.grey.shade300
              : isExpanded
                  ? _primary.shade300
                  : _primary.shade100,
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
                    _buildTopRow(time),
                    const SizedBox(height: 12),
                    _buildProgressBar(time),
                    const SizedBox(height: 14),
                    Text(
                      adi,
                      style: TextStyle(
                        fontSize: isExpanded ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: muted ? Colors.grey.shade700 : Colors.grey.shade900,
                      ),
                    ),
                    if (slogan.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSlogan(muted),
                    ],
                    const SizedBox(height: 12),
                    _buildAuthorRow(muted),
                    if (!isExpanded && direme.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDiremeChip(compact: true),
                    ],
                  ],
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                if (direme.isNotEmpty)
                  Row(
                    children: [
                      Expanded(child: _buildDiremeChip()),
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
                ? Colors.grey.shade200
                : time.accent.withValues(alpha: 0.12),
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
              color: time.isExpired ? Colors.grey.shade700 : time.accent,
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
              fontSize: 12,
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
    ({bool isExpired, double progress, String label, Color accent}) time,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: time.isExpired ? 0 : time.progress,
        minHeight: 5,
        backgroundColor: _primary.shade100,
        valueColor: AlwaysStoppedAnimation<Color>(
          time.isExpired ? Colors.grey.shade400 : time.accent,
        ),
      ),
    );
  }

  Widget _buildSlogan(bool muted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: muted
            ? Colors.grey.shade100
            : _secondary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: muted
              ? Colors.grey.shade300
              : _secondary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            MdiIcons.formatQuoteOpen,
            size: 20,
            color: muted ? Colors.grey : _secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slogan,
              maxLines: isExpanded ? null : 1,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: muted ? Colors.grey.shade600 : Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(bool muted) {
    final initial =
        authorDisplayName.isNotEmpty ? authorDisplayName[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: muted ? Colors.grey.shade200 : _primary.shade100,
          child: Text(
            initial,
            style: TextStyle(
              color: muted ? Colors.grey.shade700 : _primary.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 14,
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: muted ? Colors.grey.shade700 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                authorSubtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Icon(
          Icons.campaign_outlined,
          size: 18,
          color: muted ? Colors.grey.shade400 : _primary.shade400,
        ),
      ],
    );
  }

  Widget _buildDiremeChip({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MdiIcons.flag, size: compact ? 14 : 16, color: Colors.red.shade700),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              direme,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade800,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions
            .map((action) => Expanded(child: _HaykirSocialButton(action: action)))
            .toList(),
      ),
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
    final disabled = action.isDisabled;
    final color = disabled
        ? Colors.grey.shade400
        : (action.isActive ? action.color : Colors.grey.shade600);

    return Tooltip(
      message: action.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : action.onTap,
          onLongPress: disabled ? null : action.onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: action.isActive && !disabled
                        ? action.color.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, size: 20, color: color),
                ),
                if (action.count > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${action.count}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
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
