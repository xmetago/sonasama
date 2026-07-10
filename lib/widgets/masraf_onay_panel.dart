import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../services/masraf_onay_service.dart';
import 'sari_yildiz_satin_alma_dialog.dart';

/// KURAL SETİ'ni eksiksiz uygulayan akıllı panel.
///
/// Bu widget tek başına kullanılabilir; verilen [decision] ve mevcut kullanıcı
/// kimliği üzerinden:
///   - "Masrafları Onayla" butonunu (Durum 1, 3, 4),
///   - "Whobooma'a Ödensin" butonunu (Durum 2),
///   - 19 günlük "MASRAF/UYAR" uyarı butonunu (haklı tarafa)
/// doğru biçimde gösterir.
class MasrafOnayPanel extends StatefulWidget {
  const MasrafOnayPanel({
    super.key,
    required this.davaId,
    required this.davaAdi,
    required this.decision,
    required this.currentUserEmail,
    required this.currentUserJudgeName,
    this.onStateChanged,
  });

  final String davaId;
  final String davaAdi;
  final MasrafOnayDecision decision;
  final String? currentUserEmail;
  final String? currentUserJudgeName;

  /// Onay veya uyarı tamamlandıktan sonra çağrılır.
  final VoidCallback? onStateChanged;

  @override
  State<MasrafOnayPanel> createState() => _MasrafOnayPanelState();
}

class _MasrafOnayPanelState extends State<MasrafOnayPanel> {
  bool _loading = true;
  bool _onaylandi = false;
  bool _islemDevamEdiyor = false;
  MasrafUyarStatus? _uyarStatus;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final onaylandi =
        await MasrafOnayService.isMasrafOnaylandi(widget.davaId);
    // Decision'ı geçirerek Durum 2 (haksız üye değil) cooldown durumu
    // hesaplanmadan elenir → status'un canSend'i false döner.
    final uyari = await MasrafOnayService.getMasrafUyarStatus(
      widget.davaId,
      decision: widget.decision,
    );
    if (!mounted) return;
    setState(() {
      _onaylandi = onaylandi;
      _uyarStatus = uyari;
      _loading = false;
    });
  }

  bool get _userIsBasanTaraf => MasrafOnayService.canUserPressButton(
        decision: widget.decision,
        userEmail: widget.currentUserEmail,
        userJudgeName: widget.currentUserJudgeName,
      );

  bool get _userIsHakliTaraf => MasrafOnayService.canUserSendUyari(
        decision: widget.decision,
        userEmail: widget.currentUserEmail,
        userJudgeName: widget.currentUserJudgeName,
      );

  Future<void> _onMasraflarOnayla() async {
    if (_islemDevamEdiyor || _onaylandi) return;
    if (!_userIsBasanTaraf) {
      _snack(
        'Bu butona yalnızca ${_taraflabel(widget.decision.basanTaraf)} basabilir.',
        Colors.orange,
      );
      return;
    }

    setState(() => _islemDevamEdiyor = true);
    bool retry = true;
    int guard = 0;
    while (retry && guard < 2) {
      retry = false;
      guard++;
      try {
        final result = await MasrafOnayService.onaylaMasraf(
          davaId: widget.davaId,
          decision: widget.decision,
        );
        if (!mounted) return;
        _snack(
          result.alreadyApproved
              ? 'Masraf zaten onaylanmış.'
              : '✅ Masraflar onaylandı. (${widget.decision.durumOzeti})',
          Colors.green,
        );
        await _refresh();
        widget.onStateChanged?.call();
      } on InsufficientYellowStarException catch (e) {
        if (!mounted) return;
        final satinAlindi = await SariYildizSatinAlmaDialog.show(
          context,
          userEmail: e.email,
          requiredAmount: e.required,
          currentAmount: e.current,
          davaAdi: widget.davaAdi,
        );
        if (satinAlindi) {
          retry = true; // tekrar dene
        } else {
          _snack('Satın alma iptal edildi.', Colors.grey);
        }
      } catch (e) {
        if (!mounted) return;
        _snack('❌ Hata: $e', Colors.red);
      }
    }
    if (mounted) setState(() => _islemDevamEdiyor = false);
  }

  Future<void> _onWhoboomaOdensin() async {
    if (_islemDevamEdiyor || _onaylandi) return;
    if (!_userIsBasanTaraf) {
      _snack(
        'Bu butona yalnızca ${_taraflabel(widget.decision.basanTaraf)} basabilir.',
        Colors.orange,
      );
      return;
    }
    setState(() => _islemDevamEdiyor = true);
    try {
      final result = await MasrafOnayService.onaylaWhobooma(
        davaId: widget.davaId,
        decision: widget.decision,
      );
      if (!mounted) return;
      final String mesaj;
      if (result.alreadyApproved) {
        mesaj = "Zaten Whoboom'a ödenmiş olarak işaretlenmiş.";
      } else {
        final String? yesil = result.hakliTarafYeniYesil != null
            ? ' · Yeşil yıldız: ${result.hakliTarafYeniYesil} 🟢'
            : '';
        mesaj =
            "✅ Whoboom'a ödendi. Şeref sahibi oldun: +${MasrafOnayService.greenStarDelta} 🟢$yesil";
      }
      _snack(mesaj, Colors.green);
      await _refresh();
      widget.onStateChanged?.call();
    } catch (e) {
      if (!mounted) return;
      _snack('❌ Hata: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _islemDevamEdiyor = false);
    }
  }

  Future<void> _onMasrafUyar() async {
    if (_islemDevamEdiyor || _onaylandi) return;
    if (!_userIsHakliTaraf) {
      _snack(
        'MASRAF/UYAR butonuna yalnızca haklı taraf basabilir.',
        Colors.orange,
      );
      return;
    }
    setState(() => _islemDevamEdiyor = true);
    try {
      final result = await MasrafOnayService.sendMasrafUyar(
        davaId: widget.davaId,
        davaAdi: widget.davaAdi,
        decision: widget.decision,
      );
      if (!mounted) return;
      if (result.success) {
        _snack(
          '📣 Uyarı gönderildi: ${result.message}',
          Colors.indigo,
        );
        await _refresh();
        widget.onStateChanged?.call();
      } else {
        final String mesaj;
        switch (result.status.reason) {
          case MasrafUyarReason.zatenOnaylandi:
            mesaj = 'Masraf zaten onaylandı, uyarı gönderilemez.';
            break;
          case MasrafUyarReason.davaliUyeDegil:
            mesaj =
                'Davalı Whoboom üyesi değil — uyarılacak kimse yok.';
            break;
          case MasrafUyarReason.cooldownActive:
          default:
            final kalan = result.status.kalanLabel ?? '';
            mesaj = 'Bir sonraki uyarı için $kalan Sonra tekra Tıkla ';
            break;
        }
        _snack(mesaj, Colors.orange);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('❌ Hata: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _islemDevamEdiyor = false);
    }
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  String _taraflabel(MasrafTaraf t) =>
      t == MasrafTaraf.davaci ? 'Davacı' : 'Davalı';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final children = <Widget>[];

    // KURAL: Ana onay butonu (MASRAFLARI ONAYLA / WHOBOOM'A ÖDENSİN) yalnızca
    // basan tarafın sayfasında görünür. Karşı tarafın açtığım/katıldığım
    // sayfasında — masraf zaten onaylanmadığı sürece — pasif kopyası bile
    // çıkmaz. Onaylanmışsa her iki taraf da "✅ Onaylandı" rozetini görür.
    final bool anaButonRender = _userIsBasanTaraf || _onaylandi;
    if (anaButonRender) {
      children.add(
        widget.decision.buttonType == MasrafButtonType.whoboomaOdensin
            ? _WhoboomaOdensinButton(
                onaylandi: _onaylandi,
                loading: _islemDevamEdiyor,
                userCanPress: _userIsBasanTaraf,
                onTap: _onWhoboomaOdensin,
              )
            : _MasraflarOnaylaButton(
                decision: widget.decision,
                onaylandi: _onaylandi,
                loading: _islemDevamEdiyor,
                userCanPress: _userIsBasanTaraf,
                onTap: _onMasraflarOnayla,
              ),
      );
    }

    // 19 günlük MASRAF/UYAR butonu yalnızca:
    //   - Masraf henüz onaylanmamışsa,
    //   - Login user gerçekten haklı tarafsa (basan tarafın bekleyen yansıması),
    //   - Davalı Whoboom üyesi ise (KURAL: davalı üye değilse buton yok —
    //     bildirim alacak veya uyarıyı basacak gerçek bir kullanıcı bulunmaz).
    final bool uyariAnlamli =
        MasrafOnayService.gosterMasrafUyar(widget.decision);
    if (!_onaylandi && _userIsHakliTaraf && uyariAnlamli) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(
        _MasrafUyarButton(
          status: _uyarStatus,
          loading: _islemDevamEdiyor,
          onTap: _onMasrafUyar,
        ),
      );
    }

    if (children.isEmpty) {
      // Bu sayfada bu kullanıcı için gösterecek bir şey yok (ör. jüri).
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

// ───────────────── 1) Masrafları Onayla butonu ─────────────────

class _MasraflarOnaylaButton extends StatelessWidget {
  const _MasraflarOnaylaButton({
    required this.decision,
    required this.onaylandi,
    required this.loading,
    required this.userCanPress,
    required this.onTap,
  });

  final MasrafOnayDecision decision;
  final bool onaylandi;
  final bool loading;
  final bool userCanPress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !onaylandi && !loading && userCanPress;
    final String text = onaylandi
        ? 'Masraflar Onaylandı ✅'
        : (decision.basanTaraf == MasrafTaraf.davaci
            ? 'MASRAFLARI ONAYLA'
            : 'MASRAFLARI KABUL ET');

    return _GradientButton(
      enabled: enabled,
      loading: loading,
      icon: MdiIcons.giftOpenOutline,
      title: text,
      subtitle: _altYazi(),
      colors: <Color>[
        Colors.teal.shade400,
        Colors.teal.shade700,
        Colors.teal.shade900,
      ],
      borderColor: Colors.teal.shade300,
      settledIconState: onaylandi,
      onTap: enabled ? onTap : null,
    );
  }

  String _altYazi() {
    if (onaylandi) return 'Onaylandı';
    if (!userCanPress) {
      return 'Bu butona ${decision.basanTaraf == MasrafTaraf.davaci ? "Davacı" : "Davalı"} basabilir';
    }
    const tutar = MasrafOnayService.yellowStarCost;
    return '${decision.durumOzeti} · −$tutar 🟡, −${MasrafOnayService.greenStarDelta} 🟢';
  }
}

// ───────────────── 2) Whoboom'a Ödensin butonu ─────────────────

class _WhoboomaOdensinButton extends StatelessWidget {
  const _WhoboomaOdensinButton({
    required this.onaylandi,
    required this.loading,
    required this.userCanPress,
    required this.onTap,
  });

  final bool onaylandi;
  final bool loading;
  final bool userCanPress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !onaylandi && !loading && userCanPress;
    final String text = onaylandi
        ? "Prestij  Ödendi ✅"
        : "Prestij  Ödemesi";
    return _GradientButton(
      enabled: enabled,
      loading: loading,
      icon: MdiIcons.handCoinOutline,
      title: text,
      subtitle: onaylandi
          ? " Davacı +${MasrafOnayService.greenStarDelta} 🟢 kazandı"
          : userCanPress
              ? "  +${MasrafOnayService.greenStarDelta} 🟢 kazandın"
              : 'Bu butona yalnızca Davacı (haklı taraf) basabilir',
      colors: <Color>[
        Colors.teal.shade400,
        Colors.teal.shade700,
        Colors.teal.shade900,
      ],
      borderColor: Colors.teal.shade300,
      settledIconState: onaylandi,
      onTap: enabled ? onTap : null,
    );
  }
}

// ───────────────── 3) MASRAF/UYAR (19 günlük) butonu ─────────────────

class _MasrafUyarButton extends StatelessWidget {
  const _MasrafUyarButton({
    required this.status,
    required this.loading,
    required this.onTap,
  });

  final MasrafUyarStatus? status;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool canSend = status?.canSend ?? false;
    final String? kalan = status?.kalanLabel;
    // Uyar butonu görünse bile artık aksiyon tetiklemesin.
    final bool enabled = false;
    final String subtitle;
    if (canSend) {
      subtitle =
          '19 günde bir hatırlatma gönderebilirsin: "masrafları onayla, şeref sahibi ol"';
    } else {
      switch (status?.reason) {
        case MasrafUyarReason.zatenOnaylandi:
          subtitle = 'Masraf zaten onaylandı';
          break;
        case MasrafUyarReason.davaliUyeDegil:
          subtitle = 'Davalı Whoboom üyesi değil — uyarılacak kimse yok';
          break;
        case MasrafUyarReason.cooldownActive:
        default:
          subtitle = 'Bir sonraki uyarı için $kalan beklenmeli';
          break;
      }
    }

    return _GradientButton(
      enabled: enabled,
      loading: loading,
      icon: Icons.notifications_active,
      title: 'MASRAF UYARISI !',
      subtitle: subtitle,
      colors: <Color>[
        Colors.indigo.shade400,
        Colors.indigo.shade700,
        Colors.indigo.shade900,
      ],
      borderColor: Colors.indigo.shade300,
      onTap: null,
    );
  }
}

// ───────────────── Ortak buton iskeleti ─────────────────

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.enabled,
    required this.loading,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.borderColor,
    required this.onTap,
    this.settledIconState = false,
  });

  final bool enabled;
  final bool loading;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool settledIconState;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with TickerProviderStateMixin {
  bool _iconPressed = false;
  AnimationController? _pulseController;
  AnimationController? _glowController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _glowAnimation;

  /// Hot reload sonrası mevcut State'te controller'lar boş kalabilir; lazy init.
  void _ensureAnimations() {
    if (_pulseController != null) return;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController!, curve: Curves.easeInOut),
    );
  }

  @override
  void initState() {
    super.initState();
    _ensureAnimations();
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  void _setIconPressed(bool value) {
    if (_iconPressed == value) return;
    setState(() => _iconPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    _ensureAnimations();
    final AnimationController pulseController = _pulseController!;
    final AnimationController glowController = _glowController!;
    final Animation<double> pulseAnimation = _pulseAnimation!;
    final Animation<double> glowAnimation = _glowAnimation!;

    final bool secondState = _iconPressed || widget.settledIconState;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[pulseController, glowController]),
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: widget.enabled ? pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: widget.onTap == null ? null : (_) => _setIconPressed(true),
            onTapUp: widget.onTap == null ? null : (_) => _setIconPressed(false),
            onTapCancel: widget.onTap == null ? null : () => _setIconPressed(false),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: widget.enabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.colors,
                      )
                    : null,
                color: widget.enabled ? null : Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.enabled
                      ? widget.borderColor
                      : Colors.grey.withOpacity(0.3),
                  width: widget.enabled ? 2.5 : 1,
                ),
                boxShadow: widget.enabled
                    ? <BoxShadow>[
                        BoxShadow(
                          color: widget.borderColor.withOpacity(glowAnimation.value),
                          blurRadius: 20 * glowAnimation.value,
                          spreadRadius: 5 * glowAnimation.value,
                        ),
                        BoxShadow(
                          color: widget.colors.first
                              .withOpacity(glowAnimation.value * 0.5),
                          blurRadius: 30 * glowAnimation.value,
                          spreadRadius: 8 * glowAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.enabled
                              ? Colors.white.withOpacity(0.25)
                              : Colors.grey.withOpacity(0.2),
                          border: Border.all(
                            color: widget.enabled
                                ? Colors.white.withOpacity(0.8)
                                : Colors.grey.withOpacity(0.5),
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: widget.loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : SizedBox(
                                width: 30,
                                height: 30,
                                child: Stack(
                                  children: <Widget>[
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 140),
                                      opacity: secondState ? 1 : 0,
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          size: 11,
                                          color: widget.enabled
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    AnimatedAlign(
                                      duration: const Duration(milliseconds: 140),
                                      curve: Curves.easeOutCubic,
                                      alignment: secondState
                                          ? const Alignment(0.0, 0.15)
                                          : Alignment.topLeft,
                                      child: Padding(
                                        padding: secondState
                                            ? const EdgeInsets.only(left: 3, top: 3)
                                            : EdgeInsets.zero,
                                        child: Icon(
                                          widget.icon,
                                          size: 20,
                                          color: widget.enabled
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.enabled
                                ? Colors.white
                                : Colors.grey.shade600,
                            shadows: widget.enabled
                                ? <Shadow>[
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(1, 1),
                                    ),
                                  ]
                                : null,
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
      },
    );
  }
}
