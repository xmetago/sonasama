import 'package:flutter/material.dart';

import '../models/registration_model.dart';
import '../models/user_gamified_score_model.dart';
import '../services/hive_database_service.dart';
import '../services/itibar_endeksi_service.dart';
import '../services/user_gamified_score_service.dart';
import '../services/user_session_service.dart';
import '../theme/seyir_tokens.dart';
import '../utils/app_theme.dart';
import '../widgets/delil_surface.dart';
import '../widgets/profile_icons_row.dart';

/// Kullanıcının oyunlaştırılmış puan kartını gösteren ekran.
class UserGamifiedScorePage extends StatefulWidget {
  /// Puanı görüntülenecek kullanıcı.
  final RegistrationModel targetUser;

  /// Kullanıcının kategorisini yönetmek için çağrılacak geri çağırım.
  final VoidCallback? onManageCategory;

  /// Başkasının kartı. Düzenleme düğmeleri gizlenir.
  final bool readOnly;

  /// Widget testi: yükleme hatasını gösterir.
  final bool forceLoadError;

  /// Varsayılan kurucu.
  const UserGamifiedScorePage({
    super.key,
    required this.targetUser,
    this.onManageCategory,
    this.readOnly = false,
    this.forceLoadError = false,
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

  SeyirPalette get _palette => SeyirPalette.of(context);

  BoxDecoration _scoreCard({Color? accent}) {
    final SeyirPalette palette = _palette;
    return BoxDecoration(
      color: accent == null ? palette.card : palette.tint(accent),
      borderRadius: SeyirTokens.radiusLgAll,
      border: Border.all(
        color: accent == null ? palette.border : palette.tintBorder(accent),
      ),
      boxShadow: palette.cardShadow,
    );
  }

  Color get _positive => _palette.foreground(SeyirTokens.accept);

  Color get _negative => _palette.foreground(SeyirTokens.reject);

  bool get _viewerIsAdmin {
    final email = UserSessionService.getCurrentUser()?.email;
    return HiveDatabaseService.isAdmin(email);
  }

  @override
  void initState() {
    super.initState();
    if (widget.forceLoadError) {
      _isLoading = false;
      _errorMessage = 'Puan kartı yüklenirken bir sorun oluştu.';
      return;
    }
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
    final SeyirPalette palette = _palette;
    final Color header = SeyirTokens.brand;
    final Color headerInk = palette.onSolid(header);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: header,
        foregroundColor: headerInk,
        title: Text('Puan Kartı', style: palette.display(color: headerInk)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _isLoading ? null : _loadScore,
            style: delilIconButtonStyle(foreground: headerInk),
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
          color: SeyirTokens.brand,
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(SeyirTokens.space4),
        child: DelilLoadError(
          message: _errorMessage!,
          onRetry: _loadScore,
        ),
      );
    }

    final score = _scoreModel;
    if (score == null) {
      return const Padding(
        padding: EdgeInsets.all(SeyirTokens.space4),
        child: DelilSoftEmpty(
          title: 'Puan kartı yok',
          message: 'Bu yargıç için gösterilecek puan kaydı yok.',
          icon: Icons.emoji_events_outlined,
        ),
      );
    }

    final currentLevel = _resolveCurrentLevel(score.totalScore);
    final nextLevel = _resolveNextLevel(currentLevel);
    final progressValue = _calculateProgress(
      score.totalScore,
      currentLevel,
      nextLevel,
    );

    return RefreshIndicator(
      color: SeyirTokens.brand,
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
                    fontSize: SeyirTokens.typeDisplay,
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
                      style: _palette.headline(color: AppTheme.textOnPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.targetUser.email,
                      style: _palette.body(
                        weight: FontWeight.w400,
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
            style: _palette.caption(
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
              fontSize: SeyirTokens.typeCaption,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textOnPrimary,
              fontWeight: FontWeight.bold,
              fontSize: SeyirTokens.typeBody,
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
      decoration: _scoreCard(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seviye İlerlemeniz',
                  style: _palette.headline(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _palette.brandSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nextLevel == null
                      ? 'Zirvedesiniz'
                      : '${_formatPoints(nextLevel.points)} puana',
                  style: _palette.caption(
                    color: _positive,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (nextLevel != null) ...[
            const SizedBox(height: 6),
            Text(
              nextLevel.concept,
              style: _palette.body(
                weight: FontWeight.w400,
                color: _palette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progressValue,
              backgroundColor: _palette.border,
              valueColor: AlwaysStoppedAnimation<Color>(currentLevel.color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Başlangıç: ${_formatPoints(currentLevel.points)}',
                style: _palette.caption(),
              ),
              Text(
                '%${(progressValue * 100).round()}',
                style: _palette.caption(
                  color: _positive,
                  weight: FontWeight.w700,
                ),
              ),
              Text(
                'Zirve: ${_formatPoints(_maxScore)}',
                style: _palette.caption(),
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
        Text('İtibar Endeksi', style: _palette.headline()),
        const SizedBox(height: 4),
        Text(
          'Sosyal Lig, Dava Enerjisi, Masraf/Hediye Sadakati, '
          'Levh-i Mahfûz Defteri ve Diren Endeksi ortalaması.',
          style: _palette.body(
            weight: FontWeight.w400,
            color: _palette.textSecondary,
          ),
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
      decoration: _scoreCard(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _palette.tint(item.color),
              borderRadius: SeyirTokens.radiusMdAll,
              border: Border.all(color: _palette.tintBorder(item.color)),
            ),
            child: Icon(
              item.icon,
              color: _palette.foreground(item.color),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: _palette.title(weight: FontWeight.w600),
                ),
                Text(
                  item.description,
                  style: _palette.caption(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.metricId == 'itibar') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Trend grafiği',
                    style: _palette.caption(
                      color: _palette.foreground(item.color),
                      weight: FontWeight.w600,
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
                style: _palette.title(color: valueColor),
              ),
              if (item.metricId == 'levh' && _viewerIsAdmin && !widget.readOnly)
                TextButton(
                  onPressed: _levhBusy ? null : _incrementLevh,
                  style: TextButton.styleFrom(
                    foregroundColor: _palette.foreground(item.color),
                    minimumSize: const Size(
                      SeyirTokens.tapTarget,
                      SeyirTokens.tapTarget,
                    ),
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
    if (value < 0) return _negative;
    if (value > 0) return _positive;
    return _palette.textSecondary;
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
    final points = score.trendPoints;
    var maxAbs = 1.0;
    for (final point in points) {
      final abs = point.average.abs();
      if (abs > maxAbs) maxAbs = abs;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final SeyirPalette palette = SeyirPalette.of(dialogContext);
        final Color valueColor = score.itibarEndeksi < 0
            ? palette.foreground(SeyirTokens.reject)
            : palette.foreground(SeyirTokens.accept);
        return AlertDialog(
          backgroundColor: palette.card,
          title: Text('İtibar Endeksi', style: palette.headline()),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatSignedDouble(score.itibarEndeksi),
                  style: palette.headline(color: valueColor),
                ),
                const SizedBox(height: 6),
                Text(
                  '(Sosyal Lig + Dava Enerjisi + Masraf/Hediye Sadakati + '
                  'Levh-i Mahfûz + Diren Endeksi) / 5',
                  style: palette.caption(),
                ),
                const SizedBox(height: 16),
                if (!score.hasItibarHistory)
                  Text(
                    'Henüz geçmiş yok',
                    style: palette.body(
                      weight: FontWeight.w400,
                      color: palette.textSecondary,
                    ),
                  )
                else
                  ...points.map((point) {
                    final fraction =
                        (point.average.abs() / maxAbs).clamp(0.0, 1.0);
                    final barColor = point.average < 0
                        ? palette.foreground(SeyirTokens.reject)
                        : palette.foreground(SeyirTokens.accept);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  point.label,
                                  style: palette.body(
                                    weight: FontWeight.w400,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                _formatSignedDouble(point.average),
                                style: palette.body(
                                  weight: FontWeight.w700,
                                  color: barColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: SeyirTokens.radiusSmAll,
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: fraction == 0 ? 0.04 : fraction,
                              backgroundColor: palette.border,
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  SeyirTokens.tapTarget,
                  SeyirTokens.tapTarget,
                ),
                foregroundColor: palette.textPrimary,
              ),
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
      decoration: _scoreCard(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Değer Seviyeleri ve Puanları', style: _palette.headline()),
          const SizedBox(height: 4),
          Text(
            'Mevcut seviyeniz vurgulanmıştır.',
            style: _palette.caption(),
          ),
          const SizedBox(height: 14),
          _buildTableHeader(),
          Divider(height: 1, color: _palette.border),
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

  TextStyle get _tableHeaderStyle => _palette.caption(
        color: _palette.textSecondary,
        weight: FontWeight.w700,
      );

  /// Tablo satırını üretir.
  Widget _buildTableRow(_ScoreLevelDefinition level, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isCurrent ? _palette.brandSoft : Colors.transparent,
        borderRadius: SeyirTokens.radiusMdAll,
        border: isCurrent
            ? Border.all(color: _palette.tintBorder(SeyirTokens.brand))
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
                  color: _palette.foreground(level.color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lig ${level.lig}',
                    style: _palette.caption(
                      color: _palette.foreground(level.color),
                      weight: FontWeight.w700,
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
              style: _palette.body(
                weight: FontWeight.w600,
                color: isCurrent ? _positive : _palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isCurrent) ...[
                  Icon(Icons.arrow_forward, size: 14, color: _positive),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    level.concept,
                    style: _palette.body(
                      weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? _positive : _palette.textPrimary,
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
              style: _palette.body(
                weight: FontWeight.w700,
                color: _palette.textPrimary,
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
        Text('Değer Yolculuğu Rehberi', style: _palette.headline()),
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
      decoration: _scoreCard(accent: color),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _palette.tint(color),
              borderRadius: SeyirTokens.radiusMdAll,
              border: Border.all(color: _palette.tintBorder(color)),
            ),
            child: Icon(icon, color: _palette.foreground(color), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _palette.title(),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: _palette.body(
                    weight: FontWeight.w400,
                    color: _palette.textSecondary,
                  ),
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
        if (widget.onManageCategory != null && !widget.readOnly)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleManageCategory,
              icon: const Icon(Icons.category_outlined),
              label: const Text('Kategori Yönet'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, SeyirTokens.tapTarget),
                backgroundColor: SeyirTokens.brand,
                foregroundColor: _palette.onSolid(SeyirTokens.brand),
                padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space4),
              ),
            ),
          ),
        if (widget.onManageCategory != null && !widget.readOnly)
          const SizedBox(height: 10),

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
