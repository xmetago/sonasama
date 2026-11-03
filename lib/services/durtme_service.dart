import 'package:flutter/foundation.dart';

import 'chat_service.dart';
import 'hive_database_service.dart';

enum DurtmeSendResult { success, cooldown, noSession, error }

enum DurtmeBlockReason {
  samePersonDaily,
  senderGlobalLimit,
  receiverRecentlyNudged,
}

/// Profilde gösterilen aktif dürtme bilgisi.
class ActiveDurtmeOnProfile {
  final String kelime;
  final String senderName;

  const ActiveDurtmeOnProfile({
    required this.kelime,
    required this.senderName,
  });
}

/// Kullanıcılar arası dürtme (poke) işlemleri.
class DurtmeService {
  /// Aynı kişiye günde en fazla 1 dürtme.
  static const Duration pairDailyCooldown = Duration(hours: 24);

  /// Gönderen 19 saat içinde yalnızca 1 kişiyi dürtülebilir.
  static const Duration senderGlobalCooldown = Duration(hours: 19);

  /// Dürtülen kişi 19 dakika boyunca tekrar dürtülemez.
  static const Duration receiverShieldDuration = Duration(minutes: 19);

  static const Duration kelimeDisplayDuration = Duration(hours: 19);

  static Future<
      ({
        DurtmeSendResult result,
        Duration? remaining,
        DurtmeBlockReason? reason,
      })> sendDurtme({
    required String senderEmail,
    required String receiverId,
    required String receiverEmail,
    required String kelime,
  }) async {
    final receiverShieldRemaining =
        HiveDatabaseService.getDurtmeReceiverShieldRemaining(
      receiverEmail,
      shieldDuration: receiverShieldDuration,
    );
    if (receiverShieldRemaining != null &&
        receiverShieldRemaining > Duration.zero) {
      return (
        result: DurtmeSendResult.cooldown,
        remaining: receiverShieldRemaining,
        reason: DurtmeBlockReason.receiverRecentlyNudged,
      );
    }

    final pairDailyRemaining =
        HiveDatabaseService.getDurtmeCooldownRemaining(
      senderEmail,
      receiverEmail,
      cooldown: pairDailyCooldown,
    );
    if (pairDailyRemaining != null && pairDailyRemaining > Duration.zero) {
      return (
        result: DurtmeSendResult.cooldown,
        remaining: pairDailyRemaining,
        reason: DurtmeBlockReason.samePersonDaily,
      );
    }

    final senderGlobalRemaining =
        HiveDatabaseService.getDurtmeSenderGlobalCooldownRemaining(
      senderEmail,
      receiverEmail,
      cooldown: senderGlobalCooldown,
    );
    if (senderGlobalRemaining != null &&
        senderGlobalRemaining > Duration.zero) {
      return (
        result: DurtmeSendResult.cooldown,
        remaining: senderGlobalRemaining,
        reason: DurtmeBlockReason.senderGlobalLimit,
      );
    }

    final sender = HiveDatabaseService.getRegistrationByEmail(senderEmail);
    if (sender == null) {
      return (
        result: DurtmeSendResult.noSession,
        remaining: null,
        reason: null,
      );
    }

    try {
      await ChatService.sendMessage(
        receiverId: receiverId,
        receiverEmail: receiverEmail,
        text: '👋 Seni dürtüyorum: $kelime',
      );

      await HiveDatabaseService.appendDurtmeBildirimi(
        receiverEmail: receiverEmail,
        senderName: sender.judgeName,
        senderEmail: senderEmail,
        kelime: kelime,
      );

      await HiveDatabaseService.recordDurtmeCooldown(
        senderEmail,
        receiverEmail,
      );

      await HiveDatabaseService.recordDurtmeSenderLast(
        senderEmail,
        receiverEmail,
      );

      await HiveDatabaseService.recordLastDurtmeOnProfile(
        receiverEmail: receiverEmail,
        senderEmail: senderEmail,
        senderName: sender.judgeName,
        kelime: kelime,
      );

      return (
        result: DurtmeSendResult.success,
        remaining: null,
        reason: null,
      );
    } catch (e) {
      debugPrint('❌ Dürtme gönderilemedi: $e');
      return (
        result: DurtmeSendResult.error,
        remaining: null,
        reason: null,
      );
    }
  }

  static String cooldownMessage({
    required DurtmeBlockReason reason,
    required Duration remaining,
  }) {
    final text = formatCooldown(remaining);
    switch (reason) {
      case DurtmeBlockReason.samePersonDaily:
        return 'Bu kişiyi günde yalnızca 1 kez dürtülebilirsiniz. Tekrar dürtmek için $text bekleyin';
      case DurtmeBlockReason.senderGlobalLimit:
        return '19 saat içinde yalnızca 1 kişi dürtülebilir. Tekrar dürtmek için $text bekleyin';
      case DurtmeBlockReason.receiverRecentlyNudged:
        return 'Bu kişi yakın zamanda dürtüldü. Tekrar dürtmek için $text bekleyin';
    }
  }

  static String formatCooldown(Duration remaining) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours > 0) {
      return '$hours sa${minutes > 0 ? ' $minutes dk' : ''}';
    }
    if (minutes > 0) {
      final seconds = remaining.inSeconds % 60;
      return '$minutes dk${seconds > 0 ? ' $seconds sn' : ''}';
    }
    return '${remaining.inSeconds} sn';
  }

  /// Profil sahibine en son dürtme yapıldıysa bilgiler (19 saat geçerli).
  static ActiveDurtmeOnProfile? getActiveDurtmeForProfile({
    required String profileEmail,
  }) {
    final raw = HiveDatabaseService.getActiveDurtmeOnProfileRaw(
      receiverEmail: profileEmail,
      maxAge: kelimeDisplayDuration,
    );
    if (raw == null) return null;

    final kelime = raw['kelime']?.toString();
    if (kelime == null || kelime.isEmpty) return null;

    var senderName = raw['senderName']?.toString().trim();
    if (senderName == null || senderName.isEmpty) {
      final senderEmail = raw['senderEmail']?.toString();
      if (senderEmail != null && senderEmail.isNotEmpty) {
        senderName = HiveDatabaseService.getRegistrationByEmail(senderEmail)
                ?.judgeName ??
            'Bilinmeyen';
      } else {
        senderName = 'Bilinmeyen';
      }
    }

    return ActiveDurtmeOnProfile(
      kelime: kelime,
      senderName: senderName,
    );
  }

  /// Profilde gösterim için Türkçe büyük harf (ör. İyi → İYİ).
  static String formatKelimeLabel(String kelime) {
    final buffer = StringBuffer();
    for (final rune in kelime.runes) {
      buffer.write(_turkishUpperChar(String.fromCharCode(rune)));
    }
    return buffer.toString();
  }

  static String _turkishUpperChar(String char) {
    switch (char.toLowerCase()) {
      case 'i':
        return 'İ';
      case 'ı':
        return 'I';
      case 'ş':
        return 'Ş';
      case 'ğ':
        return 'Ğ';
      case 'ü':
        return 'Ü';
      case 'ö':
        return 'Ö';
      case 'ç':
        return 'Ç';
      default:
        return char.toUpperCase();
    }
  }
}
