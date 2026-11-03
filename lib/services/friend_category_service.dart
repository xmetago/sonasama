import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend_category_model.dart';
import '../models/registration_model.dart';
import '../utils/proximity_category_rules.dart';
import 'hive_database_service.dart';

/// Tek yönlü arkadaş kategorileri için ayrı Hive servisi
class FriendCategoryService {
  static const String _boxName = 'friend_category_box';
  static Box<FriendCategoryModel>? _box;

  /// Başlatma: adapter kaydı ve box açma
  static Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(FriendCategoryModelAdapter());
    }
    _box ??= await Hive.openBox<FriendCategoryModel>(_boxName);
    await migrateHerkesToTakipci();
  }

  /// Kaldırılan "Herkes" kayıtlarını Takipçi'ye taşır.
  static Future<void> migrateHerkesToTakipci() async {
    final box = _box;
    if (box == null) return;
    for (final record in box.values.toList()) {
      final lower = record.category.toLowerCase();
      if (!lower.contains('herkes')) continue;
      await box.put(
        record.id,
        record.copyWith(
          category: ProximityCategoryRules.takipci,
          updatedAt: record.updatedAt ?? record.createdAt,
        ),
      );
    }
  }

  static int countInCategory(String ownerUserId, String category) {
    final canonical = ProximityCategoryRules.normalize(category);
    return listByOwner(ownerUserId)
        .where((r) => ProximityCategoryRules.normalize(r.category) == canonical)
        .length;
  }

  /// Hedefi Grup-19 olarak işaretleyen sahip sayısı (Sosyal Lig).
  static int countOwnersWhoCategorized(String targetUserId, String category) {
    final canonical = ProximityCategoryRules.normalize(category);
    return _box?.values
            .where((r) =>
                r.targetUserId == targetUserId &&
                ProximityCategoryRules.normalize(r.category) == canonical)
            .length ??
        0;
  }

  /// 19 günlük kilit ve kapasite kurallarıyla kategori ata veya kaldır.
  static Future<ProximityAssignResult> assignCategory({
    required String ownerUserId,
    required String targetUserId,
    required String? category,
  }) async {
    await initialize();
    final existing = getByOwnerAndTarget(ownerUserId, targetUserId);
    final now = DateTime.now();

    if (existing != null) {
      final remaining = ProximityCategoryRules.remainingCooldown(
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
        now: now,
      );
      if (remaining != null) {
        final days = ProximityCategoryRules.remainingDays(remaining);
        return ProximityAssignResult(
          success: false,
          remainingDays: days,
          message:
              'Yakınlık kategorisi yalnızca ${ProximityCategoryRules.cooldownDays} günde bir değişebilir. $days gün sonra tekrar deneyin.',
        );
      }
    }

    if (category == null || category.trim().isEmpty) {
      if (existing != null) {
        await delete(existing.id);
      }
      return const ProximityAssignResult(
        success: true,
        message: 'Kategori kaldırıldı.',
      );
    }

    final canonical = ProximityCategoryRules.normalize(category);
    if (canonical == null) {
      return const ProximityAssignResult(
        success: false,
        message: 'Geçersiz yakınlık kategorisi.',
      );
    }

    final currentCanonical =
        ProximityCategoryRules.normalize(existing?.category);
    if (canonical != currentCanonical) {
      final limit = ProximityCategoryRules.limitFor(canonical);
      if (limit >= 0) {
        final count = countInCategory(ownerUserId, canonical);
        if (count >= limit) {
          return ProximityAssignResult(
            success: false,
            message: '$canonical kategorisi dolu. Limit: $limit kişi.',
          );
        }
      }
    }

    final record = FriendCategoryModel(
      id: existing?.id ?? '${ownerUserId}_$targetUserId',
      ownerUserId: ownerUserId,
      targetUserId: targetUserId,
      category: canonical,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await upsert(record);
    return ProximityAssignResult(
      success: true,
      message: '$canonical kategorisine eklendi.',
    );
  }

  /// Kayıt ekle veya güncelle
  static Future<void> upsert(FriendCategoryModel record) async {
    await _box?.put(record.id, record);
  }

  /// Sil
  static Future<void> delete(String id) async {
    await _box?.delete(id);
  }

  /// Sahibin bir kullanıcı için kategorisini getir
  static FriendCategoryModel? getByOwnerAndTarget(String ownerUserId, String targetUserId) {
    try {
      return _box?.values.firstWhere(
        (r) => r.ownerUserId == ownerUserId && r.targetUserId == targetUserId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sahibin tüm kategori kayıtlarını getir
  static List<FriendCategoryModel> listByOwner(String ownerUserId) {
    return _box?.values.where((r) => r.ownerUserId == ownerUserId).toList() ?? [];
  }

  /// Sahibin belirli kategori adındaki kayıtlarını getir
  static List<FriendCategoryModel> listByOwnerAndCategory(String ownerUserId, String category) {
    return _box?.values
            .where((r) => r.ownerUserId == ownerUserId && r.category == category)
            .toList() ?? [];
  }

  /// Eski email tabanlı friend_group_box verisini yeni sisteme taşır (bir kez).
  static Future<int> migrateLegacyCategoriesIfNeeded({
    required String ownerUserId,
    required String ownerEmail,
    required List<RegistrationModel> allUsers,
  }) async {
    if (listByOwner(ownerUserId).isNotEmpty) return 0;

    final legacy = HiveDatabaseService.getFriendCategories(ownerEmail);
    if (legacy.isEmpty) return 0;

    var migrated = 0;
    for (final entry in legacy.entries) {
      final targetUser = _findUserByEmail(allUsers, entry.key);
      if (targetUser == null) continue;

      await upsert(FriendCategoryModel(
        id: '${ownerUserId}_${targetUser.id}',
        ownerUserId: ownerUserId,
        targetUserId: targetUser.id,
        category: entry.value,
        createdAt: DateTime.now(),
      ));
      migrated++;
    }

    if (migrated > 0) {
      print('✅ $migrated eski kategori kaydı FriendCategoryService\'e taşındı');
    }
    return migrated;
  }

  /// Yeni sisteme kayıt yazarken davet sistemi için eski kutuyu da günceller.
  static Future<void> syncLegacyBox({
    required String ownerEmail,
    required String targetEmail,
    required String category,
  }) async {
    await HiveDatabaseService.setFriendCategory(
      ownerEmail: ownerEmail,
      friendEmail: targetEmail,
      category: category,
    );
  }

  static Future<void> removeLegacyBoxEntry({
    required String ownerEmail,
    required String targetEmail,
  }) async {
    await HiveDatabaseService.removeFriendCategory(
      ownerEmail: ownerEmail,
      friendEmail: targetEmail,
    );
  }

  static RegistrationModel? _findUserByEmail(
    List<RegistrationModel> users,
    String email,
  ) {
    for (final user in users) {
      if (user.email == email) return user;
    }
    return null;
  }
}


