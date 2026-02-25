import '../models/dava.dart' as dava_model;

/// Dava Aç ekranındaki geçici form durumunu temsil eder.
class DavaDraftState {
  static const int minDescriptionLength = 285;
  static const int maxDescriptionLength = 988;
  static const String placeholderTitle = 'Ad  ver ';
  static const String placeholderDefendant = 'Davalı  adını gir ';

  final String id;
  final String title;
  final String defendant;
  final String position;
  final String remainingTime;
  final String avatarPath;
  final String description;
  final String categoryPath;
  final String plaintiff;
  final bool isOpened;

  const DavaDraftState({
    required this.id,
    required this.title,
    required this.defendant,
    required this.position,
    required this.remainingTime,
    required this.avatarPath,
    required this.description,
    required this.categoryPath,
    required this.plaintiff,
    required this.isOpened,
  });

  factory DavaDraftState.initial() {
    return const DavaDraftState(
      id: '',
      title: placeholderTitle,
      defendant: placeholderDefendant,
      position: 'Davalı',
      remainingTime: '.../.../.....',
      avatarPath: 'lib/icons/03_davala_ana_icon.png',
      description: '',
      categoryPath: '',
      plaintiff: '',
      isOpened: false,
    );
  }

  factory DavaDraftState.fromMap(Map<String, dynamic> map) {
    return DavaDraftState(
      id: map['id']?.toString() ?? '',
      title: map['adi']?.toString() ??
          map['davaAdi']?.toString() ??
          placeholderTitle,
      defendant: map['davali']?.toString() ?? placeholderDefendant,
      position: map['mevkii']?.toString() ?? 'Davalı',
      remainingTime: map['kalanSure']?.toString() ?? '.../.../.....',
      avatarPath:
          map['profilResmi']?.toString() ?? 'lib/icons/03_davala_ana_icon.png',
      description: map['davaKonusu']?.toString() ?? '',
      categoryPath: map['davaKategorisi']?.toString() ??
          map['kategori']?.toString() ??
          '',
      plaintiff: map['davaci']?.toString() ?? '',
      isOpened: map['isOpened'] == true,
    );
  }

  factory DavaDraftState.fromDavaModel(dava_model.Dava source) {
    return DavaDraftState(
      id: source.id,
      title: source.davaAdi,
      defendant: source.davali,
      position: source.mevkii,
      remainingTime: source.kalanSure,
      avatarPath: source.profilResmi,
      description: source.davaKonusu,
      categoryPath: source.kategori,
      plaintiff: source.davaci,
      isOpened: source.isOpened,
    );
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'adi': title,
      'davaAdi': title,
      'davali': defendant,
      'mevkii': position,
      'kalanSure': remainingTime,
      'profilResmi': avatarPath,
      'davaKonusu': description,
      'davaKategorisi': categoryPath,
      'kategori': categoryPath,
      'davaci': plaintiff,
      'isOpened': isOpened,
    };
  }

  dava_model.Dava toDavaModel() {
    return dava_model.Dava(
      id: id,
      davaAdi: title,
      davaci: plaintiff,
      davali: defendant,
      mevkii: position,
      kalanSure: remainingTime,
      profilResmi: avatarPath,
      davaKonusu: description,
      kategori: categoryPath,
      isOpened: isOpened,
    );
  }

  bool get hasMeaningfulContent {
    final normalizedTitle = title.trim();
    final normalizedDefendant = defendant.trim();
    final normalizedDescription = description.trim();
    return (normalizedTitle.isNotEmpty &&
            normalizedTitle != placeholderTitle.trim()) ||
        (normalizedDefendant.isNotEmpty &&
            normalizedDefendant != placeholderDefendant.trim()) ||
        normalizedDescription.isNotEmpty;
  }

  bool get meetsPublishCriteria {
    final normalizedTitle = title.trim();
    final normalizedDefendant = defendant.trim();
    final normalizedDescription = description.trim();
    return normalizedTitle.length >= 6 &&
        normalizedDefendant.isNotEmpty &&
        normalizedDefendant != placeholderDefendant.trim() &&
        normalizedDescription.length >= minDescriptionLength &&
        normalizedDescription.length <= maxDescriptionLength;
  }

  int get descriptionLength => description.length;

  int get remainingDescriptionTarget =>
      descriptionLength >= minDescriptionLength
          ? 0
          : minDescriptionLength - descriptionLength;

  bool get exceedsMaxLength => descriptionLength > maxDescriptionLength;

  bool get shouldAutoSave => hasMeaningfulContent && !isOpened;

  DavaDraftState copyWith({
    String? id,
    String? title,
    String? defendant,
    String? position,
    String? remainingTime,
    String? avatarPath,
    String? description,
    String? categoryPath,
    String? plaintiff,
    bool? isOpened,
  }) {
    return DavaDraftState(
      id: id ?? this.id,
      title: title ?? this.title,
      defendant: defendant ?? this.defendant,
      position: position ?? this.position,
      remainingTime: remainingTime ?? this.remainingTime,
      avatarPath: avatarPath ?? this.avatarPath,
      description: description ?? this.description,
      categoryPath: categoryPath ?? this.categoryPath,
      plaintiff: plaintiff ?? this.plaintiff,
      isOpened: isOpened ?? this.isOpened,
    );
  }

  DavaDraftState updateWithModel(dava_model.Dava model) {
    return copyWith(
      id: model.id,
      title: model.davaAdi,
      defendant: model.davali,
      position: model.mevkii,
      remainingTime: model.kalanSure,
      avatarPath: model.profilResmi,
      description: model.davaKonusu,
      categoryPath: model.kategori,
      plaintiff: model.davaci,
      isOpened: model.isOpened,
    );
  }
}
