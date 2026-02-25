import 'package:flutter/material.dart';

import '../models/registration_model.dart';
import '../models/user_gamified_score_model.dart';
import '../services/user_gamified_score_service.dart';

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
  static const int _silverThreshold = 2546;
  static const int _bronzeThreshold = 19;
  static const List<_ScoreLevelDefinition> _scoreLevels = [
    _ScoreLevelDefinition(
      tierLabel: 'ALTIN',
      tierEmoji: '🟡',
      rank: 1,
      concept: 'Adalet Kişisi',
      points: 10279,
      color: Color(0xFFFFD54F),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'ALTIN',
      tierEmoji: '🟡',
      rank: 2,
      concept: 'Hikmet Kişisi',
      points: 9386,
      color: Color(0xFFFFD54F),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'ALTIN',
      tierEmoji: '🟡',
      rank: 3,
      concept: 'Hakkaniyet Kişisi',
      points: 8531,
      color: Color(0xFFFFD54F),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'ALTIN',
      tierEmoji: '🟡',
      rank: 4,
      concept: 'İnanç Sahibi Kişisi',
      points: 7714,
      color: Color(0xFFFFD54F),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'ALTIN',
      tierEmoji: '🟡',
      rank: 5,
      concept: 'İrade Sahibi Kişisi',
      points: 6935,
      color: Color(0xFFFFD54F),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'ALTIN',
      tierEmoji: '🟡',
      rank: 6,
      concept: 'Şahitlik Kişisi',
      points: 6194,
      color: Color(0xFFFFD54F),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'GÜMÜŞ',
      tierEmoji: '⚪',
      rank: 7,
      concept: 'Basiret Kişisi',
      points: 5491,
      color: Color(0xFFCFD8DC),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'GÜMÜŞ',
      tierEmoji: '⚪',
      rank: 8,
      concept: 'Feraset Kişisi',
      points: 4826,
      color: Color(0xFFCFD8DC),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'GÜMÜŞ',
      tierEmoji: '⚪',
      rank: 9,
      concept: 'Empatik (Rahmet) Kişisi',
      points: 4199,
      color: Color(0xFFCFD8DC),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'GÜMÜŞ',
      tierEmoji: '⚪',
      rank: 10,
      concept: 'Analitik / Rasyonel Kişisi',
      points: 3610,
      color: Color(0xFFCFD8DC),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'GÜMÜŞ',
      tierEmoji: '⚪',
      rank: 11,
      concept: 'İspat Ehli Kişisi',
      points: 3059,
      color: Color(0xFFCFD8DC),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'GÜMÜŞ',
      tierEmoji: '⚪',
      rank: 12,
      concept: 'Bilgelik Sahibi Kişisi',
      points: 2546,
      color: Color(0xFFCFD8DC),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'BRONZ',
      tierEmoji: '🟤',
      rank: 13,
      concept: 'Dürüst Kişisi',
      points: 2071,
      color: Color(0xFFCD7F32),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'BRONZ',
      tierEmoji: '🟤',
      rank: 14,
      concept: 'Sabır Kişisi',
      points: 1634,
      color: Color(0xFFCD7F32),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'BRONZ',
      tierEmoji: '🟤',
      rank: 15,
      concept: 'Dengeli Kişisi',
      points: 1235,
      color: Color(0xFFCD7F32),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'BRONZ',
      tierEmoji: '🟤',
      rank: 16,
      concept: 'Tutarlı Kişisi',
      points: 874,
      color: Color(0xFFCD7F32),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'BRONZ',
      tierEmoji: '🟤',
      rank: 17,
      concept: 'Bakış Sahibi Kişisi',
      points: 551,
      color: Color(0xFFCD7F32),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'BRONZ',
      tierEmoji: '🟤',
      rank: 18,
      concept: 'Fikir Sahibi Kişisi',
      points: 266,
      color: Color(0xFFCD7F32),
    ),
    _ScoreLevelDefinition(
      tierLabel: 'BRONZ',
      tierEmoji: '🟤',
      rank: 19,
      concept: 'Hassas Vicdanlı Kişisi',
      points: 19,
      color: Color(0xFFCD7F32),
    ),
  ];

  UserGamifiedScoreModel? _scoreModel;
  bool _isLoading = true;
  String? _errorMessage;

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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Puan Kartı',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScore,
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
          color: Colors.orangeAccent,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadScore,
              child: const Text('Tekrar Dene'),
            ),
          ],
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(score, currentLevel),
          const SizedBox(height: 20),
          _buildScoreSummaryCard(score, currentLevel, nextLevel),
          const SizedBox(height: 20),
          _buildProgressCard(currentLevel, nextLevel, progressValue),
          const SizedBox(height: 20),
          _buildBadgeSection(score.totalScore),
          const SizedBox(height: 20),
          _buildLevelsTable(currentLevel),
          const SizedBox(height: 20),
          _buildInsightCards(score, currentLevel, nextLevel),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
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
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                radius: 38,
                backgroundColor: Colors.orangeAccent,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.targetUser.email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: currentLevel.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: currentLevel.color),
                      ),
                      child: Text(
                        currentLevel.concept,
                        style: TextStyle(
                          color: currentLevel.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hassas Vicdanlı Kişisi\'nden Adalet Kişisi\'ne değer yolculuğu',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    motto,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seviye ve toplam puan özetini gösterir.
  Widget _buildScoreSummaryCard(
    UserGamifiedScoreModel score,
    _ScoreLevelDefinition currentLevel,
    _ScoreLevelDefinition? nextLevel,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seviye ${currentLevel.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentLevel.concept,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSummaryItem(
                label: 'Toplam Puan',
                value: _formatPoints(score.totalScore),
              ),
              _buildSummaryItem(
                label: 'Sıra',
                value: '${currentLevel.rank}/${_scoreLevels.length}',
              ),
              _buildSummaryItem(
                label: 'Seviye Durumu',
                value: currentLevel.tierText,
              ),
              _buildSummaryItem(
                label: 'Sonraki Seviye',
                value: nextLevel?.concept ?? 'Zirve',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Özet satırlarını üretir.
  Widget _buildSummaryItem({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seviye İlerlemeniz',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nextLevel == null
                      ? 'Zirvedesiniz'
                      : '${_formatPoints(nextLevel.points)} puanda ${nextLevel.concept}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progressValue,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(currentLevel.color),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Başlangıç: ${_formatPoints(currentLevel.points)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
              Text(
                'Zirve: ${_formatPoints(_maxScore)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Rozet seviyelerini gösteren bölümü oluşturur.
  Widget _buildBadgeSection(int totalScore) {
    final badges = [
      _BadgeDefinition(
        title: 'Bronz Rozet',
        points: _bronzeThreshold,
        color: const Color(0xFFCD7F32),
        icon: Icons.emoji_events_outlined,
      ),
      _BadgeDefinition(
        title: 'Gümüş Rozet',
        points: _silverThreshold,
        color: const Color(0xFFB0BEC5),
        icon: Icons.emoji_events_outlined,
      ),
      _BadgeDefinition(
        title: 'Altın Rozet',
        points: _maxScore,
        color: const Color(0xFFFFD54F),
        icon: Icons.emoji_events_outlined,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rozetler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(badges.length, (index) {
            final badge = badges[index];
            final isActive = totalScore >= badge.points;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == badges.length - 1 ? 0 : 12,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isActive ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: badge.color.withOpacity(isActive ? 0.9 : 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: badge.color.withOpacity(0.2),
                      child: Icon(
                        badge.icon,
                        color: badge.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      badge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPoints(badge.points)} puan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Seviye tablosunu oluşturur.
  Widget _buildLevelsTable(_ScoreLevelDefinition currentLevel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Değer Seviyeleri ve Puanları',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTableHeader(),
          const Divider(height: 1),
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
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              'Seviye',
              style: TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Sıra',
              style: TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Kavram',
              style: TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Puan',
              style: TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Tablo satırını üretir.
  Widget _buildTableRow(_ScoreLevelDefinition level, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFF1F5F9) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: level.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                level.tierText,
                style: TextStyle(
                  color: level.color.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              level.rank.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              level.concept,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatPoints(level.points),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
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
        const Text(
          'Değer Yolculuğu Rehberi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildInsightCard(
              title: 'Motto',
              description: _resolveMotto(currentLevel.concept),
              icon: Icons.favorite_outline,
            ),
            _buildInsightCard(
              title: 'Odak Değeri',
              description:
                  '${currentLevel.concept} seviyesinde, doğruluk ve şeffaflık önceliğiniz.',
              icon: Icons.track_changes_outlined,
            ),
            _buildInsightCard(
              title: 'Hedef Puan',
              description: nextLevel == null
                  ? 'Zirvedesiniz. Adalet Kişisi seviyesini koruyun.'
                  : '${_formatPoints(nextLevel.points)} puanda ${nextLevel.concept} olacaksınız.',
              icon: Icons.flag_outlined,
            ),
            _buildInsightCard(
              title: 'Toplam Katkı',
              description:
                  'Şu ana kadar ${_formatPoints(score.totalScore)} puan biriktirdiniz.',
              icon: Icons.auto_graph_outlined,
            ),
          ],
        ),
      ],
    );
  }

  /// Rehber kartlarını oluşturur.
  Widget _buildInsightCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Sayfanın alt aksiyon butonlarını oluşturur.
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleManageCategory,
            icon: const Icon(Icons.category_outlined),
            label: const Text('Kategori Yönet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mevcut seviye tanımını belirler.
  _ScoreLevelDefinition _resolveCurrentLevel(int totalScore) {
    for (final level in _scoreLevels) {
      if (totalScore >= level.points) {
        return level;
      }
    }
    return _scoreLevels.last;
  }

  /// Bir sonraki seviyeyi belirler.
  _ScoreLevelDefinition? _resolveNextLevel(_ScoreLevelDefinition currentLevel) {
    final currentIndex =
        _scoreLevels.indexWhere((level) => level.rank == currentLevel.rank);
    if (currentIndex <= 0) {
      return null;
    }
    return _scoreLevels[currentIndex - 1];
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
          'Vicdanının sesini dinleyen, küçük bir adalet işaretini bile büyüten bir kalbe sahipsin.',
      'Fikir Sahibi Kişisi':
          'Her soruya bir yaklaşımın var; fikirlerin topluluğun pusulası oluyor.',
      'Bakış Sahibi Kişisi':
          'Olaylara geniş pencereden bakar, değerli içgörüler üretirsin.',
      'Tutarlı Kişisi':
          'Kararlarında kararlılık ve denge, güvenin temelini oluşturur.',
      'Dengeli Kişisi':
          'Adımların ölçülü, yaklaşımın sağduyulu; ortamı dengeye taşırsın.',
      'Sabır Kişisi':
          'Zorlu süreçlerde sakin kalır, adaletin zamanla güçlendiğine inanırsın.',
      'Dürüst Kişisi':
          'Gerçeği doğru zamanda söylemek senin için bir değer pusulasıdır.',
      'Bilgelik Sahibi Kişisi':
          'Bilgiyi deneyimle yoğurur, daha derin bir anlam inşa edersin.',
      'İspat Ehli Kişisi':
          'Kanıt odaklı yaklaşımın, kararlarını sağlamlaştırır.',
      'Analitik / Rasyonel Kişisi':
          'Olayları çözümleyerek netlik ve düzen getirirsin.',
      'Empatik (Rahmet) Kişisi':
          'Başkasının kalbini duymak, kararlarına merhamet katar.',
      'Feraset Kişisi':
          'Öngörün, daha adil ve doğru kararlar almanı sağlar.',
      'Basiret Kişisi':
          'Derin kavrayışın, olayların özünü ortaya çıkarır.',
      'Şahitlik Kişisi':
          'Tanıklığın, hakikatin ve adaletin sağlam dayanağıdır.',
      'İrade Sahibi Kişisi':
          'İrade gücün, değer yolculuğunu istikrarlı kılar.',
      'İnanç Sahibi Kişisi':
          'İnancın, zor anlarda bile doğruyu savunmanı sağlar.',
      'Hakkaniyet Kişisi':
          'Hakkaniyete olan bağlılığın, dengeyi gözeten kararlar doğurur.',
      'Hikmet Kişisi':
          'Hikmetin, adaletin en olgun yorumunu temsil eder.',
      'Adalet Kişisi':
          'Adaletin en yüksek ifadesi sensin; dengeyi ve hakkı korursun.',
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
  /// Seviye etiketini ifade eder.
  final String tierLabel;

  /// Seviye rozeti için emoji.
  final String tierEmoji;

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
    required this.tierLabel,
    required this.tierEmoji,
    required this.rank,
    required this.concept,
    required this.points,
    required this.color,
  });

  /// Görselde kullanılacak rozet metnini üretir.
  String get tierText => '$tierEmoji $tierLabel';
}

/// Rozet seviyelerini temsil eder.
class _BadgeDefinition {
  /// Rozetin adı.
  final String title;

  /// Rozetin gerekli puanı.
  final int points;

  /// Rozetin rengi.
  final Color color;

  /// Rozet ikonu.
  final IconData icon;

  /// Varsayılan kurucu.
  const _BadgeDefinition({
    required this.title,
    required this.points,
    required this.color,
    required this.icon,
  });
}

