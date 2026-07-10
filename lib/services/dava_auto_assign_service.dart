import 'dart:math';

import 'hive_database_service.dart';
import 'dava_timer_service.dart';

/// 120. saatten sonra boş kalan mevkilere rastgele atama (RoleAssigned).
class DavaAutoAssignService {
  DavaAutoAssignService._();

  /// Gelen davalar / rol seçimi ile uyumlu standart görev listesi.
  static const List<String> standardCaseRoles = [
    'Temyiz hakimi',
    'Yargıç',
    'Davacı avukatı',
    'Davalı avukatı',
    '1.Jüri',
    '2.Jüri',
    'Davacı Şahidi',
    'Davalı Şahidi',
  ];

  /// Kullanıcının 8 standart rolden biriyle seçilip seçilmediğini kontrol eder.
  static bool isStandardCaseRole(String? mevkii) {
    final role = (mevkii ?? '').trim();
    if (role.isEmpty) return false;
    final compact = _compactRole(role);
    for (final standard in standardCaseRoles) {
      if (_compactRole(standard) == compact) {
        return true;
      }
    }
    return false;
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

  /// Tüm açılan davalar için süresi dolmuş olanlarda otomatik atamayı dene.
  static Future<int> processAllOpenedDavalar() async {
    final opened = HiveDatabaseService.getOpenedDavalar();
    var n = 0;
    final now = DateTime.now();
    for (final d in opened) {
      if (d['isArchived'] == true) continue;
      final id = (d['id'] ?? d['davaId'])?.toString() ?? '';
      if (id.isEmpty) continue;

      final openedAt = DavaTimerService.parseOpenedAt(d);
      if (openedAt != null &&
          DavaTimerService.shouldArchiveByPolicy(openedAt, now) &&
          d['isArchived'] != true) {
        await HiveDatabaseService.updateOpenedDava(id, {
          'isArchived': true,
          'lifecycleStatus': DavaLifecycleStatuses.archived,
          'archivedAt': now.toIso8601String(),
        });
        continue;
      }

      final ok = await runAutoAssignIfNeededForDava(
        davaId: id,
        openedDavaMap: d,
      );
      if (ok) n++;
    }
    return n;
  }

  /// [openedDavaMap] verilmişse ek Hive okuması yapılmaz.
  static Future<bool> runAutoAssignIfNeededForDava({
    required String davaId,
    Map<String, dynamic>? openedDavaMap,
  }) async {
    final opened = openedDavaMap ?? HiveDatabaseService.getOpenedDavaById(davaId);
    if (opened == null) return false;
    if (opened['isArchived'] == true) return false;

    final status = (opened['lifecycleStatus'] ?? DavaLifecycleStatuses.awaitingRole)
        .toString();
    if (status != DavaLifecycleStatuses.awaitingRole) return false;

    final openedAt = DavaTimerService.parseOpenedAt(opened);
    if (openedAt == null) return false;

    if (DateTime.now().difference(openedAt) < DavaTimerService.voluntaryRoleWindow) {
      return false;
    }

    final participants =
        await HiveDatabaseService.getDavaParticipants(davaId, normalizeExpired: false);

    final taken = <String>{};
    for (final p in participants) {
      final m = (p['mevkii'] ?? p['userRole'])?.toString().trim() ?? '';
      if (m.isNotEmpty) taken.add(m);
    }

    var freeRoles =
        standardCaseRoles.where((r) => !taken.contains(r)).toList();
    freeRoles.shuffle(Random());

    final candidates = participants.where((p) {
      final st = p['status']?.toString() ?? '';
      if (st != 'pending') return false;
      final m = (p['mevkii']?.toString() ?? '').trim();
      return m.isEmpty;
    }).toList();

    final assignCount = min(candidates.length, freeRoles.length);
    for (var i = 0; i < assignCount; i++) {
      final email = candidates[i]['userEmail']?.toString() ?? '';
      if (email.isEmpty) continue;
      final role = freeRoles[i];
      await HiveDatabaseService.markDavaParticipantStatus(
        davaId: davaId,
        userEmail: email,
        status: 'accepted',
        reason: 'auto_assign',
        extra: {
          'mevkii': role,
          'userRole': role,
          'autoAssigned': true,
        },
      );
    }

    await HiveDatabaseService.updateOpenedDava(davaId, {
      'lifecycleStatus': DavaLifecycleStatuses.roleAssigned,
      'lifecycleStatusAt': DateTime.now().toIso8601String(),
      'autoAssignCompletedAt': DateTime.now().toIso8601String(),
    });

    return true;
  }
}
