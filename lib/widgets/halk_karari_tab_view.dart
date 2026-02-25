import 'package:flutter/material.dart';

import '../models/dava_halk_karari_result.dart';
import '../services/dava_halk_karari_service.dart';

/// Hüküm alanının hemen altında halk kararını gösteren tablı widget.
class HalkKarariTabView extends StatefulWidget {
  final String? davaId;
  final DateTime? acceptedAt;

  const HalkKarariTabView({
    super.key,
    required this.davaId,
    this.acceptedAt,
  });

  @override
  State<HalkKarariTabView> createState() => _HalkKarariTabViewState();
}

class _HalkKarariTabViewState extends State<HalkKarariTabView>
    with AutomaticKeepAliveClientMixin {
  late Future<DavaHalkKarariResult> _resultFuture;

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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Text(
                    'Halk Kararı',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('76 Gün Sonrası'),
                    backgroundColor: Colors.green.shade50,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(color: Colors.green.shade700),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Verileri yenile',
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            const TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Karar'),
                Tab(text: 'Destek/Kına'),
              ],
            ),
            SizedBox(
              height: 190,
              child: FutureBuilder<DavaHalkKarariResult>(
                future: _resultFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
              'Destek ve kınama ikonlarıyla toplanan veriler 76 günün sonunda değerlendirilecek.',
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destek Farkı: ${result.supportDelta >= 0 ? '+' : ''}${result.supportDelta}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: result.supportDelta >= 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: result.supportRatio,
            minHeight: 8,
            backgroundColor: Colors.blue.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(
              result.supportDelta >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            label: 'Toplam Destek',
            value: result.totalSupport.toString(),
            color: Colors.green,
          ),
          _buildStatRow(
            label: 'Toplam Kına',
            value: result.totalCondemn.toString(),
            color: Colors.red,
          ),
          _buildStatRow(
            label: 'Geçen Gün',
            value: '${result.daysElapsed}/${result.requiredDays}',
            color: Colors.blueGrey,
          ),
        ],
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

