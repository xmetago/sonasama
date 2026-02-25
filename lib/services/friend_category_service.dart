import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend_category_model.dart';

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
}


