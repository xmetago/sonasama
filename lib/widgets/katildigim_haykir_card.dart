import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/hive_database_service.dart';
import '../utils/haykir_duration.dart';
import 'haykir_card_shell.dart';

/// Katıldığım haykırışlar için kompakt/genişleyen estetik kart.
class KatildigimHaykirCard extends StatefulWidget {
  final Map<String, dynamic> katildigimData;
  final Widget interactionsPanel;

  const KatildigimHaykirCard({
    super.key,
    required this.katildigimData,
    required this.interactionsPanel,
  });

  @override
  State<KatildigimHaykirCard> createState() => _KatildigimHaykirCardState();
}

class _KatildigimHaykirCardState extends State<KatildigimHaykirCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  String get _haykirId =>
      widget.katildigimData['haykirId']?.toString() ??
      widget.katildigimData['id']?.toString() ??
      '';

  Map<String, dynamic> get _sourceHaykir {
    if (_haykirId.isNotEmpty) {
      final fresh = HiveDatabaseService.getHaykir(_haykirId);
      if (fresh != null) return fresh;
    }
    return widget.katildigimData;
  }

  String _getDisplayName(String? email) {
    if (email == null || email.isEmpty) return 'Bilinmeyen';
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(email);
      return user?.judgeName ?? email.split('@').first;
    } catch (_) {
      return email.split('@').first;
    }
  }

  String get _authorEmail {
    final fromHaykir =
        HiveDatabaseService.getHaykir(_haykirId)?['userEmail']?.toString();
    if (fromHaykir != null && fromHaykir.isNotEmpty) return fromHaykir;
    return widget.katildigimData['authorEmail']?.toString() ?? '';
  }

  String _formatParticipatedAgo() {
    final participatedAt = widget.katildigimData['participatedAt']?.toString();
    if (participatedAt == null || participatedAt.isEmpty) return 'Katıldın';
    try {
      final date = DateTime.parse(participatedAt);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Az önce katıldın';
      if (diff.inHours < 1) return '${diff.inMinutes} dk önce katıldın';
      if (diff.inDays < 1) return '${diff.inHours} sa önce katıldın';
      if (diff.inDays < 7) return '${diff.inDays} gün önce katıldın';
      return '${date.day}.${date.month}.${date.year} tarihinde katıldın';
    } catch (_) {
      return 'Katıldın';
    }
  }

  bool get _showSuccessBadge {
    final haykir = HiveDatabaseService.getHaykir(_haykirId);
    if (haykir == null) return false;
    final createdAt = _sourceHaykir['createdAt']?.toString() ?? '';
    final scoringApplied = haykir['scoringApplied']?.toString() == 'true';
    final isSuccessStr = haykir['isSuccess']?.toString();
    return HaykirDuration.isExpired(createdAt) &&
        scoringApplied &&
        isSuccessStr != null;
  }

  bool get _isSuccess {
    final haykir = HiveDatabaseService.getHaykir(_haykirId);
    return haykir?['isSuccess']?.toString() == 'true';
  }

  @override
  Widget build(BuildContext context) {
    final source = _sourceHaykir;
    final createdAt = source['createdAt']?.toString() ?? '';
    final detaylar = source['detaylar']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HaykirCardShell(
        variant: HaykirCardShellVariant.katildigim,
        isExpanded: _isExpanded,
        isExpired: HaykirDuration.isExpired(createdAt),
        adi: source['adi']?.toString() ?? 'Haykırış',
        slogan: source['slogan']?.toString() ?? '',
        direme: source['direme']?.toString() ?? '',
        createdAt: createdAt,
        authorDisplayName: _getDisplayName(_authorEmail),
        authorSubtitle: _formatParticipatedAgo(),
        showSuccessBadge: _showSuccessBadge,
        isSuccess: _isSuccess,
        onHeaderTap: _toggleExpanded,
        expandedChildren: _isExpanded
            ? [
                if (detaylar.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildDetaylarBox(detaylar),
                ],
                const SizedBox(height: 12),
                widget.interactionsPanel,
              ]
            : null,
      ),
    );
  }

  Widget _buildDetaylarBox(String detaylar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(MdiIcons.textBoxOutline,
                  size: 16, color: Colors.teal.shade700),
              const SizedBox(width: 6),
              Text(
                'Detay',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detaylar,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
