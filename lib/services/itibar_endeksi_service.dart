import 'package:hive/hive.dart';

import '../models/registration_model.dart';
import '../utils/proximity_category_rules.dart';
import 'actigim_dava_istatistik_service.dart';
import 'friend_category_service.dart';
import 'katildigim_dava_istatistik_service.dart';

/// İtibar Endeksi olay türleri.
class ItibarOlayTipi {
  static const String hediyeSadakat = 'hediye_sadakat';
  static const String hediyeKacis = 'hediye_kacis';
  static const String levhAdmin = 'levh_admin';
  static const String direnReuse = 'diren_reuse';
}

/// Beş bileşenli itibar özeti.
class ItibarOzeti {
  final int sosyalLigHam; // grup19 seçen kişi sayısı
  final int sosyalLig; // floor(ham / 19)
  final int davaEnerjisi;
  final int hediyeSadakati;
  final int levhMahfuz;
  final int direnEndeksi;
  final double itibarEndeksi;
  final List<ItibarTrendNoktasi> trend;

  const ItibarOzeti({
    required this.sosyalLigHam,
    required this.sosyalLig,
    required this.davaEnerjisi,
    required this.hediyeSadakati,
    required this.levhMahfuz,
    required this.direnEndeksi,
    required this.itibarEndeksi,
    required this.trend,
  });
}

/// 0 / 3 / 6 / 9 / 12 aylık trend noktası.
class ItibarTrendNoktasi {
  final int monthsBack;
  final String label;
  final double average;

  const ItibarTrendNoktasi({
    required this.monthsBack,
    required this.label,
    required this.average,
  });
}

/// İtibar Endeksi defteri: olaylar, Levh-i Mahfûz, Diren atfı ve aylık kesitler.
class ItibarEndeksiService {
  ItibarEndeksiService._();

  static const String _boxName = 'itibar_endeksi_box_v1';
  static Box<dynamic>? _box;

  static Future<void> initialize() async {
    await _ensureBox();
  }

  static Future<Box<dynamic>> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<dynamic>(_boxName);
    } else {
      _box = Hive.box<dynamic>(_boxName);
    }
    return _box!;
  }

  static String _eventsKey(String userId) => 'events:$userId';
  static String _snapshotsKey(String userId) => 'snapshots:$userId';
  static String _direnAuthorKey(String text) =>
      'diren_author:${text.trim().toLowerCase()}';
  static String _direnCreditKey(String authorId, String usedById, String text) =>
      'diren_credit:${authorId}_${usedById}_${text.trim().toLowerCase()}';
  static String _giftKey(String davaId, String type) => 'gift:$type:$davaId';

  static Future<void> _addEvent({
    required String userId,
    required String type,
    required int points,
    String? refId,
  }) async {
    if (userId.isEmpty) return;
    final box = await _ensureBox();
    final key = _eventsKey(userId);
    final existing = box.get(key);
    final list = <Map<String, dynamic>>[];
    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }
    list.add({
      'type': type,
      'points': points,
      'refId': refId,
      'at': DateTime.now().toIso8601String(),
    });
    await box.put(key, list);
  }

  static int _sumEvents(List<Map<String, dynamic>> events, Set<String> types) {
    var total = 0;
    for (final e in events) {
      if (types.contains(e['type']?.toString())) {
        total += (e['points'] as num?)?.toInt() ?? 0;
      }
    }
    return total;
  }

  static Future<List<Map<String, dynamic>>> _eventsFor(String userId) async {
    final box = await _ensureBox();
    final raw = box.get(_eventsKey(userId));
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Admin, Levh-i Mahfûz `+0` alanına basınca +1.
  static Future<int> incrementLevhMahfuz(String userId) async {
    await _addEvent(
      userId: userId,
      type: ItibarOlayTipi.levhAdmin,
      points: 1,
    );
    final events = await _eventsFor(userId);
    return _sumEvents(events, {ItibarOlayTipi.levhAdmin});
  }

  static Future<void> recordGiftHonored({
    required String userId,
    required String davaId,
  }) async {
    final box = await _ensureBox();
    final key = _giftKey(davaId, 'honored');
    if (box.get(key) == true) return;
    await box.put(key, true);
    await _addEvent(
      userId: userId,
      type: ItibarOlayTipi.hediyeSadakat,
      points: 1,
      refId: davaId,
    );
  }

  static Future<void> recordGiftAvoided({
    required String userId,
    required String davaId,
  }) async {
    final box = await _ensureBox();
    final honorKey = _giftKey(davaId, 'honored');
    final avoidKey = _giftKey(davaId, 'avoided');
    if (box.get(honorKey) == true) return;
    if (box.get(avoidKey) == true) return;
    await box.put(avoidKey, true);
    await _addEvent(
      userId: userId,
      type: ItibarOlayTipi.hediyeKacis,
      points: -19,
      refId: davaId,
    );
  }

  static Future<void> registerDirenAuthor({
    required String text,
    required String authorUserId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || authorUserId.isEmpty) return;
    final box = await _ensureBox();
    final key = _direnAuthorKey(trimmed);
    if (box.get(key) != null) return;
    await box.put(key, {
      'authorUserId': authorUserId,
      'text': trimmed,
      'at': DateTime.now().toIso8601String(),
    });
  }

  /// B, A'nın diren metnini seçerse A'ya +1 (aynı çift için bir kez).
  static Future<void> creditDirenReuse({
    required String text,
    required String usedByUserId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || usedByUserId.isEmpty) return;
    final box = await _ensureBox();
    final meta = box.get(_direnAuthorKey(trimmed));
    if (meta is! Map) return;
    final authorId = meta['authorUserId']?.toString() ?? '';
    if (authorId.isEmpty || authorId == usedByUserId) return;
    final creditKey = _direnCreditKey(authorId, usedByUserId, trimmed);
    if (box.get(creditKey) == true) return;
    await box.put(creditKey, true);
    await _addEvent(
      userId: authorId,
      type: ItibarOlayTipi.direnReuse,
      points: 1,
      refId: usedByUserId,
    );
  }

  static int countGrup19Selectors(String targetUserId) {
    return FriendCategoryService.countOwnersWhoCategorized(
      targetUserId,
      ProximityCategoryRules.grup19,
    );
  }

  static int sosyalLigPuan(int selectorCount) => selectorCount ~/ 19;

  static Future<ItibarOzeti> compute(RegistrationModel user) async {
    await FriendCategoryService.initialize();
    await _ensureBox();

    final sosyalHam = countGrup19Selectors(user.id);
    final sosyal = sosyalLigPuan(sosyalHam);

    final actigim =
        await const ActigimDavaIstatistikService().compute(user.email);
    final katildigim =
        await const KatildigimDavaIstatistikService().compute(user.email);
    final davaEnerjisi = (actigim.hakliOldugum + katildigim.hakliOldugum) -
        (actigim.haksizOldugum + katildigim.haksizOldugum);

    final events = await _eventsFor(user.id);
    final hediye = _sumEvents(events, {
      ItibarOlayTipi.hediyeSadakat,
      ItibarOlayTipi.hediyeKacis,
    });
    final levh = _sumEvents(events, {ItibarOlayTipi.levhAdmin});
    final diren = _sumEvents(events, {ItibarOlayTipi.direnReuse});

    final ortalama = (sosyal + davaEnerjisi + hediye + levh + diren) / 5.0;
    await _recordSnapshot(user.id, ortalama);
    final trend = await _buildTrend(user.id, ortalama);

    return ItibarOzeti(
      sosyalLigHam: sosyalHam,
      sosyalLig: sosyal,
      davaEnerjisi: davaEnerjisi,
      hediyeSadakati: hediye,
      levhMahfuz: levh,
      direnEndeksi: diren,
      itibarEndeksi: ortalama,
      trend: trend,
    );
  }

  static Future<void> _recordSnapshot(String userId, double value) async {
    final box = await _ensureBox();
    final key = _snapshotsKey(userId);
    final now = DateTime.now();
    final monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final existing = box.get(key);
    final list = <Map<String, dynamic>>[];
    if (existing is List) {
      for (final item in existing) {
        if (item is Map) list.add(Map<String, dynamic>.from(item));
      }
    }
    final idx = list.indexWhere((e) => e['month'] == monthKey);
    final entry = {
      'month': monthKey,
      'value': value,
      'at': now.toIso8601String(),
    };
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    await box.put(key, list);
  }

  static Future<List<ItibarTrendNoktasi>> _buildTrend(
    String userId,
    double current,
  ) async {
    final box = await _ensureBox();
    final raw = box.get(_snapshotsKey(userId));
    final snapshots = <DateTime, double>{};
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final at = DateTime.tryParse(item['at']?.toString() ?? '');
        final value = (item['value'] as num?)?.toDouble();
        if (at == null || value == null) continue;
        snapshots[at] = value;
      }
    }

    const windows = [0, 3, 6, 9, 12];
    final now = DateTime.now();
    return windows.map((months) {
      final label = months == 0
          ? '0 ay'
          : months == 12
              ? '12 ay (yıllık)'
              : '$months ay';
      if (months == 0) {
        return ItibarTrendNoktasi(
          monthsBack: 0,
          label: label,
          average: current,
        );
      }
      final from = DateTime(now.year, now.month - months, now.day);
      final values = snapshots.entries
          .where((e) => !e.key.isBefore(from))
          .map((e) => e.value)
          .toList();
      final avg = values.isEmpty
          ? current
          : values.reduce((a, b) => a + b) / values.length;
      return ItibarTrendNoktasi(
        monthsBack: months,
        label: label,
        average: avg,
      );
    }).toList();
  }
}
