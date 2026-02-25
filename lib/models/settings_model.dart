import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 11)
class SettingsModel extends HiveObject {
  @HiveField(0)
  final String userEmail;

  @HiveField(1)
  Map<String, bool> privacySettings;

  @HiveField(2)
  Map<String, String> stringSettings;

  @HiveField(3)
  String? profileImageUrl;

  @HiveField(4)
  String? philosophy;

  @HiveField(5)
  String? postrestantAddress;

  @HiveField(6)
  String? country;

  @HiveField(7)
  String? language;

  @HiveField(8)
  DateTime lastUpdated;

  SettingsModel({
    required this.userEmail,
    Map<String, bool>? privacySettings,
    Map<String, String>? stringSettings,
    this.profileImageUrl,
    this.philosophy,
    this.postrestantAddress,
    this.country,
    this.language,
    DateTime? lastUpdated,
  }) : 
    privacySettings = privacySettings ?? _getDefaultPrivacySettings(),
    stringSettings = stringSettings ?? _getDefaultStringSettings(),
    lastUpdated = lastUpdated ?? DateTime.now();

  static Map<String, bool> _getDefaultPrivacySettings() {
    return {
      // SEYİR DEFTERİMİ GÖRSÜN
      "seyir_arkadaslar": false,
      "seyir_takipciler": false,
      "seyir_davalllarim": false,
      "seyir_herkes": true, // ✅ OK - Herkes görebilir

      // ONLINE GÖRÜNME
      "online_arkadaslar": true, // ✅ OK - Arkadaşlar görebilir
      "online_takipciler": false,
      "online_davalllarim": false,
      "online_herkes": false,

      // MESAJ
      "mesaj_arkadaslar": false,
      "mesaj_takipciler": false,
      "mesaj_davalllarim": false,
      "mesaj_herkes": true, // ✅ OK - Herkes mesaj atabilir

      // GENEL
      "genel_18": false,
      "genel_davaacilsin": true, // ✅ OK - Dava açılabilir
      "genel_postrestant": true, // ✅ OK - Postrestant adres görünür
      "genel_tanimak": false,

      // DAVETLER
      "davet_eylem": true, // ✅ OK - Eylem davetleri alabilir
      "davet_dava": true, // ✅ OK - Dava davetleri alabilir
      "davet_arkadaslik": true, // ✅ OK - Arkadaşlık davetleri alabilir
      "davet_7yargic": true, // ✅ OK - 7-Yargıç davetleri alabilir

      // ŞU ADLA GÖRÜN
      "adim_soyadim": false,
      "yargic_adim": false,
      "eposta": false,
    };
  }

  static Map<String, String> _getDefaultStringSettings() {
    return {
      "display_name_type": "yargic_adim", // Varsayılan olarak yargıç adı gösterilir
    };
  }

  // Ayarları güncelleme
  void updatePrivacySetting(String key, bool value) {
    privacySettings[key] = value;
    lastUpdated = DateTime.now();
  }

  // Tüm ayarları sıfırlama
  void resetToDefaults() {
    privacySettings = _getDefaultPrivacySettings();
    lastUpdated = DateTime.now();
  }

  // Ayarları kopyalama
  SettingsModel copyWith({
    String? userEmail,
    Map<String, bool>? privacySettings,
    String? profileImageUrl,
    String? philosophy,
    String? postrestantAddress,
    String? country,
    String? language,
    DateTime? lastUpdated,
  }) {
    return SettingsModel(
      userEmail: userEmail ?? this.userEmail,
      privacySettings: privacySettings ?? Map.from(this.privacySettings),
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      philosophy: philosophy ?? this.philosophy,
      postrestantAddress: postrestantAddress ?? this.postrestantAddress,
      country: country ?? this.country,
      language: language ?? this.language,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
