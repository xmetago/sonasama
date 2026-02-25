# ITS19 Proje Dizin Yapısı

## Ana Dizin Yapısı

```
its19/
├── lib/                          # Ana kaynak kod dizini
│   ├── main.dart                # Uygulama giriş noktası
│   │
│   ├── data/                    # Statik veri dosyaları
│   │   ├── category_data.dart
│   │   └── direm_data.dart
│   │
│   ├── models/                  # Veri modelleri (32 dosya)
│   │   ├── album_image_model.dart
│   │   ├── album_model.dart
│   │   ├── category_model.dart
│   │   ├── chat_message_model.dart
│   │   ├── comment_model.dart
│   │   ├── dava_draft_state.dart
│   │   ├── dava_halk_karari_result.dart
│   │   ├── dava_model.dart
│   │   ├── dava.dart
│   │   ├── evidence_comment_model.dart
│   │   ├── evidence_model.dart
│   │   ├── friend_category_model.dart
│   │   ├── friendship_model.dart
│   │   ├── hukum_sentiment.dart
│   │   ├── registration_model.dart
│   │   ├── reklam_model.dart
│   │   ├── sekiz_hukum_arguments.dart
│   │   ├── settings_model.dart
│   │   ├── user_gamified_score_model.dart
│   │   └── user_model.dart
│   │
│   ├── screens/                 # Ekranlar/Pages (44 dosya)
│   │   ├── actigim_davalar_page.dart
│   │   ├── admin_page.dart
│   │   ├── album_goruntule_page.dart
│   │   ├── album_olustur_page.dart
│   │   ├── albumler_liste_page.dart
│   │   ├── category_page.dart
│   │   ├── cezalar_page.dart
│   │   ├── chat_detail_page.dart
│   │   ├── chat_page.dart
│   │   ├── database_debug_page.dart
│   │   ├── dava_ac_page.dart
│   │   ├── davaci_unlulur_page.dart
│   │   ├── davetler_page.dart
│   │   ├── delil_detay_page.dart
│   │   ├── delil_ekle_page.dart
│   │   ├── delil_listesi_ekrani.dart
│   │   ├── delilleri_incele_page.dart
│   │   ├── forgot_password_page.dart
│   │   ├── friendship_management_page.dart
│   │   ├── gelen_davalar_kactane.dart
│   │   ├── gelen_davalar_page.dart
│   │   ├── haykir_page.dart
│   │   ├── haykirislarim_page.dart
│   │   ├── hesap_gizlilik_ayarlari_page.dart
│   │   ├── home_page.dart
│   │   ├── katildigim_davalar_kactane.dart
│   │   ├── katildigim_davalar_page.dart
│   │   ├── masraf_selection_page.dart
│   │   ├── masraflar_page.dart
│   │   ├── privacy_policy_page.dart
│   │   ├── reklam_yonetim_page.dart
│   │   ├── saved_haykirlar_page.dart
│   │   ├── saved_widgets_page.dart
│   │   ├── sekiz_hukum_page.dart
│   │   ├── statistics_dashboard_page.dart
│   │   ├── terms_conditions_page.dart
│   │   ├── test_notifications_page.dart
│   │   ├── trend_dava_page.dart
│   │   ├── trend_insights_page.dart
│   │   ├── user_gamified_score_page.dart
│   │   ├── uyarilar_page.dart
│   │   └── yargila_page.dart
│   │
│   ├── services/                # Servisler (23 dosya)
│   │   ├── ad_service.dart
│   │   ├── audio_message_service.dart
│   │   ├── category_statistics_service.dart
│   │   ├── chat_service_firestore.dart
│   │   ├── chat_service.dart
│   │   ├── dava_consensus_service.dart
│   │   ├── dava_draft_service.dart
│   │   ├── dava_halk_karari_service.dart
│   │   ├── dava_hukum_service.dart
│   │   ├── dava_seed_service.dart
│   │   ├── dava_timer_service.dart
│   │   ├── evidence_comment_service.dart
│   │   ├── evidence_service.dart
│   │   ├── friend_category_service.dart
│   │   ├── hive_database_service.dart
│   │   ├── local_notification_service_example.dart
│   │   ├── local_notification_service.dart
│   │   ├── statistics_analytics_service.dart
│   │   ├── trend_engagement_service.dart
│   │   ├── trending_insights_service.dart
│   │   ├── user_gamified_score_service.dart
│   │   ├── user_session_service.dart
│   │   └── verified_users_service.dart
│   │
│   ├── widgets/                 # Widget'lar (40 dosya)
│   │   ├── animated_buttons.dart
│   │   ├── audio_message_player.dart
│   │   ├── cached_avatar_widget.dart
│   │   ├── category_search_bar.dart
│   │   ├── ceza_yonetim_widget.dart
│   │   ├── comment_section.dart
│   │   ├── common_dava_card_widget.dart
│   │   ├── common_header_widgets.dart
│   │   ├── confetti_animation_widget.dart
│   │   ├── countdown_timer_widget.dart
│   │   ├── country_picker.dart
│   │   ├── empty_search_result.dart
│   │   ├── energy_bar.dart
│   │   ├── evidence_comment_widget.dart
│   │   ├── evidence_viewer_widget.dart
│   │   ├── friend_category_widget.dart
│   │   ├── gelen_dava_grid.dart
│   │   ├── halk_karari_tab_view.dart
│   │   ├── hukum_ceza_masraf_dialog.dart
│   │   ├── hukum_consensus_badge.dart
│   │   ├── hukum_sentiment_selector.dart
│   │   ├── ilgililerin_seyir_defteri_widgeti.dart
│   │   ├── left_navigation_column.dart
│   │   ├── lottie_animation_overlay.dart
│   │   ├── modern_dava_form_widgets.dart
│   │   ├── modern_hukum_card.dart
│   │   ├── modern_invitation_card.dart
│   │   ├── my_checkbox_widget_yargila.dart
│   │   ├── one_friend_phone_bell_menu.dart
│   │   ├── pdf_viewer_widget.dart
│   │   ├── privacy_terms_text.dart
│   │   ├── profile_icons_row.dart
│   │   ├── seyir_defteri_modal.dart
│   │   ├── simple_emoji_picker.dart
│   │   ├── street_action_haykir_card.dart
│   │   ├── sub_category_tile.dart
│   │   ├── timed_action_buttons.dart
│   │   ├── twitter_post_composer.dart
│   │   ├── verified_users_management_dialog.dart
│   │   └── video_player_widget.dart
│   │
│   ├── providers/               # State Management (3 dosya)
│   │   ├── auth_provider.dart
│   │   ├── base_provider.dart
│   │   └── dava_provider.dart
│   │
│   ├── utils/                   # Yardımcı fonksiyonlar (10 dosya)
│   │   ├── bulk_user_utils.dart
│   │   ├── comment_utils.dart
│   │   ├── dava_adapter.dart
│   │   ├── debug_davet_utils.dart
│   │   ├── debug_invitation_check.dart
│   │   ├── dialog_utils.dart
│   │   ├── map_safety.dart
│   │   ├── performance_examples.dart
│   │   ├── test_davet_system.dart
│   │   └── timeago_helper.dart
│   │
│   ├── fonts/                   # Font dosyaları
│   │   └── cocon_regular.otf
│   │
│   └── icons/                   # Icon dosyaları (103 PNG)
│       └── [103 adet PNG icon dosyası]
│
├── android/                     # Android platform dosyaları
├── ios/                         # iOS platform dosyaları
├── web/                         # Web platform dosyaları
├── windows/                     # Windows platform dosyaları
├── linux/                       # Linux platform dosyaları
├── macos/                       # macOS platform dosyaları
│
├── test/                        # Test dosyaları
│   └── demo_expired_dava_test.dart
│
├── bin/                         # Script dosyaları
│   └── demo_expired_dava.dart
│
├── build/                       # Build çıktıları (otomatik oluşturulur)
│
├── pubspec.yaml                 # Flutter bağımlılık dosyası
├── pubspec.lock                 # Kilitli bağımlılık versiyonları
├── analysis_options.yaml        # Dart analyzer ayarları
├── README.md                    # Proje dokümantasyonu
├── PROJECT_RULES.md             # Proje kuralları
├── TEST_REHBERI.md             # Test rehberi
├── FIREBASE_SETUP.md           # Firebase kurulum dokümantasyonu
└── whoboom.mdc                  # Proje konfigürasyon dosyası
```

## Lib Dizini İstatistikleri

- **Models**: 32 dosya
- **Screens**: 44 dosya (42 Dart + 2 diğer)
- **Services**: 23 dosya
- **Widgets**: 40 dosya
- **Providers**: 3 dosya
- **Utils**: 10 dosya
- **Data**: 2 dosya
- **Icons**: 103 PNG dosyası
- **Fonts**: 1 OTF dosyası

**Toplam Dart Dosyası**: ~129 dosya (lib dizini içinde)

## Mimari Yapı

Proje Clean Architecture prensiplerine uygun şekilde organize edilmiştir:

1. **Models**: Veri modelleri ve Hive adaptörleri
2. **Screens**: UI ekranları ve sayfalar
3. **Services**: İş mantığı ve veri işleme servisleri
4. **Widgets**: Yeniden kullanılabilir UI bileşenleri
5. **Providers**: State management (muhtemelen Provider paketi)
6. **Utils**: Yardımcı fonksiyonlar ve araçlar
7. **Data**: Statik veri dosyaları

## Veritabanı

Proje Hive veritabanı kullanmaktadır (hive_database_service.dart).

## Platform Desteği

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ Linux
- ✅ macOS

