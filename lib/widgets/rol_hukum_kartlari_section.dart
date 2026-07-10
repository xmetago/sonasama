import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../models/hukum_sentiment.dart';
import '../services/dava_consensus_service.dart';
import '../services/hive_database_service.dart';
import '../services/user_privacy_service.dart';
import 'halk_karari_tab_view.dart';
import 'hukum_consensus_badge.dart';

/// Kullanıcının bir hükme verebileceği tepki türleri (rol kartı diyaloğu).
enum HukumReaction { liked, disliked }

/// Rol adını kanonik hüküm anahtarına çevirir ([ModernHukumCard] ile aynı mantık).
String normalizeRolKarari(String rolAdi) {
  final String trimmed = rolAdi.trim();
  if (trimmed.isEmpty) {
    return 'Görev Kararı';
  }
  final String compact = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('Ş', 's')
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('Ğ', 'g')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'u');
  final String compactNormalized =
      compact.replaceAll(RegExp(r'[^a-z0-9]'), '');

  if (compact == '1.juri' ||
      compact == '1.jurikarari' ||
      compact == '1.jürikararı' ||
      compact == '1.jürikarari' ||
      compactNormalized == '1juri' ||
      compactNormalized == '1jurikarari' ||
      compactNormalized == '1juriuyesi') {
    return '1. Jüri Kararı';
  }

  if (compact == '2.juri' ||
      compact == '2.jurikarari' ||
      compact == '2.jürikararı' ||
      compact == '2.jürikarari' ||
      compactNormalized == '2juri' ||
      compactNormalized == '2jurikarari' ||
      compactNormalized == '2juriuyesi') {
    return '2. Jüri Kararı';
  }

  if (compact == 'davaciavukati' ||
      compact == 'davaciavukatikarari' ||
      compactNormalized == 'davaciavukati' ||
      compactNormalized == 'davacivekili') {
    return 'Davacı Avukatı Kararı';
  }

  if (compact == 'davaliavukati' ||
      compact == 'davaliavukatikarari' ||
      compactNormalized == 'davaliavukati' ||
      compactNormalized == 'davalivekili') {
    return 'Davalı Avukatı Kararı';
  }

  if (compact == 'davacisahidi' ||
      compact == 'davacisahidikarari' ||
      compactNormalized == 'davacitanigi' ||
      compactNormalized == 'davacisahidi') {
    return 'Davacı Şahidi Kararı';
  }

  if (compact == 'davalisahidi' ||
      compact == 'davalisahidikarari' ||
      compactNormalized == 'davalitanigi' ||
      compactNormalized == 'davalisahidi') {
    return 'Davalı Şahidi Kararı';
  }

  if (compact == 'yargic' ||
      compact == 'yargickarari' ||
      compact == 'yargıçkararı' ||
      compactNormalized == 'hakim' ||
      compactNormalized == 'hakimkarari') {
    return 'Yargıç Kararı';
  }

  if (compact == 'temyizhakimi' ||
      compact == 'temyizhakimikarari' ||
      compactNormalized == 'istinafhakimi' ||
      compactNormalized == 'temyizhakimi') {
    return 'Temyiz Hakimi Kararı';
  }

  return trimmed.endsWith('Kararı') ? trimmed : '$trimmed Kararı';
}

String _roleKarariToMevkii(String rolKarari) {
  final String t = rolKarari.trim();
  if (t.endsWith(' Kararı')) {
    return t.substring(0, t.length - 7).trim();
  }
  return t;
}

bool _mevkiiMatchesRoleKarari(String mevkiiRaw, String normalizedRolKarari) {
  final String a = _roleKarariToMevkii(mevkiiRaw).toLowerCase();
  final String b = _roleKarariToMevkii(normalizedRolKarari).toLowerCase();
  if (a == b) {
    return true;
  }
  final String collapsedA = a.replaceAll(RegExp(r'\s+'), '');
  final String collapsedB = b.replaceAll(RegExp(r'\s+'), '');
  return collapsedA == collapsedB;
}

Map<String, dynamic>? _findParticipantForRoleKarari(
  List<Map<String, dynamic>> participants,
  String normalizedRolKarari,
) {
  for (final Map<String, dynamic> participant in participants) {
    final String mevkii =
        (participant['mevkii'] ?? participant['userRole'] ?? '')
            .toString()
            .trim();
    if (mevkii.isEmpty) {
      continue;
    }
    if (_mevkiiMatchesRoleKarari(mevkii, normalizedRolKarari)) {
      return participant;
    }
  }
  return null;
}

/// 8 rol satırı + çoğunluk rozeti + halk kararı sekmesi.
///
/// [ModernHukumCard] içindeki rol kartları bölümünün taşınmış halidir.
class RolHukumKartlariSection extends StatefulWidget {
  const RolHukumKartlariSection({
    super.key,
    required this.davaId,
    this.openedAt,
    this.userEmail,
    required this.kullaniciGorev,
    required this.rolHukumleri,
    required this.rolSentimentleri,
    required this.rolCezalari,
    required this.rolMasraflari,
    this.seciliSentiment,
    required this.consensusEvaluation,
    required this.consensusLoading,
    this.onConsensusRefresh,
  });

  final String? davaId;
  final DateTime? openedAt;
  final String? userEmail;
  /// Aktif kullanıcı görevi ([ModernHukumCard.davaGorev] / dava.mevkii).
  final String kullaniciGorev;
  final Map<String, String> rolHukumleri;
  final Map<String, HukumSentiment> rolSentimentleri;
  final Map<String, String> rolCezalari;
  final Map<String, String> rolMasraflari;
  final HukumSentiment? seciliSentiment;
  final DavaConsensusEvaluation? consensusEvaluation;
  final bool consensusLoading;
  final VoidCallback? onConsensusRefresh;

  @override
  State<RolHukumKartlariSection> createState() => _RolHukumKartlariSectionState();
}

class _RolHukumKartlariSectionState extends State<RolHukumKartlariSection> {
  final Map<String, HukumReaction> _rolTepkileri = <String, HukumReaction>{};

  T? _mapValueForNormalizedRoleKey<T>(Map<String, T> map, String rolAdi) {
    final String n = normalizeRolKarari(rolAdi);
    if (map.containsKey(n)) {
      return map[n];
    }
    for (final MapEntry<String, T> e in map.entries) {
      if (normalizeRolKarari(e.key) == n) {
        return e.value;
      }
    }
    return null;
  }

  String? _hukumTextForRole(String rolAdi) {
    final String? t =
        _mapValueForNormalizedRoleKey<String>(widget.rolHukumleri, rolAdi);
    if (t != null && t.trim().isNotEmpty) {
      return t;
    }
    return null;
  }

  void _showNoHukumSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu rolde goruntulenecek kayitli bir hukum yok.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRoleUserNotFoundSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu rol icin kullanici bulunamadi.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onRoleIconTap(String normalizedTitle) async {
    final String? davaId = widget.davaId?.trim();
    if (davaId == null || davaId.isEmpty) {
      _showRoleUserNotFoundSnackBar();
      return;
    }

    final List<Map<String, dynamic>> participants =
        await HiveDatabaseService.getDavaParticipants(davaId);
    if (!mounted) {
      return;
    }

    final Map<String, dynamic>? participant =
        _findParticipantForRoleKarari(participants, normalizedTitle);
    if (participant == null) {
      _showRoleUserNotFoundSnackBar();
      return;
    }

    final String? targetEmail = participant['userEmail']?.toString().trim();
    if (targetEmail == null || targetEmail.isEmpty) {
      _showRoleUserNotFoundSnackBar();
      return;
    }

    final bool canView = await UserPrivacyService.canViewSeyirDefteri(
      targetUserEmail: targetEmail,
      viewerUserEmail: widget.userEmail,
      sharedDavaId: davaId,
    );
    if (!mounted) {
      return;
    }

    if (canView) {
      UserPrivacyService.navigateToSeyirDefteri(
        context,
        targetUserEmail: targetEmail,
      );
    } else {
      UserPrivacyService.showPrivacyWarning(context);
    }
  }

  Widget _buildRoleCard(String title, IconData icon) {
    final String normalizedTitle = normalizeRolKarari(title);
    final bool hasHukum = _hukumTextForRole(normalizedTitle) != null;

    final List<Widget> trailingWidgets =
        _buildRoleTrailingWidgets(hasHukum, normalizedTitle);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasHukum ? const Color(0xFFF1F8F3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasHukum ? Colors.green.shade300 : const Color(0xFFDCE7E1),
          width: hasHukum ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onRoleIconTap(normalizedTitle),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      hasHukum ? Colors.green.shade700 : Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    hasHukum ? Colors.green.shade700 : Colors.grey.shade900,
              ),
            ),
          ),
          ...trailingWidgets,
        ],
      ),
    );
  }

  List<Widget> _buildRoleTrailingWidgets(bool hasHukum, String normalizedTitle) {
    final HukumSentiment? persistedSentiment =
        _mapValueForNormalizedRoleKey(widget.rolSentimentleri, normalizedTitle);
    final String currentRole = normalizeRolKarari(widget.kullaniciGorev);
    final bool isCurrentRole = normalizedTitle == currentRole;
    final HukumSentiment? sentiment =
        isCurrentRole ? widget.seciliSentiment : persistedSentiment;

    if (sentiment != null) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: sentiment.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sentiment.color, width: 1.5),
          ),
          child: Icon(
            sentiment.icon,
            size: 24,
            color: sentiment.color,
          ),
        ),
        const SizedBox(width: 8),
        _buildRoleDialogButton(normalizedTitle, hasHukum),
      ];
    }

    return <Widget>[
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade500, width: 1.2),
        ),
        child: Icon(
          MdiIcons.emoticonNeutralOutline,
          size: 24,
          color: Colors.grey.shade700,
        ),
      ),
      const SizedBox(width: 8),
      _buildRoleDialogButton(normalizedTitle, hasHukum),
    ];
  }

  Widget _buildRoleDialogButton(String normalizedTitle, bool hasHukum) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!hasHukum) {
            _showNoHukumSnackBar();
            return;
          }
          _showHukumDialog(normalizedTitle);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            MdiIcons.fileCheckOutline,
            size: 30,
            color: hasHukum ? Colors.green.shade700 : Colors.brown,
          ),
        ),
      ),
    );
  }

  void _showHukumDialog(String rolAdi) {
    final String canonical = normalizeRolKarari(rolAdi);
    final String? hukumText = _hukumTextForRole(canonical);
    if (hukumText == null || hukumText.trim().isEmpty) {
      _showNoHukumSnackBar();
      return;
    }

    final HukumSentiment? sentiment =
        _mapValueForNormalizedRoleKey(widget.rolSentimentleri, canonical);
    final String cezaText =
        _mapValueForNormalizedRoleKey(widget.rolCezalari, canonical) ?? '';
    final String masrafText =
        _mapValueForNormalizedRoleKey(widget.rolMasraflari, canonical) ?? '';

    final IconData sentimentIcon = sentiment == HukumSentiment.positive
        ? MdiIcons.emoticonHappyOutline
        : sentiment == HukumSentiment.negative
            ? MdiIcons.emoticonCryOutline
            : MdiIcons.emoticonNeutralOutline;

    final Color sentimentColor = sentiment?.color ?? Colors.grey.shade600;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Hüküm Detayı',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (BuildContext dialogCtx, _, __) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setDialogState) {
            final HukumReaction? currentReaction = _rolTepkileri[canonical];
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.white,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Container(
                          padding:
                              const EdgeInsets.fromLTRB(24, 32, 24, 20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: sentimentColor.withValues(alpha: 0.05),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: sentimentColor.withValues(
                                        alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  sentimentIcon,
                                  size: 34,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      canonical.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1A1A1A),
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: <Widget>[
                                        const SizedBox(width: 4),
                                        Text(
                                          _getSentimentText(sentiment),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: sentimentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Semantics(
                                button: true,
                                label: 'Kapat',
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.grey.shade700,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          children: <Widget>[
                            _buildModernHukumCard(
                              title: 'RESMİ HÜKÜM',
                              value: hukumText,
                              icon: MdiIcons.textBoxCheckOutline,
                              accentColor: Colors.blue.shade700,
                            ),
                            if (cezaText.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 16),
                              _buildModernHukumCard(
                                title: 'CEZAİ YAPTIRIM',
                                value: cezaText,
                                icon: MdiIcons.gavel,
                                accentColor: Colors.red.shade700,
                              ),
                            ],
                            if (masrafText.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 16),
                              _buildModernHukumCard(
                                title: 'YARGILAMA GİDERİ',
                                value: masrafText,
                                icon: MdiIcons.currencyTry,
                                accentColor: Colors.amber.shade800,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _buildReactionButton(
                              icon: Icons.thumb_up_alt_rounded,
                              label: 'Beğen',
                              color: Colors.green.shade700,
                              selected:
                                  currentReaction == HukumReaction.liked,
                              onTap: () {
                                _handleReaction(
                                    canonical, HukumReaction.liked);
                                setDialogState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildReactionButton(
                              icon: Icons.thumb_down_alt_rounded,
                              label: 'Kınama',
                              color: Colors.red.shade700,
                              selected: currentReaction ==
                                  HukumReaction.disliked,
                              onTap: () {
                                _handleReaction(
                                    canonical, HukumReaction.disliked);
                                setDialogState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (
        BuildContext _,
        Animation<double> animation,
        Animation<double> __,
        Widget child,
      ) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildModernHukumCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D2D2D),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.3),
                width: selected ? 1.5 : 1,
              ),
              color: selected
                  ? color.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
                if (selected) ...<Widget>[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSentimentText(HukumSentiment? sentiment) {
    switch (sentiment) {
      case HukumSentiment.positive:
        return 'Olumlu';
      case HukumSentiment.negative:
        return 'Olumsuz';
      default:
        return 'Nötr';
    }
  }

  void _handleReaction(String rolAdi, HukumReaction reaction) {
    HapticFeedback.lightImpact();
    final HukumReaction? previous = _rolTepkileri[rolAdi];
    setState(() {
      if (previous == reaction) {
        _rolTepkileri.remove(rolAdi);
      } else {
        _rolTepkileri[rolAdi] = reaction;
      }
    });

    if (!mounted) return;
    final HukumReaction? current = _rolTepkileri[rolAdi];
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final String message;
    final Color bgColor;
    final IconData icon;
    if (current == null) {
      message = '$rolAdi rolüne verilen tepki kaldırıldı.';
      bgColor = Colors.grey.shade700;
      icon = Icons.undo_rounded;
    } else if (current == HukumReaction.liked) {
      message = '$rolAdi rolünü beğendiniz. Teşekkürler!';
      bgColor = Colors.green.shade700;
      icon = Icons.thumb_up;
    } else {
      message = '$rolAdi rolünü kınadınız. Geri bildiriminiz kaydedildi.';
      bgColor = Colors.red.shade700;
      icon = Icons.thumb_down;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: bgColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> roles = <Map<String, dynamic>>[
      {'title': 'Temyiz Hakimi Kararı', 'icon': MdiIcons.scaleBalance},
      {'title': 'Yargıç Kararı', 'icon': MdiIcons.gavel},
      {'title': '1. Jüri Kararı', 'icon': MdiIcons.accountGroup},
      {'title': '2. Jüri Kararı', 'icon': MdiIcons.accountMultiple},
      {'title': 'Davacı Avukatı Kararı', 'icon': MdiIcons.accountTie},
      {'title': 'Davalı Avukatı Kararı', 'icon': MdiIcons.accountTieOutline},
      {'title': 'Davacı Şahidi Kararı', 'icon': MdiIcons.account},
      {'title': 'Davalı Şahidi Kararı', 'icon': MdiIcons.accountOutline},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: roles.length + 2,
        itemBuilder: (BuildContext context, int index) {
          if (index < roles.length) {
            return _buildRoleCard(
              roles[index]['title'] as String,
              roles[index]['icon'] as IconData,
            );
          }
          if (index == roles.length) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: HukumConsensusBadge(
                evaluation: widget.consensusEvaluation,
                isLoading: widget.consensusLoading,
                onRefresh: widget.onConsensusRefresh,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: HalkKarariTabView(
              davaId: widget.davaId,
              acceptedAt: widget.openedAt,
              userEmail: widget.userEmail,
            ),
          );
        },
      ),
    );
  }
}
