import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

import '../models/hukum_sentiment.dart';
import '../services/dava_consensus_service.dart';
import '../services/dava_hukum_eligibility_service.dart';
import '../services/dava_timer_service.dart';
import '../services/hive_database_service.dart';
import '../providers/dava_provider.dart';
import 'hukum_sentiment_selector.dart';
import 'countdown_timer_widget.dart';
import 'ceza_yonetim_widget.dart';
import '../screens/hukum_gift_selection_page.dart';
import 'rol_hukum_kartlari_section.dart';

part 'modern_hukum_surec_slider.dart';

enum _HukumLoadPhase { loading, ready, empty, error }

/// Hüküm Verildi öncesi kısa onay.
Future<bool> confirmHukumVerildi(BuildContext context) async {
  final SeyirPalette palette = SeyirPalette.of(context);
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text('Emin misin?', style: palette.headline()),
        content: Text(
          'Hüküm verildikten sonra bu rolün metni kilitlenir.',
          style: palette.body(),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hüküm ver'),
          ),
        ],
      );
    },
  );
  return ok == true;
}

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
  /// true iken künye içeriği açıktır; başlıktaki ok aynı durumu gösterir.
  bool _kunyeExpanded = true;
  _HukumLoadPhase _loadPhase = _HukumLoadPhase.loading;
  String? _loadError;
  DateTime? _resolvedOpenedAt;
  String? _phaseLabel;
  Timer? _phaseTimer;
  bool _autoFinalizeQueued = false;
  bool _showStamp = false;
  String _stampCeza = '';
  String _stampMasraf = '';

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
    _armPhaseTimer();
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
    _phaseTimer?.cancel();
    _animationController.dispose();
    _cezaMasrafAnimationController?.dispose();
    _hukumFocusNode.dispose();
    _hukumController.dispose();
    super.dispose();
  }

  String? get _stableDavaId {
    final String id = widget.davaId?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  void _armPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final DateTime? opened = _resolvedOpenedAt ?? widget.openedAt;
      if (opened == null) return;
      final HukumPhaseClock clock = _phaseClock(opened);
      if (clock.label == _phaseLabel) return;
      _phaseLabel = clock.label;
      _refreshEditLock();
      final String? davaId = _stableDavaId;
      if (davaId != null) {
        DavaHukumEligibilityService.ensureAppealJudgeFallback(davaId);
      }
    });
  }

  HukumPhaseClock _phaseClock(DateTime openedAt) {
    DateTime? appealDeadline;
    final String? davaId = _stableDavaId;
    if (davaId != null) {
      final Map<String, dynamic>? opened =
          HiveDatabaseService.getOpenedDavaById(davaId);
      final DateTime? requested = DateTime.tryParse(
        opened?['appealRequestedAt']?.toString() ?? '',
      );
      if (requested != null && opened?['isAppealable'] == true) {
        appealDeadline =
            requested.add(DavaTimerService.appealJudgeDecisionWindow);
      }
    }
    return hukumPhaseClock(
      openedAt: openedAt,
      now: DateTime.now(),
      appealDeadline: appealDeadline,
    );
  }

  Future<void> _restoreCezaVeMasraf(String davaId) async {
    final String? email = widget.userEmail?.trim();
    bool sealed = false;
    bool masraf = false;
    String cezaText = '';
    String masrafText = '';
    if (email != null && email.isNotEmpty) {
      final String? ceza = await HiveDatabaseService.getCeza(
        davaId: davaId,
        userEmail: email,
      );
      sealed = ceza != null && ceza.trim().isNotEmpty;
      cezaText = ceza?.trim() ?? '';
      final List<String>? expenses = await HiveDatabaseService.getMasrafExpenses(
        davaId: davaId,
        userEmail: email,
      );
      if (expenses != null) {
        final List<String> lines = expenses
            .map((String e) => e.trim())
            .where((String e) => e.isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          masraf = true;
          masrafText = lines.first;
        }
      }
      if (!masraf) {
        final Map<String, String> map =
            await HiveDatabaseService.getMasrafGiftLineMapForDavaId(davaId);
        final String? line = map[email.toLowerCase()];
        if (line != null && line.trim().isNotEmpty) {
          masraf = true;
          masrafText = line.trim();
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _cezaMuhurluPersisted = sealed;
      _cezaCompleted = sealed;
      _masrafCompleted = masraf;
      _stampCeza = cezaText;
      _stampMasraf = masrafText;
      final String role = normalizeRolKarari(widget.davaGorev);
      if (cezaText.isNotEmpty) {
        _rolCezalari[role] = cezaText;
      }
      if (masrafText.isNotEmpty) {
        _rolMasraflari[role] = masrafText;
      }
    });
  }

  /// Hive üzerinde kayıtlı hüküm verilerini yükler.
  Future<void> _loadExistingHukumler() async {
    final String? davaId = _stableDavaId;
    if (davaId == null) {
      if (!mounted) return;
      setState(() {
        _loadPhase = _HukumLoadPhase.error;
        _loadError =
            'Dava kimliği yok. Kayıt bölünmesin diye hüküm okunmadı.';
      });
      await _refreshEditLock();
      return;
    }
    if (mounted) {
      setState(() {
        _loadPhase = _HukumLoadPhase.loading;
        _loadError = null;
      });
    }
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
        _showCezaMasrafButtons = false;
        _loadPhase = existing.isEmpty
            ? _HukumLoadPhase.empty
            : _HukumLoadPhase.ready;
        _loadError = null;
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
      if (!mounted) return;
      setState(() {
        _loadPhase = _HukumLoadPhase.error;
        _loadError = 'Hükümler yüklenemedi. Tekrar dene.';
      });
      return;
    }

    await _refreshConsensus();
    await _refreshEditLock();
    await _restoreCezaVeMasraf(davaId);
    await DavaHukumEligibilityService.ensureAppealJudgeFallback(davaId);
    _maybeAutoFinalize();
  }

  void _maybeAutoFinalize() {
    if (_roleEditLocked || _isCurrentRoleFinalized) return;
    if (!_cezaCompleted || !_masrafCompleted) return;
    _checkAndCompleteHukum();
  }

  Future<void> _refreshEditLock() async {
    final String? davaId = _stableDavaId;
    DateTime? openedAt = widget.openedAt;
    Map<String, dynamic>? opened;
    if (davaId != null) {
      opened = HiveDatabaseService.getOpenedDavaById(davaId);
      openedAt ??= DavaTimerService.parseOpenedAt(opened ?? <String, dynamic>{});
    }
    final bool appealWindow = davaId != null &&
        DavaHukumEligibilityService.isAppealJudgeWindowActive(opened);
    final bool sixDone = davaId != null &&
        await DavaHukumEligibilityService.hasSixPanelFinalized(davaId);
    final HukumRoleEditLock lock =
        DavaHukumEligibilityService.evaluateRoleEditLock(
      gorev: widget.davaGorev,
      openedAt: openedAt,
      now: DateTime.now(),
      appealWindowActive: appealWindow,
      sixPanelFinalized: sixDone,
    );
    if (!mounted) return;
    final HukumPhaseClock? clock =
        openedAt == null ? null : _phaseClock(openedAt);
    setState(() {
      _resolvedOpenedAt = openedAt;
      _roleEditLocked = lock.locked;
      _lockReason = lock.reason;
      _phaseLabel = clock?.label;
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
    final SeyirPalette palette = SeyirPalette.of(context);
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          SeyirTokens.space3,
          2,
          SeyirTokens.space3,
          SeyirTokens.space2,
        ),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: SeyirTokens.radiusLgAll,
          border: Border.all(
            color: palette.border,
            width: 1.4,
          ),
          boxShadow: palette.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: SeyirTokens.radiusLgAll,
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_loadPhase == _HukumLoadPhase.loading)
                  const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SeyirTokens.space4,
                    SeyirTokens.space3,
                    SeyirTokens.space4,
                    SeyirTokens.space4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildLoadStatus(palette),
                      _buildDavaInfo(),
                      const SizedBox(height: SeyirTokens.space3),
                      _buildHukumInput(),
                      const SizedBox(height: SeyirTokens.space4),
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

  Widget _buildLoadStatus(SeyirPalette palette) {
    if (_loadPhase == _HukumLoadPhase.loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: SeyirTokens.space3),
        child: Text('Hükümler yükleniyor', style: palette.caption()),
      );
    }
    if (_loadPhase == _HukumLoadPhase.empty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: SeyirTokens.space3),
        child: Text(
          'Bu dava için kayıtlı hüküm yok.',
          style: palette.caption(),
        ),
      );
    }
    if (_loadPhase == _HukumLoadPhase.error) {
      return Padding(
        padding: const EdgeInsets.only(bottom: SeyirTokens.space3),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _loadError ?? 'Hükümler yüklenemedi. Tekrar dene.',
                style: palette.body(color: palette.foreground(SeyirTokens.reject)),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
              ),
              onPressed: _loadExistingHukumler,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// Dava bilgilerini gösteren kutuyu oluşturur.//bu kısmı dava künyesi 2 diyorum.
  Widget _buildDavaInfo() {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(color: palette.border),
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
                child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SeyirTokens.space3,
                  vertical: SeyirTokens.space2,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '|| Dava Künyesi ||',
                        textAlign: TextAlign.center,
                        style: palette.title(),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _kunyeExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more,
                        color: palette.textSecondary,
                        size: 26,
                      ),
                    ),
                  ],
                ),
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
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                SeyirTokens.space4,
                0,
                SeyirTokens.space4,
                SeyirTokens.space3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildInfoRow(
                    'Göreviniz',
                    widget.davaGorev,
                    MdiIcons.briefcaseOutline,
                    color: SeyirPalette.of(context).foreground(SeyirTokens.brandDeep),
                  ),
                  const Divider(height: SeyirTokens.space6),
                  _buildInfoRow(
                    'Dava Adı',
                    widget.davaAdi,
                    MdiIcons.gavel,
                    color: SeyirPalette.of(context).foreground(SeyirTokens.brandDeep),
                  ),
                  const Divider(height: SeyirTokens.space6),
                  _buildInfoRow(
                    'Davacı',
                    widget.davaDavaci,
                    MdiIcons.account,
                    color: SeyirPalette.of(context).foreground(SeyirTokens.brandDeep),
                  ),
                  const Divider(height: SeyirTokens.space6),
                  _buildInfoRow(
                    'Davalı',
                    widget.davaDavali,
                    MdiIcons.accountOutline,
                    color: SeyirPalette.of(context).foreground(SeyirTokens.brandDeep),
                  ),
                  const Divider(height: SeyirTokens.space6),
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
                style: SeyirPalette.of(context).caption(weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: SeyirPalette.of(context).body(weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSection() {
    final SeyirPalette palette = SeyirPalette.of(context);
    final DateTime? openedAt = _resolvedOpenedAt ?? widget.openedAt;
    final String openedAtText = openedAt != null
        ? _formatDateTime(openedAt)
        : 'Açılış tarihi bulunamadı';
    final HukumPhaseClock? clock =
        openedAt == null ? null : _phaseClock(openedAt);
    final Color phaseColor = clock == null
        ? palette.foreground(SeyirTokens.warning)
        : seyirIncomingPhaseColor(context, clock.storageStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              MdiIcons.timerAlertOutline,
              size: 20,
              color: phaseColor,
            ),
            const SizedBox(width: SeyirTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Dava Açılış Tarihi',
                    style: palette.caption(weight: FontWeight.w600),
                  ),
                  const SizedBox(height: SeyirTokens.space1),
                  Text(
                    openedAtText,
                    style: palette.body(weight: FontWeight.w700),
                  ),

                  if (openedAt == null && widget.kalanSure.isNotEmpty) ...<Widget>[
                    const SizedBox(height: SeyirTokens.space2),
                    Text(
                      widget.kalanSure,
                      style: palette.caption(
                        weight: FontWeight.w600,
                        color: palette.foreground(SeyirTokens.sectionPeople),
                      ),
                    ),
                  ],
                  if (openedAt == null)
                    Padding(
                      padding: const EdgeInsets.only(top: SeyirTokens.space2),
                      child: Text(
                        'Süre doğrulanamadı; düzenleme kilitli.',
                        style: palette.caption(
                          color: palette.foreground(SeyirTokens.warning),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (clock != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    clock.label,
                    style: palette.caption(
                      weight: FontWeight.w700,
                      color: phaseColor,
                    ),
                  ),
                  CountdownTimerWidget(
                    key: ValueKey<String>(
                      '${clock.label}-${clock.total.inHours}',
                    ),
                    startTime: clock.start,
                    totalDuration: clock.total,
                    showHourglass: true,
                    accentColor: phaseColor,
                  ),
                ],
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
            padding: const EdgeInsets.only(bottom: SeyirTokens.space3),
            child: Material(
              color: SeyirPalette.of(context).tint(SeyirTokens.warning),
              borderRadius: SeyirTokens.radiusMdAll,
              child: Padding(
                padding: const EdgeInsets.all(SeyirTokens.space3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.lock_outline,
                      color: SeyirPalette.of(context).foreground(SeyirTokens.warning),
                    ),
                    const SizedBox(width: SeyirTokens.space2),
                    Expanded(
                      child: Text(
                        _lockReason!,
                        style: SeyirPalette.of(context).body(
                          color: SeyirPalette.of(context).foreground(SeyirTokens.warning),
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
              color: inputLocked
                  ? SeyirPalette.of(context).surfaceMuted
                  : SeyirPalette.of(context).surface,
              borderRadius: SeyirTokens.radiusLgAll,
              border: Border.all(
                color: inputLocked
                    ? SeyirPalette.of(context).border
                    : (_hukumFocusNode.hasFocus
                    ? SeyirTokens.brand
                    : SeyirPalette.of(context).border),
                width: _hukumFocusNode.hasFocus ? 2 : 1,
              ),
              boxShadow: <BoxShadow>[
                if (_hukumFocusNode.hasFocus && !inputLocked)
                  BoxShadow(
                    color: SeyirTokens.brand.withValues(alpha: 0.14),
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
              cursorColor: SeyirTokens.brand,
              cursorWidth: 3,
              cursorRadius: const Radius.circular(2),
              onTap: () {
                if (inputLocked) {
                  final String lockMessage = _isCurrentRoleFinalized
                      ? 'Bu rol için hüküm nihai hale getirildiği için düzenleme yapılamaz.'
                      : (_lockReason ?? 'Bu alanda şu anda düzenleme yapılamıyor.');
                  _showSnackBar(lockMessage, SeyirTokens.warning);
                }
              },
              decoration: InputDecoration(
                hintText: 'Hükmünü buraya yazmaya başla...',
                hintStyle: SeyirPalette.of(context).body(
                  weight: FontWeight.w400,
                  color: SeyirPalette.of(context).textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(SeyirTokens.space4),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(top: 200, right: SeyirTokens.space1),
                  child: IconButton(
                    style: IconButton.styleFrom(
                      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                    ),
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
                          ? SeyirPalette.of(context).textMuted
                          : (!_kaydetHasPendingDraftChanges &&
                                  _extractHukumBody(_hukumController.text)
                                      .trim()
                                      .isNotEmpty &&
                                  _selectedSentiment != null)
                              ? SeyirPalette.of(context).foreground(SeyirTokens.sectionPeople)
                              : (_isKaydetButtonEnabled
                                  ? SeyirTokens.brandDeep
                                  : SeyirPalette.of(context).textMuted),
                    ),
                  ),
                ),
              ),
              style: SeyirPalette.of(context).title(weight: FontWeight.w500).copyWith(height: 1.6),
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
                fontSize: SeyirTokens.typeCaption,
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
              onHukum: () async {
                final bool confirmed = await confirmHukumVerildi(context);
                if (!confirmed || !mounted) return;
                if (_roleEditLocked) {
                  _showSnackBar(
                    _lockReason ?? 'Bu alanda şu anda düzenleme yapılamıyor.',
                    SeyirTokens.warning,
                  );
                  return;
                }
                if (!_showCezaMasrafButtons) {
                  setState(() {
                    _showCezaMasrafButtons = true;
                  });
                  _cezaMasrafAnimationController?.forward(from: 0);
                  _maybeAutoFinalize();
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
    final SeyirPalette palette = SeyirPalette.of(context);
    return Material(
      color: palette.tint(SeyirTokens.sectionPeople),
      borderRadius: SeyirTokens.radiusSmAll,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: SeyirTokens.radiusSmAll,
          border: Border(
            left: BorderSide(
              color: palette.foreground(SeyirTokens.sectionPeople),
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          SeyirTokens.space3,
          SeyirTokens.space2,
          SeyirTokens.space3,
          SeyirTokens.space1,
        ),
        child: RichText(
          text: TextSpan(
            style: palette.body(),
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
    final SeyirPalette palette = SeyirPalette.of(context);
    final bool finalizedMode = _isCurrentRoleFinalized;
    final Color primaryAccent = palette.foreground(SeyirTokens.sectionPenalty);
    final Color secondaryAccent = palette.foreground(SeyirTokens.sectionGift);

    return Container(
      padding: const EdgeInsets.all(SeyirTokens.space2),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: SeyirTokens.radiusXlAll,
        border: Border.all(
          color: finalizedMode
              ? palette.border
              : primaryAccent.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (finalizedMode ? palette.shadow : primaryAccent).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (finalizedMode) _buildFinalizedSummary(palette),
          if (_showStamp) _buildStampBanner(palette),
          // Bölüm Başlığı
          Row(
            children: [
              Icon(
                MdiIcons.gavel,
                size: 20,
                color: finalizedMode ? palette.textSecondary : primaryAccent,
              ),
              const SizedBox(width: SeyirTokens.space2),
              Text(
                'Ceza ve Masraf İşlemleri',
                style: SeyirPalette.of(context).title(
                  color: finalizedMode
                      ? SeyirPalette.of(context).textSecondary
                      : SeyirPalette.of(context).textPrimary,
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
                                davaOpenedAt: _resolvedOpenedAt ?? widget.openedAt,
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
                        SeyirTokens.warning,
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
        showDone && completedLabel != null ? completedLabel : label;
    final SeyirPalette palette = SeyirPalette.of(context);
    final bool warningDone =
        showDone && completedIcon != null && completedLabel != null;
    final Color doneInk = warningDone
        ? palette.foreground(SeyirTokens.warning)
        : palette.foreground(SeyirTokens.accept);
    final Color statusColor = mutedDisabled
        ? palette.textSecondary
        : (showDone ? doneInk : activeColor);
    final Color bgColor = mutedDisabled
        ? palette.surfaceMuted
        : (showDone
            ? palette.tint(warningDone ? SeyirTokens.warning : SeyirTokens.accept)
            : activeColor.withValues(alpha: 0.08));
    final Color doneBorderColor = warningDone
        ? palette.tintBorder(SeyirTokens.warning)
        : palette.tintBorder(SeyirTokens.accept);

    return Material(
      color: bgColor,
      borderRadius: SeyirTokens.radiusLgAll,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: SeyirTokens.radiusLgAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
          padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space4),
          decoration: BoxDecoration(
            borderRadius: SeyirTokens.radiusLgAll,
            border: Border.all(
              color: mutedDisabled
                  ? palette.border
                  : (showDone ? doneBorderColor : activeColor.withValues(alpha: 0.28)),
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
                  fontSize: SeyirTokens.typeBody,
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
                    fontSize: SeyirTokens.typeBody,
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
    if (_roleEditLocked || _isCurrentRoleFinalized) return;
    if (!_cezaCompleted || !_masrafCompleted || _autoFinalizeQueued) return;
    _autoFinalizeQueued = true;
    Future.delayed(const Duration(milliseconds: 500), () async {
      _autoFinalizeQueued = false;
      if (!mounted || _roleEditLocked || _isCurrentRoleFinalized) return;
      if (_cezaCompleted && _masrafCompleted) {
        await _saveHukumForRole(
          widget.davaGorev,
          isVerdi: true,
        );
      }
    });
  }

  void _playStamp() {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _showStamp = true);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showStamp = false);
    });
  }

  Widget _buildStampBanner(SeyirPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SeyirTokens.space2),
      child: Material(
        color: palette.tint(SeyirTokens.brand),
        borderRadius: SeyirTokens.radiusMdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SeyirTokens.space3,
            vertical: SeyirTokens.space2,
          ),
          child: Row(
            children: <Widget>[
              Icon(MdiIcons.stamper, color: palette.foreground(SeyirTokens.brandDeep)),
              const SizedBox(width: SeyirTokens.space2),
              Expanded(
                child: Text(
                  'Mühürlendi',
                  style: palette.title(color: palette.foreground(SeyirTokens.brandDeep)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalizedSummary(SeyirPalette palette) {
    final String role = normalizeRolKarari(widget.davaGorev);
    final HukumSentiment? sentiment =
        _rolSentimentleri[role] ?? _selectedSentiment;
    final String ceza = (_rolCezalari[role] ?? _stampCeza).trim();
    final String masraf = (_rolMasraflari[role] ?? _stampMasraf).trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: SeyirTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Hüküm özeti', style: palette.title()),
          const SizedBox(height: SeyirTokens.space2),
          Text(
            'Yön: ${sentiment?.label ?? 'Belirtilmedi'}',
            style: palette.body(),
          ),
          Text(
            'Ceza: ${ceza.isEmpty ? 'Kayıt yok' : ceza}',
            style: palette.body(),
          ),
          Text(
            'Masraf: ${masraf.isEmpty ? 'Kayıt yok' : masraf}',
            style: palette.body(),
          ),
        ],
      ),
    );
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
        SeyirTokens.warning,
      );
      return;
    }
    if (hukumBody.length < _hukumBodyMinChars) {
      _showSnackBar(
        'Gereği düşünüldü metni en az $_hukumBodyMinChars karakter olmalıdır '
        '(şu an ${hukumBody.length}).',
        SeyirTokens.warning,
      );
      return;
    }
    if (hukumBody.length > _hukumBodyMaxChars) {
      _showSnackBar(
        'Gereği düşünüldü metni en fazla $_hukumBodyMaxChars karakter olabilir.',
        SeyirTokens.warning,
      );
      return;
    }
    if (sentiment == null) {
      _showSnackBar(
        'Lütfen hükmünüzün olumlu mu olumsuz mu olduğunu belirtmek için emojilerden birini seçin.',
        SeyirTokens.warning,
      );
      return;
    }

    final String normalizedRolAdi = normalizeRolKarari(rolAdi);
    if (_rolFinalizasyonlari[normalizedRolAdi] == true) {
      _showSnackBar(
        'Bu rol için hüküm nihai hale getirildi; düzenleme yapılamaz.',
        SeyirTokens.warning,
      );
      return;
    }

    if (_roleEditLocked) {
      _showSnackBar(
        _lockReason ?? 'Bu alanda şu anda düzenleme yapılamıyor.',
        SeyirTokens.warning,
      );
      return;
    }

    final String? davaId = _stableDavaId;
    if (davaId == null) {
      _showSnackBar(
        'Dava kimliği yok. Kayıt bölünmesin diye hüküm yazılmadı. Tekrar dene.',
        SeyirTokens.reject,
      );
      return;
    }
    final bool nextFinalizationState = isVerdi;
    final String fullText = '$_hukumPrefix$hukumBody';

    try {
      if ((widget.userEmail ?? '').isNotEmpty) {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        final bool providerOk = await davaProvider.updateHukumForDava(
          davaId: davaId,
          userRole: normalizedRolAdi,
          hukumText: fullText,
          userEmail: widget.userEmail!,
          hukumSentiment: sentiment.storageValue,
          isFinalized: nextFinalizationState,
        );
        if (!providerOk) {
          throw StateError('Hüküm kaydedilemedi');
        }

        if (isVerdi && DavaHukumEligibilityService.roleLabelIsTemyiz(rolAdi)) {
          await HiveDatabaseService.updateOpenedDava(davaId, {
            'appealJudgeSentiment': sentiment.storageValue,
            'appealJudgeRuledAt': DateTime.now().toIso8601String(),
          });
        }

        if (isVerdi) {
          final Map<String, dynamic>? feedPost =
              HiveDatabaseService.composeHomeFeedDavaSharePostAfterHukumFinalized(
            davaId: davaId,
            userEmail: widget.userEmail!,
            fallbackSnapshot: <String, dynamic>{
              'id': davaId,
              'davaAdi': widget.davaAdi,
              'davaci': widget.davaDavaci,
              'davali': widget.davaDavali,
              'davaKonusu': '',
              'kategori': '',
              'davaKategorisi': '',
              'openedAt': (_resolvedOpenedAt ?? widget.openedAt)?.toIso8601String(),
            },
          );
          if (feedPost != null) {
            HiveDatabaseService.addHomeFeedPost(feedPost,
                userEmail: widget.userEmail);
            await davaProvider.refreshHomeFeedSilent(widget.userEmail!);
          }
        }
      } else {
        final bool saved = await HiveDatabaseService.saveHukum(
          davaId: davaId,
          userRole: normalizedRolAdi,
          hukumText: fullText,
          userEmail: '',
          hukumSentiment: sentiment.storageValue,
          isFinalized: nextFinalizationState,
        );
        if (!saved) {
          throw StateError('Hüküm kaydedilemedi');
        }
      }

      if (!mounted) return;
      setState(() {
        _rolHukumleri[normalizedRolAdi] = fullText;
        _rolSentimentleri[normalizedRolAdi] = sentiment;
        _rolFinalizasyonlari[normalizedRolAdi] = nextFinalizationState;
        _isCurrentRoleFinalized = nextFinalizationState;
        _selectedSentiment = sentiment;
        _kaydetBaselineTrimmedBody = hukumBody;
        _kaydetBaselineSentiment = sentiment;
        if (isVerdi) {
          _showCezaMasrafButtons = false;
        } else {
          _hukumController.text = fullText;
          _hukumController.selection = TextSelection.collapsed(
            offset: _hukumController.text.length,
          );
        }
      });

      if (isVerdi) {
        _playStamp();
      } else {
        HapticFeedback.lightImpact();
      }

      final String successMessage = isVerdi
          ? '$rolAdi için hüküm verildi'
          : '$rolAdi için hüküm kaydedildi';

      _showSnackBar(
        successMessage,
        isVerdi ? SeyirTokens.accept : SeyirTokens.brandDeep,
      );

      widget.onHukumSave?.call(fullText);
      await _loadExistingHukumler();

      if (isVerdi && mounted) {
        setState(() {
          _isCurrentRoleFinalized = true;
          _rolFinalizasyonlari[normalizedRolAdi] = true;
          _showCezaMasrafButtons = false;
        });
      }

      if (!isVerdi && mounted) {
        setState(() {
          _hukumController.value = TextEditingValue(
            text: fullText,
            selection: TextSelection.collapsed(offset: fullText.length),
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Hüküm kaydedilemedi. Tekrar dene.',
        SeyirTokens.reject,
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
    final SeyirPalette palette = SeyirPalette.of(context);
    final String body = _extractHukumBody(_hukumController.text);
    if (body.isEmpty) {
      return palette.textMuted;
    }
    if (body.trim().length >= _hukumBodyMinChars &&
        body.length <= _hukumBodyMaxChars) {
      return palette.textMuted;
    }
    return palette.foreground(SeyirTokens.warning);
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
            Icon(
              Icons.check_rounded,
              color: SeyirPalette.of(context).onSolid(accentColor),
              size: 20,
            ),
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
            style: TextStyle(
              fontSize: SeyirTokens.typeBody,
              color: SeyirPalette.of(context).onSolid(backgroundColor),
            ),
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

