import 'dava_hukum_eligibility_service.dart';
import 'dava_timer_service.dart';

/// Hive ceza kaydı. Eski kayıtlar düz metindir; yeni mühürler metin + tarihi tutar.
class CezaKaydi {
  const CezaKaydi({
    required this.text,
    this.sealedAt,
  });

  final String text;
  final DateTime? sealedAt;

  static const int schemaVersion = 2;

  bool get isSealed => text.trim().isNotEmpty;

  /// Düz metin (eski) veya `{v, text, sealedAt}` haritası.
  static CezaKaydi? parse(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      final String text = raw.trim();
      if (text.isEmpty) {
        return null;
      }
      return CezaKaydi(text: text);
    }
    if (raw is Map) {
      final String text = (raw['text'] ?? raw['cezaText'] ?? '').toString().trim();
      if (text.isEmpty) {
        return null;
      }
      final Object? sealedRaw = raw['sealedAt'] ?? raw['muhurTarihi'];
      final DateTime? sealedAt = sealedRaw == null
          ? null
          : DateTime.tryParse(sealedRaw.toString());
      return CezaKaydi(text: text, sealedAt: sealedAt);
    }
    final String text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return CezaKaydi(text: text);
  }

  /// Tarihli mühür. Tarihsiz çağrılar eski düz metin biçiminde yazılır.
  Map<String, dynamic> toPersisted() {
    return <String, dynamic>{
      'v': schemaVersion,
      'text': text,
      if (sealedAt != null) 'sealedAt': sealedAt!.toIso8601String(),
    };
  }
}

/// Mühür zamanı gelmeden basılırsa kullanıcıya gösterilen kilit.
class CezaMuhurKilit {
  const CezaMuhurKilit.acik()
      : kilitli = false,
        neden = null;

  const CezaMuhurKilit.kilitli(this.neden) : kilitli = true;

  final bool kilitli;
  final String? neden;

  /// Hüküm kartındaki kilit ile aynı kapı.
  ///
  /// [DavaTimerService] fazları:
  /// yargıç, 144. saatte başlayan karar döneminde veya altı rol
  /// hükmünü bitirdiyse mühürler; temyiz hakimi yalnızca ana süre
  /// bittikten sonraki temyiz penceresinde; diğer roller ana 168 saat
  /// içinde mühürler, sonrası kilitlenir.
  static CezaMuhurKilit degerlendir({
    required String gorev,
    required DateTime? openedAt,
    required DateTime now,
    required bool altiRolTamam,
    required bool temyizPenceresiAcik,
  }) {
    final bool anaSureBitti =
        DavaHukumEligibilityService.isMainTrialEnded(openedAt, now);
    final bool temyizDuzenleme = temyizPenceresiAcik && anaSureBitti;
    final bool isTemyiz = DavaHukumEligibilityService.roleLabelIsTemyiz(gorev);
    final bool isYargic = _gorevYargic(gorev);

    if (temyizDuzenleme) {
      if (!isTemyiz) {
        return const CezaMuhurKilit.kilitli(
          'Temyiz süreci aktif: yalnızca Temyiz Hakimi mühürleyebilir.',
        );
      }
      return const CezaMuhurKilit.acik();
    }

    if (isTemyiz) {
      return const CezaMuhurKilit.kilitli(
        'Temyiz hükmü; 7 gün sonrası temyiz talebinden sonra 72 saatlik süre içinde mühürlenir.',
      );
    }

    if (isYargic) {
      final bool kararDonemi = openedAt != null &&
          now.difference(openedAt) >= const Duration(hours: 144);
      if (!kararDonemi && !altiRolTamam) {
        return const CezaMuhurKilit.kilitli(
          'Yargıç: Altı rol (jüri, avukatlar, şahitler) hükmünü tamamlayana '
          'veya 144. saat (yargıç karar dönemi) dolana kadar mühür kilitli.',
        );
      }
      return const CezaMuhurKilit.acik();
    }

    if (anaSureBitti && openedAt != null) {
      return const CezaMuhurKilit.kilitli(
        'Ana dava süresi (168 saat) tamamlandı; ceza artık mühürlenemez.',
      );
    }

    return const CezaMuhurKilit.acik();
  }
}

/// "Yargıç" küçük harfe inince ı düz i olur; paylaşılan yardımcı bu hali kaçırır.
bool _gorevYargic(String gorev) {
  if (DavaHukumEligibilityService.roleLabelIsYargic(gorev)) {
    return true;
  }
  final String folded = gorev
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ı', 'i');
  return folded.contains('yargic');
}

/// Panelin ceza kaydını yazması. Üretimde [DavaProvider], testte sahte kayıt.
typedef CezaKaydedici = Future<bool> Function({
  required String davaId,
  required String userEmail,
  required String cezaText,
  required DateTime sealedAt,
});
