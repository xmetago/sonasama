import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Hüküm metninin yönünü belirtir.
enum HukumSentiment { positive, negative }

/// Hüküm yönü ile ilgili yardımcı extension.
extension HukumSentimentX on HukumSentiment {
  /// Depolama için kullanılan string değer.
  String get storageValue => name;

  /// İlgili ikon bilgisi.
  IconData get icon => switch (this) {
        HukumSentiment.positive => MdiIcons.emoticonHappyOutline,
        HukumSentiment.negative => MdiIcons.emoticonCryOutline,
      };

  /// İlgili renk bilgisi.
  Color get color => switch (this) {
        HukumSentiment.positive => Colors.orange,
        HukumSentiment.negative => Colors.blue,
      };

  /// Kullanıcıya gösterilecek kısa etiket.
  String get label => switch (this) {
        HukumSentiment.positive => 'Olumlu',
        HukumSentiment.negative => 'Olumsuz',
      };

  /// Kullanıcıya gösterilecek açıklama.
  String get description => switch (this) {
        HukumSentiment.positive =>
            'Dava hakkında olumlu yönde fikir beyan ediyorsunuz.',
        HukumSentiment.negative =>
            'Dava hakkında olumsuz yönde fikir beyan ediyorsunuz.',
      };

  /// [HukumSentimentSelector] seçili kartındaki gradient ile aynı tona yakın zemin.
  Color get actionSurfaceColor =>
      Color.alphaBlend(color.withOpacity(0.28), Colors.white);

  /// [actionSurfaceColor] üzerinde okunaklı ikon/metin rengi.
  Color get onActionSurfaceColor => switch (this) {
        HukumSentiment.positive => Colors.orange.shade900,
        HukumSentiment.negative => Colors.blue.shade900,
      };

  /// Hüküm Verildi kenarlığı için vurgu rengi.
  Color get actionBorderColor => switch (this) {
        HukumSentiment.positive => Colors.orange.shade600,
        HukumSentiment.negative => Colors.blue.shade600,
      };
}

/// Depolanan string değerden [HukumSentiment] üretir.
HukumSentiment? hukumSentimentFromStorage(String? value) {
  switch (value) {
    case 'positive':
      return HukumSentiment.positive;
    case 'negative':
      return HukumSentiment.negative;
    default:
      return null;
  }
}

