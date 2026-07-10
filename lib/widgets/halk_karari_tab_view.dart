import 'package:flutter/material.dart';

import '../models/dava_halk_karari_result.dart';
import '../services/dava_halk_karari_service.dart';
import '../services/dava_hukum_service.dart';
import '../services/hive_database_service.dart';

/// Hüküm alanının hemen altında halk kararını gösteren tablı widget.
class HalkKarariTabView extends StatefulWidget {
  final String? davaId;
  final DateTime? acceptedAt;
  final String? userEmail;

  const HalkKarariTabView({
    super.key,
    required this.davaId,
    this.acceptedAt,
    this.userEmail,
  });

  @override
  State<HalkKarariTabView> createState() => _HalkKarariTabViewState();
}

class _HalkKarariTabViewState extends State<HalkKarariTabView>
    with AutomaticKeepAliveClientMixin {
  late Future<DavaHalkKarariResult> _resultFuture;
  bool _isSubmittingReaction = false;

  /// [true] iken içerik gizli (dava künyesi ile aynı: `CrossFadeState.showSecond`).
  bool _sectionExpanded = true;

  @override
  void initState() {
    super.initState();
    _resultFuture = _loadResult();
  }

  @override
  void didUpdateWidget(covariant HalkKarariTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.davaId != widget.davaId ||
        oldWidget.acceptedAt != widget.acceptedAt) {
      _resultFuture = _loadResult();
    }
  }

  Future<DavaHalkKarariResult> _loadResult() {
    final String? id = widget.davaId;
    if (id == null || id.isEmpty) {
      return Future.value(DavaHalkKarariResult.empty('unknown'));
    }

    return DavaHalkKarariService.evaluate(
      davaId: id,
      acceptedAt: widget.acceptedAt,
    );
  }

  void _handleRefresh() {
    setState(() {
      _resultFuture = _loadResult();
    });
  }

  Future<void> _handleReaction(
    bool isSupport,
    DavaHalkKarariResult result,
  ) async {
    final String email = widget.userEmail?.trim() ?? '';
    final String? davaId = widget.davaId;
    if (email.isEmpty) {
      _showSnack('Oy vermek için giriş yapın');
      return;
    }
    if (davaId == null || davaId.isEmpty) {
      return;
    }
    if (result.isWindowExpired) {
      _showSnack(
        '${DavaHukumService.hukumSuresiGun} gün doldu, oy değiştirilemez',
      );
      return;
    }

    final Map<String, dynamic> userAction =
        HiveDatabaseService.getUserDavaAction(davaId, email);
    final bool currentSupport = userAction['like'] as bool? ?? false;
    final bool currentCondemn = userAction['dislike'] as bool? ?? false;
    if (isSupport && currentSupport) {
      return;
    }
    if (!isSupport && currentCondemn) {
      return;
    }

    setState(() => _isSubmittingReaction = true);
    try {
      await HiveDatabaseService.toggleDavaLike(davaId, email, isSupport);
      if (!mounted) {
        return;
      }
      setState(() {
        _resultFuture = _loadResult();
        _isSubmittingReaction = false;
      });
      _showSnack(isSupport ? 'Destek oyunuz kaydedildi' : 'Kınama oyunuz kaydedildi');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmittingReaction = false);
      _showSnack('Oy kaydedilemedi');
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.davaId == null || widget.davaId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCE7E1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101815).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _sectionExpanded = !_sectionExpanded);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                ' Halk Kararı ',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: Color(0xFF1B2A23),
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _sectionExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.expand_more,
                                color: Colors.grey.shade600,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Verileri yenile',
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeInCubic,
              sizeCurve: Curves.easeInOutCubic,
              duration: const Duration(milliseconds: 280),
              crossFadeState: _sectionExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Align(
                      alignment: Alignment.center,
                      child: Chip(
                        label: Text(
                          '${DavaHukumService.hukumSuresiGun} Gün Sonrası',
                        ),
                        backgroundColor: Colors.green.shade50,
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ),
                  const Divider(height: 0),
                  const TabBar(
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Karar'),
                      Tab(text: 'Destek/Kınama'),
                    ],
                  ),
                  SizedBox(
                    height: 260,
                    child: FutureBuilder<DavaHalkKarariResult>(
                      future: _resultFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return _buildErrorState(snapshot.error);
                        }

                        final DavaHalkKarariResult result = snapshot.data!;
                        return TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildVerdictTab(result),
                            _buildStatsTab(result),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictTab(DavaHalkKarariResult result) {
    if (!result.canShowVerdict) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halk kararı için ${result.daysRemaining} gün kaldı.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: result.progress,
              minHeight: 8,
              backgroundColor: Colors.orange.shade100,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Destek ve kınama ikonlarıyla toplanan veriler ${DavaHukumService.hukumSuresiGun} günün sonunda değerlendirilecek.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    final bool isSuccessful = result.isSuccessful ?? false;
    final MaterialColor bannerColor =
        isSuccessful ? Colors.green : Colors.red;
    final String title = isSuccessful
        ? 'DAVACI HALK NEZDİNDE BAŞARILI OLDU'
        : 'DAVACI HALK NEZDİNDE BAŞARISIZ OLDU';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bannerColor.withOpacity(0.5), width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  isSuccessful ? Icons.check_circle : Icons.cancel,
                  color: bannerColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: bannerColor.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Destek: ${result.totalSupport}  •  Kına: ${result.totalCondemn}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          if (result.hukumTarihi != null) ...[
            const SizedBox(height: 6),
            Text(
              'Hüküm Tarihi: ${_formatDate(result.hukumTarihi!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if ((result.hukumAciklamasi ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.hukumAciklamasi!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsTab(DavaHalkKarariResult result) {
    final bool canVote = !result.isWindowExpired;
    final String email = widget.userEmail?.trim() ?? '';
    final Map<String, dynamic> userAction = email.isNotEmpty &&
            widget.davaId != null &&
            widget.davaId!.isNotEmpty
        ? HiveDatabaseService.getUserDavaAction(widget.davaId!, email)
        : const <String, dynamic>{};
    final bool userSupported = userAction['like'] as bool? ?? false;
    final bool userCondemned = userAction['dislike'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            canVote
                ? 'Herkes destek veya kınama seçebilir. ${DavaHukumService.hukumSuresiGun} gün dolana kadar seçiminizi değiştirebilirsiniz.'
                : '${DavaHukumService.hukumSuresiGun} gün doldu. Oylar kilitlendi.',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: canVote ? Colors.grey.shade700 : Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildVoteButton(
                  label: 'Destek',
                  count: result.totalSupport,
                  isActive: userSupported,
                  color: Colors.green,
                  outlineIcon: Icons.thumb_up_alt_outlined,
                  filledIcon: Icons.thumb_up,
                  enabled: canVote && !_isSubmittingReaction,
                  onTap: () => _handleReaction(true, result),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVoteButton(
                  label: 'Kınama',
                  count: result.totalCondemn,
                  isActive: userCondemned,
                  color: Colors.red,
                  outlineIcon: Icons.thumb_down_alt_outlined,
                  filledIcon: Icons.thumb_down,
                  enabled: canVote && !_isSubmittingReaction,
                  onTap: () => _handleReaction(false, result),
                ),
              ),
            ],
          ),
          if (_isSubmittingReaction) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 12),
          Text(
            'Destek Farkı: ${result.supportDelta >= 0 ? '+' : ''}${result.supportDelta}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: result.supportDelta >= 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: result.supportRatio,
            minHeight: 6,
            backgroundColor: Colors.blue.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(
              result.supportDelta >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            label: 'Geçen Gün',
            value: '${result.daysElapsed}/${result.requiredDays}',
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton({
    required String label,
    required int count,
    required bool isActive,
    required MaterialColor color,
    required IconData outlineIcon,
    required IconData filledIcon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final Color borderColor =
        isActive ? color.shade600 : const Color(0xFFDCE7E1);
    final Color backgroundColor =
        isActive ? color.withOpacity(0.12) : Colors.white;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? filledIcon : outlineIcon,
                color: enabled
                    ? (isActive ? color.shade700 : Colors.grey.shade700)
                    : Colors.grey.shade400,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? (isActive ? color.shade800 : Colors.grey.shade800)
                      : Colors.grey.shade500,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: enabled ? color.shade700 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Text(
        'Halk kararı yüklenemedi: ${error ?? 'Bilinmeyen hata'}',
        style: TextStyle(color: Colors.red.shade700),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    return '$day.$month.$year';
  }

  @override
  bool get wantKeepAlive => true;
}

