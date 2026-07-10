import 'package:flutter/material.dart';

import '../screens/home_page.dart';
import 'hive_database_service.dart';

/// Seyir defteri ve tanınma gizlilik kontrolleri.
class UserPrivacyService {
  UserPrivacyService._();

  /// Hedef kullanıcının seyir defterini görüntüleyebilir mi?
  ///
  /// [taninmak_ok]: `genel_tanimak == true`
  /// [seyir_defterimi_gorsun]: seyir görünürlük ayarlarından en az biri
  /// izin veriyorsa ve izleyici bu kapsama giriyorsa.
  static Future<bool> canViewSeyirDefteri({
    required String targetUserEmail,
    String? viewerUserEmail,
    String? sharedDavaId,
  }) async {
    final String normalizedTarget = targetUserEmail.trim().toLowerCase();
    if (normalizedTarget.isEmpty) {
      return false;
    }

    final String? normalizedViewer = viewerUserEmail?.trim().toLowerCase();
    if (normalizedViewer != null &&
        normalizedViewer.isNotEmpty &&
        normalizedViewer == normalizedTarget) {
      return true;
    }

    final settings =
        await HiveDatabaseService.getOrCreateSettings(targetUserEmail);
    final Map<String, bool> privacy = settings.privacySettings;

    if (!(privacy['genel_tanimak'] ?? false)) {
      return false;
    }

    if (privacy['seyir_herkes'] ?? true) {
      return true;
    }

    if (normalizedViewer == null || normalizedViewer.isEmpty) {
      return false;
    }

    final targetReg = HiveDatabaseService.getRegistrationByEmail(targetUserEmail);
    final viewerReg =
        HiveDatabaseService.getRegistrationByEmail(viewerUserEmail!);
    if (targetReg == null || viewerReg == null) {
      return false;
    }

    if ((privacy['seyir_arkadaslar'] ?? false) &&
        HiveDatabaseService.areFriends(targetReg.id, viewerReg.id)) {
      return true;
    }

    if ((privacy['seyir_takipciler'] ?? false) &&
        HiveDatabaseService.isFollowing(viewerReg.id, targetReg.id)) {
      return true;
    }

    if (privacy['seyir_davalllarim'] ?? false) {
      final String? davaId = sharedDavaId?.trim();
      if (davaId != null && davaId.isNotEmpty) {
        final participants =
            await HiveDatabaseService.getDavaParticipants(davaId);
        final bool hasViewer = participants.any(
          (Map<String, dynamic> p) =>
              (p['userEmail']?.toString() ?? '').toLowerCase() ==
              normalizedViewer,
        );
        final bool hasTarget = participants.any(
          (Map<String, dynamic> p) =>
              (p['userEmail']?.toString() ?? '').toLowerCase() ==
              normalizedTarget,
        );
        if (hasViewer && hasTarget) {
          return true;
        }
      }
    }

    return false;
  }

  static void showPrivacyWarning(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('UYARI!'),
        content: const Text('Kişi tanınmak istemiyor.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static void navigateToSeyirDefteri(
    BuildContext context, {
    required String targetUserEmail,
  }) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            HomePage(userEmail: targetUserEmail),
      ),
    );
  }
}
