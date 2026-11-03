import 'package:flutter/material.dart';

import '../models/registration_model.dart';
import '../models/user_gamified_score_model.dart';
import '../services/hive_database_service.dart';
import '../services/itibar_endeksi_service.dart';
import '../services/user_gamified_score_service.dart';
import '../services/user_session_service.dart';
import '../utils/app_theme.dart';
import '../widgets/profile_icons_row.dart';

/// Kullanıcının oyunlaştırılmış puan kartını gösteren ekran.
class UserGamifiedScorePage extends StatefulWidget {
  /// Puanı görüntülenecek kullanıcı.
  final RegistrationModel targetUser;

  /// Kullanıcının kategorisini yönetmek için çağrılacak geri çağırım.
  final VoidCallback? onManageCategory;

  /// Varsayılan kurucu.
  const UserGamifiedScorePage({
    super.key,
    required this.targetUser,
    this.onManageCategory,
  });

  @override
  State<UserGamifiedScorePage> createState() => _UserGamifiedScorePageState();
}

class _UserGamifiedScorePageState extends State<UserGamifiedScorePage> {
  static const int _maxScore = 10279;
  static const List<_ScoreLevelDefinition> _scoreLevels = [
    _ScoreLevelDefinition(
      lig: 5,
      rank: 19,
      concept: 'Adalet Kişisi',
      points: 10279,
      color: AppTheme.warningColor,
    ),
    _ScoreLevelDefinition(
      lig: 4,
      rank: 18,
      concept: 'Vefa Kişisi',
      points: 9386,
      color: AppTheme.warningColor,
    ),
    _ScoreLevelDefinition(
      lig: 4,
      rank: 17,
      concept: 'Hakkaniyet Kişisi',
      points: 8531,
      color: AppTheme.warningColor,
    ),
    _ScoreLevelDefinition(
      lig: 4,
      rank: 16,
      concept: 'Hikmet Kişisi',
      points: 7714,
      color: AppTheme.warningColor,
    ),
    _ScoreLevelDefinition(
      lig: 3,
      rank: 15,
      concept: 'Bilgelik Sahibi Kişisi',
      points: 6935,
      color: AppTheme.primaryColor,
    ),
    _ScoreLevelDefinition(
      lig: 3,
      rank: 14,
      concept: 'Sadakat Kişisi',
      points: 6194,
      color: AppTheme.primaryColor,
    ),
    _ScoreLevelDefinition(
      lig: 3,
      rank: 13,
      concept: 'Basiret Kişisi',
      points: 5491,
      color: AppTheme.primaryColor,
    ),
    _ScoreLevelDefinition(
      lig: 3,
      rank: 12,
      concept: 'Şahitlik Kişisi',
      points: 4826,
      color: AppTheme.primaryColor,
    ),
    _ScoreLevelDefinition(
      lig: 3,
      rank: 11,
      concept: 'İspat Ehli Kişisi',
      points: 4199,
      color: AppTheme.primaryColor,
    ),
    _ScoreLevelDefinition(
      lig: 2,
      rank: 10,
      concept: 'Analitik / Rasyonel Kişisi',
      points: 3610,
      color: const Color(0xFF2563EB),
    ),
    _ScoreLevelDefinition(
      lig: 2,
      rank: 9,
      concept: 'Bakış Sahibi Kişisi',
      points: 3059,
      color: const Color(0xFF2563EB),
    ),
    _ScoreLevelDefinition(
      lig: 2,
      rank: 8,
      concept: 'Feraset Kişisi',
      points: 2546,
      color: const Color(0xFF2563EB),
    ),
    _ScoreLevelDefinition(
      lig: 2,
      rank: 7,
      concept: 'Mizan Kişisi',
      points: 2071,
      color: const Color(0xFF2563EB),
    ),
    _ScoreLevelDefinition(
      lig: 2,
      rank: 6,
      concept: 'Tutarlı Kişisi',
      points: 1634,
      color: const Color(0xFF2563EB),
    ),
    _ScoreLevelDefinition(
      lig: 1,
      rank: 5,
      concept: 'İrade Sahibi Kişisi',
      points: 1235,
      color: const Color(0xFFB45309),
    ),
    _ScoreLevelDefinition(
      lig: 1,
      rank: 4,
      concept: 'Sabır Kişisi',
      points: 874,
      color: const Color(0xFFB45309),
    ),
    _ScoreLevelDefinition(
      lig: 1,
      rank: 3,
      concept: 'Dürüst Kişisi',
      points: 551,
      color: const Color(0xFFB45309),
    ),
    _ScoreLevelDefinition(
      lig: 1,
      rank: 2,
      concept: 'Empatik (Rahmet) Kişisi',
      points: 266,
      color: const Color(0xFFB45309),
    ),
    _ScoreLevelDefinition(
      lig: 1,
      rank: 1,
      concept: 'Hassas Vicdanlı Kişisi',
      points: 19,
      color: const Color(0xFFB45309),
    ),
  ];

  UserGamifiedScoreModel? _scoreModel;
  bool _isLoading = true;
  bool _levhBusy = false;
  String? _errorMessage;

  bool get _viewerIsAdmin {
    final email = UserSessionService.getCurrentUser()?.email;
    return HiveDatabaseService.isAdmin(email);
  }

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  /// Skor verisini servis üzerinden yükler.
  Future<void> _loadScore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final score = await UserGamifiedScoreService.buildScore(
        targetUser: widget.targetUser,
      );
      if (!mounted) return;
      setState(() {
        _scoreModel = score;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Puan kartı yüklenirken bir sorun oluştu.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Kategori yönetimini tetikler.
  void _handleManageCategory() {
    if (widget.onManageCategory == null) return;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onManageCategory?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.successColor,
        foregroundColor: AppTheme.textOnPrimary,
        title: const Text('Puan Kartı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _isLoading ? null : _loadScore,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Ekranın gövdesini oluşturur.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.successColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadScore,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: AppTheme.primaryButtonStyle,
              ),
            ],
          ),
        ),
      );
    }

    final score = _scoreModel;
    if (score == null) {
      return const SizedBox.shrink();
    }

    final currentLevel = _resolveCurrentLevel(score.totalScore);
    final nextLevel = _resolveNextLevel(currentLevel);
    final progressValue = _calculateProgress(
      score.totalScore,
      currentLevel,
      nextLevel,
    );

    return RefreshIndicator(
      color: AppTheme.successColor,
      onRefresh: _loadScore,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(score, currentLevel),
            const SizedBox(height: 16),
            _buildScoreSummaryCard(score, currentLevel, nextLevel),
            const SizedBox(height: 16),
            _buildProgressCard(currentLevel, nextLevel, progressValue),
            const SizedBox(height: 16),
            _buildBreakdownSection(score),
            if (score.earnedBadges.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildEarnedBadgesSection(score),
            ],
            const SizedBox(height: 16),
            _buildLevelsTable(currentLevel),
            const SizedBox(height: 16),
            _buildInsightCards(score, currentLevel, nextLevel),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Kullanıcının profil başlığını oluşturur.
  Widget _buildHeroHeader(
    UserGamifiedScoreModel score,
    _ScoreLevelDefinition currentLevel,
  ) {
    final initials = widget.targetUser.judgeName.isNotEmpty
        ? widget.targetUser.judgeName.characters.first.toUpperCase()
        : '?';
    final motto = _resolveMotto(currentLevel.concept);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.calmGreenDark, AppTheme.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.textOnPrimary.withOpacity(0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.targetUser.judgeName,
                      style: AppTheme.headline4.copyWith(
                        color: AppTheme.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.targetUser.email,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textOnPrimary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.textOnPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.textOnPrimary.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        currentLevel.concept,
                        style: const TextStyle(
                          color: AppTheme.textOnPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildHeroChip(
                iconWidget: ProfileIconsRow.ligIcon(
                  currentLevel.lig,
                  size: 18,
                  color: AppTheme.textOnPrimary,
                ),
                label: 'Lig ${currentLevel.lig}',
                subtitle: ProfileIconsRow.ligLabel(currentLevel.lig),
              ),
              const SizedBox(width: 10),
              _buildHeroChip(
                icon: Icons.star_outline,
                label: _formatPoints(score.totalScore),
                subtitle: 'Toplam puan',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '1-Hassas Vicdanlı Kişisi\'nden  --> 2- Empatik(Rahmet) Kişisi\'ne  değer yolculuğu',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textOnPrimary.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// Hero bölümündeki küçük bilgi çiplerini oluşturur.
  Widget _buildHeroChip({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.textOnPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (iconWidget != null)
              iconWidget
            else
              Icon(icon, color: AppTheme.textOnPrimary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textOnPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textOnPrimary.withOpacity(0.75),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Seviye ve toplam puan özetini gösterir.
  Widget _buildScoreSummaryCard(
    UserGamifiedScoreModel score,
    _ScoreLevelDefinition currentLevel,
    _ScoreLevelDefinition? nextLevel,
  ) {
    return Container();
  }

  /// Özet satırlarını üretir.
  Widget _buildSummaryItem({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.textOnPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textOnPrimary.withOpacity(0.75),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textOnPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// İlerleme çubuğu kartını oluşturur.
  Widget _buildProgressCard(
    _ScoreLevelDefinition currentLevel,
    _ScoreLevelDefinition? nextLevel,
    double progressValue,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration(bordered: true),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seviye İlerlemeniz',
                  style: AppTheme.headline4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.calmGreenUltraLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nextLevel == null
                      ? 'Zirvedesiniz'
                      : '${_formatPoints(nextLevel.points)} puana',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.successDarkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (nextLevel != null) ...[
            const SizedBox(height: 6),
            Text(
              nextLevel.concept,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progressValue,
              backgroundColor: AppTheme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(currentLevel.color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Başlangıç: ${_formatPoints(currentLevel.points)}',
                style: AppTheme.caption,
              ),
              Text(
                '%${(progressValue * 100).round()}',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.successDarkColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Zirve: ${_formatPoints(_maxScore)}',
                style: AppTheme.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Puan kalemlerini gösteren bölümü oluşturur.
  Widget _buildBreakdownSection(UserGamifiedScoreModel score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İtibar Endeksi', style: AppTheme.headline4),
        const SizedBox(height: 4),
        Text(
          'Sosyal Lig, Dava Enerjisi, Masraf/Hediye Sadakati, '
          'Levh-i Mahfûz Defteri ve Diren Endeksi ortalaması.',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ...score.breakdownItems.map((item) {
          final isItibar = item.metricId == 'itibar';
          final card = _buildBreakdownCard(item);
          if (!isItibar) return card;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showItibarTrend(score),
              child: card,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBreakdownCard(ScoreBreakdownItem item) {
    final valueColor = _pointsColor(item);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(bordered: true),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.description,
                  style: AppTheme.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.metricId == 'itibar') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Trend grafiği',
                    style: AppTheme.caption.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMetricValue(item),
                style: AppTheme.bodyMedium.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.metricId == 'levh' && _viewerIsAdmin)
                TextButton(
                  onPressed: _levhBusy ? null : _incrementLevh,
                  style: TextButton.styleFrom(
                    foregroundColor: item.color,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(_levhBusy ? '...' : '+0'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _pointsColor(ScoreBreakdownItem item) {
    final value = item.preciseValue ?? item.points.toDouble();
    if (value < 0) return AppTheme.errorColor;
    if (value > 0) return AppTheme.successDarkColor;
    return AppTheme.textSecondary;
  }

  String _formatMetricValue(ScoreBreakdownItem item) {
    if (item.preciseValue != null) {
      return _formatSignedDouble(item.preciseValue!);
    }
    if (item.metricId == 'levh' && item.points == 0) return '+0';
    return _formatSignedInt(item.points);
  }

  String _formatSignedInt(int value) {
    if (value > 0) return '+${_formatPoints(value)}';
    if (value < 0) return '-${_formatPoints(value.abs())}';
    return '0';
  }

  String _formatSignedDouble(double value) {
    final text = value.abs().toStringAsFixed(2);
    if (value > 0) return '+$text';
    if (value < 0) return '-$text';
    return '0.00';
  }

  Future<void> _incrementLevh() async {
    setState(() => _levhBusy = true);
    try {
      final next = await ItibarEndeksiService.incrementLevhMahfuz(
        widget.targetUser.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Levh-i Mahfûz Defteri: +$next')),
      );
      await _loadScore();
    } finally {
      if (mounted) setState(() => _levhBusy = false);
    }
  }

  void _showItibarTrend(UserGamifiedScoreModel score) {
    final points = score.trendPoints.isEmpty
        ? const [0, 3, 6, 9, 12]
            .map(
              (months) => ItibarTrendPoint(
                monthsBack: months,
                label: months == 12 ? '12 ay (yıllık)' : '$months ay',
                average: score.itibarEndeksi,
              ),
            )
            .toList()
        : score.trendPoints;
    var maxAbs = 1.0;
    for (final point in points) {
      final abs = point.average.abs();
      if (abs > maxAbs) maxAbs = abs;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İtibar Endeksi'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatSignedDouble(score.itibarEndeksi),
                  style: AppTheme.headline4.copyWith(
                    color: score.itibarEndeksi < 0
                        ? AppTheme.errorColor
                        : AppTheme.successDarkColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '(Sosyal Lig + Dava Enerjisi + Masraf/Hediye Sadakati + '
                  'Levh-i Mahfûz + Diren Endeksi) / 5',
                  style: AppTheme.caption,
                ),
                const SizedBox(height: 16),
                ...points.map((point) {
                  final fraction = (point.average.abs() / maxAbs).clamp(0.0, 1.0);
                  final barColor = point.average < 0
                      ? AppTheme.errorColor
                      : AppTheme.successColor;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(point.label, style: AppTheme.bodySmall),
                            ),
                            Text(
                              _formatSignedDouble(point.average),
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: barColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: fraction == 0 ? 0.04 : fraction,
                            backgroundColor: AppTheme.dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  /// Servisten gelen kazanılmış rozetleri gösterir.
  Widget _buildEarnedBadgesSection(UserGamifiedScoreModel score) {
    return Column(

    );
  }

  /// Seviye tablosunu oluşturur.
  Widget _buildLevelsTable(_ScoreLevelDefinition currentLevel) {
    return Container(
      decoration: AppTheme.cardDecoration(bordered: true),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Değer Seviyeleri ve Puanları', style: AppTheme.headline4),
          const SizedBox(height: 4),
          Text(
            'Mevcut seviyeniz vurgulanmıştır.',
            style: AppTheme.caption,
          ),
          const SizedBox(height: 14),
          _buildTableHeader(),
          const Divider(height: 1, color: AppTheme.dividerColor),
          ..._scoreLevels.map((level) {
            final isCurrent = level.rank == currentLevel.rank;
            return _buildTableRow(level, isCurrent);
          }),
        ],
      ),
    );
  }

  /// Tablo başlık satırını oluşturur.
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Seviye', style: _tableHeaderStyle),
          ),
          Expanded(
            child: Text('Sıra', style: _tableHeaderStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: Text('Kavram', style: _tableHeaderStyle),
          ),
          Expanded(
            child: Text('Puan', style: _tableHeaderStyle, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    color: AppTheme.textSecondary,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  /// Tablo satırını üretir.
  Widget _buildTableRow(_ScoreLevelDefinition level, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.calmGreenUltraLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(color: AppTheme.successColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                ProfileIconsRow.ligIcon(
                  level.lig,
                  size: 16,
                  color: level.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lig ${level.lig}',
                    style: TextStyle(
                      color: level.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              level.rank.toString(),
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isCurrent ? AppTheme.successDarkColor : AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isCurrent) ...[
                  Icon(Icons.arrow_forward, size: 14, color: AppTheme.successColor),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    level.concept,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? AppTheme.successDarkColor : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              _formatPoints(level.points),
              textAlign: TextAlign.right,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Yeni öneri alanlarını gösteren kartları oluşturur.
  Widget _buildInsightCards(
    UserGamifiedScoreModel score,
    _ScoreLevelDefinition currentLevel,
    _ScoreLevelDefinition? nextLevel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Değer Yolculuğu Rehberi', style: AppTheme.headline4),
        const SizedBox(height: 12),
        _buildInsightCard(
          title: 'Motto',
          description: _resolveMotto(currentLevel.concept),
          icon: Icons.favorite_outline,
          color: AppTheme.accentColor,
        ),
        const SizedBox(height: 10),
        _buildInsightCard(
          title: 'Odak Değeri',
          description:
              '${currentLevel.concept} seviyesinde, doğruluk ve şeffaflık önceliğiniz.',
          icon: Icons.track_changes_outlined,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 10),
        _buildInsightCard(
          title: 'Hedef Puan',
          description: nextLevel == null
              ? 'Zirvedesiniz. Adalet Kişisi seviyesini koruyun.'
              : '${_formatPoints(nextLevel.points)} puanda ${nextLevel.concept} olacaksınız.',
          icon: Icons.flag_outlined,
          color: AppTheme.warningColor,
        ),
        const SizedBox(height: 10),
        _buildInsightCard(
          title: 'Toplam Katkı',
          description:
              'Şu ana kadar ${_formatPoints(score.totalScore)} puan biriktirdiniz.',
          icon: Icons.auto_graph_outlined,
          color: AppTheme.successColor,
        ),
      ],
    );
  }

  /// Rehber kartlarını oluşturur.
  Widget _buildInsightCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(
        color: color.withOpacity(0.05),
        bordered: true,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sayfanın alt aksiyon butonlarını oluşturur.
  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.onManageCategory != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleManageCategory,
              icon: const Icon(Icons.category_outlined),
              label: const Text('Kategori Yönet'),
              style: AppTheme.primaryButtonStyle.copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        if (widget.onManageCategory != null) const SizedBox(height: 10),

      ],
    );
  }

  /// Mevcut seviye tanımını belirler.
  _ScoreLevelDefinition _resolveCurrentLevel(int totalScore) {
    _ScoreLevelDefinition? best;
    for (final level in _scoreLevels) {
      if (totalScore >= level.points &&
          (best == null || level.rank > best.rank)) {
        best = level;
      }
    }
    return best ?? _scoreLevels.last;
  }

  /// Bir sonraki seviyeyi belirler.
  _ScoreLevelDefinition? _resolveNextLevel(_ScoreLevelDefinition currentLevel) {
    if (currentLevel.rank >= 19) {
      return null;
    }
    for (final level in _scoreLevels) {
      if (level.rank == currentLevel.rank + 1) {
        return level;
      }
    }
    return null;
  }

  /// İlerleme yüzdesini hesaplar.
  double _calculateProgress(
    int totalScore,
    _ScoreLevelDefinition currentLevel,
    _ScoreLevelDefinition? nextLevel,
  ) {
    if (nextLevel == null) {
      return 1;
    }
    final span = nextLevel.points - currentLevel.points;
    if (span <= 0) {
      return 1;
    }
    final progress = (totalScore - currentLevel.points) / span;
    return progress.clamp(0, 1);
  }

  /// Kavrama uygun motto üretir.
  String _resolveMotto(String concept) {
    const mottos = {
      'Hassas Vicdanlı Kişisi':
          'Pusulanın iğnesi vicdandır; yönü o belirler.',
      'Empatik (Rahmet) Kişisi':
          'Başkasının halini hissetmek, pusulanın hassasiyetidir.',
      'Dürüst Kişisi':
          'Pusula yalan söylemez; dürüstlük yönün doğruluğudur.',
      'Sabır Kişisi':
          'Fırtınada pusula titrer ama sapmaz; sabır istikrardır.',
      'İrade Sahibi Kişisi':
          'Pusula yönü gösterir, irade o yönde yürür.',
      'Tutarlı Kişisi':
          'El sıkışmanın değeri tutarlılığındadır; sözünde durmak.',
      'Mizan Kişisi':
          'Elden ele geçen hakkın ölçüsü; tartma eylemi.',
      'Feraset Kişisi':
          'Doğru eli doğru zamanda sıkmak; isabetli bağ kurma.',
      'Bakış Sahibi Kişisi':
          'Karşındakinin elini değil, niyetini görmek.',
      'Analitik / Rasyonel Kişisi':
          'Güvenin duygusal değil, rasyonel temellerini inşa etmek.',
      'İspat Ehli Kişisi':
          'Kanıt, gerçeğin aynadaki yansımasıdır.',
      'Şahitlik Kişisi':
          'Tanıklık, olayı olduğu gibi yansıtan aynadır.',
      'Basiret Kişisi':
          'Aynanın buğusunu silen derin kavrayış; özü görme.',
      'Sadakat Kişisi':
          'Ayna sadıktır; neyi yansıtacağını seçmez, olduğu gibi gösterir.',
      'Bilgelik Sahibi Kişisi':
          'Aynanın sadece yüzeyi değil, derinliğini de yansıtması.',
      'Hikmet Kişisi':
          'Terazinin kefelerini okuyabilme bilinci; yorumlama zirvesi.',
      'Hakkaniyet Kişisi':
          'Hakkı yerine koyma; terazinin temel işlevi.',
      'Vefa Kişisi':
          'Terazinin borç kefesini dengeleyen karşılıksız bağlılık.',
      'Adalet Kişisi':
          'Terazinin kendisi; tüm ışıkların birleştiği nihai denge noktası.',
    };
    return mottos[concept] ??
        'Değer odaklı ilerleyişin, topluluğun adalet bilincini güçlendiriyor.';
  }

  /// Puanları binlik formatında döndürür.
  String _formatPoints(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}

/// Seviye tablo tanımlarını temsil eder.
class _ScoreLevelDefinition {
  /// Lig numarası (1 Pusula … 5 ⑲).
  final int lig;

  /// Puan tablosundaki sıra.
  final int rank;

  /// Kavram başlığı.
  final String concept;

  /// Seviyenin puanı.
  final int points;

  /// Seviyenin rengi.
  final Color color;

  /// Varsayılan kurucu.
  const _ScoreLevelDefinition({
    required this.lig,
    required this.rank,
    required this.concept,
    required this.points,
    required this.color,
  });
}
