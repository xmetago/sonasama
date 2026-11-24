import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/delil_surface.dart';
import '../widgets/seyir_defteri_menu_items.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import '../widgets/gelen_dava_card.dart';
import '../services/hive_database_service.dart';
import '../services/dava_timer_service.dart';
import 'gelen_davalar_kactane.dart';
import '../providers/dava_provider.dart';
import '../theme/seyir_tokens.dart';

export '../widgets/gelen_dava_card.dart' show Dava, FiveCardCaseInformation, DashedLinePainter;

class GelenDavalarPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  /// Test: gelen davalar yüklenemesin.
  final bool forceLoadError;

  /// Test: yükleme göstergesinde kalsın.
  final bool forceLoading;

  const GelenDavalarPage({
    super.key,
    this.userEmail,
    this.forceLoadError = false,
    this.forceLoading = false,
  });

  @override
  State<GelenDavalarPage> createState() => _GelenDavalarPageState();
}

class _PendingGelenReject {
  _PendingGelenReject(this.dava);

  final Dava dava;
  bool settled = false;
  bool undone = false;
}

class _GelenDavalarPageState extends State<GelenDavalarPage> {
  String? _expandedDavaId;
  DavaProvider? _davaProvider;
  bool _isLoading = true;
  String? _loadError;
  bool _bootstrapped = false;
  final Set<String> _pendingRejectIds = <String>{};
  final Map<String, _PendingGelenReject> _pendingRejects = <String, _PendingGelenReject>{};
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      HiveDatabaseService.debugPrintIncomingFor('testyargic1@gmail.com');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bootstrapped) return;
      _bootstrapped = true;
      _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _davaProvider ??= Provider.of<DavaProvider>(context, listen: false);
  }

  @override
  void didUpdateWidget(GelenDavalarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userEmail != widget.userEmail ||
        oldWidget.forceLoadError != widget.forceLoadError ||
        oldWidget.forceLoading != widget.forceLoading) {
      _load();
    }
  }

  @override
  void dispose() {
    for (final pending in _pendingRejects.values) {
      if (pending.settled || pending.undone) continue;
      pending.settled = true;
      unawaited(
        commitGelenDavaRejection(
          dava: pending.dava,
          userEmail: widget.userEmail,
          provider: _davaProvider,
        ),
      );
    }
    _davaProvider?.stopWatchingIncoming();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (widget.forceLoading) return;
    _davaProvider ??= Provider.of<DavaProvider>(context, listen: false);
    if (!refresh) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      if (widget.forceLoadError) {
        throw Exception('Gelen davalar yüklenemedi');
      }
      final email = widget.userEmail;
      if (email != null && email.isNotEmpty) {
        if (refresh) {
          await _davaProvider!.reloadIncomingDavalar(email);
        } else {
          await _davaProvider!.loadUserData(email);
        }
        if (!mounted) return;
        _davaProvider!.startWatchingIncoming(email);
        if (!refresh &&
            _davaProvider!.error != null &&
            _davaProvider!.incomingDavalar.isEmpty) {
          throw Exception(_davaProvider!.error);
        }
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      final hasItems = _davaProvider?.incomingDavalar.isNotEmpty ?? false;
      setState(() {
        _isLoading = false;
        _loadError = 'Gelen davalar yüklenemedi';
      });
      if (refresh && hasItems) {
        final scheme = Theme.of(context).colorScheme;
        _messengerKey.currentState?.showSnackBar(
          seyirNoticeSnackBar(
            scheme: scheme,
            message: 'Gelen davalar yüklenemedi',
            actionLabel: 'Tekrar dene',
            onAction: () => _load(refresh: true),
          ),
        );
      }
    }
  }

  Dava _davaFromMap(Map<dynamic, dynamic> raw) {
    final safeMap = <String, dynamic>{};
    raw.forEach((key, value) {
      safeMap[key.toString()] = value;
    });

    DateTime? createdAt;
    DateTime? acceptedAt;
    final createdRaw = safeMap['createdAt'] ?? safeMap['openedAt'];
    if (createdRaw != null) {
      createdAt = DateTime.tryParse(createdRaw.toString());
    }
    if (safeMap['acceptedAt'] != null) {
      acceptedAt = DateTime.tryParse(safeMap['acceptedAt'].toString());
    }

    final davaliRaw = (safeMap['davali'] ?? '').toString();
    final davaliEmailRaw = (safeMap['davaliEmail'] ?? '').toString().trim();
    return Dava(
      id: (safeMap['id'] ?? safeMap['davaId'] ?? '').toString(),
      adi: (safeMap['adi'] ?? safeMap['davaAdi'] ?? '').toString(),
      davali: davaliRaw,
      mevkii: (safeMap['mevkii'] ?? '').toString(),
      kalanSure: (safeMap['kalanSure'] ?? '.../.../.....').toString(),
      profilResmi: (safeMap['profilResmi'] ?? 'lib/icons/03_davala_ana_icon.png').toString(),
      davaKonusu: (safeMap['davaKonusu'] ?? '').toString(),
      davaci: (safeMap['davaci'] ?? '').toString(),
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      lifecycleStatus: (safeMap['lifecycleStatus'] ?? DavaLifecycleStatuses.awaitingRole).toString(),
      davaliEmail: davaliEmailRaw.isNotEmpty
          ? davaliEmailRaw
          : (davaliRaw.contains('@') ? davaliRaw : null),
      isAppealJudgeAssignment: safeMap['isAppealJudgeAssignment'] == true,
    );
  }

  List<Dava> _visibleDavalar(DavaProvider provider) {
    return provider.incomingDavalar
        .map(_davaFromMap)
        .where((dava) => dava.id.isNotEmpty && !_pendingRejectIds.contains(dava.id))
        .toList();
  }

  void _queueReject(Dava dava) {
    if (_pendingRejects.containsKey(dava.id) && !(_pendingRejects[dava.id]?.undone ?? false)) {
      return;
    }
    final pending = _PendingGelenReject(dava);
    setState(() {
      _pendingRejectIds.add(dava.id);
      _pendingRejects[dava.id] = pending;
      if (_expandedDavaId == dava.id) _expandedDavaId = null;
    });

    final scheme = Theme.of(context).colorScheme;
    final messenger = _messengerKey.currentState;
    if (messenger == null) {
      Future<void>.delayed(const Duration(seconds: 5), () {
        if (pending.settled || pending.undone) return;
        pending.settled = true;
        unawaited(_finishReject(pending));
      });
      return;
    }
    final controller = messenger.showSnackBar(
      seyirNoticeSnackBar(
        scheme: scheme,
        message: 'Dava reddedildi',
        duration: const Duration(seconds: 5),
        actionLabel: 'Geri al',
        onAction: () {
          pending.undone = true;
          pending.settled = true;
          if (!mounted) return;
          setState(() {
            _pendingRejectIds.remove(dava.id);
            _pendingRejects.remove(dava.id);
          });
        },
      ),
    );
    controller.closed.then((reason) {
      if (pending.settled) return;
      if (pending.undone || reason == SnackBarClosedReason.action) {
        pending.settled = true;
        return;
      }
      pending.settled = true;
      unawaited(_finishReject(pending));
    });
  }

  Future<void> _finishReject(_PendingGelenReject pending) async {
    await commitGelenDavaRejection(
      dava: pending.dava,
      userEmail: widget.userEmail,
      provider: _davaProvider,
    );
    if (!mounted) return;
    setState(() {
      _pendingRejectIds.remove(pending.dava.id);
      _pendingRejects.remove(pending.dava.id);
    });
  }

  Widget _scrollable({required Widget child}) {
    return RefreshIndicator(
      color: SeyirTokens.brand,
      onRefresh: () => _load(refresh: true),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        body: SafeArea(
          child: AppExpandableIconMenu.seyirDefteri(
            items: buildSeyirDefteriMenuItems(
              context,
              userEmail: widget.userEmail,
            ),
            headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
              return Column(
                children: [
                  ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                  Padding(
                    padding: kSeyirFriendRowPadding,
                    child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                  ),
                  Padding(
                    padding: kSeyirProfilePadding,
                    child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                      userEmail: widget.userEmail,
                      onShowSavedDavalar: () {},
                    ),
                  ),
                  GelenDavalarHeadlineRow(
                    menuButton: menuButton,
                    pendingRejectIds: _pendingRejectIds,
                  ),
                ],
              );
            },
            body: Consumer<DavaProvider>(
              builder: (context, provider, _) {
                if (widget.forceLoading || (_isLoading && _loadError == null)) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(SeyirTokens.space6),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final visible = _visibleDavalar(provider);
                if (_loadError != null && visible.isEmpty) {
                  return _scrollable(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        DelilLoadError(
                          message: _loadError!,
                          onRetry: () => _load(),
                        ),
                      ],
                    ),
                  );
                }
                if (visible.isEmpty) {
                  return _scrollable(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        _GelenEmptyState(),
                      ],
                    ),
                  );
                }
                return _scrollable(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final dava = visible[index];
                      return FiveCardCaseInformation(
                        key: ValueKey(dava.id),
                        dava: dava,
                        isExpanded: _expandedDavaId == dava.id,
                        userEmail: widget.userEmail,
                        onTap: () {
                          setState(() {
                            _expandedDavaId = _expandedDavaId == dava.id ? null : dava.id;
                          });
                        },
                        onRejectQueued: () => _queueReject(dava),
                        onDavaRejected: () {
                          if (!mounted) return;
                          setState(() {
                            if (_expandedDavaId == dava.id) _expandedDavaId = null;
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Menü, sayfa başlığı ve gelen dava sayısı rozetini tek satırda hizalar.
class GelenDavalarHeadlineRow extends StatelessWidget {
  final Widget menuButton;
  final Set<String> pendingRejectIds;

  const GelenDavalarHeadlineRow({
    super.key,
    required this.menuButton,
    this.pendingRejectIds = const <String>{},
  });

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Padding(
      padding: kSeyirHeadlinePadding,
      child: Row(
        children: [
          menuButton,
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gelen Davalar',
                    style: palette.headline(weight: FontWeight.w600),
                  ),
                  const SizedBox(width: 7),
                  _IncomingDavaCountBadge(pendingRejectIds: pendingRejectIds),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _GelenEmptyState extends StatelessWidget {
  const _GelenEmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(SeyirTokens.space6),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: palette.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Gelen dava yok',
            style: palette.title(
              weight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size atanan davalar burada görünür',
            textAlign: TextAlign.center,
            style: palette.body(
              weight: FontWeight.w400,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Özet sayfasına giden, sayı rozeti taşıyan ikon.
class _IncomingDavaCountBadge extends StatelessWidget {
  const _IncomingDavaCountBadge({required this.pendingRejectIds});

  final Set<String> pendingRejectIds;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Tooltip(
      message: 'Gelen dava özeti',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const GelenDavalarKactanePage(),
              ),
            );
          },
          child: SizedBox(
            width: SeyirTokens.tapTarget,
            height: SeyirTokens.tapTarget,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    MdiIcons.briefcaseArrowLeftRightOutline,
                    size: 26,
                    color: palette.textSecondary,
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Consumer<DavaProvider>(
                      builder: (context, davaProvider, child) {
                        final incomingIds = davaProvider.incomingDavalar
                            .map((dava) => (dava['id'] ?? dava['davaId'] ?? '').toString())
                            .where((id) => id.isNotEmpty)
                            .toSet();
                        final hidden = pendingRejectIds.where(incomingIds.contains).length;
                        final count = davaProvider.incomingDavaCount - hidden;
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: SeyirTokens.brand,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: palette.shadow,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: TextStyle(
                              color: palette.onSolid(SeyirTokens.brand),
                              fontSize: SeyirTokens.typeCaption,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
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
