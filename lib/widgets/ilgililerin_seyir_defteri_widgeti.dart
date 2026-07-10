import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/evidence_comment_model.dart';
import '../models/evidence_model.dart';
import '../models/hukum_sentiment.dart';
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../services/dava_appeal_judge_assign_service.dart';
import '../services/ceza_consensus_service.dart';
import '../services/hediye_consensus_service.dart';
import '../services/dava_consensus_service.dart';
import '../services/dava_timer_service.dart';
import '../services/evidence_comment_service.dart';
import '../services/evidence_service.dart';
import '../services/hive_database_service.dart';
import '../utils/comment_utils.dart';
import 'comment_section.dart';
import 'rol_hukum_kartlari_section.dart';

/// [KatildigimDavalarPage] / [ActigimDavaCard] ile aynı birleştirme: gerçek `davaId` ve
/// `dava_${davaAdi.hashCode}` altındaki kayıtlar tek haritada toplanır.
Map<String, Map<String, dynamic>> _mergeSeyirHukumlerGroupedMaps(
    List<Map<String, Map<String, dynamic>>> parts,
    ) {
  final Map<String, Map<String, dynamic>> out = <String, Map<String, dynamic>>{};
  for (final Map<String, Map<String, dynamic>> part in parts) {
    for (final MapEntry<String, Map<String, dynamic>> e in part.entries) {
      final String roleFromRow =
      (e.value['userRole'] as String?)?.trim().isNotEmpty == true
          ? (e.value['userRole'] as String)
          : e.key;
      final String nk = normalizeRolKarari(roleFromRow);
      final String newText = (e.value['hukumText'] as String?)?.trim() ?? '';
      final Map<String, dynamic>? prev = out[nk];
      final String oldText = (prev?['hukumText'] as String?)?.trim() ?? '';
      if (prev == null) {
        out[nk] = Map<String, dynamic>.from(e.value)..['userRole'] = nk;
      } else if (newText.isNotEmpty &&
          (oldText.isEmpty || newText.length > oldText.length)) {
        out[nk] = Map<String, dynamic>.from(e.value)..['userRole'] = nk;
      }
    }
  }
  return out;
}

class IlgililerinSeyirDefteriWidgeti extends StatefulWidget {
  final String? davaId;
  final String? userEmail;
  final String? davaAdi;
  final String? davaci;
  final String? davali;
  final String? kategori;
  final String? davaKonusu;
  final DateTime? openedAt;
  final VoidCallback? onClose;
  final VoidCallback? onRemove;
  final VoidCallback? onToggleCollapse;
  /// Ana sayfa akışındaki kaynak post (yorum/retweet senkronu).
  final String? feedPostId;
  final String? sourceAuthorEmail;
  final bool initiallyCollapsed;
  final bool? collapsed;
  final String? kullaniciGorev;

  const IlgililerinSeyirDefteriWidgeti({
    super.key,
    this.davaId,
    this.userEmail,
    this.davaAdi,
    this.davaci,
    this.davali,
    this.kategori,
    this.davaKonusu,
    this.openedAt,
    this.onClose,
    this.onRemove,
    this.onToggleCollapse,
    this.feedPostId,
    this.sourceAuthorEmail,
    this.initiallyCollapsed = false,
    this.collapsed,
    this.kullaniciGorev,
  });

  @override
  State<IlgililerinSeyirDefteriWidgeti> createState() => _IlgililerinSeyirDefteriWidgetiState();
}

class _IlgililerinSeyirDefteriWidgetiState extends State<IlgililerinSeyirDefteriWidgeti>
    with AutomaticKeepAliveClientMixin {
  bool showDetails = true;
  bool isLiked = false;
  bool isDisliked = false;
  bool isRetweeted = false;
  bool isSaved = false;
  bool _engagementMenuOpen = false;
  bool _showComments = false;
  bool _yorumGizliTanik = false;
  bool _isSendingComment = false;
  List<Map<String, dynamic>> _yorumlar = <Map<String, dynamic>>[];

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  bool get wantKeepAlive => _engagementMenuOpen || _showComments || showDetails;

  int yorumSayisi = 0;
  int retweetSayisi = 0;
  int begeniSayisi = 0;
  int begenmemeSayisi = 0;
  int goruntulenmeSayisi = 0;
  int paylasSayisi = 0;

  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _rejecters = [];
  bool _isLoadingRejecters = false;

  Future<_DelillerHakkindaBundle>? _delillerHakkindaFuture;
  Future<_UygunCezalarBundle>? _uygunCezalarFuture;
  Future<_HediyelerBundle>? _hediyelerFuture;

  String _davaAdi = '';
  String _davaci = '';
  String _davali = '';
  String _kategori = '';
  String _davaKonusu = '';
  DateTime? _openedAt;

  List<Map<String, String>> get caseDetails {
    return [
      if (_kategori.isNotEmpty) {"label": "Dava kategorisi", "value": _kategori},
      if (_davaci.isNotEmpty) {"label": "Davacı", "value": _davaci},
      if (_davali.isNotEmpty) {"label": "Davalı", "value": _davali},
    ];
  }

  // 🎨 GÜNCELLENMİŞ: Bölüm bazlı ikon ve renk eşleştirmeleri
  static const Map<String, MapEntry<Color, IconData>> _sectionStyles = {
    "Davayı Yorumlamayı Kabul ve Red Edenler": MapEntry(Colors.blue, Icons.people_outline),
    "Deliller Hakkında": MapEntry(Colors.purple, Icons.receipt_long_outlined),
    "Uygun Görülen Cezalar": MapEntry(Colors.red, Icons.scale_outlined),
    "Ceza Onayı": MapEntry(Colors.indigo, Icons.fact_check_outlined),
    "Uygun Görülen Hediyeler": MapEntry(Colors.pink, Icons.redeem_outlined),
    "Hediye Onayı": MapEntry(Colors.amber, Icons.schedule_send_outlined),
  };

  final List<String> expandableItems = [
    "Davayı Yorumlamayı Kabul ve Red Edenler",
    "Deliller Hakkında",
    "Uygun Görülen Cezalar",
    "Ceza Onayı",
    "Uygun Görülen Hediyeler",
    "Hediye Onayı",
  ];

  String _kullaniciGorevResolved = '';
  final Map<String, String> _rolHukumleri = <String, String>{};
  final Map<String, HukumSentiment> _rolSentimentleri = <String, HukumSentiment>{};
  final Map<String, String> _rolCezalari = <String, String>{};
  final Map<String, String> _rolMasraflari = <String, String>{};
  HukumSentiment? _rolSeciliSentiment;
  DavaConsensusEvaluation? _rolConsensusEvaluation;
  bool _rolConsensusLoading = false;

  bool get _canRefreshRolConsensus {
    final String id = widget.davaId?.trim() ?? '';
    return id.isNotEmpty;
  }

  String _effectiveDavaAdi() => (widget.davaAdi ?? _davaAdi).trim();

  String _resolveKullaniciGorev() {
    final String? w = widget.kullaniciGorev?.trim();
    if (w != null && w.isNotEmpty) {
      return w;
    }
    final String email = widget.userEmail?.trim() ?? '';
    final String id = widget.davaId?.trim() ?? '';
    if (email.isEmpty || id.isEmpty) {
      return '';
    }
    final List<Map<String, dynamic>> katildim =
    HiveDatabaseService.getKatildigimDavalar(email);
    for (final Map<String, dynamic> d in katildim) {
      final String did =
      (d['id'] ?? d['davaId'] ?? '').toString().trim();
      if (did == id) {
        return (d['mevkii'] ?? d['userRole'] ?? '').toString().trim();
      }
    }
    final List<Map<String, dynamic>> incoming =
    HiveDatabaseService.getIncomingDavalar(email);
    for (final Map<String, dynamic> d in incoming) {
      if ((d['id'] ?? '').toString().trim() == id) {
        return (d['mevkii'] ?? d['userRole'] ?? '').toString().trim();
      }
    }
    return '';
  }

  Future<void> _loadRolConsensusEvaluation() async {
    final String davaId = widget.davaId?.trim() ?? '';
    if (davaId.isEmpty) {
      return;
    }
    if (mounted) {
      setState(() {
        _rolConsensusLoading = true;
      });
    }
    try {
      DateTime? openedAt = widget.openedAt ?? _openedAt;
      if (openedAt == null && widget.davaId != null && widget.davaId!.isNotEmpty) {
        final List<Map<String, dynamic>> opened =
        HiveDatabaseService.getOpenedDavalar();
        final Map<String, dynamic> row = opened.firstWhere(
              (Map<String, dynamic> d) => d['id'] == widget.davaId,
          orElse: () => <String, dynamic>{},
        );
        final String? s = row['openedAt'] as String?;
        if (s != null && s.isNotEmpty) {
          openedAt = DateTime.tryParse(s);
        }
      }
      final DavaConsensusEvaluation evaluation =
      await DavaConsensusService.evaluateConsensus(
        davaId: davaId,
        openedAt: openedAt,
      );
      if (mounted) {
        setState(() {
          _rolConsensusEvaluation = evaluation;
          _rolConsensusLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rolConsensusLoading = false;
        });
      }
    }
  }

  Future<void> _loadRolHukumMaps() async {
    final String pid = widget.davaId?.trim() ?? '';
    final String davaAdi = _effectiveDavaAdi();
    final String? hid =
    davaAdi.isNotEmpty ? 'dava_${davaAdi.hashCode}' : null;
    if (pid.isEmpty && (hid == null || hid.isEmpty)) {
      return;
    }
    try {
      final List<Map<String, Map<String, dynamic>>> idChunks =
      <Map<String, Map<String, dynamic>>>[];
      if (pid.isNotEmpty) {
        Map<String, Map<String, dynamic>> byPid = <String, Map<String, dynamic>>{};
        try {
          final DavaProvider davaProvider =
          Provider.of<DavaProvider>(context, listen: false);
          byPid = await davaProvider.getHukumlerByDavaId(
            pid,
            davaAdi: davaAdi.isNotEmpty ? davaAdi : null,
          );
        } catch (_) {
          byPid = <String, Map<String, dynamic>>{};
        }
        if (byPid.isEmpty) {
          byPid = await HiveDatabaseService.getHukumlerByDavaIdGrouped(
            pid,
            davaAdi: davaAdi.isNotEmpty ? davaAdi : null,
          );
        }
        if (byPid.isNotEmpty) {
          idChunks.add(byPid);
        }
      }
      if (hid != null && (pid.isEmpty || hid != pid)) {
        final Map<String, Map<String, dynamic>> byHid =
        await HiveDatabaseService.getHukumlerByDavaIdGrouped(
          hid,
          davaAdi: davaAdi.isNotEmpty ? davaAdi : null,
        );
        if (byHid.isNotEmpty) {
          idChunks.add(byHid);
        }
      }
      final Map<String, Map<String, dynamic>> existing =
      _mergeSeyirHukumlerGroupedMaps(idChunks);
      if (!mounted) {
        return;
      }
      final String cezaPrimaryId = pid.isNotEmpty ? pid : (hid ?? '');
      Map<String, String> cezalarByEmail = <String, String>{};
      Map<String, String> masraflarByEmail = <String, String>{};
      if (cezaPrimaryId.isNotEmpty) {
        cezalarByEmail = Map<String, String>.from(
          await HiveDatabaseService.getCezaMapForDavaId(cezaPrimaryId),
        );
        masraflarByEmail = Map<String, String>.from(
          await HiveDatabaseService.getMasrafGiftLineMapForDavaId(cezaPrimaryId),
        );
      }
      if (hid != null) {
        final Map<String, String> cezaAlt =
        await HiveDatabaseService.getCezaMapForDavaId(hid);
        final Map<String, String> masrafAlt =
        await HiveDatabaseService.getMasrafGiftLineMapForDavaId(hid);
        for (final MapEntry<String, String> e in cezaAlt.entries) {
          cezalarByEmail.putIfAbsent(e.key, () => e.value);
        }
        for (final MapEntry<String, String> e in masrafAlt.entries) {
          masraflarByEmail.putIfAbsent(e.key, () => e.value);
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _rolHukumleri
          ..clear()
          ..addEntries(
            existing.entries.where((MapEntry<String, Map<String, dynamic>> entry) {
              final dynamic text = entry.value['hukumText'];
              return (text is String) && text.trim().isNotEmpty;
            }).map((MapEntry<String, Map<String, dynamic>> entry) {
              final String normalizedKey = normalizeRolKarari(entry.key);
              return MapEntry<String, String>(
                normalizedKey,
                entry.value['hukumText'].toString(),
              );
            }),
          );
        _rolSentimentleri.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry
        in existing.entries) {
          final String? sentimentValue =
          entry.value['hukumSentiment'] as String?;
          final HukumSentiment? sentiment =
          hukumSentimentFromStorage(sentimentValue);
          final String normalizedKey = normalizeRolKarari(entry.key);
          if (sentiment != null) {
            _rolSentimentleri[normalizedKey] = sentiment;
          }
        }
        _rolCezalari.clear();
        _rolMasraflari.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry
        in existing.entries) {
          final String roleFromRow =
          (entry.value['userRole'] as String?)?.trim().isNotEmpty == true
              ? (entry.value['userRole'] as String)
              : entry.key;
          final String normalizedKey = normalizeRolKarari(roleFromRow);
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
        _kullaniciGorevResolved = _resolveKullaniciGorev();
        final String normalizedUserRole =
        normalizeRolKarari(_kullaniciGorevResolved);
        _rolSeciliSentiment = _rolSentimentleri[normalizedUserRole];
      });
    } catch (e) {
      // Sessiz: seyir defteri salt okunur; hüküm yoksa kartlar boş kalır.
    }
  }

  Future<void> _refreshRolHukumSection() async {
    await Future.wait(<Future<void>>[
      _loadRolHukumMaps(),
      _loadRolConsensusEvaluation(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _kullaniciGorevResolved = _resolveKullaniciGorev();
    final isCollapsed = widget.collapsed ?? widget.initiallyCollapsed;
    showDetails = !isCollapsed;
    _loadDavaInfo();
    _loadEngagementData();
    _loadComments();
    if (widget.davaId != null && widget.davaId!.isNotEmpty) {
      _loadParticipants();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.davaId != null && widget.davaId!.trim().isNotEmpty) {
        _refreshRolHukumSection();
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant IlgililerinSeyirDefteriWidgeti oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prev = oldWidget.collapsed ?? oldWidget.initiallyCollapsed;
    final next = widget.collapsed ?? widget.initiallyCollapsed;
    if (prev != next) {
      setState(() {
        showDetails = !next;
        if (showDetails) {
          _closeEngagementMenu();
        }
      });
    }
    if (oldWidget.davaId != widget.davaId ||
        oldWidget.userEmail != widget.userEmail ||
        oldWidget.davaAdi != widget.davaAdi ||
        oldWidget.openedAt != widget.openedAt ||
        oldWidget.kullaniciGorev != widget.kullaniciGorev) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            widget.davaId != null &&
            widget.davaId!.trim().isNotEmpty) {
          _refreshRolHukumSection();
        }
      });
    }
  }

  void _loadDavaInfo() {
    _davaAdi = widget.davaAdi ?? '';
    _davaci = widget.davaci ?? '';
    _davali = widget.davali ?? '';
    _kategori = widget.kategori ?? '';
    _davaKonusu = widget.davaKonusu ?? '';
    _openedAt = widget.openedAt;

    if (widget.davaId != null && widget.davaId!.isNotEmpty) {
      if (_davaAdi.isEmpty ||
          _davaci.isEmpty ||
          _davali.isEmpty ||
          _openedAt == null) {
        _loadDavaInfoFromDatabase();
      }
    }
  }

  void _loadDavaInfoFromDatabase() {
    try {
      final openedDavalar = HiveDatabaseService.getOpenedDavalar();
      final dava = openedDavalar.firstWhere(
            (d) => d['id'] == widget.davaId,
        orElse: () => <String, dynamic>{},
      );

      if (dava.isNotEmpty) {
        setState(() {
          _davaAdi = _davaAdi.isEmpty
              ? (dava['davaAdi'] ?? dava['adi'] ?? '').toString().trim()
              : _davaAdi;
          _davaci = _davaci.isEmpty
              ? (dava['davaci'] ?? '').toString().trim()
              : _davaci;
          _davali = _davali.isEmpty
              ? (dava['davali'] ?? '').toString().trim()
              : _davali;
          _kategori = _kategori.isEmpty
              ? (dava['kategori'] ?? dava['davaKategori'] ?? '').toString().trim()
              : _kategori;
          _davaKonusu = _davaKonusu.isEmpty
              ? (dava['davaKonusu'] ?? '').toString().trim()
              : _davaKonusu;

          if (_openedAt == null && dava['openedAt'] != null) {
            try {
              _openedAt = DateTime.parse(dava['openedAt'].toString());
            } catch (e) {
              _openedAt = null;
            }
          }
          if (_openedAt == null && dava['createdAt'] != null) {
            try {
              _openedAt = DateTime.parse(dava['createdAt'].toString());
            } catch (e) {
              _openedAt = null;
            }
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              widget.davaId != null &&
              widget.davaId!.trim().isNotEmpty) {
            _refreshRolHukumSection();
          }
        });
        return;
      }

      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        final incomingDavalar = HiveDatabaseService.getIncomingDavalar(widget.userEmail!);
        final incomingDava = incomingDavalar.firstWhere(
              (d) => d['id'] == widget.davaId,
          orElse: () => <String, dynamic>{},
        );

        if (incomingDava.isNotEmpty) {
          setState(() {
            _davaAdi = _davaAdi.isEmpty
                ? (incomingDava['davaAdi'] ?? incomingDava['adi'] ?? '').toString().trim()
                : _davaAdi;
            _davaci = _davaci.isEmpty
                ? (incomingDava['davaci'] ?? '').toString().trim()
                : _davaci;
            _davali = _davali.isEmpty
                ? (incomingDava['davali'] ?? '').toString().trim()
                : _davali;
            _kategori = _kategori.isEmpty
                ? (incomingDava['kategori'] ?? incomingDava['davaKategori'] ?? '').toString().trim()
                : _kategori;
            _davaKonusu = _davaKonusu.isEmpty
                ? (incomingDava['davaKonusu'] ?? '').toString().trim()
                : _davaKonusu;

            if (_openedAt == null && incomingDava['openedAt'] != null) {
              try {
                _openedAt = DateTime.parse(incomingDava['openedAt'].toString());
              } catch (e) {
                _openedAt = null;
              }
            }
            if (_openedAt == null && incomingDava['createdAt'] != null) {
              try {
                _openedAt = DateTime.parse(incomingDava['createdAt'].toString());
              } catch (e) {
                _openedAt = null;
              }
            }
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                widget.davaId != null &&
                widget.davaId!.trim().isNotEmpty) {
              _refreshRolHukumSection();
            }
          });
        }
      }
    } catch (e) {
      print('❌ Dava bilgileri yüklenirken hata: $e');
    }
  }

  Future<void> _loadParticipants() async {
    if (widget.davaId == null || widget.davaId!.isEmpty) return;

    setState(() {
      _isLoadingRejecters = true;
    });

    try {
      final participants = await HiveDatabaseService.getDavaParticipants(widget.davaId!);
      if (!mounted) return;
      setState(() {
        _participants = participants;
        _rejecters = participants
            .where((p) {
          final status = p['status']?.toString();
          return status == 'manual_rejected' || status == 'auto_rejected' || status == 'rejected';
        })
            .toList();
        _isLoadingRejecters = false;
      });
    } catch (e) {
      print('❌ Red eden kişiler yüklenirken hata: $e');
      setState(() {
        _isLoadingRejecters = false;
      });
    }
  }

  String _buildDavaDescription() {
    final parts = <String>[];

    if (_davaci.isNotEmpty) {
      parts.add('"$_davaci"');
    }

    if (_davali.isNotEmpty) {
      parts.add('"$_davali"ya');
    }

    if (_kategori.isNotEmpty) {
      parts.add('"$_kategori" kategorisinde');
    }

    final davaAdiText = _davaAdi.isNotEmpty ? _davaAdi : 'Dava Adı Belirtilmemiş';
    parts.add('"$davaAdiText" adlı davayı');

    final tarihText = _openedAt != null
        ? '${_openedAt!.day.toString().padLeft(2, '0')}.${_openedAt!.month.toString().padLeft(2, '0')}.${_openedAt!.year}'
        : DateTime.now().toString().substring(0, 10).replaceAll('-', '.');
    parts.add('"$tarihText" tarihi ile açmış bulunuyor.');

    final description = parts.join(' ');

    if (description.trim().isEmpty || description == '"Dava Adı Belirtilmemiş" adlı davayı "..." tarihi ile açmış bulunuyor.') {
      return 'Dava bilgileri yükleniyor...';
    }

    return description;
  }

  String _formatHeaderDate() {
    final date = widget.openedAt ?? _openedAt;
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _headerTitle() {
    final ad = _effectiveDavaAdi();
    return (ad.isNotEmpty ? ad : 'DAVA').toUpperCase();
  }

  void _loadEngagementData() {
    final davaId = widget.davaId?.trim() ?? '';
    if (davaId.isEmpty) return;

    try {
      final stats = HiveDatabaseService.getDavaActionStats(davaId);
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        final userAction = HiveDatabaseService.getUserDavaAction(davaId, widget.userEmail!);
        isLiked = userAction['like'] == true;
        isDisliked = userAction['dislike'] == true;
        yorumSayisi = userAction['commentCount'] as int? ?? 0;
        paylasSayisi = userAction['sharedAt'] != null ? 1 : 0;
      }

      begeniSayisi = stats['totalLikes'] as int? ?? 0;
      begenmemeSayisi = stats['totalDislikes'] as int? ?? 0;
      yorumSayisi = stats['totalComments'] as int? ?? yorumSayisi;
      paylasSayisi = stats['totalShares'] as int? ?? paylasSayisi;

      final opened = HiveDatabaseService.getOpenedDavalar();
      Map<String, dynamic>? row;
      for (final d in opened) {
        if ((d['id']?.toString() ?? '') == davaId) {
          row = Map<String, dynamic>.from(d);
          break;
        }
      }
      if (row != null) {
        retweetSayisi = row['retweetSayisi'] as int? ?? retweetSayisi;
        isRetweeted = row['userRetweeted'] == true;
        goruntulenmeSayisi = row['goruntulenmeSayisi'] as int? ??
            row['viewCount'] as int? ??
            goruntulenmeSayisi;
        isLiked = row['userLiked'] == true || isLiked;
        isDisliked = row['userDisliked'] == true || isDisliked;
        begeniSayisi = row['begeniSayisi'] as int? ?? begeniSayisi;
        begenmemeSayisi = row['begenmemeSayisi'] as int? ?? begenmemeSayisi;
        yorumSayisi = row['yorumSayisi'] as int? ?? yorumSayisi;
      }

      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        isRetweeted = HiveDatabaseService.hasUserRetweetedDava(davaId, widget.userEmail!) ||
            isRetweeted;
      }
    } catch (e) {
      // Engagement yüklenemezse varsayılanlarla devam et.
    }
  }

  void _loadComments() {
    final davaId = widget.davaId?.trim() ?? '';
    if (davaId.isEmpty) return;
    _yorumlar = HiveDatabaseService.getAllDavaComments(davaId);
    yorumSayisi = CommentUtils.countAllComments(_yorumlar);
  }

  Map<String, dynamic> _buildDavaPayloadSnapshot() {
    return <String, dynamic>{
      'id': widget.davaId,
      'davaId': widget.davaId,
      'davaAdi': _effectiveDavaAdi(),
      'adi': _effectiveDavaAdi(),
      'davaci': _davaci,
      'davali': _davali,
      'kategori': _kategori,
      'davaKonusu': _davaKonusu,
      'openedAt': (widget.openedAt ?? _openedAt)?.toIso8601String(),
      'yorumSayisi': yorumSayisi,
      'retweetSayisi': retweetSayisi,
      'begeniSayisi': begeniSayisi,
      'begenmemeSayisi': begenmemeSayisi,
      'goruntulenmeSayisi': goruntulenmeSayisi,
    };
  }

  Future<void> _syncCommentsToStores() async {
    final davaId = widget.davaId?.trim() ?? '';
    final userEmail = widget.userEmail?.trim() ?? '';
    if (davaId.isEmpty) return;

    _loadComments();
    final count = CommentUtils.countAllComments(_yorumlar);

    final provider = context.read<DavaProvider>();
    await provider.updateDavaEngagement(
      davaId: davaId,
      yorumSayisi: count,
      yorumlar: _yorumlar,
      userEmail: userEmail.isNotEmpty ? userEmail : null,
    );

    final postId = widget.feedPostId?.trim() ?? '';
    if (postId.isNotEmpty && userEmail.isNotEmpty) {
      final post = HiveDatabaseService.getHomeFeedPostById(postId, userEmail: userEmail);
      if (post != null) {
        final updated = Map<String, dynamic>.from(post);
        final payload = Map<String, dynamic>.from(
          (updated['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
        );
        payload['yorumlar'] = _yorumlar;
        payload['yorumSayisi'] = count;
        updated['payload'] = payload;
        await provider.updateHomeFeedPost(postId, updated);
      }
    }
  }

  String _effectiveUserEmail() {
    final fromWidget = widget.userEmail?.trim() ?? '';
    if (fromWidget.isNotEmpty) return fromWidget;
    try {
      final auth = context.read<AuthProvider>();
      return auth.currentUser?.email.trim() ?? auth.userEmail?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  bool get _canWriteComments {
    final davaId = widget.davaId?.trim() ?? '';
    return davaId.isNotEmpty && _effectiveUserEmail().isNotEmpty;
  }

  Future<void> _submitComment(
    String yorumMetni, {
    String? parentCommentId,
    bool isGizliTanik = false,
  }) async {
    final davaId = widget.davaId?.trim() ?? '';
    final userEmail = _effectiveUserEmail();
    if (davaId.isEmpty || userEmail.isEmpty) {
      _showEngagementSnack('Yorum yazmak için giriş yapmanız gerekir.');
      return;
    }

    final userAction = HiveDatabaseService.getUserDavaAction(davaId, userEmail);
    final commentCount = userAction['commentCount'] as int? ?? 0;
    if (commentCount >= 19) {
      _showEngagementSnack('⚠️ Maksimum yorum sayısına ulaşıldı (19/19)');
      return;
    }

    final success = await HiveDatabaseService.addDavaComment(
      davaId,
      userEmail,
      yorumMetni: yorumMetni,
      isGizliTanik: isGizliTanik,
      parentCommentId: parentCommentId,
    );

    if (!mounted) return;

    if (success) {
      await _syncCommentsToStores();
      if (parentCommentId == null) {
        _commentController.clear();
        setState(() => _yorumGizliTanik = false);
      }
      setState(() {});
      _showEngagementSnack(
        '💬 Yorum eklendi (${commentCount + 1}/19)${isGizliTanik ? ' (Gizli Tanık)' : ''}',
      );
    } else {
      _showEngagementSnack(
        '⚠️ Yorum eklenemedi. 19 saniye kuralı veya limit nedeniyle engellenmiş olabilir.',
      );
    }
  }

  String? _currentUserDisplayName() {
    final email = widget.userEmail?.trim() ?? '';
    if (email.isEmpty) return null;
    final user = HiveDatabaseService.getRegistrationByEmail(email);
    return user?.judgeName ?? email.split('@').first;
  }

  void _closeEngagementMenu() {
    if (!_engagementMenuOpen) return;
    setState(() => _engagementMenuOpen = false);
  }

  void _toggleEngagementMenu() {
    if (showDetails) return;
    setState(() {
      _engagementMenuOpen = !_engagementMenuOpen;
      if (_engagementMenuOpen) {
        goruntulenmeSayisi++;
      }
    });
  }

  void _showEngagementSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _handleEngagementAction(String type) async {
    final davaId = widget.davaId?.trim() ?? '';
    final userEmail = _effectiveUserEmail();

    if (type == 'comment') {
      final opening = !_showComments;
      setState(() {
        _showComments = !_showComments;
        if (_showComments) {
          _loadComments();
        }
      });
      if (opening && _canWriteComments) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _commentFocusNode.requestFocus();
        });
      }
      return;
    }

    if (davaId.isEmpty || userEmail.isEmpty) {
      _showEngagementSnack('Bu işlem için giriş yapmanız gerekir.');
      return;
    }

    final provider = context.read<DavaProvider>();

    try {
      switch (type) {
        case 'retweet':
          if (isRetweeted) {
            final undone = await HiveDatabaseService.undoRetweetDavaFromSeyirDefteri(
              davaId,
              userEmail,
            );
            if (!undone) {
              _showEngagementSnack('Retweet kaydı bulunamadı');
              return;
            }
            final newCount = (retweetSayisi - 1).clamp(0, 999999);
            await provider.updateDavaEngagement(
              davaId: davaId,
              retweetSayisi: newCount,
              userRetweeted: false,
              userEmail: userEmail,
            );
            await provider.refreshHomeFeedSilent(userEmail);
            if (!mounted) return;
            setState(() {
              isRetweeted = false;
              retweetSayisi = newCount;
            });
            _showEngagementSnack('Retweet kaldırıldı');
          } else {
            final added = await HiveDatabaseService.retweetDavaToSeyirDefteri(
              davaId: davaId,
              userEmail: userEmail,
              sourcePostId: widget.feedPostId,
              sourceAuthorEmail: widget.sourceAuthorEmail,
              payloadOverride: _buildDavaPayloadSnapshot(),
            );
            if (!added) {
              _showEngagementSnack('Retweet zaten yapılmış veya dava verisi bulunamadı');
              return;
            }
            final newCount = retweetSayisi + 1;
            await provider.updateDavaEngagement(
              davaId: davaId,
              retweetSayisi: newCount,
              userRetweeted: true,
              userEmail: userEmail,
            );
            await provider.refreshHomeFeedSilent(userEmail);
            if (!mounted) return;
            setState(() {
              isRetweeted = true;
              retweetSayisi = newCount;
            });
            _showEngagementSnack('🔁 Seyir defterinize eklendi');
          }
          break;
        case 'like':
          await HiveDatabaseService.toggleDavaLike(davaId, userEmail, true);
          _loadEngagementData();
          setState(() {});
          _showEngagementSnack(isLiked ? '❤️ Beğeni kaldırıldı' : '❤️ Beğenildi');
          break;
        case 'dislike':
          await HiveDatabaseService.toggleDavaLike(davaId, userEmail, false);
          _loadEngagementData();
          setState(() {});
          _showEngagementSnack(isDisliked ? 'Kına kaldırıldı' : '👎 Kına gönderildi');
          break;
        case 'save':
          setState(() => isSaved = !isSaved);
          _showEngagementSnack(isSaved ? '🔖 Kaydedildi' : 'Kayıt kaldırıldı');
          break;
        case 'share':
          final userAction = HiveDatabaseService.getUserDavaAction(davaId, userEmail);
          if (userAction['sharedAt'] != null) {
            _showEngagementSnack('Bu davayı zaten paylaştınız');
            return;
          }
          await HiveDatabaseService.shareDava(davaId, userEmail);
          _loadEngagementData();
          setState(() {});
          _showEngagementSnack('📤 Paylaşıldı');
          break;
        case 'view':
          _showEngagementSnack('👁️ $goruntulenmeSayisi görüntülenme');
          break;
        case 'remove':
          widget.onRemove?.call();
          _closeEngagementMenu();
          break;
      }
    } catch (e) {
      _showEngagementSnack('İşlem tamamlanamadı');
    }
  }

  Widget _buildCollapsedHeaderSection() {
    final isCollapsed = !showDetails;
    final showEngagementRow = isCollapsed && _engagementMenuOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCollapsedHeaderRow(isCollapsed: isCollapsed),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: showEngagementRow
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTwitterEngagementRow(),
                    if (_showComments) _buildCommentsPanel(),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _sendCommentFromPanel() async {
    if (_isSendingComment || !_canWriteComments) return;
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      _showEngagementSnack('Lütfen bir yorum yazın');
      return;
    }
    setState(() => _isSendingComment = true);
    try {
      await _submitComment(text, isGizliTanik: _yorumGizliTanik);
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Widget _buildCommentsPanel() {
    final normalized = CommentUtils.normalizeComments(_yorumlar);
    final canWrite = _canWriteComments;

    return Material(
      color: const Color(0xFFF9FAFB),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Yorumlar (${CommentUtils.countAllComments(normalized)})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!canWrite)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Yorum yazmak için giriş yapın ve dava kimliğinin yüklü olması gerekir.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              )
            else ...[
              Text(
                'Yorum türü',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Normal yorum'),
                      selected: !_yorumGizliTanik,
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() => _yorumGizliTanik = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Gizli Tanık'),
                      selected: _yorumGizliTanik,
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() => _yorumGizliTanik = true);
                      },
                    ),
                  ),
                ],
              ),
              if (_yorumGizliTanik)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Yorumunuz "${HiveDatabaseService.gizliTanikDisplayName}" adıyla görünecektir.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                enabled: canWrite && !_isSendingComment,
                decoration: InputDecoration(
                  hintText: _yorumGizliTanik
                      ? 'Gizli tanık yorumunuzu yazın...'
                      : 'Yorumunuzu yazın...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                minLines: 2,
                maxLines: 5,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isSendingComment ? null : _sendCommentFromPanel,
                  icon: _isSendingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(_isSendingComment ? 'Gönderiliyor...' : 'Gönder'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (normalized.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Henüz yorum yok. İlk yorumu sen yaz!',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              )
            else
              ...normalized.map(
                (comment) => CommentCard(
                  comment: comment,
                  depth: 0,
                  onReply: canWrite
                      ? ({
                          required String text,
                          required bool isGizliTanik,
                        }) =>
                          _submitComment(
                            text,
                            parentCommentId: comment['id']?.toString(),
                            isGizliTanik: isGizliTanik,
                          )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedHeaderRow({required bool isCollapsed}) {
    final headerDate = _formatHeaderDate();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: _engagementMenuOpen && isCollapsed
                ? Colors.transparent
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          if (headerDate.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: isCollapsed ? _toggleEngagementMenu : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _engagementMenuOpen && isCollapsed
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFE9FFF6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _engagementMenuOpen && isCollapsed
                          ? const Color(0xFF34D399)
                          : const Color(0xFFBFEFDC),
                    ),
                  ),
                  child: Text(
                    headerDate,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0C7A54),
                    ),
                  ),
                ),
              ),
            ),
          if (headerDate.isNotEmpty) const SizedBox(width: 8),
          Expanded(
            child: Text(
              _headerTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (widget.onToggleCollapse != null)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onToggleCollapse,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCollapsed ? const Color(0xFFF3F4F6) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCollapsed ? const Color(0xFFE5E7EB) : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 12,
                      color: isCollapsed ? const Color(0xFF6B7280) : const Color(0xFF15803D),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      size: 16,
                      color: isCollapsed ? const Color(0xFF6B7280) : const Color(0xFF15803D),
                    ),
                  ],
                ),
              ),
            )
          else if (widget.onClose != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, size: 20),
            ),
        ],
      ),
    );
  }

  /// 3×2 eşit grid: Yorum · Retweet · Beğen / Kına · Görüntüleme · Kaydet
  Widget _buildTwitterEngagementRow() {
    const Color inactiveColor = Color(0xFF71767B);

    final List<List<_EngagementCellConfig>> grid = <List<_EngagementCellConfig>>[
      <_EngagementCellConfig>[
        _EngagementCellConfig(
          icon: MdiIcons.commentOutline,
          activeIcon: MdiIcons.comment,
          count: yorumSayisi,
          isActive: _showComments || yorumSayisi > 0,
          activeColor: const Color(0xFF1D9BF0),
          onTap: () => _handleEngagementAction('comment'),
        ),
        _EngagementCellConfig(
          icon: MdiIcons.repeat,
          activeIcon: MdiIcons.repeat,
          count: retweetSayisi,
          isActive: isRetweeted,
          activeColor: const Color(0xFF00BA7C),
          onTap: () => _handleEngagementAction('retweet'),
        ),
        _EngagementCellConfig(
          icon: MdiIcons.heartOutline,
          activeIcon: MdiIcons.heart,
          count: begeniSayisi,
          isActive: isLiked,
          activeColor: const Color(0xFFF91880),
          onTap: () => _handleEngagementAction('like'),
        ),
      ],
      <_EngagementCellConfig>[
        _EngagementCellConfig(
          icon: MdiIcons.handWaveOutline,
          activeIcon: MdiIcons.handWave,
          count: begenmemeSayisi,
          isActive: isDisliked,
          activeColor: Colors.grey.shade700,
          onTap: () => _handleEngagementAction('dislike'),
        ),
        _EngagementCellConfig(
          icon: MdiIcons.eyeOutline,
          activeIcon: MdiIcons.eye,
          count: goruntulenmeSayisi,
          isActive: false,
          activeColor: inactiveColor,
          alwaysShowCount: true,
          onTap: () => _handleEngagementAction('view'),
        ),
        _EngagementCellConfig(
          icon: MdiIcons.bookmarkOutline,
          activeIcon: MdiIcons.bookmark,
          count: 0,
          isActive: isSaved,
          activeColor: const Color(0xFF7856FF),
          showCount: false,
          onTap: () => _handleEngagementAction('save'),
        ),
      ],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int row = 0; row < grid.length; row++) ...<Widget>[
            if (row > 0) Divider(height: 1, color: Colors.grey.shade200),
            _buildEngagementGridRow(
              inactiveColor: inactiveColor,
              cells: grid[row],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementGridRow({
    required Color inactiveColor,
    required List<_EngagementCellConfig> cells,
  }) {
    assert(cells.length == 3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int col = 0; col < 3; col++) ...<Widget>[
            if (col > 0) _buildEngagementRowDivider(),
            _buildTwitterEngagementItem(
              icon: cells[col].icon,
              activeIcon: cells[col].activeIcon,
              count: cells[col].count,
              isActive: cells[col].isActive,
              activeColor: cells[col].activeColor,
              inactiveColor: inactiveColor,
              showCount: cells[col].showCount,
              alwaysShowCount: cells[col].alwaysShowCount,
              onTap: cells[col].onTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementRowDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey.shade200,
    );
  }

  Widget _buildTwitterEngagementItem({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
    bool showCount = true,
    bool alwaysShowCount = false,
    bool expanded = true,
  }) {
    final Color color = isActive ? activeColor : inactiveColor;
    final bool displayCount = showCount && (alwaysShowCount || count > 0);

    final Widget content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 18,
                  color: color,
                ),
                if (displayCount) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return Expanded(child: content);
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCollapsedHeaderSection(),
          if (showDetails)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: _buildCaseTable(),
            ),
        ],
      ),
    );
  }

  Widget _buildCaseTable() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFAFA),
            Color(0xFFF5F5F5),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...caseDetails.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final label = row["label"]!;
              final appealParty = label == 'Davacı'
                  ? 'davaci'
                  : (label == 'Davalı' ? 'davali' : null);
              return Padding(
                padding: EdgeInsets.only(bottom: index < caseDetails.length - 1 ? 12 : 0),
                child: _buildInfoCard(
                  label,
                  row["value"]!,
                  appealParty: appealParty,
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34dfae).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description_outlined, // 🎨 GÜNCELLENDİ
                      color: Color(0xFF34dfae),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _buildDavaDescription(),
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Dava Detayları", Icons.gavel),
            const SizedBox(height: 14),
            ...expandableItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final style = _sectionStyles[item] ?? const MapEntry(Colors.green, Icons.info_outline);
              return Padding(
                padding: EdgeInsets.only(bottom: index < expandableItems.length - 1 ? 8 : 0),
                child: _buildModernExpansionTile(
                  item,
                  style.key,
                  style.value,
                  index: index,
                ),
              );
            }),
            if (_davaKonusu.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCollapsibleSection(
                title: 'Dava Konusu',
                color: const Color(0xFF34dfae),
                icon: Icons.description_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildDavaKonusuCard(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              title: 'Rol Kararları ve Hükümleri',
              color: Colors.indigo,
              icon: Icons.account_balance,
              children: [
                if (widget.davaId != null && widget.davaId!.trim().isNotEmpty)
                  RolHukumKartlariSection(
                    davaId: widget.davaId,
                    openedAt: widget.openedAt ?? _openedAt,
                    userEmail: widget.userEmail,
                    kullaniciGorev: _kullaniciGorevResolved,
                    rolHukumleri: _rolHukumleri,
                    rolSentimentleri: _rolSentimentleri,
                    rolCezalari: _rolCezalari,
                    rolMasraflari: _rolMasraflari,
                    seciliSentiment: _rolSeciliSentiment,
                    consensusEvaluation: _rolConsensusEvaluation,
                    consensusLoading: _rolConsensusLoading,
                    onConsensusRefresh: _canRefreshRolConsensus
                        ? () {
                      _loadRolConsensusEvaluation();
                    }
                        : null,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      'Dava kimliği olmadan rol hükümleri gösterilemez.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  /// Davacı tarafının nihai sonucu: true = davacı haklı, false = davalı haklı, null = belirsiz.
  /// Öncelik: Temyiz Hakimi Kararı → Yargıç Kararı → Konsensus (çoğunluk).
  bool? _getFinalDavaciVerdict() {
    final normalizedTemyiz = normalizeRolKarari('Temyiz Hakimi Kararı');
    final HukumSentiment? temyizSent = _rolSentimentleri[normalizedTemyiz];
    if (temyizSent != null) {
      return temyizSent == HukumSentiment.positive;
    }

    final normalizedYargic = normalizeRolKarari('Yargıç Kararı');
    final HukumSentiment? yargicSent = _rolSentimentleri[normalizedYargic];
    if (yargicSent != null) {
      return yargicSent == HukumSentiment.positive;
    }

    final DavaConsensusEvaluation? consensus = _rolConsensusEvaluation;
    if (consensus != null && consensus.totalVotes > 0) {
      if (consensus.positiveCount > consensus.negativeCount) {
        return true;
      }
      if (consensus.negativeCount > consensus.positiveCount) {
        return false;
      }
    }

    return null;
  }

  bool _isPartyHakli(String appealParty) {
    final bool? davaciHakli = _getFinalDavaciVerdict();
    if (davaciHakli == null) {
      return false;
    }
    if (appealParty == 'davaci') {
      return davaciHakli;
    }
    if (appealParty == 'davali') {
      return !davaciHakli;
    }
    return false;
  }

  // 🎨 GÜNCELLENDİ: Bağlama göre dinamik ikon
  IconData _getInfoCardIcon(String label) {
    switch (label) {
      case 'Davacı':
        return Icons.person_outline;
      case 'Davalı':
        return Icons.person_off_outlined;
      case 'Dava kategorisi':
        return Icons.category_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildInfoCard(
      String label,
      String value, {
        String? appealParty,
      }) {
    final isDavali = label == 'Davalı';
    final guest = isDavali && _isGuestDisplayValue(value);

    Widget temyizHakimiTrailing() {
      if (appealParty == null) {
        return const SizedBox.shrink();
      }

      final canTap = _canTapAppealDoor(appealParty);
      final blockReason = _appealDoorBlockReason(appealParty);
      final bool showHakliSmile = _isPartyHakli(appealParty);

      Widget temyizIcon = Icon(
        MdiIcons.scaleBalance,
        color: canTap ? const Color(0xFF8A5FBF) : Colors.grey.shade400,
        size: 32,
      );
      if (canTap) {
        temyizIcon = InkWell(
          onTap: () => _onAppealDoorTapped(appealParty),
          borderRadius: BorderRadius.circular(8),
          child: temyizIcon,
        );
      }

      Widget trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHakliSmile)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: appealParty == 'davaci' ? 'Davacı haklı' : 'Davalı haklı',
                child: Icon(
                  Icons.sentiment_satisfied_alt,
                  color: Colors.green.shade600,
                  size: 28,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: temyizIcon,
          ),
        ],
      );

      if (blockReason != null && blockReason.isNotEmpty) {
        trailing = Tooltip(message: blockReason, child: trailing);
      }
      return trailing;
    }

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8A5FBF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getInfoCardIcon(label), // 🎨 GÜNCELLENDİ: Dinamik ikon
              color: const Color(0xFF8A5FBF),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (guest) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Misafir (üye kaydı yok)',
                              child: Icon(
                                Icons.person_off_outlined,
                                color: Colors.red.shade700,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (appealParty != null) temyizHakimiTrailing(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isGuestDisplayValue(String v) {
    final t = v.trim();
    if (t.isEmpty) return false;
    if (t.contains('@')) {
      return HiveDatabaseService.getRegistrationByEmail(t) == null;
    }
    return HiveDatabaseService.getRegistrationByJudgeName(t) == null;
  }

  static String _compactRole(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u');
  }

  bool _isTarafDavaciRole(String mevkii) => _compactRole(mevkii) == 'davaci';

  bool _isTarafDavaliRole(String mevkii) => _compactRole(mevkii) == 'davali';

  bool _partyFieldMatchesUser(String partyValue, String userEmail) {
    final pv = partyValue.trim();
    final email = userEmail.trim();
    if (pv.isEmpty || email.isEmpty) return false;
    if (pv.toLowerCase() == email.toLowerCase()) return true;
    final reg = HiveDatabaseService.getRegistrationByEmail(email);
    final judgeName = reg?.judgeName.trim() ?? '';
    if (judgeName.isNotEmpty && pv == judgeName) return true;
    if (pv.contains('@')) {
      return pv.toLowerCase() == email.toLowerCase();
    }
    final partyReg = HiveDatabaseService.getRegistrationByJudgeName(pv);
    return partyReg?.email.toLowerCase() == email.toLowerCase();
  }

  /// Yalnızca davacı veya davalı taraf; avukat/jüri/yargıç değil.
  String? _currentUserAppealParty() {
    final email = widget.userEmail?.trim() ?? '';
    if (email.isEmpty) return null;

    final gorev = _kullaniciGorevResolved.trim();
    final roleDavaci = _isTarafDavaciRole(gorev);
    final roleDavali = _isTarafDavaliRole(gorev);
    final identityDavaci = _partyFieldMatchesUser(_davaci, email);
    final identityDavali = _partyFieldMatchesUser(_davali, email);

    if (roleDavaci && !roleDavali) {
      if (_davaci.trim().isEmpty || identityDavaci) return 'davaci';
      return null;
    }
    if (roleDavali && !roleDavaci) {
      if (_davali.trim().isEmpty || identityDavali) return 'davali';
      return null;
    }
    if (identityDavaci && !identityDavali) return 'davaci';
    if (identityDavali && !identityDavaci) return 'davali';
    return null;
  }

  Map<String, dynamic>? _openedDavaRow() {
    final id = widget.davaId?.trim() ?? '';
    if (id.isEmpty) return null;
    return HiveDatabaseService.getOpenedDavaById(id);
  }

  String? _appealDoorBlockReason(String party) {
    final userParty = _currentUserAppealParty();
    if (widget.userEmail == null || widget.userEmail!.trim().isEmpty) {
      return 'Temyiz talebi için oturum gerekir.';
    }
    if (userParty == null) {
      return 'Temyiz talebini yalnızca davacı veya davalı verebilir.';
    }
    if (userParty != party) {
      return 'Temyiz talebi yalnızca kendi tarafınız için verilebilir.';
    }

    final start = _openedAt;
    if (start == null) {
      return 'Dava tarihi bulunamadı.';
    }

    final elapsed = DateTime.now().difference(start);
    if (elapsed < DavaTimerService.mainTrialWindow) {
      return 'Temyiz için ana süreç (7 gün) tamamlanmalıdır.';
    }
    if (elapsed >=
        DavaTimerService.mainTrialWindow +
            DavaTimerService.appealOptionalWindow) {
      return 'Temyiz talebi süresi doldu (72 saatlik pencere).';
    }

    final opened = _openedDavaRow();
    if (opened?['isAppealable'] == true) {
      return 'Temyiz süreci zaten başlatıldı.';
    }

    return null;
  }

  bool _canTapAppealDoor(String party) => _appealDoorBlockReason(party) == null;

  Future<void> _onAppealDoorTapped(String party) async {
    if (widget.davaId == null || widget.davaId!.isEmpty) return;

    final blockReason = _appealDoorBlockReason(party);
    if (blockReason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blockReason),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final email = widget.userEmail!.trim();
    final result = await DavaAppealJudgeAssignService.assignFromAppealRequest(
      davaId: widget.davaId!,
      requestedByEmail: email,
      party: party,
    );
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Temyiz talebi kaydedilemedi.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (result.noFollowers) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                'Temyiz talebi kaydedildi; takipçi bulunamadı. Dava mevcut haliyle sonuçlanır.',
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Temyiz süreci başlatıldı. '
          '${result.assigneeDisplayName ?? 'Takipçi'} temyiz hakimi olarak görevlendirildi.',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
    setState(() {});
  }

  Widget _buildDavaKonusuCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDCE7E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SelectableText(
        _davaKonusu,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF34dfae).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF34dfae)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required Color color,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            iconColor: color,
            collapsedIconColor: color,
            textColor: const Color(0xFF1A1A1A),
            collapsedTextColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          maintainState: true,
          leading: _buildAnimatedIcon(icon, color),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
              height: 1.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildModernExpansionTile(String title, Color color, IconData icon, {int index = 0}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            iconColor: color,
            collapsedIconColor: color,
            textColor: const Color(0xFF1A1A1A),
            collapsedTextColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          maintainState: true,
          onExpansionChanged: (isExpanded) {
            if (isExpanded) {
              if (title == "Davayı Yorumlamayı Kabul ve Red Edenler" && widget.davaId != null && widget.davaId!.isNotEmpty) {
                _loadParticipants();
              }
              if (title == "Deliller Hakkında" &&
                  isExpanded &&
                  widget.davaId != null &&
                  widget.davaId!.isNotEmpty) {
                setState(() {
                  _delillerHakkindaFuture = _loadDelillerHakkindaBundle();
                });
              }
              if ((title == "Uygun Görülen Cezalar" || title == "Ceza Onayı") &&
                  isExpanded &&
                  widget.davaId != null &&
                  widget.davaId!.isNotEmpty) {
                setState(() {
                  _uygunCezalarFuture = _loadUygunCezalarBundle();
                });
              }
              if ((title == "Uygun Görülen Hediyeler" || title == "Hediye Onayı") &&
                  isExpanded &&
                  widget.davaId != null &&
                  widget.davaId!.isNotEmpty) {
                setState(() {
                  _hediyelerFuture = _loadHediyelerBundle();
                });
              }
              Future.delayed(const Duration(milliseconds: 250), () {
                // Scroll işlemi için gerekirse burada yapılabilir
              });
            }
          },
          leading: _buildAnimatedIcon(icon, color), // 🎨 GÜNCELLENDİ: Animasyonlu ikon wrapper
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
              height: 1.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          children: [
            if (title == "Davayı Yorumlamayı Kabul ve Red Edenler" && widget.davaId != null && widget.davaId!.isNotEmpty)
              _buildRejectersContent(color)
            else if (title == "Deliller Hakkında" && widget.davaId != null && widget.davaId!.isNotEmpty)
              _buildDelillerHakkindaContent(color)
            else if (title == "Uygun Görülen Cezalar" && widget.davaId != null && widget.davaId!.isNotEmpty)
              _buildUygunGorulenCezalarContent(color)
            else if (title == "Ceza Onayı" && widget.davaId != null && widget.davaId!.isNotEmpty)
              _buildCezaOnayiContent(color)
            else if (title == "Uygun Görülen Hediyeler" &&
                widget.davaId != null &&
                widget.davaId!.isNotEmpty)
              _buildUygunGorulenHediyelerContent(color)
            else if (title == "Hediye Onayı" &&
                widget.davaId != null &&
                widget.davaId!.isNotEmpty)
              _buildHediyeOnayiContent(color)
            else
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.06),
                              color.withOpacity(0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                size: 15,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title.contains("Kişi")
                                    ? "$title: Henüz yorum yapılmadı."
                                    : "Bu bölüm için içerik yakında eklenecektir.",
                                style: TextStyle(
                                  color: color.withOpacity(0.9),
                                  fontSize: 12.5,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // 🎨 YENİ: Animasyonlu ikon wrapper
  Widget _buildAnimatedIcon(IconData icon, Color color, {double size = 17}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Icon(icon, size: size, color: color),
    );
  }

  /// Red eden kişileri gösteren içerik - İki sütunlu yapı
  Widget _buildRejectersContent(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.groups_outlined, // 🎨 GÜNCELLENDİ
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Davada Hüküm Vermeyi Kabul ve Red Edenler',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoadingRejecters)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 520;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRejectedColumn(color),
                      const SizedBox(height: 16),
                      _buildActiveColumn(color),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildRejectedColumn(color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActiveColumn(color),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectedColumn(Color color) {
    final normalizedRejecters = _rejecters
        .where((r) => (r['userEmail'] as String? ?? '').trim().isNotEmpty)
        .toList();

    if (normalizedRejecters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red[50]!,
              Colors.red[50]!.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_remove_outlined, // 🎨 GÜNCELLENDİ
                size: 36,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Red Edenler',
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Henüz red eden yok',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red[50]!,
            Colors.red[50]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red[100]!,
                  Colors.red[50]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.red[300]!,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person_remove_outlined, // 🎨 GÜNCELLENDİ
                    size: 18,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Red',
                    style: TextStyle(
                      color: Colors.red[900],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${normalizedRejecters.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: normalizedRejecters.asMap().entries.map((entry) {
                final index = entry.key;
                final rejecter = entry.value;
                final email = rejecter['userEmail'] as String? ?? '';
                final displayName = (rejecter['displayName'] ?? '').toString().isNotEmpty
                    ? rejecter['displayName'].toString()
                    : HiveDatabaseService.getRegistrationByEmail(email)?.judgeName ?? email.split('@')[0];
                final initials = _getInitials(displayName);
                final settings = HiveDatabaseService.getSettings(email);
                final profileImageUrl = settings?.profileImageUrl;

                String? rejectedTimeText;
                final rejectedAt = rejecter['statusUpdatedAt'] ?? rejecter['rejectedAt'] ?? '';

                if (rejectedAt.isNotEmpty) {
                  try {
                    final rejectedDate = DateTime.parse(rejectedAt.toString());
                    final now = DateTime.now();
                    final difference = now.difference(rejectedDate);

                    if (difference.inDays > 0) {
                      rejectedTimeText = '${difference.inDays} gün önce';
                    } else if (difference.inHours > 0) {
                      rejectedTimeText = '${difference.inHours} saat önce';
                    } else if (difference.inMinutes > 0) {
                      rejectedTimeText = '${difference.inMinutes} dakika önce';
                    } else {
                      rejectedTimeText = 'Az önce';
                    }
                  } catch (e) {
                    rejectedTimeText = null;
                  }
                }

                final String statusLabel;
                final status = rejecter['status']?.toString() ?? 'rejected';
                if (status == 'auto_rejected') {
                  statusLabel = 'Süre doldu';
                } else {
                  statusLabel = 'Red';
                }

                return Container(
                  margin: EdgeInsets.only(bottom: index < normalizedRejecters.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red[300]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: Colors.red[400],
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? (exception, stackTrace) {}
                            : null,
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? null
                            : Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.red[900],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  status == 'auto_rejected' ? Icons.timer_outlined : Icons.person_remove_outlined, // 🎨 GÜNCELLENDİ
                                  size: 12,
                                  color: Colors.red[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (rejectedTimeText != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.history_toggle_off_outlined, // 🎨 GÜNCELLENDİ
                                    size: 12,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rejectedTimeText,
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveColumn(Color color) {
    final activeParticipants = _participants
        .where((participant) {
      final email = (participant['userEmail']?.toString() ?? '').trim().toLowerCase();
      if (email.isEmpty) return false;
      final status = participant['status']?.toString() ?? 'pending';
      return !(status == 'manual_rejected' || status == 'auto_rejected' || status == 'rejected');
    })
        .toList();

    if (activeParticipants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green[50]!,
              Colors.green[50]!.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_add_outlined, // 🎨 GÜNCELLENDİ
                size: 36,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kabul Edenler',
              style: TextStyle(
                color: Colors.green[900],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Henüz kabul eden yok',
              style: TextStyle(
                color: Colors.green[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[50]!,
            Colors.green[50]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[100]!,
                  Colors.green[50]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.green[300]!,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person_add_outlined, // 🎨 GÜNCELLENDİ
                    size: 18,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kabul Edenler',
                    style: TextStyle(
                      color: Colors.green[900],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeParticipants.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: activeParticipants.asMap().entries.map((entry) {
                final index = entry.key;
                final participant = entry.value;
                final email = participant['userEmail']?.toString() ?? '';
                final user = HiveDatabaseService.getRegistrationByEmail(email);
                final displayName = (participant['displayName'] ?? '').toString().isNotEmpty
                    ? participant['displayName'].toString()
                    : user?.judgeName ?? (email.contains('@') ? email.split('@')[0] : email);
                final initials = _getInitials(displayName);
                final settings = HiveDatabaseService.getSettings(email);
                final profileImageUrl = settings?.profileImageUrl;

                String? acceptedTimeText;
                final status = participant['status']?.toString() ?? 'pending';
                if (status == 'accepted') {
                  final acceptedAtStr = participant['statusUpdatedAt']?.toString();
                  if (acceptedAtStr != null && acceptedAtStr.isNotEmpty) {
                    try {
                      final acceptedDate = DateTime.parse(acceptedAtStr);
                      final now = DateTime.now();
                      final difference = now.difference(acceptedDate);
                      if (difference.inDays > 0) {
                        acceptedTimeText = '${difference.inDays} gün önce';
                      } else if (difference.inHours > 0) {
                        acceptedTimeText = '${difference.inHours} saat önce';
                      } else if (difference.inMinutes > 0) {
                        acceptedTimeText = '${difference.inMinutes} dakika önce';
                      } else {
                        acceptedTimeText = 'Az önce';
                      }
                    } catch (_) {
                      acceptedTimeText = null;
                    }
                  }
                }

                return Container(
                  margin: EdgeInsets.only(bottom: index < activeParticipants.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: Colors.green[400],
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? (exception, stackTrace) {}
                            : null,
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? null
                            : Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.green[900],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  status == 'accepted' ? Icons.verified_user_outlined : Icons.pending_actions_outlined, // 🎨 GÜNCELLENDİ
                                  size: 12,
                                  color: status == 'accepted' ? Colors.green[600] : Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    status == 'accepted' ? (acceptedTimeText ?? 'Onaylandı') : 'Beklemede',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle_outline, // 🎨 GÜNCELLENDİ: Outlined versiyon
                        color: Colors.green[400],
                        size: 20,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.length == 1 && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    } else {
      return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
    }
  }

  Future<_DelillerHakkindaBundle> _loadDelillerHakkindaBundle() async {
    final davaId = widget.davaId;
    if (davaId == null || davaId.isEmpty) {
      return const _DelillerHakkindaBundle(evidences: [], comments: []);
    }
    final evSvc = EvidenceService();
    final cmtSvc = EvidenceCommentService();
    await evSvc.initialize();
    await cmtSvc.initialize();
    final evidences = evSvc.getEvidenceByDavaId(davaId);
    final comments = cmtSvc.getCommentsByDavaId(davaId);
    evidences.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _DelillerHakkindaBundle(evidences: evidences, comments: comments);
  }

  Widget _buildDelillerHakkindaContent(Color color) {
    _delillerHakkindaFuture ??= _loadDelillerHakkindaBundle();
    return FutureBuilder<_DelillerHakkindaBundle>(
      future: _delillerHakkindaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  color.withOpacity(0.06),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildDelillerHakkindaPlaceholder(
            color,
            'Delil yorumları yüklenirken hata oluştu.',
          );
        }
        final bundle = snapshot.data ?? const _DelillerHakkindaBundle(evidences: [], comments: []);
        final orderedIds = _orderedEvidenceIds(bundle);
        if (orderedIds.isEmpty) {
          return _buildDelillerHakkindaPlaceholder(
            color,
            'Bu dava için henüz delil veya kayıtlı delil yorumu bulunmuyor.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: orderedIds.map((evidenceId) {
            final titleText = _evidenceTitleFor(bundle, evidenceId);
            final byEvidence = bundle.comments.where((c) => c.evidenceId == evidenceId).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOneDelilSection(
                color,
                delilTitle: titleText,
                evidenceId: evidenceId,
                commentsForEvidence: byEvidence,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<String> _orderedEvidenceIds(_DelillerHakkindaBundle bundle) {
    final ids = bundle.evidences.map((e) => e.id).toList();
    final fromComments = bundle.comments.map((c) => c.evidenceId).toSet();
    for (final id in fromComments) {
      if (id.trim().isNotEmpty && !ids.contains(id)) {
        ids.add(id);
      }
    }
    return ids;
  }

  String _evidenceTitleFor(_DelillerHakkindaBundle bundle, String evidenceId) {
    for (final e in bundle.evidences) {
      if (e.id == evidenceId) {
        final t = e.title.trim();
        return t.isNotEmpty ? t : '(Adsız delil)';
      }
    }
    final orphan = EvidenceService().getEvidenceById(evidenceId);
    if (orphan != null) {
      final t = orphan.title.trim();
      return t.isNotEmpty ? t : '(Adsız delil)';
    }
    return 'Bilinmeyen delil ($evidenceId)';
  }

  String _delilCommentDisplayName(String email) {
    final e = email.trim();
    if (e.isEmpty) return '—';
    final reg = HiveDatabaseService.getRegistrationByEmail(e);
    final judgeName = (reg?.judgeName ?? '').trim();
    if (judgeName.isNotEmpty) {
      return judgeName;
    }
    if (e.contains('@')) return e.split('@').first;
    return e;
  }

  Widget _buildDelillerHakkindaPlaceholder(Color color, String message) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.06),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.receipt_long_outlined, size: 15, color: color), // 🎨 GÜNCELLENDİ
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(EvidenceCommentRole role) => role.icon;

  // 🎨 GÜNCELLENDİ: Eleştiri badge ikonları
  IconData _getCriticismIcon(String criticism) {
    switch (criticism) {
      case 'positive':
        return Icons.sentiment_satisfied_outlined;
      case 'negative':
        return Icons.sentiment_dissatisfied_outlined;
      default:
        return Icons.sentiment_neutral_outlined;
    }
  }

  Widget _buildOneDelilSection(
      Color color, {
        required String delilTitle,
        required String evidenceId,
        required List<EvidenceCommentModel> commentsForEvidence,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.insert_drive_file_outlined, size: 18, color: color), // 🎨 GÜNCELLENDİ
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delilTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...EvidenceCommentRole.allRoles.map((role) {
              final roleComments =
              commentsForEvidence.where((c) => c.userRole == role.value).toList();
              roleComments.sort((a, b) {
                final da = a.updatedAt ?? a.createdAt;
                final db = b.updatedAt ?? b.createdAt;
                return db.compareTo(da);
              });
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: roleComments.isEmpty
                        ? Colors.grey[50]
                        : role.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: roleComments.isEmpty
                          ? Colors.grey[200]!
                          : role.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_getRoleIcon(role), size: 16, color: role.color), // 🎨 GÜNCELLENDİ
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              role.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: role.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (roleComments.isEmpty)
                        Text(
                          'Henüz yorum yok',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        ...roleComments.map((c) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDelilCriticismBadge(c.criticism),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _delilCommentDisplayName(c.userEmail),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.commentText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[900],
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDelilCriticismBadge(String criticism) {
    late final Color clr;
    late final String label;
    late final IconData icon;
    switch (criticism) {
      case 'positive':
        clr = Colors.green;
        label = 'Olumlu';
        icon = _getCriticismIcon(criticism); // 🎨 GÜNCELLENDİ
        break;
      case 'negative':
        clr = Colors.red;
        label = 'Olumsuz';
        icon = _getCriticismIcon(criticism); // 🎨 GÜNCELLENDİ
        break;
      default:
        clr = Colors.grey;
        label = 'Nötr';
        icon = _getCriticismIcon(criticism); // 🎨 GÜNCELLENDİ
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: clr.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: clr.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: clr),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: clr,
            ),
          ),
        ],
      ),
    );
  }

  static String _stripMevkiiKarariSuffix(String raw) {
    final t = raw.trim();
    if (t.endsWith(' Kararı')) {
      return t.substring(0, t.length - 7).trim();
    }
    return t;
  }

  bool _mevkiiMatchesEvidenceRole(String mevkiiRaw, String roleValue) {
    final a = _stripMevkiiKarariSuffix(mevkiiRaw).toLowerCase();
    final b = roleValue.trim().toLowerCase();
    if (a == b) {
      return true;
    }
    final collapsedA = a.replaceAll(RegExp(r'\s+'), '');
    final collapsedB = b.replaceAll(RegExp(r'\s+'), '');
    return collapsedA == collapsedB;
  }

  Map<String, dynamic>? _findParticipantForRole(
      List<Map<String, dynamic>> participants,
      String roleValue,
      ) {
    for (final p in participants) {
      final mevki = p['mevkii']?.toString() ?? '';
      if (mevki.isEmpty) continue;
      if (_mevkiiMatchesEvidenceRole(mevki, roleValue)) {
        return p;
      }
    }
    return null;
  }

  Future<_UygunCezalarBundle> _loadUygunCezalarBundle() async {
    final davaId = widget.davaId ?? '';
    if (davaId.isEmpty) {
      return const _UygunCezalarBundle(
        participants: [],
        cezaByEmailLower: {},
        votesByEmail: {},
        roleCezaMap: {},
        effective: CezaEffectiveResult(
          cezaText: null,
          sourceRole: null,
          source: CezaEffectiveSource.none,
          voteCountsByRole: {},
          votingPeriodClosed: false,
        ),
        votingOpen: true,
      );
    }
    final participants = await HiveDatabaseService.getDavaParticipants(davaId);
    Map<String, String> cezaByEmail =
        await HiveDatabaseService.getCezaMapForDavaId(davaId);
    final String ad = _davaAdi.isNotEmpty ? _davaAdi : (widget.davaAdi ?? '').trim();
    if (ad.isNotEmpty) {
      final altId = 'dava_${ad.hashCode}';
      if (altId != davaId) {
        final altMap = await HiveDatabaseService.getCezaMapForDavaId(altId);
        for (final e in altMap.entries) {
          cezaByEmail.putIfAbsent(e.key, () => e.value);
        }
      }
    }
    final Map<String, String> votesByEmail =
        await HiveDatabaseService.getCezaOyMapForDavaId(davaId);
    final bool votingOpen = await CezaConsensusService.isVotingPeriodOpen(davaId);
    final bool votingClosed = !votingOpen;
    final List<String> roleValues =
        EvidenceCommentRole.allRoles.map((r) => r.value).toList();
    final Map<String, String> roleCezaMap = CezaConsensusService.buildRoleCezaMap(
      participants: participants,
      cezaByEmailLower: cezaByEmail,
      roleValues: roleValues,
      roleMatcher: _mevkiiMatchesEvidenceRole,
    );
    final CezaEffectiveResult effective = CezaConsensusService.resolveEffectiveCeza(
      roleCezaMap: roleCezaMap,
      votesByEmail: votesByEmail,
      votingPeriodClosed: votingClosed,
      participants: participants,
      roleMatcher: _mevkiiMatchesEvidenceRole,
    );
    return _UygunCezalarBundle(
      participants: participants,
      cezaByEmailLower: cezaByEmail,
      votesByEmail: votesByEmail,
      roleCezaMap: roleCezaMap,
      effective: effective,
      votingOpen: votingOpen,
    );
  }

  bool _isEmailDavaParticipant(String email, List<Map<String, dynamic>> participants) {
    final String e = email.trim().toLowerCase();
    if (e.isEmpty) {
      return false;
    }
    for (final Map<String, dynamic> p in participants) {
      final String pe = (p['userEmail']?.toString() ?? '').trim().toLowerCase();
      if (pe == e) {
        return true;
      }
    }
    return false;
  }

  Future<void> _onCezaRoleVote({
    required EvidenceCommentRole role,
    required _UygunCezalarBundle bundle,
  }) async {
    final String davaId = widget.davaId?.trim() ?? '';
    final String voterEmail = widget.userEmail?.trim().toLowerCase() ?? '';
    if (davaId.isEmpty || voterEmail.isEmpty) {
      return;
    }
    if (!bundle.votingOpen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('19 günlük ceza oylama süresi sona erdi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    if (!_isEmailDavaParticipant(voterEmail, bundle.participants)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ceza oyu yalnızca dava üyeleri tarafından verilebilir.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final String? cezaForRole = bundle.roleCezaMap[role.value];
    if (cezaForRole == null || cezaForRole.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${role.label} için henüz mühürlenmiş ceza yok.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    try {
      await HiveDatabaseService.toggleCezaOy(
        davaId: davaId,
        voterEmail: voterEmail,
        roleValue: role.value,
      );
      if (mounted) {
        setState(() {
          _uygunCezalarFuture = _loadUygunCezalarBundle();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ceza oyu kaydedilemedi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<_HediyelerBundle> _loadHediyelerBundle() async {
    final davaId = widget.davaId ?? '';
    final String ad = _davaAdi.isNotEmpty ? _davaAdi : (widget.davaAdi ?? '').trim();
    if (davaId.isEmpty) {
      return const _HediyelerBundle(
        participants: [],
        hediyeSatirByEmailLower: {},
        votesByEmail: {},
        roleHediyeMap: {},
        effective: HediyeEffectiveResult(
          hediyeText: null,
          sourceRole: null,
          source: HediyeEffectiveSource.none,
          voteCountsByRole: {},
          votingPeriodClosed: false,
        ),
        votingOpen: true,
      );
    }
    final participants = await HiveDatabaseService.getDavaParticipants(davaId);
    Map<String, String> hediyeByEmail =
        await HiveDatabaseService.getMasrafGiftLineMapForDavaId(davaId);
    if (ad.isNotEmpty) {
      final altId = 'dava_${ad.hashCode}';
      if (altId != davaId) {
        final altMap = await HiveDatabaseService.getMasrafGiftLineMapForDavaId(altId);
        for (final e in altMap.entries) {
          hediyeByEmail.putIfAbsent(e.key, () => e.value);
        }
      }
    }
    final Map<String, String> votesByEmail =
        await HiveDatabaseService.getHediyeOyMapForDavaId(davaId);
    final bool votingOpen = await HediyeConsensusService.isVotingPeriodOpen(davaId);
    final List<String> roleValues =
        EvidenceCommentRole.allRoles.map((r) => r.value).toList();
    final Map<String, String> roleHediyeMap = HediyeConsensusService.buildRoleHediyeMap(
      participants: participants,
      hediyeByEmailLower: hediyeByEmail,
      roleValues: roleValues,
    );
    final HediyeEffectiveResult effective = HediyeConsensusService.resolveEffectiveHediye(
      roleHediyeMap: roleHediyeMap,
      votesByEmail: votesByEmail,
      votingPeriodClosed: !votingOpen,
      participants: participants,
    );
    return _HediyelerBundle(
      participants: participants,
      hediyeSatirByEmailLower: hediyeByEmail,
      votesByEmail: votesByEmail,
      roleHediyeMap: roleHediyeMap,
      effective: effective,
      votingOpen: votingOpen,
    );
  }

  Future<void> _onHediyeRoleVote({
    required EvidenceCommentRole role,
    required _HediyelerBundle bundle,
  }) async {
    final String davaId = widget.davaId?.trim() ?? '';
    final String voterEmail = widget.userEmail?.trim().toLowerCase() ?? '';
    if (davaId.isEmpty || voterEmail.isEmpty) {
      return;
    }
    if (!bundle.votingOpen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('19 günlük hediye oylama süresi sona erdi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    if (!_isEmailDavaParticipant(voterEmail, bundle.participants)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hediye oyu yalnızca dava üyeleri tarafından verilebilir.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final String? hediyeForRole = bundle.roleHediyeMap[role.value];
    if (hediyeForRole == null || hediyeForRole.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${role.label} için henüz kayıtlı hediye yok.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    try {
      await HiveDatabaseService.toggleHediyeOy(
        davaId: davaId,
        voterEmail: voterEmail,
        roleValue: role.value,
      );
      if (mounted) {
        setState(() {
          _hediyelerFuture = _loadHediyelerBundle();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hediye oyu kaydedilemedi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildUygunGorulenCezalarContent(Color color) {
    _uygunCezalarFuture ??= _loadUygunCezalarBundle();
    return FutureBuilder<_UygunCezalarBundle>(
      future: _uygunCezalarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  color.withOpacity(0.06),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildDelillerHakkindaPlaceholder(
            color,
            'Cezalar yüklenirken hata oluştu.',
          );
        }
        final bundle = snapshot.data ??
            const _UygunCezalarBundle(
              participants: [],
              cezaByEmailLower: {},
              votesByEmail: {},
              roleCezaMap: {},
              effective: CezaEffectiveResult(
                cezaText: null,
                sourceRole: null,
                source: CezaEffectiveSource.none,
                voteCountsByRole: {},
                votingPeriodClosed: false,
              ),
              votingOpen: true,
            );
        final String voterEmail = widget.userEmail?.trim().toLowerCase() ?? '';
        final String? userVotedRole = voterEmail.isNotEmpty
            ? bundle.votesByEmail[voterEmail]
            : null;
        final roles = EvidenceCommentRole.allRoles;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bundle.votingOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '19 gün içinde bir role tıklayarak o cezaya oy verin. '
                  'En çok oy alan ceza, süre sonunda Ceza Onayı\'nda nihai olur. '
                  'Yargıç veya temyiz hakimi atanmışsa cezası geçici önceliklidir; halk oyu bunu değiştirebilir.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ...roles.map((role) {
              final p = _findParticipantForRole(bundle.participants, role.value);
              final email = (p?['userEmail']?.toString() ?? '').trim().toLowerCase();
              String displayName = '—';
              if (p != null) {
                final dn = (p['displayName'] ?? '').toString().trim();
                if (dn.isNotEmpty) {
                  displayName = dn;
                } else if (email.isNotEmpty) {
                  displayName = HiveDatabaseService.getRegistrationByEmail(email)?.judgeName ??
                      (email.contains('@') ? email.split('@').first : email);
                }
              }
              final ceza = email.isNotEmpty ? bundle.cezaByEmailLower[email] : null;
              final bool hasCeza = ceza != null && ceza.trim().isNotEmpty;
              final cezaText = hasCeza
                  ? ceza.trim()
                  : (p == null
                      ? 'Bu göreve atanmış kullanıcı yok.'
                      : 'Henüz ceza seçilmedi (Ceza panelinden mühürleme bekleniyor).');
              final bool userVotedHere = userVotedRole == role.value;
              final int voteCount = bundle.effective.voteCountsByRole[role.value] ?? 0;
              final bool canVote = bundle.votingOpen && hasCeza;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canVote
                        ? () => _onCezaRoleVote(role: role, bundle: bundle)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: userVotedHere
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: userVotedHere
                                  ? Colors.green.shade300
                                  : role.color.withValues(alpha: 0.28),
                              width: userVotedHere ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: role.color.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_getRoleIcon(role), size: 16, color: role.color),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      role.label,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: role.color,
                                      ),
                                    ),
                                  ),
                                  if (voteCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        '$voteCount oy',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cezaText,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[900],
                                  height: 1.45,
                                  fontStyle: hasCeza ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (userVotedHere)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.green.shade400),
                              ),
                              child: Icon(
                                MdiIcons.gavel,
                                size: 16,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCezaOnayiContent(Color color) {
    _uygunCezalarFuture ??= _loadUygunCezalarBundle();
    return FutureBuilder<_UygunCezalarBundle>(
      future: _uygunCezalarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  color.withOpacity(0.06),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2), width: 1.2),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildDelillerHakkindaPlaceholder(
            color,
            'Ceza onayı yüklenirken hata oluştu.',
          );
        }
        final bundle = snapshot.data;
        final CezaEffectiveResult effective = bundle?.effective ??
            const CezaEffectiveResult(
              cezaText: null,
              sourceRole: null,
              source: CezaEffectiveSource.none,
              voteCountsByRole: {},
              votingPeriodClosed: false,
            );
        final String? cezaText = effective.cezaText;
        final bool hasCeza = cezaText != null && cezaText.trim().isNotEmpty;
        final String sourceLabel = effective.sourceLabel();
        final bool votingOpen = bundle?.votingOpen ?? true;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(MdiIcons.gavel, size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      votingOpen ? 'Geçerli ceza (oylama sürüyor)' : 'Nihai ceza',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              if (sourceLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Kaynak: $sourceLabel'
                  '${effective.sourceRole != null ? ' (${effective.sourceRole})' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                hasCeza
                    ? cezaText.trim()
                    : (votingOpen
                        ? 'Henüz geçerli ceza yok. Üyeler Uygun Görülen Cezalar bölümünden oy verebilir; '
                            'yargıç veya temyiz hakimi atanmışsa cezası geçici olarak burada görünür.'
                        : '19 gün sona erdi; oy verilmiş veya yargıç/temyiz cezası bulunan bir karar yok.'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[900],
                  height: 1.5,
                  fontStyle: hasCeza ? FontStyle.italic : FontStyle.normal,
                  fontWeight: hasCeza ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (!votingOpen && hasCeza) ...[
                const SizedBox(height: 8),
                Text(
                  '19 günlük oylama tamamlandı; yukarıdaki ceza nihai olarak onaylanır.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUygunGorulenHediyelerContent(Color color) {
    _hediyelerFuture ??= _loadHediyelerBundle();
    return FutureBuilder<_HediyelerBundle>(
      future: _hediyelerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  color.withOpacity(0.06),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildDelillerHakkindaPlaceholder(
            color,
            'Uygun görülen hediyeler yüklenirken hata oluştu.',
          );
        }
        final bundle = snapshot.data ??
            const _HediyelerBundle(
              participants: [],
              hediyeSatirByEmailLower: {},
              votesByEmail: {},
              roleHediyeMap: {},
              effective: HediyeEffectiveResult(
                hediyeText: null,
                sourceRole: null,
                source: HediyeEffectiveSource.none,
                voteCountsByRole: {},
                votingPeriodClosed: false,
              ),
              votingOpen: true,
            );
        final String voterEmail = widget.userEmail?.trim().toLowerCase() ?? '';
        final String? userVotedRole = voterEmail.isNotEmpty
            ? bundle.votesByEmail[voterEmail]
            : null;
        final roles = EvidenceCommentRole.allRoles;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bundle.votingOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '19 gün içinde bir role tıklayarak o hediyeye oy verin. '
                  'En çok oy alan hediye, süre sonunda Hediye Onayı bölümünde nihai olur. '
                  'Yargıç veya temyiz hakimi atanmışsa hediyesi geçici önceliklidir; halk oyu bunu değiştirebilir.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ...roles.map((role) {
              final p = _findParticipantForRole(bundle.participants, role.value);
              final email = (p?['userEmail']?.toString() ?? '').trim().toLowerCase();
              String displayName = '—';
              if (p != null) {
                final dn = (p['displayName'] ?? '').toString().trim();
                if (dn.isNotEmpty) {
                  displayName = dn;
                } else if (email.isNotEmpty) {
                  displayName = HiveDatabaseService.getRegistrationByEmail(email)?.judgeName ??
                      (email.contains('@') ? email.split('@').first : email);
                }
              }
              final hediyeSatir =
                  email.isNotEmpty ? bundle.hediyeSatirByEmailLower[email] : null;
              final bool hasHediye =
                  hediyeSatir != null && hediyeSatir.trim().isNotEmpty;
              final hediyeText = hasHediye
                  ? hediyeSatir.trim()
                  : (p == null
                      ? 'Bu göreve atanmış kullanıcı yok.'
                      : 'Henüz hediye seçilmedi (Hüküm hediye ekranından kayıt bekleniyor).');
              final bool userVotedHere = userVotedRole == role.value;
              final int voteCount =
                  bundle.effective.voteCountsByRole[role.value] ?? 0;
              final bool canVote = bundle.votingOpen && hasHediye;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canVote
                        ? () => _onHediyeRoleVote(role: role, bundle: bundle)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: userVotedHere
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: userVotedHere
                                  ? Colors.green.shade300
                                  : role.color.withValues(alpha: 0.28),
                              width: userVotedHere ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: role.color.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.redeem_outlined,
                                      size: 16, color: role.color),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      role.label,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: role.color,
                                      ),
                                    ),
                                  ),
                                  if (voteCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.pink.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.pink.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        '$voteCount oy',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.pink.shade800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hediyeText,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[900],
                                  height: 1.45,
                                  fontStyle:
                                      hasHediye ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (userVotedHere)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.pink.shade400),
                              ),
                              child: Icon(
                                Icons.card_giftcard,
                                size: 16,
                                color: Colors.pink.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildHediyeOnayiContent(Color color) {
    _hediyelerFuture ??= _loadHediyelerBundle();
    return FutureBuilder<_HediyelerBundle>(
      future: _hediyelerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  color.withOpacity(0.06),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2), width: 1.2),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildDelillerHakkindaPlaceholder(
            color,
            'Hediye Onayı yüklenirken hata oluştu.',
          );
        }
        final bundle = snapshot.data;
        final HediyeEffectiveResult effective = bundle?.effective ??
            const HediyeEffectiveResult(
              hediyeText: null,
              sourceRole: null,
              source: HediyeEffectiveSource.none,
              voteCountsByRole: {},
              votingPeriodClosed: false,
            );
        final String? hediyeText = effective.hediyeText;
        final bool hasHediye = hediyeText != null && hediyeText.trim().isNotEmpty;
        final String sourceLabel = effective.sourceLabel();
        final bool votingOpen = bundle?.votingOpen ?? true;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard, size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      votingOpen
                          ? 'Geçerli hediye (oylama sürüyor)'
                          : 'Nihai hediye',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              if (sourceLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Kaynak: $sourceLabel'
                  '${effective.sourceRole != null ? ' (${effective.sourceRole})' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                hasHediye
                    ? hediyeText.trim()
                    : (votingOpen
                        ? 'Henüz geçerli hediye yok. Üyeler Uygun Görülen Hediyeler bölümünden oy verebilir; '
                            'yargıç veya temyiz hakimi atanmışsa hediyesi geçici olarak burada görünür.'
                        : '19 gün sona erdi; oy verilmiş veya yargıç/temyiz hediyesi bulunan bir karar yok.'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[900],
                  height: 1.5,
                  fontStyle: hasHediye ? FontStyle.italic : FontStyle.normal,
                  fontWeight: hasHediye ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (!votingOpen && hasHediye) ...[
                const SizedBox(height: 8),
                Text(
                  '19 günlük oylama tamamlandı; yukarıdaki hediye nihai olarak onaylanır.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EngagementCellConfig {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final bool showCount;
  final bool alwaysShowCount;

  const _EngagementCellConfig({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.showCount = true,
    this.alwaysShowCount = false,
  });
}

class _DelillerHakkindaBundle {
  final List<EvidenceModel> evidences;
  final List<EvidenceCommentModel> comments;

  const _DelillerHakkindaBundle({
    required this.evidences,
    required this.comments,
  });
}

class _UygunCezalarBundle {
  final List<Map<String, dynamic>> participants;
  final Map<String, String> cezaByEmailLower;
  final Map<String, String> votesByEmail;
  final Map<String, String> roleCezaMap;
  final CezaEffectiveResult effective;
  final bool votingOpen;

  const _UygunCezalarBundle({
    required this.participants,
    required this.cezaByEmailLower,
    required this.votesByEmail,
    required this.roleCezaMap,
    required this.effective,
    required this.votingOpen,
  });
}

class _HediyelerBundle {
  final List<Map<String, dynamic>> participants;
  final Map<String, String> hediyeSatirByEmailLower;
  final Map<String, String> votesByEmail;
  final Map<String, String> roleHediyeMap;
  final HediyeEffectiveResult effective;
  final bool votingOpen;

  const _HediyelerBundle({
    required this.participants,
    required this.hediyeSatirByEmailLower,
    required this.votesByEmail,
    required this.roleHediyeMap,
    required this.effective,
    required this.votingOpen,
  });
}