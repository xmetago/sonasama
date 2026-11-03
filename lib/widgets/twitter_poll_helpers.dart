import 'package:flutter/material.dart';

/// Twitter/X anket mavi tonu (görseldeki çerçeve/metin rengine yakın)
const Color kTwitterPollBlue = Color(0xFF1D9BF0);

/// Anket alanını ayırt etmek için (adalet terazisi)
Widget pollTypeBadgeIcon({double size = 18}) {
  return Icon(
    Icons.balance,
    size: size,
    color: kTwitterPollBlue.withValues(alpha: 0.9),
  );
}

/// Anket bitişine kalan tam gün sayısı (eski kayıtlar için `createdAt` + `duration` ile tahmin)
int pollDaysLeftFromData(Map<String, dynamic> pollData) {
  final endsAtStr = pollData['endsAt']?.toString();
  DateTime? end;
  if (endsAtStr != null && endsAtStr.isNotEmpty) {
    end = DateTime.tryParse(endsAtStr);
  }
  if (end == null) {
    final created =
        DateTime.tryParse(pollData['createdAt']?.toString() ?? '') ??
            DateTime.now();
    final dur = pollData['duration'];
    final days = dur is int ? dur : int.tryParse(dur.toString()) ?? 1;
    end = created.add(Duration(days: days));
  }
  final diff = end.difference(DateTime.now());
  if (diff.isNegative) return 0;
  return diff.inDays.clamp(0, 3650);
}

int pollAsInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
