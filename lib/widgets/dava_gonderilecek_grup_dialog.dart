import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/friendship_model.dart';
import '../models/registration_model.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';

/// Dava açılırken yargıç grubunu seçtiren bilet diyalogu.
///
/// Atama dizeleri değişmez: `Grup19`, `Arkadaşlar`, `Takipçiler`,
/// `Tanımadıklarım`. Her kart kendi havuzundan 7 yargıç seçer; davacı ve
/// davalı bu yediye girmez. Havuz 7'den kısaysa eksik kadro Grup-19 ile aynı
/// zincirle tamamlanır. Seçili kartın özeti 7 yargıç + sen + davalı, toplam
/// 9 kişidir. Dördüncü kartın havuzu arkadaş kategorisi değildir. Kaldırılan
/// Herkes / Tanımadıklarım kategorileri Takipçi sayılır; bu kart ise
/// [HiveDatabaseService.pickGroupRecipients] ile aynı kümedir: kabul edilmiş
/// arkadaşı, takipçisi ve takip ettiği olmayan kayıtlı kişiler.
class DavaGonderilecekGrupDialog extends StatefulWidget {
  const DavaGonderilecekGrupDialog({
    super.key,
    required this.onConfirm,
    this.openerEmail,
    this.defendant,
  });

  final ValueChanged<String> onConfirm;

  /// Dava açan. Havuz sayıları bu kişiye göre okunur.
  final String? openerEmail;

  /// Davalı metni. Boşsa özette davalı yer almaz.
  final String? defendant;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onConfirm,
    String? openerEmail,
    String? defendant,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DavaGonderilecekGrupDialog(
        onConfirm: onConfirm,
        openerEmail: openerEmail,
        defendant: defendant,
      ),
    );
  }

  @override
  State<DavaGonderilecekGrupDialog> createState() =>
      _DavaGonderilecekGrupDialogState();
}

class _DavaGonderilecekGrupDialogState extends State<DavaGonderilecekGrupDialog>
    with SingleTickerProviderStateMixin {
  static const Duration _stampDuration = Duration(milliseconds: 420);

  String? _selectedGroup;
  AnimationController? _stampController;
  late final _DavaGrupSecimi _secim;

  void _ensureStamp() {
    if (_stampController != null) return;
    _stampController = AnimationController(vsync: this, duration: _stampDuration);
  }

  AnimationController get _stamp {
    _ensureStamp();
    return _stampController!;
  }

  @override
  void initState() {
    super.initState();
    _ensureStamp();
    _secim = _DavaGrupSecimi.resolve(
      openerEmail: widget.openerEmail,
      defendant: widget.defendant,
    );
  }

  @override
  void dispose() {
    _stampController?.dispose();
    super.dispose();
  }

  void _select(String value) {
    if (_selectedGroup == value) return;
    setState(() => _selectedGroup = value);
    HapticFeedback.selectionClick();
    HapticFeedback.mediumImpact();
    if (MediaQuery.disableAnimationsOf(context)) {
      _stamp.value = 0;
      return;
    }
    _stamp.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    _ensureStamp();
    final palette = SeyirPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : SeyirTokens.motion;
    final selected = _secim.card(_selectedGroup);
    final headerInk = selected == null
        ? palette.foreground(SeyirTokens.brandDeep)
        : palette.foreground(selected.color);
    final headerFill = selected == null
        ? palette.brandSoft
        : palette.tint(selected.color);
    final headerBorder = selected == null
        ? palette.tintBorder(SeyirTokens.brandDeep)
        : palette.tintBorder(selected.color);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Dialog(
      backgroundColor: palette.surface,
      surfaceTintColor: palette.surface,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space4,
        vertical: SeyirTokens.space6,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(SeyirTokens.radiusXl)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SeyirTokens.space4,
            SeyirTokens.space6,
            SeyirTokens.space4,
            SeyirTokens.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: headerFill),
                duration: motion,
                builder: (context, fill, child) {
                  return DavaHukmeJaggedHeader(
                    title: 'Davayı Hükme Gönder',
                    fillColor: fill ?? headerFill,
                    borderColor: headerBorder,
                    inkColor: headerInk,
                    stamp: _stamp,
                    textStyle: palette.display(
                      color: headerInk,
                      weight: FontWeight.w800,
                    ),
                  );
                },
              ),
              const SizedBox(height: SeyirTokens.space6),
              for (var i = 0; i < _secim.cards.length; i++) ...[
                if (i > 0) const SizedBox(height: SeyirTokens.space3),
                _GrupOptionCard(
                  data: _secim.cards[i],
                  selected: _selectedGroup == _secim.cards[i].value,
                  motion: motion,
                  onTap: () => _select(_secim.cards[i].value),
                ),
              ],
              const SizedBox(height: SeyirTokens.space6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.textPrimary,
                        minimumSize: const Size(0, SeyirTokens.tapTarget),
                        padding: const EdgeInsets.symmetric(
                          vertical: SeyirTokens.space3,
                          horizontal: SeyirTokens.space3,
                        ),
                        side: BorderSide(color: palette.border),
                        shape: const RoundedRectangleBorder(
                          borderRadius: SeyirTokens.radiusLgAll,
                        ),
                      ),
                      child: Text(
                        'İPTAL',
                        style: palette.title(weight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: SeyirTokens.space4),
                  Expanded(
                    child: FilledButton(
                      key: const Key('dava-grup-ata'),
                      onPressed: selected == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onConfirm(selected.value);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: selected == null
                            ? scheme.primary.withValues(alpha: 0.38)
                            : scheme.primary,
                        foregroundColor: selected == null
                            ? palette.textMuted
                            : scheme.onPrimary,
                        disabledBackgroundColor:
                            scheme.primary.withValues(alpha: 0.38),
                        disabledForegroundColor: palette.textMuted,
                        minimumSize: const Size(0, SeyirTokens.tapTarget),
                        padding: const EdgeInsets.symmetric(
                          vertical: SeyirTokens.space3,
                          horizontal: SeyirTokens.space3,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: SeyirTokens.radiusLgAll,
                        ),
                        elevation: selected == null ? 0 : 2,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selected?.ataLabel ?? 'DAVA ATA',
                          maxLines: 1,
                          style: palette.title(
                            weight: FontWeight.w700,
                            color: selected == null
                                ? palette.textMuted
                                : scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrupOptionCard extends StatelessWidget {
  const _GrupOptionCard({
    required this.data,
    required this.selected,
    required this.motion,
    required this.onTap,
  });

  final _GrupCardData data;
  final bool selected;
  final Duration motion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final notice = data.notice;
    return AnimatedContainer(
      duration: motion,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: SeyirTokens.radiusLgAll,
        border: Border.all(
          color: selected ? SeyirTokens.brand : palette.surface,
          width: 2,
        ),
      ),
      child: Material(
        color: palette.surface,
        borderRadius: SeyirTokens.radiusLgAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('dava-grup-${data.value}'),
          onTap: onTap,
          borderRadius: SeyirTokens.radiusLgAll,
          splashColor: data.color.withValues(alpha: 0.16),
          highlightColor: data.color.withValues(alpha: 0.08),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
            child: AnimatedContainer(
              duration: motion,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: SeyirTokens.space4,
                vertical: SeyirTokens.space3,
              ),
              decoration: BoxDecoration(
                color: selected ? palette.tint(data.color) : palette.surfaceMuted,
                borderRadius: SeyirTokens.radiusLgAll,
                border: Border.all(
                  color: selected ? data.color : palette.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        data.icon,
                        size: SeyirTokens.space6,
                        color: selected
                            ? palette.foreground(data.color)
                            : palette.textSecondary,
                      ),
                      const SizedBox(width: SeyirTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: palette.headline(
                                weight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: selected
                                    ? palette.foreground(data.color)
                                    : palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: SeyirTokens.space1),
                            Text(
                              data.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: palette.body(color: palette.textSecondary),
                            ),
                            const SizedBox(height: SeyirTokens.space1),
                            Text(
                              '${data.poolSize} kişi',
                              key: Key('dava-grup-count-${data.value}'),
                              style: palette.caption(
                                weight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        duration: motion,
                        opacity: selected ? 1 : 0,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: selected
                              ? palette.foreground(data.color)
                              : palette.surface,
                          size: SeyirTokens.space6,
                        ),
                      ),
                    ],
                  ),
                  if (notice != null) ...[
                    const SizedBox(height: SeyirTokens.space2),
                    Text(
                      notice,
                      style: palette.caption(
                        color: palette.foreground(SeyirTokens.warning),
                      ),
                    ),
                  ],
                  ClipRect(
                    child: AnimatedAlign(
                      duration: motion,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      heightFactor: selected ? 1 : 0,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: SeyirTokens.space3,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (data.members.isNotEmpty) ...[
                                    _AvatarStack(
                                      people: data.members,
                                      poolSize: data.poolSize,
                                      accent: data.color,
                                    ),
                                    const SizedBox(height: SeyirTokens.space2),
                                  ],
                                  Text(
                                    data.summary,
                                    key: const Key('dava-grup-summary'),
                                    style: palette.body(
                                      weight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
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
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.people,
    required this.poolSize,
    required this.accent,
  });

  final List<RegistrationModel> people;
  final int poolSize;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(5).toList();
    final extra = poolSize - shown.length;
    const double size = 32;
    const double step = 20;
    final count = shown.length + (extra > 0 ? 1 : 0);
    final width = size + (count - 1) * step;

    return SizedBox(
      height: size,
      width: width,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: _PoolAvatar(person: shown[i], accent: accent, size: size),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: _PlusBadge(extra: extra, accent: accent, size: size),
            ),
        ],
      ),
    );
  }
}

class _PoolAvatar extends StatelessWidget {
  const _PoolAvatar({
    required this.person,
    required this.accent,
    required this.size,
  });

  final RegistrationModel person;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final initials = _initials(person.judgeName);
    final fallback = ColoredBox(
      color: palette.tint(accent),
      child: Center(
        child: Text(
          initials,
          style: palette.caption(
            weight: FontWeight.w800,
            color: palette.foreground(accent),
          ),
        ),
      ),
    );
    final image = _avatarImage(person.profileImage, fallback);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: palette.surface, width: 2),
        color: palette.tint(accent),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

class _PlusBadge extends StatelessWidget {
  const _PlusBadge({
    required this.extra,
    required this.accent,
    required this.size,
  });

  final int extra;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.tint(accent),
        border: Border.all(color: palette.surface, width: 2),
      ),
      child: Text(
        '+$extra',
        style: palette.caption(
          weight: FontWeight.w800,
          color: palette.foreground(accent),
        ),
      ),
    );
  }
}

Widget _avatarImage(String? raw, Widget fallback) {
  final provider = _imageProvider(raw);
  if (provider == null) return fallback;
  return Image(
    image: provider,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => fallback,
  );
}

ImageProvider? _imageProvider(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('data:image')) {
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    try {
      return MemoryImage(base64Decode(value.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }
  final path = value.startsWith('file://') ? value.substring(7) : value;
  if (path.startsWith('/')) return FileImage(File(path));
  return null;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final word = parts.first;
    return word.length >= 2
        ? word.substring(0, 2).toUpperCase()
        : word.toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

/// Bilet / makbuz tarzı tırtıklı üst–alt kenar; dolgu ve çerçeve tek path ile çizilir.
class DavaHukmeJaggedHeader extends StatelessWidget {
  const DavaHukmeJaggedHeader({
    super.key,
    required this.title,
    this.textStyle,
    this.fillColor,
    this.borderColor,
    this.inkColor,
    this.stamp,
  });

  final String title;
  final TextStyle? textStyle;
  final Color? fillColor;
  final Color? borderColor;
  final Color? inkColor;
  final Animation<double>? stamp;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final ink = inkColor ?? palette.foreground(SeyirTokens.brandDeep);
    final style = textStyle ??
        palette.display(
          color: ink,
          weight: FontWeight.w800,
        );

    return CustomPaint(
      painter: _JaggedTicketHeaderPainter(
        fillColor: fillColor ?? palette.brandSoft,
        borderColor: borderColor ?? palette.tintBorder(SeyirTokens.brandDeep),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SeyirTokens.space4,
          SeyirTokens.space4,
          SeyirTokens.space4,
          SeyirTokens.space4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StampGavel(color: ink, stamp: stamp),
            const SizedBox(width: SeyirTokens.space3),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final resolvedStyle = style;
                  final baseFontSize =
                      resolvedStyle.fontSize ?? SeyirTokens.typeDisplay;
                  const minScale = 0.84;

                  final textPainter = TextPainter(
                    text: TextSpan(text: title, style: resolvedStyle),
                    maxLines: 1,
                    textDirection: Directionality.of(context),
                  )..layout(maxWidth: double.infinity);

                  final intrinsicWidth = textPainter.width;
                  final availableWidth = constraints.maxWidth;
                  final widthScale = intrinsicWidth > 0
                      ? (availableWidth / intrinsicWidth).clamp(minScale, 1.0)
                      : 1.0;

                  return Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: resolvedStyle.copyWith(
                      fontSize: baseFontSize * widthScale,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampGavel extends StatelessWidget {
  const _StampGavel({required this.color, this.stamp});

  final Color color;
  final Animation<double>? stamp;

  @override
  Widget build(BuildContext context) {
    final animation = stamp;
    if (animation == null) {
      return Icon(Icons.gavel_rounded, size: 20, color: color);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          final pulse = math.sin(t * math.pi);
          return SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (pulse * 0.7).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 1.55 - (0.55 * t),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -0.4 * pulse,
                  child: Transform.scale(
                    scale: 1 + (0.22 * pulse),
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.gavel_rounded, size: 20, color: color),
      ),
    );
  }
}

class _JaggedTicketHeaderPainter extends CustomPainter {
  _JaggedTicketHeaderPainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  static const double _r = SeyirTokens.radiusMd;
  static const double _toothW = 9;
  static const double _toothD = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true,
    );
  }

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(0, h - _r);
    path.arcToPoint(
      Offset(_r, h),
      radius: const Radius.circular(_r),
      clockwise: false,
    );

    var x = _r;
    while (x < w - _r - 0.5) {
      final next = math.min(x + _toothW, w - _r);
      final mid = (x + next) / 2;
      path.lineTo(mid, h - _toothD);
      path.lineTo(next, h);
      x = next;
    }

    path.arcToPoint(
      Offset(w, h - _r),
      radius: const Radius.circular(_r),
      clockwise: false,
    );
    path.lineTo(w, _r);
    path.arcToPoint(
      Offset(w - _r, 0),
      radius: const Radius.circular(_r),
      clockwise: false,
    );

    x = w - _r;
    while (x > _r + 0.5) {
      final next = math.max(x - _toothW, _r);
      final mid = (x + next) / 2;
      path.lineTo(mid, _toothD);
      path.lineTo(next, 0);
      x = next;
    }

    path.arcToPoint(
      const Offset(0, _r),
      radius: const Radius.circular(_r),
      clockwise: false,
    );
    path.lineTo(0, h - _r);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _JaggedTicketHeaderPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}

class _GrupCardData {
  const _GrupCardData({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.ataLabel,
    required this.poolSize,
    required this.yargic,
    required this.rastgeleDoldurulur,
    required this.davaliVar,
    required this.members,
    required this.color,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final String ataLabel;
  final int poolSize;
  final int yargic;
  final bool rastgeleDoldurulur;
  final bool davaliVar;
  final List<RegistrationModel> members;
  final Color color;
  final IconData icon;

  String? get notice {
    if (poolSize >= 7) return null;
    if (rastgeleDoldurulur) {
      return 'Bu grupta yeterli kişi yok. Eksik yerler rastgele doldurulur.';
    }
    return 'Bu grupta yeterli kişi yok. Eksik yerler bu havuzda tamamlanmaz.';
  }

  String get summary => _atamaOzeti(yargic: yargic, davaliVar: davaliVar);
}

class _DavaGrupSecimi {
  const _DavaGrupSecimi(this.cards);

  final List<_GrupCardData> cards;

  _GrupCardData? card(String? value) {
    if (value == null) return null;
    for (final item in cards) {
      if (item.value == value) return item;
    }
    return null;
  }

  static _DavaGrupSecimi resolve({
    String? openerEmail,
    String? defendant,
  }) {
    final opener = openerEmail == null || openerEmail.trim().isEmpty
        ? null
        : HiveDatabaseService.getRegistrationByEmail(openerEmail.trim());
    final openerId = opener?.id;
    final openerMail = opener?.email ?? openerEmail?.trim();
    final defendantText = _meaningfulDefendant(defendant);
    final all = HiveDatabaseService.getAllRegistrations();

    final grupEmails = HiveDatabaseService.getRegisteredGrup19MemberEmails();
    final friendships = openerId == null
        ? const <FriendshipModel>[]
        : HiveDatabaseService.getAcceptedFriendships(openerId);
    final followers = openerId == null
        ? const <FriendshipModel>[]
        : HiveDatabaseService.getFollowers(openerId);
    final following = openerId == null
        ? const <FriendshipModel>[]
        : HiveDatabaseService.getFollowingUsers(openerId);

    final friendIds = friendships
        .map((f) => f.requesterId == openerId ? f.recipientId : f.requesterId)
        .toSet();
    final followerIds = followers.map((f) => f.requesterId).toSet();
    final followingIds = following.map((f) => f.recipientId).toSet();
    final strangerExclude = <String>{
      ...friendships.expand((f) => [f.requesterId, f.recipientId]),
      ...followerIds,
      ...followingIds,
      if (openerId != null) openerId,
    };

    final grupMembers = _peopleByEmail(all, grupEmails);
    final friendMembers = _uniqueById(
      friendIds.map((id) => _byId(all, id)).whereType<RegistrationModel>(),
    );
    final followerMembers = _uniqueById(
      followerIds.map((id) => _byId(all, id)).whereType<RegistrationModel>(),
    );
    final strangerMembers = all
        .where((r) => !strangerExclude.contains(r.id))
        .toList();

    final davaliVar = defendantText != null;

    _GrupCardData build({
      required String value,
      required String title,
      required String subtitle,
      required int poolSize,
      required List<RegistrationModel> members,
      required Color color,
      required IconData icon,
    }) {
      final plan = _planJudges(
        primary: members,
        everyone: all,
        openerEmail: openerMail,
        defendant: defendantText,
      );
      return _GrupCardData(
        value: value,
        title: title,
        subtitle: subtitle,
        ataLabel: _ataLabel(title),
        poolSize: poolSize,
        yargic: plan.yargic,
        rastgeleDoldurulur: plan.rastgele,
        davaliVar: davaliVar,
        members: _sorted(members),
        color: color,
        icon: icon,
      );
    }

    return _DavaGrupSecimi([
      build(
        value: 'Grup19',
        title: 'Grup-19',
        subtitle: 'Grup-19’dan 7 üye seç',
        poolSize: grupEmails.length,
        members: grupMembers,
        color: SeyirTokens.sectionEvidence,
        icon: Icons.group_rounded,
      ),
      build(
        value: 'Arkadaşlar',
        title: 'Arkadaşlar',
        subtitle: 'Arkadaşlardan 7 üye seç',
        poolSize: friendships.length,
        members: friendMembers,
        color: SeyirTokens.sectionPeople,
        icon: Icons.people_alt_rounded,
      ),
      build(
        value: 'Takipçiler',
        title: 'Takipçiler',
        subtitle: 'Takipçilerden 7 üye seç',
        poolSize: followers.length,
        members: followerMembers,
        color: SeyirTokens.sectionGift,
        icon: Icons.notifications_active_rounded,
      ),
      build(
        value: 'Tanımadıklarım',
        title: 'Tanımadıklarım',
        subtitle: 'Tanımadıklarından 7 üye seç',
        poolSize: strangerMembers.length,
        members: strangerMembers,
        color: SeyirTokens.sectionAppeal,
        icon: Icons.public_rounded,
      ),
    ]);
  }
}

class _JudgePlan {
  const _JudgePlan({required this.yargic, required this.rastgele});

  final int yargic;
  final bool rastgele;
}

_JudgePlan _planJudges({
  required List<RegistrationModel> primary,
  required List<RegistrationModel> everyone,
  required String? openerEmail,
  required String? defendant,
}) {
  bool blocked(RegistrationModel person) {
    final settings = HiveDatabaseService.getSettings(person.email);
    if (settings == null) return false;
    final allowsDava = settings.privacySettings['genel_davaacilsin'] ?? true;
    final allowsSevenJudge = settings.privacySettings['davet_7yargic'] ?? true;
    return !allowsDava || !allowsSevenJudge;
  }

  bool isOpener(RegistrationModel person) =>
      openerEmail != null &&
      person.email.trim().toLowerCase() == openerEmail.trim().toLowerCase();

  bool isDefendant(RegistrationModel person) {
    final needle = defendant?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return false;
    return person.email.trim().toLowerCase() == needle ||
        person.judgeName.trim().toLowerCase() == needle;
  }

  final own = primary
      .where((person) => !isOpener(person) && !isDefendant(person) && !blocked(person))
      .length;
  final eligible = <String>{};
  for (final person in everyone) {
    if (isOpener(person) || isDefendant(person) || blocked(person)) continue;
    eligible.add(person.email);
  }
  final yargic = math.min(7, eligible.length);
  return _JudgePlan(yargic: yargic, rastgele: own < 7 && yargic > own);
}

String _atamaOzeti({required int yargic, required bool davaliVar}) {
  final roller = <String>['$yargic yargıç', 'sen'];
  var toplam = yargic + 1;
  if (davaliVar) {
    roller.add('davalı');
    toplam += 1;
  }
  return '${roller.join(' + ')}, toplam $toplam kişi alacak';
}

String _ataLabel(String title) => '$title${_dativeSuffix(title)} ata';

String _dativeSuffix(String phrase) {
  const back = {'a', 'A', 'ı', 'I', 'o', 'O', 'u', 'U'};
  const front = {'e', 'E', 'i', 'İ', 'ö', 'Ö', 'ü', 'Ü'};
  for (var i = phrase.length - 1; i >= 0; i--) {
    final char = phrase[i];
    if (back.contains(char)) return '’a';
    if (front.contains(char)) return '’e';
  }
  return '’a';
}

String? _meaningfulDefendant(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty ||
      text == 'Davalı  adını gir ' ||
      text == 'Beklemede') {
    return null;
  }
  return text;
}

RegistrationModel? _byId(List<RegistrationModel> all, String id) {
  for (final person in all) {
    if (person.id == id) return person;
  }
  return null;
}

List<RegistrationModel> _peopleByEmail(
  List<RegistrationModel> all,
  Set<String> emails,
) {
  final wanted = emails.map((email) => email.trim().toLowerCase()).toSet();
  return all
      .where((person) => wanted.contains(person.email.trim().toLowerCase()))
      .toList();
}

List<RegistrationModel> _uniqueById(Iterable<RegistrationModel> people) {
  final seen = <String>{};
  final result = <RegistrationModel>[];
  for (final person in people) {
    if (seen.add(person.id)) result.add(person);
  }
  return result;
}

List<RegistrationModel> _sorted(List<RegistrationModel> people) {
  final copy = List<RegistrationModel>.from(people);
  copy.sort((a, b) {
    final byName = a.judgeName.compareTo(b.judgeName);
    if (byName != 0) return byName;
    return a.email.compareTo(b.email);
  });
  return copy;
}
