import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/hukum_sentiment.dart';
import '../services/dava_consensus_service.dart';
import '../services/hive_database_service.dart';
import '../providers/dava_provider.dart';
import 'hukum_consensus_badge.dart';
import 'halk_karari_tab_view.dart';
import 'hukum_sentiment_selector.dart';
import 'countdown_timer_widget.dart';
import 'ceza_yonetim_widget.dart';
import '../screens/masraf_selection_page.dart';

/// ✨ Modern 8 Hüküm Kartı Widget'ı
///
/// Özellikler:
/// - 🎨 Koyu başlık ve gradient gövde
/// - ⚖️ Rol bazlı kalıcı hüküm yazma alanı
/// - 👥 8 farklı rol kartı
/// - 💬 Hive veritabanı entegrasyonu
/// - 🎯 Material 3 uyumu
/// - 📱 Responsive ve animasyonlu yapı
class ModernHukumCard extends StatefulWidget {
  final String? userEmail;
  final String? davaId;
  final DateTime? openedAt;
  final String davaAdi;
  final String davaDavali;
  final String davaDavaci;
  final String davaGorev;
  final String kalanSure;
  final Function(String?)? onHukumSave;

  const ModernHukumCard({
    super.key,
    this.userEmail,
    this.davaId,
    this.openedAt,
    required this.davaAdi,
    required this.davaDavali,
    required this.davaDavaci,
    required this.davaGorev,
    required this.kalanSure,
    this.onHukumSave,
  });

  @override
  State<ModernHukumCard> createState() => _ModernHukumCardState();
}

class _ModernHukumCardState extends State<ModernHukumCard>
    with TickerProviderStateMixin {
  static const String _hukumPrefix =
      'whoboom sakinleri adına, gereği düşünüldü: ';

  bool isExpanded = true;
  final TextEditingController _hukumController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isApplyingPrefix = false;

  /// Ceza ve Masraf butonlarının gösterilip gösterilmeyeceği
  bool _showCezaMasrafButtons = false;
  /// Ceza işleminin tamamlanıp tamamlanmadığı
  bool _cezaCompleted = false;
  /// Masraf işleminin tamamlanıp tamamlanmadığı
  bool _masrafCompleted = false;
  /// Ceza ve Masraf butonları için animasyon controller
  AnimationController? _cezaMasrafAnimationController;
  Animation<double>? _cezaMasrafFadeAnimation;
  Animation<Offset>? _cezaMasrafSlideAnimation;

  /// Rol bazlı hüküm kayıtları; key rol adı, value hüküm metni.
  final Map<String, String> _rolHukumleri = <String, String>{};
  /// Rol bazlı hüküm yönleri; key rol adı, value olumlu/olumsuz bilgi.
  final Map<String, HukumSentiment> _rolSentimentleri =
      <String, HukumSentiment>{};
  /// Rol bazlı hüküm finalizasyon bilgisi; true ise düzenleme kilitlenir.
  final Map<String, bool> _rolFinalizasyonlari = <String, bool>{};
  /// Aktif olarak yazılan hükmün yönü.
  HukumSentiment? _selectedSentiment;
  bool _isCurrentRoleFinalized = false;

  /// Çoğunluk kararına ilişkin değerlendirme.
  DavaConsensusEvaluation? _consensusEvaluation;
  bool _isConsensusLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _cezaMasrafAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _cezaMasrafFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cezaMasrafAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    _cezaMasrafSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cezaMasrafAnimationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();

    _hukumController.addListener(() {
      if (_isCurrentRoleFinalized) {
        return;
      }
      _enforcePrefixOnController();
      setState(() {});
    });

    _applyDefaultPrefix();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingHukumler();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cezaMasrafAnimationController?.dispose();
    _hukumController.dispose();
    super.dispose();
  }

  /// Hive üzerinde kayıtlı hüküm verilerini yükler.
  Future<void> _loadExistingHukumler() async {
    final String davaId = widget.davaId ?? 'dava_${widget.davaAdi.hashCode}';
    try {
      final Map<String, Map<String, dynamic>> existing =
          await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId);

      if (!mounted) return;

      setState(() {
        _rolHukumleri
          ..clear()
          ..addEntries(existing.entries.where((entry) {
            final dynamic text = entry.value['hukumText'];
            return (text is String) && text.trim().isNotEmpty;
          }).map(
            (entry) {
              // Veritabanından gelen rol adını normalize et
              final String normalizedKey = _normalizeRole(entry.key);
              return MapEntry(
                normalizedKey,
                entry.value['hukumText'].toString(),
              );
            },
          ));

        _rolSentimentleri.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry
            in existing.entries) {
          final String? sentimentValue = entry.value['hukumSentiment'] as String?;
          final HukumSentiment? sentiment =
              hukumSentimentFromStorage(sentimentValue);
          
          if (sentiment != null) {
            // Veritabanından gelen rol adı zaten normalize edilmiş olmalı
            // Ama yine de normalize edelim ki tutarlı olsun
            final String normalizedKey = _normalizeRole(entry.key);
            _rolSentimentleri[normalizedKey] = sentiment;
          }
        }

        _rolFinalizasyonlari
          ..clear()
          ..addEntries(existing.entries.map(
            (entry) {
              // Veritabanından gelen rol adını normalize et
              final String normalizedKey = _normalizeRole(entry.key);
              return MapEntry(
                normalizedKey,
                (entry.value['isFinalized'] as bool?) ?? false,
              );
            },
          ));

        final String normalizedRole = _normalizeRole(widget.davaGorev);
        final String persistedText = _rolHukumleri[normalizedRole] ?? '';
        if (persistedText.isNotEmpty) {
          _hukumController.text =
              _ensurePrefix(persistedText, allowFallbackPrefix: true);
        } else {
          _applyDefaultPrefix();
        }
        _selectedSentiment = _rolSentimentleri[normalizedRole];
        _isCurrentRoleFinalized =
            _rolFinalizasyonlari[normalizedRole] ?? false;
        if (_isCurrentRoleFinalized) {
          _hukumController.value = _hukumController.value.copyWith(
            selection: TextSelection.collapsed(
              offset: _hukumController.text.length,
            ),
          );
        }
      });
    } catch (_) {
      // Hive erişiminde hata oluşursa UI tarafında sessizce devam edilir.
    }

    await _refreshConsensus();
  }

  String _normalizeRole(String rolAdi) {
    final String trimmed = rolAdi.trim();
    if (trimmed.isEmpty) {
      return 'Görev Kararı';
    }
    return trimmed.endsWith('Kararı') ? trimmed : '$trimmed Kararı';
  }

  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  void _applyDefaultPrefix() {
    _isApplyingPrefix = true;
    _hukumController.text = _hukumPrefix;
    _hukumController.selection = TextSelection.collapsed(
      offset: _hukumController.text.length,
    );
    _isApplyingPrefix = false;
  }

  void _enforcePrefixOnController() {
    if (_isApplyingPrefix) return;

    final TextEditingValue currentValue = _hukumController.value;
    final String currentText = currentValue.text;
    if (currentText.isEmpty) {
      _applyDefaultPrefix();
      return;
    }

    if (!currentText.startsWith(_hukumPrefix)) {
      final int baseOffset = currentValue.selection.baseOffset;
      final String newText =
          _ensurePrefix(currentText, allowFallbackPrefix: false);
      final int desiredOffset = baseOffset < _hukumPrefix.length
          ? _hukumPrefix.length
          : baseOffset;
      final int clampedOffset = desiredOffset > newText.length
          ? newText.length
          : desiredOffset;
      _isApplyingPrefix = true;
      _hukumController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: clampedOffset,
        ),
      );
      _isApplyingPrefix = false;
    }
  }

  String _ensurePrefix(
    String text, {
    required bool allowFallbackPrefix,
  }) {
    if (text.startsWith(_hukumPrefix)) {
      return text;
    }

    final String body = text.replaceFirst(_hukumPrefix.trim(), '').trimLeft();
    if (body.isEmpty && allowFallbackPrefix) {
      return _hukumPrefix;
    }

    return '$_hukumPrefix$body';
  }

  String _extractHukumBody(String text) {
    if (text.startsWith(_hukumPrefix)) {
      return text.substring(_hukumPrefix.length);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Colors.white,
              Colors.green.shade50,
              Colors.blue.shade50,
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.green.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildGradientHeader(),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildDavaInfo(),
                        const SizedBox(height: 16),
        _buildHukumInput(),
                        const SizedBox(height: 16),
                        _buildRoleCardsSection(),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Koyu gradient başlık bölümünü oluşturur.
  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.greenAccent.shade700,
            Colors.blueGrey.shade700,
          ],
        ),
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.28),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    MdiIcons.accountDetails,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '8 HÜKÜM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.sentiment_very_satisfied_sharp,
            size: 36,
            color: Colors.black,
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() => isExpanded = !isExpanded);
            },
            icon: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.18),
            ),
          ),
        ],
      ),
    );
  }

  /// Dava bilgilerini gösteren kutuyu oluşturur.
  Widget _buildDavaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.green.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildInfoRow(
            'Dava Adı',
            widget.davaAdi,
            MdiIcons.gavel,
            color: Colors.orangeAccent,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Davacı',
            widget.davaDavaci,
            MdiIcons.account,
            color: Colors.green,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Davalı',
            widget.davaDavali,
            MdiIcons.accountOutline,
            color: Colors.redAccent,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Görev',
            widget.davaGorev,
            MdiIcons.briefcaseOutline,
            color: Colors.blue,
          ),
          const Divider(height: 24),
          _buildCountdownSection(),
        ],
      ),
    );
  }

  /// Bilgi satırı oluşturan yardımcı widget.
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSection() {
    final DateTime? openedAt = widget.openedAt;
    final String openedAtText = openedAt != null
        ? _formatDateTime(openedAt)
        : 'Açılış tarihi bulunamadı';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              MdiIcons.timerAlertOutline,
              size: 20,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Dava Açılış Tarihi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    openedAtText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),

                  if (openedAt == null && widget.kalanSure.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      widget.kalanSure,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (openedAt != null)
              CountdownTimerWidget(
                startTime: openedAt,
                totalDuration: const Duration(hours: 168),
                showHourglass: true,
              ),
          ],
        ),
      ],
    );
  }

  /// Genişletilmiş hüküm yazma alanını ve aksiyon butonlarını oluşturur.
  Widget _buildHukumInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Colors.green.shade50,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: TextField(
            controller: _hukumController,
            maxLines: 12,
            minLines: 12,
            enabled: !_isCurrentRoleFinalized,
            readOnly: _isCurrentRoleFinalized,
            decoration: InputDecoration(
              hintText: 'Hükmünü buraya yaz...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),

            ),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        HukumSentimentSelector(
          selectedSentiment: _selectedSentiment,
          isDisabled: _isCurrentRoleFinalized,
          onSentimentSelected: (HukumSentiment sentiment) {
            setState(() {
              _selectedSentiment = sentiment;
            });
          },
        ),
        const SizedBox(height: 12),
        HukumConsensusBadge(
          evaluation: _consensusEvaluation,
          isLoading: _isConsensusLoading,
          onRefresh: _canEvaluateConsensus ? _refreshConsensus : null,
        ),
        const SizedBox(height: 12),
        HalkKarariTabView(
          davaId: widget.davaId,
          acceptedAt: widget.openedAt,
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isHukumKaydetEnabled
                    ? () async {
                        await _saveHukumForRole(widget.davaGorev);
                      }
                    : null,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isHukumKaydetEnabled && !_showCezaMasrafButtons
                    ? () {
                        // İlk tıklamada Ceza ve Masraf butonlarını göster
                        setState(() {
                          _showCezaMasrafButtons = true;
                        });
                        _cezaMasrafAnimationController?.forward();
                      }
                    : null,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Hüküm Verildi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Ceza ve Masraf butonları
        if (_showCezaMasrafButtons && 
            _cezaMasrafFadeAnimation != null && 
            _cezaMasrafSlideAnimation != null) ...[
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _cezaMasrafFadeAnimation!,
            child: SlideTransition(
              position: _cezaMasrafSlideAnimation!,
              child: _buildCezaMasrafButtons(),
            ),
          ),
        ],
      ],
    );
  }

  /// Ceza Ver ve Masrafla butonlarını oluşturur
  Widget _buildCezaMasrafButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.orange.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                MdiIcons.gavel,
                size: 20,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Ceza ve Masraf İşlemleri',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildActionButton(
                  label: 'Ceza Ver',
                  icon: MdiIcons.handcuffs,
                  isCompleted: _cezaCompleted,
                  onTap: () {
                    _showCezaYonetimDialog();
                  },
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Masrafla',
                  icon: MdiIcons.giftOpenOutline,
                  isCompleted: _masrafCompleted,
                  onTap: () async {
                    // Masraf seçim sayfasına yönlendir
                    final bool? masraflandi = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (BuildContext context) => MasrafSelectionPage(
                          userEmail: widget.userEmail,
                          davaId: widget.davaId,
                          davaAdi: widget.davaAdi,
                        ),
                      ),
                    );
                    // Masraf seçiminden başarıyla dönüldüyse
                    if (masraflandi == true && mounted) {
                      setState(() {
                        _masrafCompleted = true;
                      });
                      _checkAndCompleteHukum();
                    }
                  },
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tekil aksiyon butonunu oluşturur (Ceza Ver veya Masrafla)
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onTap,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              isCompleted ? color.shade400 : color.shade100,
              isCompleted ? color.shade600 : color.shade200,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? color.shade700 : color.shade300,
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withOpacity(isCompleted ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 22,
                  color: isCompleted ? Colors.white : color.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.white : color.shade700,
                  ),
                ),
              ],
            ),
            // Sağ üstte yeşil onay ikonu
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                width: isCompleted ? 28 : 0,
                height: isCompleted ? 28 : 0,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Her iki işlem de tamamlandıysa hüküm verildi işlemini kontrol eder
  void _checkAndCompleteHukum() {
    if (_cezaCompleted && _masrafCompleted) {
      // Her iki işlem de tamamlandı, hüküm verildi işlemini yap
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted) {
          await _saveHukumForRole(
            widget.davaGorev,
            isVerdi: true,
          );
        }
      });
    }
  }

  /// Ceza yönetim dialog'unu gösterir
  void _showCezaYonetimDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return CezaYonetimWidget(
          davaId: widget.davaId,
          davaAdi: widget.davaAdi,
          davaDavali: widget.davaDavali,
          davaDavaci: widget.davaDavaci,
          userEmail: widget.userEmail,
        );
      },
    ).then((_) {
      // Dialog kapandığında ceza işleminin tamamlandığını işaretle
      setState(() {
        _cezaCompleted = true;
      });
      _checkAndCompleteHukum();
    });
  }

  /// Hükmü ilgili rol adına kaydeder ve Hive'a yazar.
  Future<void> _saveHukumForRole(
    String rolAdi, {
    bool isVerdi = false,
  }) async {
    final String hukumText = _hukumController.text;
    final String hukumBody = _extractHukumBody(hukumText).trim();
    final HukumSentiment? sentiment = _selectedSentiment;
    if (hukumBody.isEmpty) {
      _showSnackBar(
        'Lütfen sabit ifadeden sonra hükmünüzü yazın.',
        Colors.orange.shade800,
      );
      return;
    }
    if (sentiment == null) {
      _showSnackBar(
        'Lütfen hükmünüzün olumlu mu olumsuz mu olduğunu belirtmek için emojilerden birini seçin.',
        Colors.orange.shade800,
      );
      return;
    }

    final String normalizedRolAdi = _normalizeRole(rolAdi);
    if (_rolFinalizasyonlari[normalizedRolAdi] == true) {
      _showSnackBar(
        'Bu rol için hüküm nihai hale getirildi; düzenleme yapılamaz.',
        Colors.orange.shade800,
      );
      return;
    }

    final String davaId = widget.davaId ?? 'dava_${widget.davaAdi.hashCode}';
    final bool nextFinalizationState = isVerdi;
    final String fullText = '$_hukumPrefix$hukumBody';
    
    print('🔍 [ModernHukumCard] _saveHukumForRole çağrıldı:');
    print('   - widget.davaId: ${widget.davaId}');
    print('   - widget.davaAdi: ${widget.davaAdi}');
    print('   - Hesaplanan davaId: $davaId');
    print('   - normalizedRolAdi: $normalizedRolAdi');
    print('   - hukumText uzunluğu: ${fullText.length}');
    print('   - sentiment: ${sentiment.storageValue}');

    setState(() {
      _rolHukumleri[normalizedRolAdi] = fullText;
      _rolSentimentleri[normalizedRolAdi] = sentiment;
      _rolFinalizasyonlari[normalizedRolAdi] = nextFinalizationState;
      _isCurrentRoleFinalized = nextFinalizationState;
      _selectedSentiment = sentiment;
      // Hüküm verildiğinde ceza ve masraf butonlarını gizle
      if (isVerdi) {
        _showCezaMasrafButtons = false;
        _cezaCompleted = false;
        _masrafCompleted = false;
        _cezaMasrafAnimationController?.reset();
      }
      if (!_isCurrentRoleFinalized) {
        _hukumController.text = fullText;
        _hukumController.selection = TextSelection.collapsed(
          offset: _hukumController.text.length,
        );
      }
    });

    try {
      if ((widget.userEmail ?? '').isNotEmpty) {
        // Provider üzerinden kaydet (senkronizasyon için)
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        await davaProvider.updateHukumForDava(
          davaId: davaId,
          userRole: normalizedRolAdi,
          hukumText: fullText,
          userEmail: widget.userEmail!,
          hukumSentiment: sentiment.storageValue,
          isFinalized: nextFinalizationState,
        );
        
        print('✅ [ModernHukumCard] Hüküm Provider üzerinden kaydedildi:');
        print('   - Dava ID: $davaId');
        print('   - Rol: $normalizedRolAdi');
        print('   - Sentiment: ${sentiment.storageValue}');
        print('   - Provider versiyonu: ${davaProvider.hukumUpdateVersion}');
      }

      final String successMessage = isVerdi
          ? '$rolAdi için hüküm verildi'
          : '$rolAdi için hüküm kaydedildi';

      _showSnackBar(
        '✅ Veritabanına kaydediliyor...\n'
        '✅ Kalıcı olarak saklanıyor...\n'
        '✅ Uygulama yeniden başlatıldığında korunuyor...\n'
        '$successMessage',
        isVerdi ? Colors.green.shade700 : Colors.blue.shade700,
      );

      widget.onHukumSave?.call(fullText);

      // Hüküm kaydedildikten sonra mevcut hükümleri yeniden yükle
      // Bu, sentiment'lerin doğru gösterilmesini sağlar
      await _loadExistingHukumler();
      
      await _refreshConsensus();
    } catch (error) {
      _showSnackBar(
        '❌ Hüküm kaydedilirken hata oluştu: $error',
        Colors.red.shade700,
      );
    }
  }

  bool get _isHukumKaydetEnabled =>
      !_isCurrentRoleFinalized &&
      _extractHukumBody(_hukumController.text).trim().isNotEmpty &&
      _selectedSentiment != null;

  bool get _canEvaluateConsensus =>
      (widget.davaId != null && widget.davaId!.isNotEmpty);

  Future<void> _refreshConsensus() async {
    if (!_canEvaluateConsensus) {
      setState(() {
        _consensusEvaluation = null;
        _isConsensusLoading = false;
      });
      return;
    }

    setState(() {
      _isConsensusLoading = true;
    });

    final DavaConsensusEvaluation evaluation =
        await DavaConsensusService.evaluateConsensus(
      davaId: widget.davaId!,
      openedAt: widget.openedAt,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _consensusEvaluation = evaluation;
      _isConsensusLoading = false;
    });
  }

  /// Rol kartları listesini oluşturur.
  Widget _buildRoleCardsSection() {
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: roles.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildRoleCard(
            roles[index]['title'] as String,
            roles[index]['icon'] as IconData,
          );
        },
      ),
    );
  }

  /// Tekil rol kartını oluşturur.
  Widget _buildRoleCard(String title, IconData icon) {
    // Rol adını normalize et (kayıt sırasında normalize edildiği için)
    final String normalizedTitle = _normalizeRole(title);
    final bool hasHukum =
        (_rolHukumleri[normalizedTitle]?.trim().isNotEmpty ?? false);

    final List<Widget> trailingWidgets =
        _buildRoleTrailingWidgets(title, hasHukum, normalizedTitle);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasHukum ? Colors.green.shade400 : Colors.blue.shade200,
          width: hasHukum ? 2 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasHukum ? Colors.green.shade700 : Colors.blue.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
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

  /// Rol satırının sağ tarafındaki ikon alanını oluşturur.
  List<Widget> _buildRoleTrailingWidgets(String title, bool hasHukum, String normalizedTitle) {
    // Rol adını normalize et (kayıt sırasında normalize edildiği için)
    final HukumSentiment? sentiment = _rolSentimentleri[normalizedTitle];

    // Eğer sentiment seçilmişse, sentiment ikonunu göster
    if (sentiment != null) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: sentiment.color.withOpacity(0.14),
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

    // Sentiment seçilmemişse, tüm roller için varsayılan ikonları göster
    // (Davacı Avukatı Kararı dahil tüm roller aynı mantıkta çalışır)
    return <Widget>[
      Icon(
        MdiIcons.emoticonHappyOutline,
        size: 24,
        color: Colors.orange,
      ),
      const SizedBox(width: 4),
      Icon(
        MdiIcons.emoticonCryOutline,
        size: 24,
        color: Colors.blue,
      ),
      const SizedBox(width: 4),
      _buildRoleDialogButton(normalizedTitle, hasHukum),
    ];
  }

  /// Rol kartında hükmü görüntüleyen aksiyon ikonunu üretir.
  Widget _buildRoleDialogButton(String normalizedTitle, bool hasHukum) {
    return GestureDetector(
      onTap: hasHukum ? () => _showHukumDialog(normalizedTitle) : null,
      child: Icon(
        MdiIcons.fileCheckOutline,
        size: 30,
        color: hasHukum ? Colors.green.shade700 : Colors.brown,
      ),
    );
  }

  /// Kaydedilmiş hükmü görüntüleyen dialogu açar.
  void _showHukumDialog(String rolAdi) {
    final String? hukumText = _rolHukumleri[rolAdi];
    if (hukumText == null || hukumText.trim().isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final double screenHeight = MediaQuery.of(context).size.height;
        final double maxHeight = screenHeight * 0.8;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.green.shade50,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Icon(
                              MdiIcons.fileCheck,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rolAdi,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        hukumText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kapat'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// SnackBar üzerinden bilgi ve hata mesajlarını gösterir.
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}

