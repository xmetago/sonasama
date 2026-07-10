import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/hukum_sentiment.dart';
import '../services/dava_consensus_service.dart';
import '../services/dava_hukum_eligibility_service.dart';
import '../services/hive_database_service.dart';
import '../providers/dava_provider.dart';
import 'hukum_sentiment_selector.dart';
import 'countdown_timer_widget.dart';
import 'ceza_yonetim_widget.dart';
import '../screens/hukum_gift_selection_page.dart';
import 'rol_hukum_kartlari_section.dart';

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

  /// Sabit ifadeden sonraki hüküm metni (gereği düşünüldü alanı).
  static const int _hukumBodyMinChars = 285;
  static const int _hukumBodyMaxChars = 988;

  final TextEditingController _hukumController = TextEditingController();
  final FocusNode _hukumFocusNode = FocusNode();
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
  /// Rol bazlı ceza kayıtları; key rol adı, value ceza metni.
  final Map<String, String> _rolCezalari = <String, String>{};
  /// Rol bazlı masraf kayıtları; key rol adı, value masraf/hediye satırı.
  final Map<String, String> _rolMasraflari = <String, String>{};
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

  /// Temyiz penceresi / yargıç sırası gibi kurallardan dolayı düzenleme kilitli mi?
  bool _roleEditLocked = false;
  String? _lockReason;
  bool _kunyeExpanded = true;

  /// Son Kaydet ile eşleşen taslak; aynıysa Kaydet gri, Hüküm Verildi duygu renginde kalır.
  String _kaydetBaselineTrimmedBody = '';
  HukumSentiment? _kaydetBaselineSentiment;

  /// Ceza yönetiminde resmi mühür ile kayıt (Hive) var mı; bu kullanıcı bu davada tekrar ceza veremez.
  bool _cezaMuhurluPersisted = false;

  /// Olumlu/olumsuz tıklanınca "düzenlenebilir ve kaydedildi" bilgi notunu göster.
  bool _showSentimentChoiceNote = false;

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
    _hukumFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _applyDefaultPrefix();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingHukumler();
    });
  }

  @override
  void didUpdateWidget(covariant ModernHukumCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.davaId != widget.davaId) {
      _showSentimentChoiceNote = false;
    }
    if (oldWidget.davaId != widget.davaId ||
        oldWidget.davaGorev != widget.davaGorev ||
        oldWidget.openedAt != widget.openedAt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingHukumler();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cezaMasrafAnimationController?.dispose();
    _hukumFocusNode.dispose();
    _hukumController.dispose();
    super.dispose();
  }

  /// Hive üzerinde kayıtlı hüküm verilerini yükler.
  Future<void> _loadExistingHukumler() async {
    final String davaId = widget.davaId ?? 'dava_${widget.davaAdi.hashCode}';
    try {
      final Map<String, Map<String, dynamic>> existing =
          await HiveDatabaseService.getHukumlerByDavaIdGrouped(
        davaId,
        davaAdi: widget.davaAdi,
      );
      final Map<String, String> cezalarByEmail =
          await HiveDatabaseService.getCezaMapForDavaId(davaId);
      final Map<String, String> masraflarByEmail =
          await HiveDatabaseService.getMasrafGiftLineMapForDavaId(davaId);

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
              final String normalizedKey = normalizeRolKarari(entry.key);
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
            final String normalizedKey = normalizeRolKarari(entry.key);
            _rolSentimentleri[normalizedKey] = sentiment;
          }
        }

        _rolFinalizasyonlari.clear();
        _rolCezalari.clear();
        _rolMasraflari.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry
            in existing.entries) {
          final String roleFromRow =
              (entry.value['userRole'] as String?)?.trim().isNotEmpty == true
                  ? (entry.value['userRole'] as String)
                  : entry.key;
          final String normalizedKey = normalizeRolKarari(roleFromRow);
          final bool fin = _readHiveBool(entry.value['isFinalized']);
          // Aynı normalize anahtara birden fazla satır düşerse: biri true ise nihai true.
          _rolFinalizasyonlari[normalizedKey] =
              (_rolFinalizasyonlari[normalizedKey] ?? false) || fin;

          final String email =
              (entry.value['userEmail'] as String? ?? '').trim();
          if (email.isNotEmpty) {
            final String emailKey = email.toLowerCase();
            final String? ceza = cezalarByEmail[emailKey];
            final String? masraf = masraflarByEmail[emailKey];
            if (ceza != null && ceza.trim().isNotEmpty) {
              _rolCezalari[normalizedKey] = ceza.trim();
            }
            if (masraf != null && masraf.trim().isNotEmpty) {
              _rolMasraflari[normalizedKey] = masraf.trim();
            }
          }
        }

        final String normalizedRole = normalizeRolKarari(widget.davaGorev);
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
        // Her rol geçişinde ceza/masraf kartı varsayılan ikonlarla başlasın.
        _cezaCompleted = false;
        _masrafCompleted = false;
        _showCezaMasrafButtons = false;
        if (_isCurrentRoleFinalized) {
          _hukumController.value = _hukumController.value.copyWith(
            selection: TextSelection.collapsed(
              offset: _hukumController.text.length,
            ),
          );
        }
        _kaydetBaselineTrimmedBody =
            _extractHukumBody(_hukumController.text).trim();
        _kaydetBaselineSentiment = _selectedSentiment;
      });
    } catch (_) {
      // Hive erişiminde hata oluşursa UI tarafında sessizce devam edilir.
    }

    await _refreshConsensus();
    await _refreshEditLock();
    await _refreshCezaSealState();
  }

  /// Bu dava + oturumdaki kullanıcı için ceza mühürlü mü? (8-Hüküm: yalnızca ilgili kişi salt okunur.)
  Future<void> _refreshCezaSealState() async {
    final String? email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) {
      if (mounted) {
        setState(() => _cezaMuhurluPersisted = false);
      }
      return;
    }
    final String davaId = widget.davaId ?? 'dava_${widget.davaAdi.hashCode}';
    final String? ceza = await HiveDatabaseService.getCeza(
      davaId: davaId,
      userEmail: email,
    );
    if (!mounted) {
      return;
    }
    final bool sealed = ceza != null && ceza.trim().isNotEmpty;
    setState(() {
      _cezaMuhurluPersisted = sealed;
      if (sealed) {
        _cezaCompleted = true;
      }
    });
  }

  Future<void> _refreshEditLock() async {
    if (widget.davaId == null || widget.davaId!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _roleEditLocked = false;
        _lockReason = null;
      });
      return;
    }

    final opened = HiveDatabaseService.getOpenedDavaById(widget.davaId!);
    final now = DateTime.now();
    final openedAt = widget.openedAt;

    final appealWindow =
        DavaHukumEligibilityService.isAppealJudgeWindowActive(opened);
    final mainEnded =
        DavaHukumEligibilityService.isMainTrialEnded(openedAt, now);
    final appealEditingAllowed = appealWindow && mainEnded;

    final gorev = widget.davaGorev;
    final isTemyiz = DavaHukumEligibilityService.roleLabelIsTemyiz(gorev);
    final isYargic = DavaHukumEligibilityService.roleLabelIsYargic(gorev);

    String? reason;
    var locked = false;

    if (appealEditingAllowed) {
      if (!isTemyiz) {
        locked = true;
        reason =
            'Temyiz süreci aktif: yalnızca Temyiz Hakimi hüküm düzenleyebilir.';
      }
    } else if (isTemyiz) {
      locked = true;
      reason =
          'Temyiz hükmü; 7 gün sonrası temyiz talebinden sonra 72 saatlik süre içinde açılır.';
    }

    if (!locked && isYargic && !appealEditingAllowed) {
      final past144 = openedAt != null &&
          now.difference(openedAt) >= const Duration(hours: 144);
      final sixDone = await DavaHukumEligibilityService.hasSixPanelFinalized(
        widget.davaId!,
      );
      if (!past144 && !sixDone) {
        locked = true;
        reason =
            'Yargıç: Altı rol (jüri, avukatlar, şahitler) hükmünü tamamlayana veya 144. saat dolana kadar bekleyin.';
      }
    }

    // Ana süre (168 saat) bittiyse jüri / avukat / şahit rolleri taslak da olsa
    // metin güncelleyemez; yargıç ve temyiz (kendi pencerelerinde) hariç.
    if (!locked &&
        mainEnded &&
        openedAt != null &&
        !isTemyiz &&
        !isYargic) {
      locked = true;
      reason =
          'Ana dava süresi (168 saat) tamamlandı; hüküm metni artık güncellenemez.';
    }

    if (!mounted) return;
    setState(() {
      _roleEditLocked = locked;
      _lockReason = reason;
    });
  }

  /// Hive bazen bool yerine int/String döndürebilir.
  static bool _readHiveBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value != 0;
    }
    if (value is String) {
      final String s = value.toLowerCase().trim();
      return s == 'true' || s == '1';
    }
    return false;
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

    final String afterPrefix = _hukumController.text;
    if (!afterPrefix.startsWith(_hukumPrefix)) {
      return;
    }
    final String body = _extractHukumBody(afterPrefix);
    if (body.length > _hukumBodyMaxChars) {
      final int baseOffset = _hukumController.selection.baseOffset;
      _isApplyingPrefix = true;
      final String truncated = body.substring(0, _hukumBodyMaxChars);
      final String newText = '$_hukumPrefix$truncated';
      int newOffset = baseOffset;
      if (newOffset > newText.length) {
        newOffset = newText.length;
      }
      if (newOffset < _hukumPrefix.length) {
        newOffset = _hukumPrefix.length;
      }
      _hukumController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
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
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDDE9E2),
            width: 1.4,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF101815).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildDavaInfo(),
                      const SizedBox(height: 14),
                      _buildHukumInput(),
                      const SizedBox(height: 16),
                      RolHukumKartlariSection(
                        davaId: widget.davaId,
                        openedAt: widget.openedAt,
                        userEmail: widget.userEmail,
                        kullaniciGorev: widget.davaGorev,
                        rolHukumleri: _rolHukumleri,
                        rolSentimentleri: _rolSentimentleri,
                        rolCezalari: _rolCezalari,
                        rolMasraflari: _rolMasraflari,
                        seciliSentiment: _selectedSentiment,
                        consensusEvaluation: _consensusEvaluation,
                        consensusLoading: _isConsensusLoading,
                        onConsensusRefresh:
                            _canEvaluateConsensus ? _refreshConsensus : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dava bilgilerini gösteren kutuyu oluşturur.//bu kısmı dava künyesi 2 diyorum.
  Widget _buildDavaInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _kunyeExpanded = !_kunyeExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '|| Dava Künyesi ||',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: Color(0xFF1B2A23),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _kunyeExpanded ? 0.5 : 0,
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
          AnimatedCrossFade(
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            sizeCurve: Curves.easeInOutCubic,
            duration: const Duration(milliseconds: 280),
            crossFadeState: _kunyeExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildInfoRow(
                    'Göreviniz',
                    widget.davaGorev,
                    MdiIcons.briefcaseOutline,
                    color: Colors.green.shade700,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Dava Adı',
                    widget.davaAdi,
                    MdiIcons.gavel,
                    color: Colors.green.shade700,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Davacı',
                    widget.davaDavaci,
                    MdiIcons.account,
                    color: Colors.green.shade700,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Davalı',
                    widget.davaDavali,
                    MdiIcons.accountOutline,
                    color: Colors.green.shade700,
                  ),
                  const Divider(height: 20),
                  _buildCountdownSection(),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
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
    final bool hukumKesinlesti = _isCurrentRoleFinalized;
    final bool inputLocked = hukumKesinlesti || _roleEditLocked;
    /// 114 sonrası Ceza/Masraf adımı: metin, duygu, mavi not ve slider gizlenir.
    final bool hideMainHukumChrome =
        !hukumKesinlesti && _showCezaMasrafButtons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (hukumKesinlesti) _buildCezaMasrafButtons(),
        if (!hukumKesinlesti) ...<Widget>[
        if (!hideMainHukumChrome &&
            _lockReason != null &&
            _lockReason!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.lock_outline, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lockReason!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!hideMainHukumChrome) ...<Widget>[
        AnimatedScale(
          scale: inputLocked ? 1.0 : (_hukumFocusNode.hasFocus ? 1.01 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: inputLocked ? Colors.grey.shade200 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: inputLocked
                    ? Colors.grey.shade400
                    : (_hukumFocusNode.hasFocus
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFDCE8DF)),
                width: _hukumFocusNode.hasFocus ? 2 : 1,
              ),
              boxShadow: <BoxShadow>[
                if (_hukumFocusNode.hasFocus && !inputLocked)
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.14),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            // Kaydet sonrası controller, kaydedilen son metinle güncellenir (hızlı iterasyon).
            child: TextField(
              controller: _hukumController,
              focusNode: _hukumFocusNode,
              maxLines: 12,
              minLines: 12,
              enabled: true,
              readOnly: inputLocked,
              showCursor: !inputLocked,
              cursorColor: const Color(0xFF4CAF50),
              cursorWidth: 3,
              cursorRadius: const Radius.circular(2),
              onTap: () {
                if (inputLocked) {
                  final String lockMessage = _isCurrentRoleFinalized
                      ? 'Bu rol için hüküm nihai hale getirildiği için düzenleme yapılamaz.'
                      : (_lockReason ?? 'Bu alanda şu anda düzenleme yapılamıyor.');
                  _showSnackBar(lockMessage, Colors.orange.shade800);
                }
              },
              decoration: InputDecoration(
                hintText: 'Hükmünü buraya yazmaya başla...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(top: 200, right: 4),
                  child: IconButton(
                    tooltip: _isCurrentRoleFinalized
                        ? 'Hüküm kesinleştiği için kaydedilemez'
                        : (!_kaydetHasPendingDraftChanges &&
                                _extractHukumBody(_hukumController.text).trim().isNotEmpty &&
                                _selectedSentiment != null)
                            ? 'Kaydedildi'
                        : 'Taslağı kaydet',
                    onPressed: _isKaydetButtonEnabled
                        ? () => _saveHukumForRole(widget.davaGorev)
                        : null,
                    icon: Icon(
                      Icons.save_as_outlined,
                      color: _isCurrentRoleFinalized
                          ? Colors.grey.shade300
                          : (!_kaydetHasPendingDraftChanges &&
                                  _extractHukumBody(_hukumController.text)
                                      .trim()
                                      .isNotEmpty &&
                                  _selectedSentiment != null)
                              ? Colors.blue.shade700
                              : (_isKaydetButtonEnabled
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_extractHukumBody(_hukumController.text).length} / $_hukumBodyMaxChars karakter · en az $_hukumBodyMinChars',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _hukumBodyLengthHintColor(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        HukumSentimentSelector(
          selectedSentiment: _selectedSentiment,
          isDisabled: inputLocked,
          hidePartySideLabels:
              _showCezaMasrafButtons || _isCurrentRoleFinalized,
          onSentimentSelected: (HukumSentiment sentiment) {
            setState(() {
              final String currentRole = normalizeRolKarari(widget.davaGorev);
              _selectedSentiment = sentiment;
              _rolSentimentleri[currentRole] = sentiment;
              _showSentimentChoiceNote = true;
            });
          },
        ),
        if (_showSentimentChoiceNote && _selectedSentiment != null) ...<Widget>[
          const SizedBox(height: 12),
          _buildSentimentSavedInfoNote(),
        ],
        ],
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
        if (!hideMainHukumChrome) ...<Widget>[
        const SizedBox(height: 20),
        Builder(
          builder: (BuildContext context) {
            /// Ceza paneli veya nihai hüküm: slider kilitli / gri.
            final bool stripGrey =
                _showCezaMasrafButtons || _isCurrentRoleFinalized;
            final bool dragEnabled =
                !stripGrey &&
                !_roleEditLocked &&
                !_isCurrentRoleFinalized &&
                _selectedSentiment != null;
            final String? disabledHint = _selectedSentiment == null
                ? 'Hüküm onayı için önce hüküm yönünüzü (olumlu/olumsuz) seçin.'
                : (_roleEditLocked && !stripGrey && !_isCurrentRoleFinalized
                    ? _lockReason
                    : null);
            final int inactiveSegment =
                _showCezaMasrafButtons && !_isCurrentRoleFinalized ? 2 : 1;

            return _HukukiSurecSlider(
              key: ValueKey<String>(
                'hukum-slider-${widget.davaId}-${widget.davaGorev}',
              ),
              dragEnabled: dragEnabled,
              finalized: _isCurrentRoleFinalized,
              inactiveSegment: inactiveSegment,
              canSave: _isKaydetButtonEnabled,
              canHukum: _isHukumVerildiButtonEnabled,
              disabledHint: disabledHint,
              focusNode: _hukumFocusNode,
              onSave: () => _saveHukumForRole(widget.davaGorev),
              onHukum: () {
                if (!_showCezaMasrafButtons) {
                  setState(() {
                    _showCezaMasrafButtons = true;
                    _cezaCompleted = false;
                    _masrafCompleted = false;
                  });
                  _cezaMasrafAnimationController?.forward(from: 0);
                  return;
                }
                _saveHukumForRole(
                  widget.davaGorev,
                  isVerdi: true,
                );
              },
            );
          },
        ),
        ],
        ],
      ],
    );
  }

  /// Olumlu/olumsuz seçiminden sonra: düzenlenebilir ve kaydedildi bilgisi (HTML ilhamı).
  Widget _buildSentimentSavedInfoNote() {
    if (_isCurrentRoleFinalized) {
      return const SizedBox.shrink();
    }
    final HukumSentiment s = _selectedSentiment!;
    final String upper = s == HukumSentiment.positive ? 'OLUMLU' : 'OLUMSUZ';
    return Material(
      color: const Color(0xFFE3F2FD),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Color(0xFF2196F3), width: 4),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.grey.shade800,
            ),
            children: <TextSpan>[
              TextSpan(
                text: upper,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const TextSpan(
                text:
                    ' kararı verildi.Düzenlenebilir',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ceza Ver ve Masrafla butonlarını oluşturur
  Widget _buildCezaMasrafButtons() {
    final bool finalizedMode = _isCurrentRoleFinalized;
    // Temayı canlı tutmak için kırmızı tonu kullanıyoruz
    const Color primaryAccent = Colors.red;
    const Color secondaryAccent = Colors.purple;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: finalizedMode ? Colors.grey.shade300 : primaryAccent.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (finalizedMode ? Colors.grey : primaryAccent).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bölüm Başlığı
          Row(
            children: [
              Icon(MdiIcons.gavel, size: 20, color: finalizedMode ? Colors.grey : Colors.red.shade700),
              const SizedBox(width:10),
              Text(
                'Ceza ve Masraf İşlemleri',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: finalizedMode ? Colors.grey.shade700 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              // CEZA VER BUTONU
              Expanded(
                child: _cezaMuhurluPersisted
                    ? Tooltip(
                        message: 'Bu dava için cezayı resmi mühür ile kaydettiniz; tekrar açılamaz.',
                        child: _buildStatusButton(
                          label: 'Mühürlü',
                          defaultIcon: MdiIcons.stamper,
                          isCompleted: _cezaCompleted,
                          activeColor: primaryAccent,
                          enabled: false,
                          onTap: () {},
                        ),
                      )
                    : _buildStatusButton(
                        label: 'Ceza Ver',
                        defaultIcon: MdiIcons.handcuffs, // Senin orijinal ikonun
                        isCompleted: _cezaCompleted,
                        activeColor: primaryAccent,
                        onTap: () async {
                          final bool? result = await Navigator.of(context)
                              .push<bool>(
                            MaterialPageRoute(
                              builder: (c) => CezaYonetimPage(
                                key: ValueKey<String>(
                                  'ceza_yonetim_${widget.davaId ?? ''}_${widget.davaAdi}',
                                ),
                                davaId: widget.davaId,
                                davaAdi: widget.davaAdi,
                                davaDavali: widget.davaDavali,
                                davaDavaci: widget.davaDavaci,
                                userEmail: widget.userEmail,
                                davaGorev: widget.davaGorev,
                                kalanSure: widget.kalanSure,
                                davaOpenedAt: widget.openedAt,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            setState(() {
                              _cezaCompleted = true;
                              _cezaMuhurluPersisted = true;
                            });
                            _checkAndCompleteHukum();
                          }
                        },
                      ),
              ),
              const SizedBox(width: 12),
              // MASRAFLA BUTONU
              Expanded(
                child: _buildStatusButton(
                  label: 'Masrafla',
                  defaultIcon: MdiIcons.giftOpenOutline,
                  isCompleted: _masrafCompleted,
                  activeColor: secondaryAccent,
                  enabled: !_masrafCompleted,
                  completedIcon: Icons.outbound_rounded,
                  completedLabel: 'MASRAF/UYAR!',
                  onTap: () async {
                    if (!_cezaMuhurluPersisted) {
                      _showSnackBar(
                        'Önce cezayı mühürlemeniz (Ceza Ver) gerekir. '
                        'Cezalama bitmeden masraf akışı seyir defterine düşmez.',
                        Colors.orange.shade800,
                      );
                      return;
                    }
                    final bool? result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (BuildContext c) => HukumGiftSelectionPage(
                          userEmail: widget.userEmail,
                          davaId: widget.davaId,
                          davaAdi: widget.davaAdi,
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() => _masrafCompleted = true);
                      _checkAndCompleteHukum();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Duruma göre ikon değiştiren estetik buton taslağı
  Widget _buildStatusButton({
    required String label,
    required IconData defaultIcon,
    required bool isCompleted,
    required Color activeColor,
    required VoidCallback onTap,
    bool enabled = true,
    /// Tamamlanınca tik yerine gösterilecek ikon (ör. masraf hediyesi sonrası).
    IconData? completedIcon,
    /// Tamamlanınca [label] yerine gösterilecek metin.
    String? completedLabel,
  }) {
    final bool showDone = isCompleted;
    final bool mutedDisabled = !enabled;
    final IconData displayIcon = showDone
        ? (completedIcon ?? Icons.check_circle)
        : defaultIcon;
    final String displayLabel =
        showDone && completedLabel != null ? completedLabel! : label;
    final bool warningDone =
        showDone && completedIcon != null && completedLabel != null;
    // Tamamlandığında: varsayılan yeşil tik; masraf/hediye (özel ikon+UYAR!) için uyarı tonu.
    final Color statusColor = mutedDisabled
        ? Colors.blueGrey.shade500
        : (showDone
            ? (warningDone ? Colors.deepOrange.shade800 : Colors.green.shade600)
            : activeColor);
    final Color bgColor = mutedDisabled
        ? Colors.grey.shade200
        : (showDone
            ? (warningDone
                ? Colors.deepOrange.shade50
                : Colors.green.shade50)
            : activeColor.withOpacity(0.05));
    final Color doneBorderColor = warningDone
        ? Colors.deepOrange.withOpacity(0.35)
        : Colors.green.withOpacity(0.2);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: mutedDisabled
                  ? Colors.blueGrey.shade200
                  : (showDone ? doneBorderColor : activeColor.withOpacity(0.1)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                displayIcon,
                color: statusColor,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                displayLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Yardımcı Buton Widget'ı (Daha temiz ve reusable)
  Widget _newCustomButton({
    required String label,
    required IconData icon,
    required bool status,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: status ? Colors.green.shade50 : primaryColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        highlightColor: primaryColor.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: status ? Colors.green.withOpacity(0.3) : primaryColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                status ? Icons.check_circle : icon,
                color: status ? Colors.green : primaryColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: status ? Colors.green.shade700 : primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tekil aksiyon butonunu oluşturur (Ceza Ver veya Masrafla)
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isCompleted,
    required bool isLocked,
    required VoidCallback onTap,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              isLocked
                  ? Colors.grey.shade500
                  : (isCompleted ? color.shade400 : color.shade100),
              isLocked
                  ? Colors.grey.shade700
                  : (isCompleted ? color.shade600 : color.shade200),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocked
                ? Colors.grey.shade800
                : (isCompleted ? color.shade700 : color.shade300),
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (isLocked ? Colors.grey : color)
                  .withOpacity(isCompleted ? 0.3 : 0.1),
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
                  size: 29,
                  color: isLocked
                      ? Colors.white
                      : (isCompleted ? Colors.white : color.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? Colors.white
                        : (isCompleted ? Colors.white : color.shade700),
                  ),
                ),
              ],
            ),
            // Sağ üstte yeşil onay ikonu
            Positioned(
              top: -10,
              right: -10,
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
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 4,
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
    if (hukumBody.length < _hukumBodyMinChars) {
      _showSnackBar(
        'Gereği düşünüldü metni en az $_hukumBodyMinChars karakter olmalıdır '
        '(şu an ${hukumBody.length}).',
        Colors.orange.shade800,
      );
      return;
    }
    if (hukumBody.length > _hukumBodyMaxChars) {
      _showSnackBar(
        'Gereği düşünüldü metni en fazla $_hukumBodyMaxChars karakter olabilir.',
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

    final String normalizedRolAdi = normalizeRolKarari(rolAdi);
    if (_rolFinalizasyonlari[normalizedRolAdi] == true) {
      _showSnackBar(
        'Bu rol için hüküm nihai hale getirildi; düzenleme yapılamaz.',
        Colors.orange.shade800,
      );
      return;
    }

    // Süre / temyiz gibi kurallar taslak kaydını engeller; nihai "Hüküm Verildi"
    // tamamlanırken (isVerdi) kayıt yine yazılabilir.
    if (_roleEditLocked && !isVerdi) {
      _showSnackBar(
        _lockReason ?? 'Bu alanda şu anda düzenleme yapılamıyor.',
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
      }
      if (!_isCurrentRoleFinalized) {
        _hukumController.text = fullText;
        _hukumController.selection = TextSelection.collapsed(
          offset: _hukumController.text.length,
        );
      }
    });

    try {
      // Hive mutlaka güncellenmeli; userEmail boşken eskiden hiç yazılmıyordu ve
      // _loadExistingHukumler isFinalized=false okuyup kesinleşmiş ekranı geri açıyordu.
      if ((widget.userEmail ?? '').isNotEmpty) {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        final bool? providerOk = await davaProvider.updateHukumForDava(
          davaId: davaId,
          userRole: normalizedRolAdi,
          hukumText: fullText,
          userEmail: widget.userEmail!,
          hukumSentiment: sentiment.storageValue,
          isFinalized: nextFinalizationState,
        );
        if (providerOk != true) {
          throw Exception('Provider hüküm kaydını tamamlayamadı (sonuç: $providerOk).');
        }

        if (isVerdi &&
            DavaHukumEligibilityService.roleLabelIsTemyiz(rolAdi) &&
            widget.davaId != null &&
            widget.davaId!.isNotEmpty) {
          await HiveDatabaseService.updateOpenedDava(davaId, {
            'appealJudgeSentiment': sentiment.storageValue,
            'appealJudgeRuledAt': DateTime.now().toIso8601String(),
          });
        }

        // Ceza mühürü + masraf sonrası kesin hüküm: kendi seyir defterine dava_share
        // (anasayfadaki IlgililerinSeyirDefteriWidgeti ile aynı veri yapısı).
        if (isVerdi &&
            widget.davaId != null &&
            widget.davaId!.trim().isNotEmpty) {
          final Map<String, dynamic>? feedPost =
              HiveDatabaseService.composeHomeFeedDavaSharePostAfterHukumFinalized(
            davaId: widget.davaId!.trim(),
            userEmail: widget.userEmail!,
            fallbackSnapshot: <String, dynamic>{
              'id': widget.davaId,
              'davaAdi': widget.davaAdi,
              'davaci': widget.davaDavaci,
              'davali': widget.davaDavali,
              'davaKonusu': '',
              'kategori': '',
              'davaKategorisi': '',
              'openedAt': widget.openedAt?.toIso8601String(),
            },
          );
          if (feedPost != null) {
            HiveDatabaseService.addHomeFeedPost(feedPost,
                userEmail: widget.userEmail);
            await davaProvider.refreshHomeFeedSilent(widget.userEmail!);
          }
        }

        print('✅ [ModernHukumCard] Hüküm Provider üzerinden kaydedildi:');
        print('   - Dava ID: $davaId');
        print('   - Rol: $normalizedRolAdi');
        print('   - Sentiment: ${sentiment.storageValue}');
        print('   - Provider versiyonu: ${davaProvider.hukumUpdateVersion}');
      } else {
        await HiveDatabaseService.saveHukum(
          davaId: davaId,
          userRole: normalizedRolAdi,
          hukumText: fullText,
          userEmail: '',
          hukumSentiment: sentiment.storageValue,
          isFinalized: nextFinalizationState,
        );
        print('✅ [ModernHukumCard] Hüküm Hive\'a yazıldı (userEmail boş).');
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

      // Nihai hüküm: _loadExistingHukumler bazen isFinalized'ı yanlış okuyor (Hive tipi,
      // davaId/rol anahtarı uyumsuzluğu). Kayıt başarılıysa kesinleşmiş UI'yı garanti et.
      if (isVerdi && mounted) {
        setState(() {
          _isCurrentRoleFinalized = true;
          _rolFinalizasyonlari[normalizedRolAdi] = true;
          _showCezaMasrafButtons = false;
          _cezaCompleted = false;
          _masrafCompleted = false;
        });
      }

      // Taslak kayıtta Hive yeniden yükleme gecikmesi veya anahtar uyumsuzluğu alanı
      // boşaltabildiği için TextField'ı her zaman az önce kaydedilen metinle eşitle.
      if (!isVerdi && mounted) {
        setState(() {
          _hukumController.value = TextEditingValue(
            text: fullText,
            selection: TextSelection.collapsed(offset: fullText.length),
          );
        });
      }
    } catch (error) {
      _showSnackBar(
        '❌ Hüküm kaydedilirken hata oluştu: $error',
        Colors.red.shade700,
      );
    }
  }

  /// Kaydet: yalnızca taslakta değişiklik varken (güncelleme butonu).
  bool get _isKaydetButtonEnabled =>
      !_roleEditLocked &&
      !_isCurrentRoleFinalized &&
      !_showCezaMasrafButtons &&
      _hukumBodySatisfiesLengthRules &&
      _selectedSentiment != null &&
      _kaydetHasPendingDraftChanges;

  /// Hüküm Verildi: nihai karar; senkron taslak olsa da kullanılabilir.
  bool get _isHukumVerildiButtonEnabled =>
      !_roleEditLocked &&
      !_isCurrentRoleFinalized &&
      _hukumBodySatisfiesLengthRules &&
      _selectedSentiment != null &&
      !_showCezaMasrafButtons;

  bool get _kaydetHasPendingDraftChanges {
    final String trimmed = _extractHukumBody(_hukumController.text).trim();
    return trimmed != _kaydetBaselineTrimmedBody ||
        _selectedSentiment != _kaydetBaselineSentiment;
  }

  bool get _hukumBodySatisfiesLengthRules {
    final String body = _extractHukumBody(_hukumController.text);
    return body.trim().length >= _hukumBodyMinChars &&
        body.length <= _hukumBodyMaxChars;
  }

  Color _hukumBodyLengthHintColor() {
    final String body = _extractHukumBody(_hukumController.text);
    if (body.isEmpty) {
      return Colors.grey.shade600;
    }
    if (body.trim().length >= _hukumBodyMinChars &&
        body.length <= _hukumBodyMaxChars) {
      return Colors.grey.shade600;
    }
    return Colors.orange.shade800;
  }

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

  /// Verilen metni panoya kopyalar ve SnackBar ile bildirim gösterir.
  Future<void> _copyToClipboard(String text, Color accentColor) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(child: Text('Panoya kopyalandı.')),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: accentColor,
      ),
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

/// 0–114 hukuki süreç slider'ı: 19 artan çubuk, 19'un katları, Kaydet / Düzenle / Hüküm.
class _HukukiSurecSlider extends StatefulWidget {
  const _HukukiSurecSlider({
    super.key,
    required this.dragEnabled,
    required this.finalized,
    required this.inactiveSegment,
    required this.canSave,
    required this.canHukum,
    required this.focusNode,
    required this.onSave,
    required this.onHukum,
    this.disabledHint,
  });

  final bool dragEnabled;
  final bool finalized;
  /// Kilitliyken: 1 → orta (~57), 2 → sağ (~95).
  final int inactiveSegment;
  final bool canSave;
  final bool canHukum;
  final FocusNode focusNode;
  final Future<void> Function() onSave;
  final VoidCallback onHukum;
  final String? disabledHint;

  static const double maxValue = 114;
  static const List<int> milestones = <int>[0, 19, 38, 57, 76, 95, 114];
  static const int barCount = 19;

  static const Color finalizedGrey = Color(0xFF90A4AE);
  static const Color trackMuted = Color(0xFFE8ECEF);

  /// 0→114 sürekli geçiş: düşük uyarılma (mavi) → dikkat (sarı) → risk (turuncu) → nihai (koyu).
  static Color accentForProgress(double v) {
    final double t = (v / maxValue).clamp(0.0, 1.0);
    if (t < 0.38) {
      return Color.lerp(
        const Color(0xFF2196F3),
        const Color(0xFFFFD600),
        Curves.easeIn.transform(t / 0.38),
      )!;
    }
    if (t < 0.833) {
      return Color.lerp(
        const Color(0xFFFFD600),
        const Color(0xFFE65100),
        Curves.easeInOut.transform((t - 0.38) / (0.833 - 0.38)),
      )!;
    }
    return Color.lerp(
      const Color(0xFFE65100),
      const Color(0xFF2C3E50),
      Curves.easeIn.transform((t - 0.833) / (1.0 - 0.833)),
    )!;
  }

  @override
  State<_HukukiSurecSlider> createState() => _HukukiSurecSliderState();
}

class _HukukiSurecSliderState extends State<_HukukiSurecSlider> {
  /// Sürekli konum 0…114; bırakınca en yakın milestone'a yuvarlanır.
  double _value = 0;
  double? _dragValue;

  static int _nearestMilestone(double v) {
    int best = _HukukiSurecSlider.milestones.first;
    double bestD = (v - best).abs();
    for (final int m in _HukukiSurecSlider.milestones) {
      final double d = (v - m).abs();
      if (d < bestD) {
        bestD = d;
        best = m;
      }
    }
    return best;
  }

  static int _zoneForValue(double v) {
    if (v <= 38) {
      return 0;
    }
    if (v < 114) {
      return 1;
    }
    return 2;
  }

  double _lockedValue() {
    if (widget.finalized) {
      return _HukukiSurecSlider.maxValue;
    }
    if (!widget.dragEnabled) {
      return widget.inactiveSegment >= 2 ? 95.0 : 57.0;
    }
    return _value;
  }

  Color _progressColor(double v, {required bool lockedGrey}) {
    if (lockedGrey || widget.finalized) {
      return _HukukiSurecSlider.finalizedGrey;
    }
    return _HukukiSurecSlider.accentForProgress(v);
  }

  @override
  void initState() {
    super.initState();
    if (widget.finalized) {
      _value = _HukukiSurecSlider.maxValue;
    }
  }

  @override
  void didUpdateWidget(covariant _HukukiSurecSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.finalized && !oldWidget.finalized) {
      _value = _HukukiSurecSlider.maxValue;
      _dragValue = null;
    }
    if (!widget.dragEnabled &&
        oldWidget.dragEnabled &&
        !widget.finalized) {
      _value = widget.inactiveSegment >= 2 ? 95.0 : 0.0;
      _dragValue = null;
    }
    if (widget.dragEnabled && !oldWidget.dragEnabled) {
      _value = 0;
    }
  }

  Future<void> _onDragEnd() async {
    if (_dragValue == null) {
      return;
    }
    final int snapped = _nearestMilestone(_dragValue!);
    final int zone = _zoneForValue(snapped.toDouble());

    int resolvedMilestone = snapped;

    if (zone == 0) {
      if (!widget.canSave) {
        resolvedMilestone = 0;
      } else {
        await widget.onSave();
        if (!mounted) {
          return;
        }
        resolvedMilestone = 0;
      }
    } else if (zone == 1) {
      widget.focusNode.requestFocus();
      resolvedMilestone = snapped;
    } else {
      if (!widget.canHukum) {
        resolvedMilestone = 57;
      } else {
        widget.onHukum();
        resolvedMilestone = _HukukiSurecSlider.maxValue.toInt();
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _value = resolvedMilestone.toDouble();
      _dragValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.finalized) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final bool locked = widget.finalized || !widget.dragEnabled;
        final double displayV =
            locked ? _lockedValue() : (_dragValue ?? _value);
        final bool greyMode = locked || widget.finalized;
        final Color progressColor = _progressColor(
          displayV,
          lockedGrey: greyMode,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Hüküm onayı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hükmü kesinleştirmek için sürükleyin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 118,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 22,
                    height: 72,
                    child: _SurecBarChart(
                      maxValue: _HukukiSurecSlider.maxValue,
                      value: displayV,
                      barCount: _HukukiSurecSlider.barCount,
                      inactiveColor: _HukukiSurecSlider.trackMuted,
                      activeColor: progressColor,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 96,
                    height: 22,
                    child: _SurecTickRow(width: w),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22, bottom: 24),
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints c) {
                          const double handleR = 11;
                          final double usable = c.maxWidth - 2 * handleR;
                          final double x =
                              handleR + (displayV / _HukukiSurecSlider.maxValue) * usable;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Positioned(
                                left: 0,
                                top: c.maxHeight / 2 -
                                    _SurecHandle.sideForProgress(0) / 2,
                                child: _SurecHandle(
                                  ringColor: greyMode
                                      ? _HukukiSurecSlider.finalizedGrey
                                      : _HukukiSurecSlider.accentForProgress(0),
                                  filled: false,
                                  progress: 0,
                                ),
                              ),
                              Positioned(
                                left: x -
                                    _SurecHandle.sideForProgress(
                                          displayV,
                                        ) /
                                        2,
                                top: c.maxHeight / 2 -
                                    _SurecHandle.sideForProgress(displayV) / 2,
                                child: widget.finalized
                                    ? _SurecHandle(
                                        ringColor:
                                            _HukukiSurecSlider.finalizedGrey,
                                        filled: true,
                                        progress:
                                            _HukukiSurecSlider.maxValue,
                                      )
                                    : GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onHorizontalDragStart: locked
                                            ? null
                                            : (_) {
                                                setState(() {
                                                  _dragValue = _dragValue ?? _value;
                                                });
                                              },
                                        onHorizontalDragUpdate: locked
                                            ? null
                                            : (DragUpdateDetails d) {
                                                setState(() {
                                                  final double cur =
                                                      _dragValue ?? _value;
                                                  final double delta =
                                                      (d.delta.dx / usable) *
                                                          _HukukiSurecSlider
                                                              .maxValue;
                                                  _dragValue = (cur + delta)
                                                      .clamp(
                                                    0.0,
                                                    _HukukiSurecSlider.maxValue,
                                                  );
                                                });
                                              },
                                        onHorizontalDragEnd: locked
                                            ? null
                                            : (_) => _onDragEnd(),
                                        onHorizontalDragCancel: locked
                                            ? null
                                            : () {
                                                setState(() {
                                                  _dragValue = null;
                                                });
                                              },
                                        child: _SurecHandle(
                                          ringColor: greyMode
                                              ? _HukukiSurecSlider
                                                  .finalizedGrey
                                              : progressColor,
                                          filled: true,
                                          progress: displayV,
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        );
      },
    );
  }
}

class _SurecTickRow extends StatelessWidget {
  const _SurecTickRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        for (final int m in _HukukiSurecSlider.milestones)
          Positioned(
            left: width * (m / _HukukiSurecSlider.maxValue) - 12,
            child: Text(
              m == 0 ? '0' : '$m',
              style: TextStyle(
                fontSize: m == 0 ? 13 : 11,
                fontWeight: FontWeight.w800,
                color: m == 0
                    ? _HukukiSurecSlider.accentForProgress(0)
                    : Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }
}

class _SurecHandle extends StatelessWidget {
  const _SurecHandle({
    required this.ringColor,
    required this.filled,
    required this.progress,
  });

  final Color ringColor;
  final bool filled;
  /// 0…114 — en yakın milestone adımına göre çekiç büyür.
  final double progress;

  static const List<double> _milestones = <double>[
    0,
    19,
    38,
    57,
    76,
    95,
    114,
  ];

  static int _nearestIndex(double v) {
    int nearest = 0;
    double bestD = double.infinity;
    for (int i = 0; i < _milestones.length; i++) {
      final double d = (v - _milestones[i]).abs();
      if (d < bestD) {
        bestD = d;
        nearest = i;
      }
    }
    return nearest;
  }

  static double _gavelIconSize(double v) {
    final int n = _nearestIndex(v);
    return 9.5 + n * 1.42 * 3;
  }

  static double sideForProgress(double v) {
    final int n = _nearestIndex(v.clamp(0.0, _HukukiSurecSlider.maxValue));
    return 22 + n * 6.0;
  }

  @override
  Widget build(BuildContext context) {
    final double v = progress.clamp(0.0, _HukukiSurecSlider.maxValue);
    final double side = sideForProgress(v);
    final double iconSize = _gavelIconSize(v);
    final double radius = (side * 0.22).clamp(6.0, 14.0);
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ringColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Icon(
          MdiIcons.gavel,
          size: iconSize,
          color: ringColor,
        ),
      ),
    );
  }
}

class _SurecBarChart extends StatelessWidget {
  const _SurecBarChart({
    required this.maxValue,
    required this.value,
    required this.barCount,
    required this.inactiveColor,
    required this.activeColor,
  });

  final double maxValue;
  final double value;
  final int barCount;
  final Color inactiveColor;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final double fillEnd = (value / maxValue).clamp(0.0, 1.0) * barCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List<Widget>.generate(barCount, (int i) {
        final double h = 18 + (54 * i / (barCount - 1));
        final double t = i.toDouble();
        final bool filled = t < fillEnd - 0.001;
        final double partial = (fillEnd - t).clamp(0.0, 1.0);
        final bool isPartial = !filled && partial > 0 && partial < 1;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: h,
                      color: inactiveColor,
                    ),
                    if (filled)
                      Container(
                        width: double.infinity,
                        height: h,
                        color: activeColor,
                      )
                    else if (isPartial)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          height: h * partial,
                          color: activeColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

