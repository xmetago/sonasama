import 'hive_database_service.dart';

/// Zamanlayıcı ve süre sonu işlemleri için yardımcı servis.
///
/// - 3 gün (72 saat) içinde davanın kabul edilmesi gerekir.
/// - Kabul edilen davalar 7 gün (168 saat) içinde hüküm vermelidir.
class DavaTimerService {
  /// Gelen davaların kabul edilmesi gereken maksimum süre.
  static const Duration incomingAcceptanceWindow = Duration(hours: 72);

  /// Kabul edilen davalar için hüküm verme süresi.
  static const Duration acceptedHukumWindow = Duration(hours: 168);

  /// Kabul edilen davalarda süre aşımına uğrayan kullanıcıları döndürür.
  ///
  /// Dönen listedeki her kayıt şu alanları içerir:
  /// - `mevki`: Kullanıcının görev/mevki bilgisi.
  /// - `displayName`: Kullanıcının görünen adı.
  /// - `userEmail`: Kullanıcının e-posta adresi.
  /// - `acceptedAt`: Kabul tarihi.
  /// - `expiredAt`: Süre aşımının gerçekleştiği tarih.
  static Future<List<Map<String, dynamic>>> getExpiredAcceptedParticipants({
    required String davaId,
    DateTime? referenceTime,
  }) async {
    if (davaId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final now = referenceTime ?? DateTime.now();
    final participants = await HiveDatabaseService.getDavaParticipants(
      davaId,
      normalizeExpired: false,
    );

    if (participants.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final hukumlerByRole =
        await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId);

    final List<Map<String, dynamic>> expiredList = [];

    for (final participant in participants) {
      final status = participant['status']?.toString();
      if (status != 'accepted') {
        continue;
      }

      final mevki = _extractMevki(participant);
      if (mevki.isEmpty) {
        continue;
      }

      // Eğer ilgili mevki için hüküm verilmişse süre aşımı oluşmaz.
      if (hukumlerByRole.containsKey(mevki)) {
        continue;
      }

      final acceptedAt = _parseAcceptedAt(participant);
      if (acceptedAt == null) {
        continue;
      }

      final deadline = acceptedAt.add(acceptedHukumWindow);
      if (!now.isAfter(deadline)) {
        continue;
      }

      final displayName = _resolveDisplayName(participant);
      final email = participant['userEmail']?.toString() ?? '';

      expiredList.add({
        'mevki': mevki,
        'displayName': displayName,
        'userEmail': email,
        'acceptedAt': acceptedAt,
        'expiredAt': deadline,
      });
    }

    return expiredList;
  }

  /// Süre aşımına uğrayan kullanıcılar için metinleri üretir.
  static Future<List<String>> buildExpiredAcceptedMessages({
    required String davaId,
    required String davaAdi,
    DateTime? referenceTime,
  }) async {
    final normalizedDavaAdi =
        davaAdi.trim().isEmpty ? 'Dava Adı Belirtilmemiş' : davaAdi.trim();
    final expired = await getExpiredAcceptedParticipants(
      davaId: davaId,
      referenceTime: referenceTime,
    );

    if (expired.isEmpty) {
      return <String>[];
    }

    return expired.map((participant) {
      final mevki = participant['mevki']?.toString() ?? '';
      final displayName = participant['displayName']?.toString() ?? '';
      return '"$mevki" "$displayName" vicdanı problemleri sebebi ile '
          '"$normalizedDavaAdi" davasında HÜKÜM verememiş bulunmaktadır.';
    }).toList();
  }

  static String _resolveDisplayName(Map<String, dynamic> participant) {
    final directName = participant['displayName']?.toString();
    if (directName != null && directName.trim().isNotEmpty) {
      return directName.trim();
    }

    final email = participant['userEmail']?.toString();
    if (email == null || email.trim().isEmpty) {
      return 'Bilinmeyen Yargıç';
    }

    final registration =
        HiveDatabaseService.getRegistrationByEmail(email.trim());
    if (registration?.judgeName != null &&
        registration!.judgeName.trim().isNotEmpty) {
      return registration.judgeName.trim();
    }

    return email.split('@').first;
  }

  static String _extractMevki(Map<String, dynamic> participant) {
    final mevki = participant['mevkii']?.toString();
    if (mevki != null && mevki.trim().isNotEmpty) {
      return mevki.trim();
    }

    final userRole = participant['userRole']?.toString();
    if (userRole != null && userRole.trim().isNotEmpty) {
      return userRole.trim();
    }

    return '';
  }

  static DateTime? _parseAcceptedAt(Map<String, dynamic> participant) {
    final candidates = <String?>[
      participant['acceptedAt']?.toString(),
      participant['statusUpdatedAt']?.toString(),
      participant['assignedAt']?.toString(),
    ];

    for (final candidate in candidates) {
      if (candidate == null || candidate.trim().isEmpty) {
        continue;
      }
      final parsed = DateTime.tryParse(candidate.trim());
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }
}

