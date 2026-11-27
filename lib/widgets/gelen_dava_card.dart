import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/dava_provider.dart';
import '../screens/yargila_page.dart';
import '../services/dava_appeal_judge_assign_service.dart';
import '../services/dava_auto_assign_service.dart';
import '../services/dava_timer_service.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';
import 'countdown_timer_widget.dart';
import 'package:its19/utils/app_logger.dart';

class Dava {
  final String id;
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final String davaKonusu;
  final String davaci; // Davacı bilgisi eklendi
  final DateTime? createdAt; // Dava açılış tarihi
  final DateTime? acceptedAt; // Dava kabul edilme tarihi
  /// AwaitingRole | RoleAssigned | FinalJudgement | …
  final String lifecycleStatus;

  /// Davalı e-posta (üyelik / misafir rozeti için)
  final String? davaliEmail;

  /// Temyiz hakimi görevi mi (tarafın takipçisine atanan)
  final bool isAppealJudgeAssignment;

  Dava({
    required this.id,
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    required this.davaKonusu,
    this.davaci = '', // Varsayılan boş değer
    this.createdAt,
    this.acceptedAt,
    this.lifecycleStatus = DavaLifecycleStatuses.awaitingRole,
    this.davaliEmail,
    this.isAppealJudgeAssignment = false,
  });
}

/// Tema renkleriyle kısa bildirim. Sabit kırmızı/turuncu kullanılmaz.
SnackBar seyirNoticeSnackBar({
  required ColorScheme scheme,
  required String message,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return SnackBar(
    backgroundColor: scheme.inverseSurface,
    behavior: SnackBarBehavior.floating,
    duration: duration,
    // Aksiyon varken Flutter snackbar'ı kalıcı yapar; süre dolunca kapansın.
    persist: false,
    content: Text(
      message,
      style: TextStyle(
        color: scheme.onInverseSurface,
        fontSize: SeyirTokens.typeBody,
      ),
    ),
    action: actionLabel == null
        ? null
        : SnackBarAction(
            label: actionLabel,
            textColor: SeyirTokens.brand,
            onPressed: onAction ?? () {},
          ),
  );
}

/// Reddin kalıcı etkileri: yalnızca bu kullanıcının gelen kutusu,
/// çekilme notu ve Katıldığım Davalar kaydı.
Future<void> commitGelenDavaRejection({
  required Dava dava,
  required String? userEmail,
  DavaProvider? provider,
}) async {
  final email = (userEmail ?? '').trim();
  if (email.isEmpty) return;

  final appeal = dava.isAppealJudgeAssignment ||
      DavaAppealJudgeAssignService.isAppealJudgeRole(dava.mevkii);
  try {
    if (appeal) {
      await HiveDatabaseService.markDavaParticipantStatus(
        davaId: dava.id,
        userEmail: email,
        status: 'manual_rejected',
        reason: 'appeal_judge_declined',
        extra: {
          'mevkii': dava.mevkii.isNotEmpty
              ? dava.mevkii
              : DavaAppealJudgeAssignService.appealJudgeRole,
          'isAppealJudgeAssignment': true,
        },
      );
      await HiveDatabaseService.updateOpenedDava(dava.id, {
        'appealJudgeAssignmentPending': false,
        'appealJudgeDeclined': true,
        'appealJudgeDeclinedAt': DateTime.now().toIso8601String(),
      });
    } else {
      await HiveDatabaseService.markDavaParticipantStatus(
        davaId: dava.id,
        userEmail: email,
        status: 'manual_rejected',
        reason: 'user_rejected',
        extra: {
          if (dava.mevkii.isNotEmpty) 'mevkii': dava.mevkii,
        },
      );

      final reg = HiveDatabaseService.getRegistrationByEmail(email);
      final mevkiiLabel = dava.mevkii.isNotEmpty ? dava.mevkii : 'Katılımcı';
      final kisiAdi = reg?.judgeName ?? email.split('@').first;
      final davaciAd = dava.davaci.isNotEmpty ? dava.davaci : 'Davacı';
      final davaliAd = dava.davali.isNotEmpty ? dava.davali : 'Davalı';
      final davaAdi = dava.adi.isNotEmpty ? dava.adi : 'Dava';
      final narrative =
          '"$mevkiiLabel" "$kisiAdi", vicdanıyla girdiği düelloyu kaybettiği için '
          '"$davaciAd"\'in "$davaliAd"\'ya açtığı "$davaAdi" davasından çekilmek zorunda kalmıştır.';

      await HiveDatabaseService.appendWithdrawalNarrative(dava.id, narrative);
      await HiveDatabaseService.appendDavaHistoryEvent(dava.id, {
        'type': 'withdraw_reject',
        'userEmail': email,
        'mevkii': mevkiiLabel,
        'narrative': narrative,
      });
      await HiveDatabaseService.updateOpenedDava(dava.id, {
        'davaOverallStatus': 'Reddedildi/Çekildi',
      });
      await HiveDatabaseService.saveHukum(
        davaId: dava.id,
        userRole: mevkiiLabel,
        hukumText: narrative,
        userEmail: email,
        hukumSentiment: 'positive',
        isFinalized: true,
      );

      final davaData = {
        'id': dava.id,
        'adi': dava.adi,
        'davaAdi': dava.adi,
        'davaKonusu': dava.davaKonusu,
        'davaci': dava.davaci,
        'davali': dava.davali,
        'displayName': dava.davaci,
        'userEmail': email,
        'mevkii': 'Katılımcı',
        'kalanSure':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'profilResmi': dava.profilResmi,
        'openedAt': DateTime.now().toIso8601String(),
        'acceptedAt': DateTime.now().toIso8601String(),
        'kategori': 'Genel',
        'davaKategori': 'Genel',
        'source': 'gelen_davalar_page',
        'isAccepted': true,
        'isRejected': false,
        'status': 'Reddedildi/Çekildi',
      };
      await HiveDatabaseService.addKatildigimDava(email, davaData);
    }

    await HiveDatabaseService.removeIncomingDavaForUser(email, dava.id);
    if (provider != null) {
      try {
        await provider.reloadKatildigimDavalar(email);
        await provider.reloadIncomingDavalar(email);
      } catch (e) {
        appLog('Red sonrası liste yenilenemedi: $e');
      }
    }
  } catch (e) {
    appLog('Gelen dava reddi kaydedilemedi: $e');
  }
}

class FiveCardCaseInformation extends StatefulWidget {
  final Dava dava;
  final String? userEmail;
  final VoidCallback? onDavaRejected; // Kabul sonrası listeyi tazelemek için
  /// Red onayı: sayfa kartı gizler ve geri alma süresini başlatır.
  final VoidCallback? onRejectQueued;

  const FiveCardCaseInformation({
    super.key,
    required this.dava,
    this.userEmail,
    this.onDavaRejected,
    this.onRejectQueued,
  });

  @override
  State<FiveCardCaseInformation> createState() =>
      _FiveCardCaseInformationState();
}

class _FiveCardCaseInformationState extends State<FiveCardCaseInformation>
    with TickerProviderStateMixin {
  String? selectedRole;
  bool isAccepted = false;
  bool isRejected = false;
  bool showRoleSelection = false;
  bool isRoleConfirmed = false;
  bool _confirmingRole = false;
  bool _showStamp = false;
  bool _pulseWanted = false;
  DateTime? _acceptedAt;
  bool _hasExistingRole = false;
  String? _existingRole;

  late final AnimationController _pulseController;
  late final AnimationController _stampController;

  static const String _yargilaGit = 'Yargıla’ya git';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stampController.dispose();
    super.dispose();
  }

  Duration? _phaseRemaining() {
    final opened = widget.dava.createdAt;
    if (opened == null) return null;
    final segment =
        DavaTimerService.buildIncomingListCountdown(openedAt: opened);
    if (segment == null) return null;
    final left = segment.segmentEnd.difference(DateTime.now());
    if (left.isNegative) return Duration.zero;
    return left;
  }

  String? _urgentLabel() {
    final left = _phaseRemaining();
    if (left == null ||
        left <= Duration.zero ||
        left >= const Duration(hours: 24)) {
      return null;
    }
    final hours = left.inHours >= 1 ? left.inHours : 1;
    return 'Karar için $hours saat kaldı';
  }

  void _schedulePulse(bool wanted) {
    if (_pulseWanted == wanted) return;
    _pulseWanted = wanted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pulseWanted) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    });
  }

  bool _isAppealJudgeAssignmentCard() =>
      widget.dava.isAppealJudgeAssignment ||
      DavaAppealJudgeAssignService.isAppealJudgeRole(widget.dava.mevkii);

  Future<bool> _askConfirm(
    String message,
    String confirmLabel,
    Key confirmKey, {
    Color? confirmColor,
  }) async {
    final palette = SeyirPalette.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final buttonStyle = TextButton.styleFrom(
          minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
          textStyle: const TextStyle(
            fontSize: SeyirTokens.typeTitle,
            fontWeight: FontWeight.w700,
          ),
        );
        return AlertDialog(
          backgroundColor: palette.card,
          title: Text('Emin misin?', style: palette.title()),
          content: Text(message, style: palette.body()),
          actions: [
            TextButton(
              style: buttonStyle,
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Vazgeç',
                  style: palette.title(color: palette.textSecondary)),
            ),
            TextButton(
              key: confirmKey,
              style: buttonStyle,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                confirmLabel,
                style:
                    palette.title(color: confirmColor ?? SeyirTokens.brandDeep),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _startAcceptFlow({bool haptic = true}) async {
    if (haptic) HapticFeedback.lightImpact();
    if (isAccepted && showRoleSelection) return;
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    setState(() {
      isAccepted = true;
      isRejected = false;
    });
    final hasRole = await _checkExistingRole();
    if (!mounted) return;
    if (hasRole && _hasExistingRole) {
      setState(() {
        isAccepted = false;
        showRoleSelection = false;
      });
      messenger.showSnackBar(
        seyirNoticeSnackBar(
          scheme: scheme,
          message:
              'Bu davada zaten "$_existingRole" görevini seçtiniz. Aynı davada farklı bir görev seçemezsiniz.',
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    setState(() {
      showRoleSelection = true;
      if (_isAppealJudgeAssignmentCard()) {
        selectedRole = DavaAppealJudgeAssignService.appealJudgeRole;
      }
    });
  }

  Future<void> _onRejectPressed() async {
    final ok = await _askConfirm(
      'Bu davayı reddetmek istediğine emin misin?',
      'Reddet',
      const Key('gelen-reddet-onay'),
      confirmColor: SeyirTokens.reject,
    );
    if (!ok || !mounted) return;
    HapticFeedback.lightImpact();
    widget.onRejectQueued?.call();
  }

  Future<bool> _confirmSwipe(DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      final ok = await _askConfirm(
        'Bu davayı kabul etmek istediğine emin misin?',
        'Kabul et',
        const Key('gelen-kabul-onay'),
      );
      if (ok && mounted) {
        HapticFeedback.lightImpact();
        await _startAcceptFlow(haptic: false);
      }
      return false;
    }
    if (direction == DismissDirection.endToStart) {
      final ok = await _askConfirm(
        'Bu davayı reddetmek istediğine emin misin?',
        'Reddet',
        const Key('gelen-reddet-onay'),
        confirmColor: SeyirTokens.reject,
      );
      if (!ok || !mounted || widget.onRejectQueued == null) return false;
      HapticFeedback.lightImpact();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final urgentLabel = _urgentLabel();
    final urgent = urgentLabel != null;
    _schedulePulse(urgent && !disableAnimations);
    final openedAt = widget.dava.createdAt ?? DateTime.now();
    final segment =
        DavaTimerService.buildIncomingListCountdown(openedAt: openedAt);

    return Dismissible(
      key: ValueKey('gelen-dismiss-${widget.dava.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: _confirmSwipe,
      onDismissed: (_) => widget.onRejectQueued?.call(),
      background: _swipeBackground(accept: true),
      secondaryBackground: _swipeBackground(accept: false),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              vertical: SeyirTokens.space3,
              horizontal: SeyirTokens.space2,
            ),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: SeyirTokens.radiusLgAll,
              border: Border.all(color: palette.border),
              boxShadow: palette.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(SeyirTokens.space1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (segment != null) ...[
                    _buildPhaseChip(segment),
                    const SizedBox(height: SeyirTokens.space2),
                  ],
                  _buildCaseInfo(urgentLabel, disableAnimations, segment),
                  const SizedBox(height: SeyirTokens.space6),
                  _buildActionButtons(),
                  if (showRoleSelection && isAccepted) ...[
                    const SizedBox(height: SeyirTokens.space6),
                    _buildDashedLine(),
                    Center(
                      child: Text(
                        _isAppealJudgeAssignmentCard()
                            ? 'TEMYİZ HAKİMLİĞİ GÖREVİ'
                            : 'MEVKİNİZİ SEÇİNİZ',
                        style: const TextStyle(
                          fontSize: SeyirTokens.typeHeadline,
                          fontWeight: FontWeight.bold,
                          color: SeyirTokens.brand,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (_isAppealJudgeAssignmentCard()) ...[
                      const SizedBox(height: SeyirTokens.space2),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SeyirTokens.space3,
                        ),
                        child: Text(
                          'Görevi seçip "Görevi onayla" ile kabul edin; ardından 8-Hüküm sayfasında karar verin. '
                          'Kabul etmezseniz görev başkasına verilmez, dava mevcut haliyle sonuçlanır.',
                          textAlign: TextAlign.center,
                          style: palette
                              .body(
                                weight: FontWeight.w400,
                                color: palette.textSecondary,
                              )
                              .copyWith(height: 1.4),
                        ),
                      ),
                    ],
                    _buildCaseInfoSeparator(),
                    const SizedBox(height: SeyirTokens.space2),
                    _buildRoleSelection(),
                  ],
                  if (isRoleConfirmed && selectedRole != null) ...[
                    const SizedBox(height: SeyirTokens.space6),
                    _buildDashedLine(),
                    Center(
                      child: Text(
                        'SEÇİLEN MEVKİ',
                        style: TextStyle(
                          fontSize: SeyirTokens.typeHeadline,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _buildCaseInfoSeparator(),
                    const SizedBox(height: SeyirTokens.space4),
                    _buildSelectedRoleDisplay(),
                    _buildCaseInfoSeparator(),
                    const SizedBox(height: SeyirTokens.space4),
                    if (_acceptedAt != null)
                      CountdownTimerWidget(
                        startTime: _acceptedAt!,
                        totalDuration: _isAppealJudgeAssignmentCard()
                            ? DavaTimerService.appealJudgeDecisionWindow
                            : DavaTimerService.acceptedHukumWindow,
                        showHourglass: true,
                        onTimeUp: () {
                          final scheme = Theme.of(context).colorScheme;
                          ScaffoldMessenger.of(context).showSnackBar(
                            seyirNoticeSnackBar(
                              scheme: scheme,
                              message: 'Dava süresi doldu',
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (_showStamp)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(child: _buildStamp(palette)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStamp(SeyirPalette palette) {
    final scale = Tween<double>(begin: 1.28, end: 1).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.easeOutBack),
    );
    return ScaleTransition(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SeyirTokens.space4,
          vertical: SeyirTokens.space3,
        ),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
          border: Border.all(color: SeyirTokens.brand, width: 3),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              color: palette.foreground(SeyirTokens.brand),
              size: 28,
            ),
            const SizedBox(width: SeyirTokens.space2),
            Text(
              'ONAYLANDI',
              style: palette.headline(
                color: palette.foreground(SeyirTokens.brand),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swipeBackground({required bool accept}) {
    final palette = SeyirPalette.of(context);
    final color = accept ? SeyirTokens.accept : SeyirTokens.reject;
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: SeyirTokens.space3,
        horizontal: SeyirTokens.space2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space4),
      alignment: accept ? Alignment.centerLeft : Alignment.centerRight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SeyirTokens.radiusLg),
      ),
      child: Text(
        accept ? 'Kabul et' : 'Reddet',
        style: TextStyle(
          color: palette.onSolid(color),
          fontSize: SeyirTokens.typeTitle,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    final palette = SeyirPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space2),
      child: CustomPaint(
        painter:
            DashedLinePainter(color: palette.tintBorder(SeyirTokens.brand)),
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }

  Widget _buildCaseInfoSeparator() {
    final palette = SeyirPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space1),
      child: CustomPaint(
        painter: DashedLinePainter(color: palette.border),
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }

  bool _davaliIsGuest() {
    final key = (widget.dava.davaliEmail ?? widget.dava.davali).trim();
    if (key.isEmpty) return false;
    if (!key.contains('@')) {
      return HiveDatabaseService.getRegistrationByEmail(key) == null &&
          HiveDatabaseService.getRegistrationByJudgeName(key) == null;
    }
    return HiveDatabaseService.getRegistrationByEmail(key) == null;
  }

  Widget _buildPhaseChip(DavaIncomingCountdownSegment segment) {
    final palette = SeyirPalette.of(context);
    final token = seyirIncomingPhaseToken(context, segment.storageStatus);
    final ink = seyirIncomingPhaseColor(context, segment.storageStatus);
    return Row(
      children: [
        Flexible(
          child: Container(
            key: Key('gelen-faz-${widget.dava.id}'),
            padding: const EdgeInsets.symmetric(
              horizontal: SeyirTokens.space2,
              vertical: SeyirTokens.space1,
            ),
            decoration: BoxDecoration(
              color: palette.tint(token),
              borderRadius: SeyirTokens.radiusSmAll,
              border: Border.all(color: palette.tintBorder(token)),
            ),
            child: Text(
              segment.phaseLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette.caption(weight: FontWeight.w700, color: ink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaseInfo(
    String? urgentLabel,
    bool disableAnimations,
    DavaIncomingCountdownSegment? segment,
  ) {
    final palette = SeyirPalette.of(context);
    final guest = _davaliIsGuest();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space4,
        vertical: SeyirTokens.space3,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusMdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCaseInfoRow(
            'Dava Adı',
            widget.dava.adi.isNotEmpty ? widget.dava.adi : 'Belirtilmedi',
            Icons.description,
          ),
          const SizedBox(height: SeyirTokens.space2),
          _buildYargilaStyleSeparator(),
          const SizedBox(height: SeyirTokens.space2),
          _buildCaseInfoRow(
            'Davacı',
            widget.dava.davaci.isNotEmpty ? widget.dava.davaci : 'Davacı Adı',
            Icons.person,
          ),
          const SizedBox(height: SeyirTokens.space2),
          _buildYargilaStyleSeparator(),
          const SizedBox(height: SeyirTokens.space2),
          _buildModernDavaliRow(guest),
          const SizedBox(height: SeyirTokens.space2),
          _buildYargilaStyleSeparator(),
          const SizedBox(height: SeyirTokens.space2),
          _buildStyledCountdownRow(urgentLabel, disableAnimations, segment),
        ],
      ),
    );
  }

  Widget _buildYargilaStyleSeparator() {
    final palette = SeyirPalette.of(context);
    return SizedBox(
      height: SeyirTokens.space2,
      child: CustomPaint(
        size: const Size(double.infinity, SeyirTokens.space2),
        painter: DashedLinePainter(
          color: palette.border,
          strokeWidth: 1.6,
        ),
      ),
    );
  }

  Widget _buildCaseInfoRow(String label, String value, IconData icon) {
    final palette = SeyirPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: SeyirTokens.brand,
        ),
        const SizedBox(width: SeyirTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: palette.caption(weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: palette.title(weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernDavaliRow(bool guest) {
    final palette = SeyirPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.person_outline,
          size: 20,
          color: SeyirTokens.brand,
        ),
        const SizedBox(width: SeyirTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Davalı',
                style: palette.caption(weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.dava.davali.isNotEmpty
                          ? widget.dava.davali
                          : 'Davalı Adı',
                      style: palette.title(weight: FontWeight.w700),
                    ),
                  ),
                  if (guest) ...[
                    const SizedBox(width: SeyirTokens.space2),
                    Tooltip(
                      message: 'Bu davalı WhoBoom üyesi değil (misafir)',
                      child: Icon(
                        Icons.person_off_outlined,
                        color: palette.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyledCountdownRow(
    String? urgentLabel,
    bool disableAnimations,
    DavaIncomingCountdownSegment? segment,
  ) {
    final palette = SeyirPalette.of(context);
    final timer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kalan Süre',
          style: palette.caption(weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        _buildCountdownRow(segment),
        if (urgentLabel != null) ...[
          const SizedBox(height: SeyirTokens.space1),
          Text(
            urgentLabel,
            key: const Key('gelen-karar-suresi'),
            style: palette.body(
              weight: FontWeight.w700,
              color: SeyirTokens.warning,
            ),
          ),
        ],
      ],
    );

    Widget pulsed = timer;
    if (urgentLabel != null && !disableAnimations) {
      pulsed = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final t = _pulseController.value;
          return Opacity(
            opacity: 0.72 + (0.28 * t),
            child: Transform.scale(
              alignment: Alignment.centerLeft,
              scale: 1 + (0.015 * t),
              child: child,
            ),
          );
        },
        child: timer,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.hourglass_bottom,
          size: 20,
          color: SeyirTokens.brand,
        ),
        const SizedBox(width: SeyirTokens.space3),
        Expanded(child: pulsed),
      ],
    );
  }

  Widget _buildCountdownRow(DavaIncomingCountdownSegment? segment) {
    final palette = SeyirPalette.of(context);
    if (segment == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Süre :',
              style: palette.body(weight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              'Ana süreç ve temyiz penceresi tamamlandı.',
              style: palette.body(
                weight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            'Süre :',
            style: palette.body(weight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: CountdownTimerWidget(
            startTime: segment.segmentStart,
            totalDuration: segment.totalDuration,
            accentColor:
                seyirIncomingPhaseColor(context, segment.storageStatus),
            showHourglass: true,
            onTimeUp: () {
              final scheme = Theme.of(context).colorScheme;
              ScaffoldMessenger.of(context).showSnackBar(
                seyirNoticeSnackBar(
                  scheme: scheme,
                  message: 'Bu fazın süresi doldu',
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            key: const Key('gelen-reddet'),
            label: 'RED ET',
            isReject: true,
            onPressed: _onRejectPressed,
          ),
        ),
        const SizedBox(width: SeyirTokens.space4),
        Expanded(
          child: _buildActionButton(
            key: const Key('gelen-kabul'),
            label: 'KABUL ET',
            isReject: false,
            onPressed: () {
              if (isAccepted) {
                setState(() {
                  isAccepted = false;
                  showRoleSelection = false;
                  isRoleConfirmed = false;
                  selectedRole = null;
                });
                return;
              }
              _startAcceptFlow();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Key key,
    required String label,
    required bool isReject,
    required VoidCallback onPressed,
  }) {
    final isSelected = isReject ? isRejected : isAccepted;
    final Color tone = isReject ? SeyirTokens.reject : SeyirTokens.accept;
    return _GelenDecisionButton(
      key: key,
      label: label,
      tone: tone,
      selected: isSelected,
      onPressed: onPressed,
    );
  }

  Future<bool> _checkExistingRole() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return false;
    }

    try {
      final participants =
          await HiveDatabaseService.getDavaParticipants(widget.dava.id);
      final existingParticipant = participants.firstWhere(
        (p) =>
            (p['userEmail']?.toString() ?? '').toLowerCase() ==
            widget.userEmail!.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (!mounted) return false;
      if (existingParticipant.isNotEmpty) {
        final status = existingParticipant['status']?.toString() ?? '';
        final existingRole = existingParticipant['mevkii']?.toString() ?? '';

        if (status == 'accepted' && existingRole.isNotEmpty) {
          setState(() {
            _hasExistingRole = true;
            _existingRole = existingRole;
          });
          return true;
        }
      }

      setState(() {
        _hasExistingRole = false;
        _existingRole = null;
      });
      return false;
    } catch (e) {
      appLog('Katılımcı kontrolü sırasında hata: $e');
      return false;
    }
  }

  Widget _buildRoleSelection() {
    final List<Map<String, String>> roles;
    if (_isAppealJudgeAssignmentCard()) {
      roles = [
        {
          'label': DavaAppealJudgeAssignService.appealJudgeRole,
          'value': DavaAppealJudgeAssignService.appealJudgeRole,
        },
      ];
    } else {
      roles = DavaAutoAssignService.standardCaseRoles
          .map((r) => {'label': r, 'value': r})
          .toList();
    }

    return Column(
      children: [
        ...roles.map(_buildRoleRow),
        _buildConfirmTaskButton(),
      ],
    );
  }

  Widget _buildRoleRow(Map<String, String> role) {
    final palette = SeyirPalette.of(context);
    final label = role['label'] ?? '';
    final isSelected = selectedRole == label;
    final isDisabled = _hasExistingRole;
    final Color borderColor = isDisabled
        ? palette.border
        : (isSelected ? SeyirTokens.brand : palette.border);
    final Color fill = isDisabled
        ? palette.surfaceMuted
        : (isSelected ? palette.brandSoft : palette.card);
    final Color ink = isDisabled
        ? palette.textMuted
        : (isSelected
            ? palette.foreground(SeyirTokens.brand)
            : palette.textPrimary);

    return Container(
      key: Key('gelen-role-$label'),
      margin: const EdgeInsets.only(bottom: SeyirTokens.space2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SeyirTokens.radiusSm),
          onTap: isDisabled
              ? null
              : () {
                  setState(() {
                    selectedRole = label;
                  });
                },
          child: Container(
            constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: SeyirTokens.space3,
              vertical: SeyirTokens.space2,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(SeyirTokens.radiusSm),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDisabled
                          ? palette.border
                          : (isSelected ? SeyirTokens.brand : palette.border),
                      width: 2,
                    ),
                    color: isDisabled
                        ? palette.surfaceMuted
                        : (isSelected ? SeyirTokens.brand : Colors.transparent),
                  ),
                  child: isDisabled
                      ? Icon(Icons.block, size: 12, color: palette.textMuted)
                      : (isSelected
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: palette.onSolid(SeyirTokens.brand),
                            )
                          : null),
                ),
                const SizedBox(width: SeyirTokens.space3),
                Expanded(
                  child: Text(
                    label,
                    style: palette.title(weight: FontWeight.w600, color: ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmTaskButton() {
    final palette = SeyirPalette.of(context);
    final enabled =
        selectedRole != null && !_hasExistingRole && !_confirmingRole;
    return Padding(
      padding: const EdgeInsets.only(top: SeyirTokens.space2),
      child: SizedBox(
        key: const Key('gorevi-onayla'),
        width: double.infinity,
        height: SeyirTokens.tapTarget,
        child: ElevatedButton(
          onPressed: enabled ? _confirmSelectedRole : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(SeyirTokens.tapTarget),
            backgroundColor: SeyirTokens.brand,
            disabledBackgroundColor: palette.surfaceMuted,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
            ),
          ),
          child: Text(
            'Görevi onayla',
            style: TextStyle(
              fontSize: SeyirTokens.typeTitle,
              fontWeight: FontWeight.bold,
              color: enabled
                  ? palette.onSolid(SeyirTokens.brand)
                  : palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSelectedRole() async {
    if (selectedRole == null || _confirmingRole) return;
    final email = widget.userEmail;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final scheme = Theme.of(context).colorScheme;
    final provider = Provider.of<DavaProvider>(context, listen: false);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (email != null && email.isNotEmpty) {
      try {
        final participants =
            await HiveDatabaseService.getDavaParticipants(widget.dava.id);
        final existingParticipant = participants.firstWhere(
          (p) =>
              (p['userEmail']?.toString() ?? '').toLowerCase() ==
              email.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        if (existingParticipant.isNotEmpty) {
          final status = existingParticipant['status']?.toString() ?? '';
          final existingRole = existingParticipant['mevkii']?.toString() ?? '';
          if (status == 'accepted' && existingRole.isNotEmpty) {
            messenger.showSnackBar(
              seyirNoticeSnackBar(
                scheme: scheme,
                message:
                    'Bu davada zaten "$existingRole" görevini seçtiniz. Aynı davada farklı bir görev seçemezsiniz.',
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }
        }
      } catch (e) {
        appLog('Katılımcı kontrolü sırasında hata: $e');
      }
    }

    if (!mounted) return;
    _confirmingRole = true;
    final acceptedTime = DateTime.now();
    HapticFeedback.mediumImpact();
    setState(() {
      isRoleConfirmed = true;
      showRoleSelection = false;
      _acceptedAt = acceptedTime;
      _showStamp = !disableAnimations;
    });
    if (!disableAnimations) {
      try {
        await _stampController.forward(from: 0);
      } catch (_) {}
      if (mounted) setState(() => _showStamp = false);
    }

    final role = selectedRole;
    final davaData = {
      'id': widget.dava.id,
      'davaId': widget.dava.id,
      'adi': widget.dava.adi,
      'davali': widget.dava.davali,
      'mevkii': role,
      'kalanSure': widget.dava.kalanSure,
      'profilResmi': widget.dava.profilResmi,
      'davaKonusu': widget.dava.davaKonusu,
      'davaci': widget.dava.davaci,
      'userEmail': email,
      'userRole': role,
      'status': 'accepted',
      'acceptedAt': acceptedTime.toIso8601String(),
      'createdAt': widget.dava.createdAt?.toIso8601String() ??
          acceptedTime.toIso8601String(),
      'remainingHours': 76,
      if (_isAppealJudgeAssignmentCard()) 'isAppealJudgeAssignment': true,
    };

    final success = await provider.acceptDava(davaData);
    if (!success) {
      _confirmingRole = false;
      messenger.showSnackBar(
        seyirNoticeSnackBar(
          scheme: scheme,
          message: 'Dava kabul edilirken hata oluştu. Lütfen tekrar deneyin.',
          duration: const Duration(seconds: 3),
        ),
      );
      if (mounted) {
        setState(() {
          isRoleConfirmed = false;
          showRoleSelection = true;
        });
      }
      return;
    }

    messenger.showSnackBar(
      seyirNoticeSnackBar(
        scheme: scheme,
        message: 'Dava kabul edildi',
        actionLabel: _yargilaGit,
        onAction: () {
          navigator.push(
            MaterialPageRoute<void>(
              builder: (context) => YargilaPage(userEmail: email),
            ),
          );
        },
      ),
    );
    widget.onDavaRejected?.call();
    _confirmingRole = false;

    try {
      await _persistAcceptedRole(
        provider: provider,
        email: email,
        role: role,
        acceptedTime: acceptedTime,
        davaData: davaData,
      );
    } catch (e) {
      appLog('Kabul sonrası kayıt tamamlanamadı: $e');
    }
  }

  Future<void> _persistAcceptedRole({
    required DavaProvider provider,
    required String? email,
    required String? role,
    required DateTime acceptedTime,
    required Map<String, dynamic> davaData,
  }) async {
    if (_isAppealJudgeAssignmentCard()) {
      await HiveDatabaseService.updateOpenedDava(widget.dava.id, {
        'appealJudgeAssignmentPending': false,
        'appealJudgeAcceptedAt': acceptedTime.toIso8601String(),
      });
      if (email != null && email.isNotEmpty) {
        await HiveDatabaseService.markDavaParticipantStatus(
          davaId: widget.dava.id,
          userEmail: email,
          status: 'accepted',
          reason: 'appeal_judge_accepted',
          extra: {
            'mevkii': role,
            'userRole': role,
            'acceptedAt': acceptedTime.toIso8601String(),
            'isAppealJudgeAssignment': true,
          },
        );
      }
    }

    if (email != null && email.isNotEmpty) {
      final opened = HiveDatabaseService.getOpenedDavaById(widget.dava.id);
      final katildigimKayit = Map<String, dynamic>.from(davaData);
      katildigimKayit['davaAdi'] = widget.dava.adi;
      katildigimKayit['isAccepted'] = true;
      katildigimKayit['isRejected'] = false;
      katildigimKayit['source'] = 'gelen_davalar_accept';
      if (opened != null) {
        final kat = opened['kategori'] ?? opened['davaKategorisi'];
        if (kat != null && kat.toString().trim().isNotEmpty) {
          katildigimKayit['kategori'] = kat;
          katildigimKayit['davaKategori'] = kat;
        }
        final oa = opened['openedAt']?.toString();
        if (oa != null && oa.isNotEmpty) {
          katildigimKayit['openedAt'] = oa;
        }
        if (opened['isOpened'] != null) {
          katildigimKayit['isOpened'] = opened['isOpened'];
        }
      } else {
        katildigimKayit['openedAt'] = katildigimKayit['acceptedAt']?.toString();
        katildigimKayit['isOpened'] = true;
      }
      await HiveDatabaseService.removeKatildigimDava(email, widget.dava.id);
      await HiveDatabaseService.addKatildigimDava(email, katildigimKayit);
      await provider.reloadKatildigimDavalar(email);
      await provider.reloadIncomingDavalar(email);
    }
  }

  Widget _buildSelectedRoleDisplay() {
    final palette = SeyirPalette.of(context);
    final tone = palette.foreground(SeyirTokens.brand);
    return Container(
      key: const Key('secilen-mevki'),
      padding: const EdgeInsets.all(SeyirTokens.space4),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
        border:
            Border.all(color: palette.tintBorder(SeyirTokens.brand), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: tone,
          ),
          const SizedBox(height: SeyirTokens.space3),
          Text(
            'Seçilen Mevki:',
            style: palette.headline(color: tone),
          ),
          const SizedBox(height: SeyirTokens.space2),
          Text(
            selectedRole ?? '',
            style: palette.display(color: palette.textPrimary),
          ),
          const SizedBox(height: SeyirTokens.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SeyirTokens.space4,
              vertical: SeyirTokens.space2,
            ),
            decoration: BoxDecoration(
              color: SeyirTokens.brand,
              borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
            ),
            child: Text(
              'Mevki Onaylandı',
              style: TextStyle(
                color: palette.onSolid(SeyirTokens.brand),
                fontWeight: FontWeight.bold,
                fontSize: SeyirTokens.typeBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kabul / red: boşta ince renkli kenar ve açık dolgu, seçilince dolu.
class _GelenDecisionButton extends StatefulWidget {
  const _GelenDecisionButton({
    super.key,
    required this.label,
    required this.tone,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final Color tone;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_GelenDecisionButton> createState() => _GelenDecisionButtonState();
}

class _GelenDecisionButtonState extends State<_GelenDecisionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _emphasis;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _emphasis = AnimationController(vsync: this, duration: SeyirTokens.motion);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.045), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.045, end: 1), weight: 55),
    ]).animate(CurvedAnimation(parent: _emphasis, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _GelenDecisionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.selected) return;
        if (MediaQuery.disableAnimationsOf(context)) {
          _emphasis.value = 0;
          return;
        }
        _emphasis.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _emphasis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final motion = disableAnimations ? Duration.zero : SeyirTokens.motion;
    final tone = widget.tone;
    final selected = widget.selected;
    final fill = selected ? tone : palette.tint(tone);
    final ink = selected ? palette.onSolid(tone) : palette.foreground(tone);

    return ScaleTransition(
      scale: disableAnimations ? kAlwaysCompleteAnimation : _scale,
      child: AnimatedContainer(
        duration: motion,
        curve: Curves.easeOut,
        height: 50,
        constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: SeyirTokens.radiusMdAll,
          border: Border.all(color: tone),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: SeyirTokens.radiusMdAll,
            onTap: widget.onPressed,
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: SeyirTokens.typeTitle,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed Line Painter for creating dashed borders
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
