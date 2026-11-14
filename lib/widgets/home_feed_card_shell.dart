import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';
import 'seyir_defteri/seyir_sheet_chrome.dart';

/// Haykır ve dava izleme kartlarının ortak gövdesi.
///
/// Üstte avatar, ad ve göreli zaman; altta hizalı eylem şeridi.
class HomeFeedCardShell extends StatelessWidget {
  const HomeFeedCardShell({
    super.key,
    required this.name,
    required this.timeLabel,
    this.avatar,
    this.body,
    this.actions,
    this.headerTrailing,
    this.onHeaderTap,
    this.margin = cardMargin,
  });

  final String name;
  final String timeLabel;
  final Widget? avatar;
  final Widget? body;
  final Widget? actions;
  final Widget? headerTrailing;
  final VoidCallback? onHeaderTap;
  final EdgeInsetsGeometry margin;

  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: SeyirTokens.space4,
    vertical: SeyirTokens.space2,
  );

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: SeyirTokens.radiusLgAll,
          border: Border.all(color: palette.border),
          boxShadow: palette.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: SeyirTokens.radiusLgAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onHeaderTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SeyirTokens.space4,
                    SeyirTokens.space4,
                    SeyirTokens.space3,
                    SeyirTokens.space3,
                  ),
                  child: Row(
                    children: [
                      avatar ??
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: palette.brandSoft,
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: palette.title(
                                color: palette.foreground(SeyirTokens.brandDeep),
                              ),
                            ),
                          ),
                      const SizedBox(width: SeyirTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: palette.title(),
                            ),
                            const SizedBox(height: SeyirTokens.space1),
                            Text(
                              timeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: palette.caption(),
                            ),
                          ],
                        ),
                      ),
                      if (headerTrailing != null) headerTrailing!,
                    ],
                  ),
                ),
              ),
              if (body != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SeyirTokens.space4,
                    0,
                    SeyirTokens.space4,
                    SeyirTokens.space3,
                  ),
                  child: body,
                ),
              if (actions != null) ...[
                Divider(height: 1, color: palette.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SeyirTokens.space2,
                    vertical: SeyirTokens.space1,
                  ),
                  child: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dava izleme kartı. Kapatma ve durum düğmeleri aynı şeritte hizalanır.
class DavaWatchFeedCard extends StatelessWidget {
  const DavaWatchFeedCard({
    super.key,
    required this.name,
    required this.timeLabel,
    required this.avatar,
    required this.isWatching,
    required this.stateLabel,
    this.onClose,
    this.onToggle,
  });

  final String name;
  final String timeLabel;
  final Widget avatar;
  final bool isWatching;
  final String stateLabel;
  final VoidCallback? onClose;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color accent =
        isWatching ? SeyirTokens.brandDeep : palette.textSecondary;
    return HomeFeedCardShell(
      name: name,
      timeLabel: timeLabel,
      avatar: avatar,
      actions: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_sharp),
            color: SeyirTokens.reject,
            style: IconButton.styleFrom(
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: SeyirTokens.tapTarget,
            child: OutlinedButton(
              onPressed: onToggle,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.foreground(accent),
                backgroundColor: palette.tint(accent),
                side: BorderSide(color: palette.tintBorder(accent)),
                shape: const RoundedRectangleBorder(
                  borderRadius: SeyirTokens.radiusMdAll,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: SeyirTokens.space4,
                ),
              ),
              child: Text(
                stateLabel,
                style: palette.body(weight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Akış yüklenirken kart iskeleti. [CircularProgressIndicator] yerine.
class HomeFeedSkeletonCard extends StatelessWidget {
  const HomeFeedSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Padding(
      padding: HomeFeedCardShell.cardMargin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: SeyirTokens.radiusLgAll,
          border: Border.all(color: palette.border),
        ),
        child: const Padding(
          padding: EdgeInsets.all(SeyirTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkeletonBlock(width: 36, height: 36, round: true),
                  SizedBox(width: SeyirTokens.space3),
                  Expanded(child: SeyirShimmer(lines: 2, height: 12)),
                ],
              ),
              SizedBox(height: SeyirTokens.space4),
              SeyirShimmer(lines: 3, height: 12),
              SizedBox(height: SeyirTokens.space4),
              Row(
                children: [
                  Expanded(child: _SkeletonBlock(height: 28)),
                  SizedBox(width: SeyirTokens.space2),
                  Expanded(child: _SkeletonBlock(height: 28)),
                  SizedBox(width: SeyirTokens.space2),
                  Expanded(child: _SkeletonBlock(height: 28)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeFeedSkeletonList extends StatelessWidget {
  const HomeFeedSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) const HomeFeedSkeletonCard(),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    required this.height,
    this.round = false,
  });

  final double? width;
  final double height;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: round
            ? BorderRadius.circular(height)
            : SeyirTokens.radiusSmAll,
      ),
    );
  }
}

/// Sayfalama hatası. [onRetry] aynı geri çağrıyı çalıştırır.
class HomeFeedErrorCard extends StatelessWidget {
  const HomeFeedErrorCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Padding(
      padding: HomeFeedCardShell.cardMargin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: SeyirTokens.radiusLgAll,
          border: Border.all(color: palette.tintBorder(SeyirTokens.reject)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SeyirTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 36,
                color: palette.foreground(SeyirTokens.reject),
              ),
              const SizedBox(height: SeyirTokens.space3),
              Text(
                'Veriler yüklenirken bir hata oluştu',
                textAlign: TextAlign.center,
                style: palette.title(),
              ),
              const SizedBox(height: SeyirTokens.space4),
              SizedBox(
                height: SeyirTokens.tapTarget,
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: SeyirTokens.brandDeep,
                    foregroundColor: palette.onSolid(SeyirTokens.brandDeep),
                    shape: const RoundedRectangleBorder(
                      borderRadius: SeyirTokens.radiusMdAll,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeyirTokens.space6,
                    ),
                  ),
                  child: Text(
                    'Tekrar dene',
                    style: palette.title(
                      color: palette.onSolid(SeyirTokens.brandDeep),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Henüz dava yok. Başlık aynı kalır; altına kısa bir yardımcı satır eklenir.
class HomeEmptyCases extends StatelessWidget {
  const HomeEmptyCases({super.key});

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color ink = palette.foreground(SeyirTokens.brandDeep);
    return Padding(
      padding: const EdgeInsets.all(SeyirTokens.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 8,
                  child: Icon(
                    Icons.description_outlined,
                    size: 28,
                    color: ink.withValues(alpha: 0.85),
                  ),
                ),
                Icon(Icons.gavel_rounded, size: 40, color: ink),
              ],
            ),
          ),
          const SizedBox(height: SeyirTokens.space4),
          Text(
            'Henüz Dava Açmadınız',
            textAlign: TextAlign.center,
            style: palette.headline(),
          ),
          const SizedBox(height: SeyirTokens.space2),
          Text(
            'Açtığınız davalar burada görünecek.',
            textAlign: TextAlign.center,
            style: palette.body(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
