import 'package:flutter/foundation.dart';

import '../models/dava_draft_state.dart';
import '../services/hive_database_service.dart';

/// Dava taslakları için Hive erişimlerini yöneten servis.
class DavaDraftService {
  /// Hive veritabanından kaydedilmiş tüm taslakları çeker.
  static List<DavaDraftState> loadSavedDrafts() {
    final rawDrafts = HiveDatabaseService.getSavedDavalar();
    return rawDrafts.map(DavaDraftState.fromMap).toList();
  }

  /// Taslağı Hive'a kaydeder veya günceller.
  static Future<void> upsertDraft(DavaDraftState draft) async {
    HiveDatabaseService.saveDava(draft.toHiveMap());
  }

  /// Taslağı Hive'dan siler.
  static Future<void> deleteDraft(String draftId) async {
    HiveDatabaseService.deleteSavedDava(draftId);
  }

  /// Yeni benzersiz dava kimliği üretir.
  static String generateDraftId(String? userEmail) {
    return HiveDatabaseService.generateUniqueDavaId(userEmail ?? 'unknown');
  }

  /// Taslak içeriğinin kaydedilmeye değer olup olmadığını kontrol eder.
  static bool shouldPersist(DavaDraftState draft) {
    return draft.shouldAutoSave;
  }

  /// Taslağı "beklemede" durumunda kaydeder. Gerekiyorsa varsayılan alanları doldurur.
  static Future<void> persistPendingDraft({
    required DavaDraftState draft,
    required String fallbackTitle,
  }) async {
    if (!shouldPersist(draft)) return;

    final normalizedDraft = draft.copyWith(
      title: draft.title.trim().isEmpty || draft.title == DavaDraftState.placeholderTitle
          ? fallbackTitle
          : draft.title,
      defendant: draft.defendant.trim().isEmpty || draft.defendant == DavaDraftState.placeholderDefendant
          ? 'Beklemede'
          : draft.defendant,
      description: draft.description.trim().isEmpty ? 'Beklemede' : draft.description,
      categoryPath: draft.categoryPath.trim().isEmpty ? 'Genel' : draft.categoryPath,
    );

    await upsertDraft(normalizedDraft);
  }

  /// Hive kaydetme sorunlarını loglar.
  static void showPersistenceError(dynamic error) {
    debugPrint('❌ Taslak kaydedilirken hata oluştu: $error');
  }
}


