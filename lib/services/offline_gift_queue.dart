import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/gift_models.dart';
import 'hive_database_service.dart';
import 'user_star_balance_store.dart';

/// Masraf (hediye) satırı Hive'a yazılamadığında kalıcı sıra.
///
/// **Not:** Masraf verisi zaten tamamen yerel Hive'dadır; internet gerekmez.
/// Önceki taslaktaki `_checkConnection` ile kuyruğu işlemek, çevrimdışıyken
/// asla yeniden denemeyi engellerdi — bu yüzden burada ağ kontrolü yoktur.
class OfflineGiftQueue {
  OfflineGiftQueue._();

  static const String _boxName = 'offline_gift_masraf_pending_v1';

  static Box<dynamic>? _box;

  static Future<void> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<dynamic>(_boxName);
    }
  }

  static String masrafLineForGift(Gift gift) =>
      '${gift.emoji} ${gift.name} · ⭐${gift.price} · ${gift.catName} › ${gift.subName}';

  /// Kayıt başarısız olduğunda çağırın; yıldız henüz düşürülmemiş olmalı.
  static Future<void> enqueue({
    required Gift gift,
    required String davaId,
    required String email,
  }) async {
    await _ensureBox();
    final String id = const Uuid().v4();
    final Map<String, dynamic> row = <String, dynamic>{
      'id': id,
      'gift': gift.toJson(),
      'davaId': davaId.trim(),
      'email': email.trim(),
      'masrafLine': masrafLineForGift(gift),
      'price': gift.price,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _box!.put(id, row);
  }

  static Future<int> pendingCount() async {
    await _ensureBox();
    return _box!.length;
  }

  /// Sıradaki kayıtları uygular. Başarılı olanlar kutudan silinir; başarısız
  /// olanlar yerinde kalır (taslakta `clear()` sonrası veri kaybı yok).
  ///
  /// Doğrudan [HiveDatabaseService] kullanır ([DavaProvider.executeAsync]
  /// loading tetiklemez).
  static Future<int> processPending({void Function()? onAnyApplied}) async {
    await _ensureBox();
    if (_box!.isEmpty) {
      return 0;
    }

    final List<dynamic> keys = _box!.keys.toList(growable: false);
    int applied = 0;

    for (final dynamic key in keys) {
      final Object? raw = _box!.get(key);
      if (raw is! Map) {
        await _box!.delete(key);
        continue;
      }

      final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
      final String? davaId = row['davaId']?.toString();
      final String? email = row['email']?.toString();
      final int price = (row['price'] as num?)?.toInt() ?? 0;

      if (davaId == null ||
          davaId.isEmpty ||
          email == null ||
          email.isEmpty ||
          price < 0) {
        await _box!.delete(key);
        continue;
      }

      Gift gift;
      try {
        final Object? giftRaw = row['gift'];
        if (giftRaw is Map) {
          gift = Gift.fromJson(Map<String, dynamic>.from(giftRaw));
        } else {
          await _box!.delete(key);
          continue;
        }
      } catch (_) {
        await _box!.delete(key);
        continue;
      }

      final String line = (row['masrafLine']?.toString().isNotEmpty ?? false)
          ? row['masrafLine']!.toString()
          : masrafLineForGift(gift);

      final int balance = await UserStarBalanceStore.getYellowStars(email);
      if (balance < price) {
        continue;
      }

      final bool spent =
          await UserStarBalanceStore.trySpendYellowStars(email, price);
      if (!spent) {
        continue;
      }

      try {
        await HiveDatabaseService.saveMasrafExpenses(
          davaId: davaId,
          userEmail: email,
          expenses: <String>[line],
        );
      } catch (_) {
        await UserStarBalanceStore.addYellowStars(email, price);
        continue;
      }

      await _box!.delete(key);
      applied++;
    }

    if (applied > 0) {
      onAnyApplied?.call();
    }
    return applied;
  }
}
