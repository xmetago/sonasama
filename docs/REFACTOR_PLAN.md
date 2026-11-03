# WhoBoom arayüz yeniden yapılandırma planı

Bu belge Adım 1 denetiminin kaydıdır. Amaç, `lib/screens` altındaki ekranları ve `lib/widgets` altındaki parçaları ortak bir bileşen kütüphanesine taşımak, kopyayı azaltmak ve performansı sayfa sayfa düzeltmektir. Görünüm ve davranış bu seride kendiliğinden değişmez. Estetik birleştirme sonraki bir fazdır; o faz `lib/utils/app_theme.dart` paletine yaslanır. Bu adımda yeşil temayı mor arşiv çubuğunun veya gri kartların yerine geçirmedik, çünkü bu pikselleri değiştirir.

Denetim `lib/` altındaki elle yazılmış Dart dosyaları üzerinde yapıldı. Üretilmiş `*.g.dart` dosyalarına dokunulmadı. Sayımlar dosya içeriğinden alındı (satır sayısı, `setState`, `Consumer`, `ListView` / `ListView.builder`, `SnackBar`, `showDialog`, `CircleAvatar`, `LinearGradient`).

## 1. Envanter

`lib/screens` altında 45 Dart dosyası, `lib/widgets` altında 58 Dart dosyası var. Ekranların büyük kısmı tek `State` sınıfında toplanmış. En büyük dosyalar:

| Dosya | Satır | `setState` | Not |
| --- | ---: | ---: | --- |
| `lib/screens/actigim_davalar_page.dart` | 4857 | 35 | Kart `build` içinde Hive taraması ve `Consumer` |
| `lib/screens/home_page.dart` | 4674 | 16 | Akış `PagedListView` (tembel). Başlık ve gövde aynı `setState` |
| `lib/widgets/ilgililerin_seyir_defteri_widgeti.dart` | 4510 | 31 | Ekran kadar büyük widget |
| `lib/screens/katildigim_davalar_page.dart` | 3824 | 30 | Kart `build` içinde `Consumer<DavaProvider>` |
| `lib/screens/dava_ac_page.dart` | 3086 | 34 | Form, menü ve diyalog aynı dosyada |
| `lib/widgets/cezalar_ceza_unified_panel.dart` | 3080 | 19 | |
| `lib/screens/haykir_page.dart` | 2568 | 22 | 44 `SnackBar` |
| `lib/screens/admin_page.dart` | 2327 | 14 | 9 `showDialog`, 3 `CircleAvatar` |
| `lib/widgets/modern_hukum_card.dart` | 2296 | 22 | |
| `lib/screens/friendship_management_page.dart` | 2273 | 23 | |
| `lib/screens/statistics_dashboard_page.dart` | 2086 | 14 | Arşiv kromunun üçüncü kopyası; `ListView` + `.map` |
| `lib/screens/davetler_page.dart` | 2084 | 22 | 48 `SnackBar` |
| `lib/screens/gelen_davalar_page.dart` | 1732 | 13 | Sayfanın tamamı `Consumer<DavaProvider>` |
| `lib/widgets/twitter_post_composer.dart` | 1632 | 18 | |
| `lib/screens/delil_ekle_page.dart` | 1577 | 6 | 40 `SnackBar` |

Daha küçük ama neredeyse aynı olan çift: `gelen_davalar_kactane.dart` (296 satır) ve `katildigim_davalar_kactane.dart` (312 satır). Metin benzerliği yaklaşık %92.

## 2. Tekrar eden arayüz kalıpları

Aynı isim, aynı widget anlamına gelmez. Aşağıdaki gruplar gerçek kopya ile yalnızca ada benzeyen parçaları ayırır.

### 2.1 Birebir kopyalanan arşiv kromu (bu adımın konusu)

Üç dosya aynı özel sınıfları yeniden yazmış:

- `lib/screens/saved_haykirlar_page.dart`
- `lib/screens/saved_widgets_page.dart`
- `lib/screens/statistics_dashboard_page.dart` (`_SearchField`, `_SectionHeader`, `_EmptySearchResultCard`, yükleme ve hata gövdesi)

Aynı ağaç, küçük parametre farklarıyla:

| Parça | Ortak görünüm | Fark |
| --- | --- | --- |
| Arama kutusu | 16 köşe, beyaz dolgu, gri kenar, `blurRadius: 10` gölge, odak çizgisi `Theme.primaryColor` | İpucu metni. İstatistikte sağda `Icons.tune_rounded` var; haykır aramasının ikinci kopyası `_HaykirSearchField` |
| Bölüm başlığı | 4×20 renk çubuğu, 18 pt kalın başlık, `Colors.grey[800]` | Kaydedilenlerde çubuk `Colors.purple`. İstatistikte `Theme.primaryColor` |
| Boş kart | Gri zemin, 20 köşe, beyaz daire içinde 48 px ikon | İkon ve boş liste cümlesi. Dolu sorguda başlık her yerde "Arama sonucuna ulaşılamadı" |
| Yükleme | Ortalanmış `CircularProgressIndicator` (`primaryColor`) + 16 pt gri metin | Yalnızca cümle |
| Hata | Kırmızı daire, 64 px `error_outline_rounded`, 18 pt mesaj, "Tekrar Dene" | Aynı üç dosyada aynı ağaç |
| Başlık çubuğu | 22 pt kalın başlık + yenile. Yüklerken ikon gri ve düğme kapalı | İki kaydedilenler sayfasında başlık aynı: "Kaydedilenler Arşivi" |
| Sayaç rozeti | 8 köşe, renk `%10` zemin, 16 px ikon, 13 pt sayı | `saved_haykirlar_page.dart` içinde `_StatBadge`. Trend ekranındaki `_StatChip` ayrı bir hap (yarıçap 30, etiketli) |

`user_gamified_score_page.dart` de "Tekrar Dene" kullanır fakat ikon 48 px, renkler `AppTheme`, buton `AppTheme.primaryButtonStyle`. Bu varyantı şimdi ortaklaştırmak görünümü değiştirir.

### 2.2 Başlık ve kabuk

Uygulamanın asıl üst şeridi Material `AppBar` değil. `ZeroWhoboomSearchMessage`, `OneFriendPhoneBellMenu` ve `SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant` (`lib/widgets/common_header_widgets.dart`, 1226 satır) birçok dava ekranında tekrar kullanılır. Bu parçalar zaten paylaşılıyor; sorun içlerinin şişmesi ve her `setState` ile birlikte yeniden kurulması.

Material `AppBar` daha çok ayar, sohbet detayı, gizlilik, albüm ve politika sayfalarında (yaklaşık 20 çağrı). İki aile birbirine karıştırılmamalı.

`TreeMenuPageheadlines` iki yerde duruyor: `dava_ac_page.dart` (kısa) ve `actigim_davalar_page.dart` (uzun). `home_page.dart` dava aç sayfasındaki sınıfı import eder. Bunlar birleştirilmeden önce satır satır karşılaştırılacak.

### 2.3 Kartlar

`FiveCardCaseInformation` sekiz dosyada ayrı sınıf. İsim ortak, sözleşme değil:

- `actigim_davalar_page.dart` — `Dava`, animasyonlu, geniş
- `katildigim_davalar_page.dart` — `Map`, seyir defteri bayrağı
- `gelen_davalar_page.dart` — kabul / red / rol
- `haykir_page.dart` — `Haykir` modeli ve sosyal sayaçlar
- `dava_ac_page.dart` — form kartı, en uzun kopya
- `yargila_page.dart`, `delilleri_incele_page.dart`, `masraflar_page.dart` — daha kısa, farklı alanlar

`CommonDavaCardWidget` ve `SimpleDavaCardWidget` (`lib/widgets/common_dava_card_widget.dart`) hiçbir ekran tarafından kullanılmıyor. Zorla bağlamak görünümü değiştirir. Estetik fazdan önce, hangi kartın hangi veri şekline oturduğu ayrı bir adımda yazılacak.

Haykır kartları da dağınık: `home_page.dart` içindeki `HaykirCardWidget`, `haykir_card_shell.dart`, `street_action_haykir_card.dart`, `katildigim_haykir_card.dart`.

### 2.4 Boş, yükleme ve hata durumları (arşiv kromu dışında)

Aynı iş, farklı piksel:

- `EmptySearchResult` yalnızca `category_page.dart` (yeşil, "Kategori bulunamadı")
- `home_page.dart` `_buildEmptyState` (tokmak ikonu, "Henüz Dava Açmadınız")
- `gelen_dava_grid.dart` özel `_EmptyState`
- `dialog_utils.dart` kayıtlı dava diyaloğunun boş hali
- `trend_insights_page.dart` kırmızı kart (yeniden dene yok) ve gri boş liste
- `davetler_page.dart` `Icons.inbox_outlined`
- `actigim` / `katildigim` `Icons.folder_open`

Ortak bir `AppEmptyState` ancak her çağrı mevcut ikon, metin, renk ve yerleşimi parametre olarak geçtiğinde güvenlidir. Tek bir "güzel" boş ekrana indirgemek bu serinin işi değil.

### 2.5 Avatar, diyalog, buton, rozet

- `CircleAvatar` ekran ve widget'larda düzinelerce kez elle kuruluyor. `CachedAvatarWidget` hazır ama üretimde neredeyse yalnız `test_notifications_page.dart` kullanıyor. Ağ görselleri önbelleksiz.
- `showDialog` yoğun: `admin_page` 9, `dava_ac_page` 7, `actigim` 5, `delil_ekle` 4. Başlık şeridi (yeşil gradient, kapat ikonu, 24 köşe) `dialog_utils.dart`, `dava_opened_success_dialog.dart`, `modern_success_alert_dialog.dart` arasında tekrar ediyor.
- `SnackBar` kopyası çok yüksek: `home_page` 68, `davetler_page` 48, `haykir_page` 44, `delil_ekle_page` 40, `admin_page` 36, `friendship_management_page` 30, `actigim` 28. Renk ve süre çağrıya göre değişiyor; tek helper ancak mevcut argümanları taşırsa güvenli.
- `AnimatedPrimaryButton` / `AnimatedSecondaryButton` / `AnimatedDangerButton` kullanılmıyor. `AppTheme` içinde `primaryButtonStyle`, `accentButtonStyle`, `secondaryButtonStyle` duruyor ama çoğu ekran `ElevatedButton.styleFrom` ile yerel stil yazıyor.
- `ModernSectionHeader` (`modern_dava_form_widgets.dart`) turuncu gradient ve hiçbir çağrısı yok. Adım 1'deki çubuklu başlıkla karıştırılmamalı.
- `MyCheckboxWidget` gövdesi `gelen_davalar_kactane.dart` ve `katildigim_davalar_kactane.dart` içinde. `MyCheckboxWidgetYargila` ayrı dosyada ve ayrı iş.

### 2.6 Sayfa çiftleri

`gelen_davalar_kactane.dart` ile `katildigim_davalar_kactane.dart` yaklaşık %92 aynı. Ortak bir sayfa kabuğu (başlık, menü, sayı rozeti, checkbox satırı) iki dosyanın farkını (hangi sayı, hangi liste) parametreye indirger.

`saved_haykirlar_page.dart` ile `saved_widgets_page.dart` sayfa iskeleti aynı, kart içeriği farklı. İskelet bu adımda ortaklandı; kartlar yerinde kaldı.

## 3. Önerilen paylaşılan kütüphane

Konum: `lib/widgets/shared/`. Dışa aktarma: `lib/widgets/shared/shared.dart`.

Mevcut `lib/widgets/*.dart` dosyaları olduğu yerde kalır. Yeni kod, bir ekranın özel sınıfını ancak ağaç birebir örtüşüyorsa buraya alır. `AppTheme` renklerine geçiş estetik fazın işidir; o faz bu sınıfların varsayılan renklerini değiştirir, çağrı yerlerini tek tek boyamaz.

### 3.1 Adım 1'de yazılanlar

```dart
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.suffixIcon,
  });
  final String hintText;
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;
}

class AppAccentSectionHeader extends StatelessWidget {
  const AppAccentSectionHeader({
    super.key,
    required this.title,
    this.accentColor = Colors.purple,
  });
  final String title;
  final Color accentColor;
}

class AppEmptyResultCard extends StatelessWidget {
  const AppEmptyResultCard({
    super.key,
    required this.query,
    required this.emptyMessage,
    required this.icon,
  });
  final String query;
  final String emptyMessage;
  final IconData icon;
}

class AppLoadingMessage extends StatelessWidget {
  const AppLoadingMessage({super.key, required this.message});
  final String message;
}

class AppErrorRetryView extends StatelessWidget {
  const AppErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;
}

class AppStatBadge extends StatelessWidget {
  const AppStatBadge({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
  });
  final IconData icon;
  final int count;
  final Color color;
}

class AppRefreshTitleBar extends StatelessWidget {
  const AppRefreshTitleBar({
    super.key,
    required this.title,
    required this.isLoading,
    required this.onRefresh,
  });
  final String title;
  final bool isLoading;
  final VoidCallback onRefresh;
}
```

Kullanan ekranlar (hedef):

| Sınıf | Şimdi | Sıradaki aynı ağaç |
| --- | --- | --- |
| `AppSearchField` | İki kaydedilenler sayfası | `statistics_dashboard_page` (`suffixIcon` ile) ve `_HaykirSearchField` |
| `AppAccentSectionHeader` | İki kaydedilenler sayfası (mor varsayılan) | İstatistik panosu `accentColor: Theme.of(context).primaryColor` ile |
| `AppEmptyResultCard` | İki kaydedilenler sayfası | İstatistikteki `_EmptySearchResultCard` (`Icons.search_off_rounded`, "Kayıt bulunamadı") |
| `AppLoadingMessage` | İki kaydedilenler sayfası | İstatistik panosunun yükleme gövdesi |
| `AppErrorRetryView` | İki kaydedilenler sayfası | İstatistik panosunun hata gövdesi |
| `AppStatBadge` | Kaydedilen haykır kartı | Yeni rozet ihtiyacı. `_StatChip` (trend) ayrı kalır |
| `AppRefreshTitleBar` | İki kaydedilenler sayfası | İstatistik başlığı farklı kurulduğu için zorlanmaz |

### 3.2 Sonraki sınıflar (henüz yazılmadı)

Her biri kendi adımında, ilk kullanımındaki piksel ölçüsüne kilitlenerek eklenir.

| Sınıf | Konum | Ne işe yarar | İlk taşınacak yer |
| --- | --- | --- | --- |
| `AppInfoBanner` | `shared/app_info_banner.dart` | İstatistikteki mavi bilgi şeridi: ikon, metin, zemin, kenar | `statistics_dashboard_page` `_InfoBanner` |
| `AppSnack` | `shared/app_snack.dart` | `showAppSnack(context, message, {color, duration})`. Varsayılanlar çağrıdaki değerlere eşit olmalı | Önce `saved_*` içindeki tek mor kayıt snack'i, sonra `delil_detay_page` |
| `AppDialogFrame` | `shared/app_dialog_frame.dart` | 24 köşe, başlık gradient'i, kapat. Gövde `child` | `dialog_utils.dart` kayıtlı dava diyaloğu |
| `AppCachedAvatar` | mevcut `cached_avatar_widget.dart` sarmalayıcısı | `CircleAvatar` + ağ URL'si için tek giriş | `chat_page`, `chat_detail_page`, `admin_page` |
| `CountHeadlinePage` | `shared/count_headline_page.dart` veya `screens/` altında ortak kabuk | %92 aynı "kaç tane" sayfaları | `gelen_davalar_kactane`, `katildigim_davalar_kactane` |
| `AppOutlinedCard` | `shared/app_outlined_card.dart` | Yükseklik 0, 16 köşe, `grey[200]` kenar, 16 padding. İçerik `child` | İstatistik `_CaseTile` / `_HaykirTile` kabuğu, kaydedilen kartların dış kabuğu |
| Dava kartı ailesi | `widgets/dava/` | `FiveCard*` birleştirilmez. Önce ortak alt parçalar: künye satırı, süre şeridi, rol seçimi | Her ekrandan tek alt parça |

`EmptySearchResult` kategori araması için yerinde kalır. Estetik faz onu `AppEmptyResultCard` ile birleştirmeye karar verirse ikon ve metin parametreleri yeter; renk şimdi yeşil, arşiv kartı gri.

## 4. Performans bulguları (etki sırası)

Ölçüm yok; sıralama yeniden çizim kapsamı ve build içinde yapılan işe göre. Görünümü değiştirmeden yapılacak işler ayrıca işaretlendi.

### 4.1 Yüksek

1. **Kart `build` içinde Hive taraması.** `ActigimDavaCard.build`, `_getOpenedAtForKunye()` çağırıyor. Bu metot her çizimde `HiveDatabaseService.getOpenedDavalar()` ile tüm açılmış davaları geziyor (`actigim_davalar_page.dart`, künye satırı). Görünen her kart tüm kutuyu okur. Düzeltme: açılış tarihini kart kurulurken veya liste yüklenirken bir kez hesaplayıp alana yazmak. Görünüm aynı kalır.

2. **`build` içinde yan etki.** `ActigimDavaCard` ve katıldığım dava kartı `Consumer<DavaProvider>` kuruyor, sürüm değişince `Future.microtask` ile yükleme ve ardından `setState` planlıyor. Provider her bildirildiğinde kart yeniden kurulur, yükleme yeniden tetiklenebilir. Dinlemeyi `hukumUpdateVersion` için `Selector` ile sınırlamak ve yüklemeyi `didChangeDependencies` / sürüm karşılaştırmasının tek yerine almak aynı veriyi daha az turda gösterir.

3. **Sayfanın tamamını dinleyen `Consumer`.** `gelen_davalar_page.dart` `build` metodu doğrudan `Consumer<DavaProvider>` döndürür. `notifyListeners` üst şeridi, profil satırını ve listeyi birlikte kurar. `home_page.dart` provider'ı çoğunlukla `listen: false` okur; asıl maliyet orada `setState`. Gelen davalar sayfası önce daraltılmalı.

4. **Dev durum sınıfları.** `actigim` (35), `dava_ac` (34), `katildigim` (30), `seyir defteri` (31), `haykir` (22), `davetler` (22), `modern_hukum_card` (22) `setState` çağrısı, binlerce satırlık `build` ağacını işaretler. Bir anahtar veya sayaç değişince başlık, liste ve diyalog kurulumu aynı turda çalışır. Çözüm, sayfayı küçük `StatefulWidget` parçalarına bölmek. Bu, davranış değiştirmeden yapılabilir: aynı callback, aynı koşullu ağaç, daha dar `State`.

### 4.2 Orta

5. **Tembel olmayan listeler.** `ListView(children: [...map])` şunlarda var: istatistik panosu (dört yayılım), iki kaydedilenler sayfası, `trend_insights_page` içinde dört düz `ListView`, `albumler_liste_page` içinde iki düz `ListView`. Kayıt sayısı küçükken maliyeti düşük. İstatistik ve trend listeleri büyüyebilir; `ListView.builder` / `separated` aynı hücre widget'ını koruyarak geçirilmeli. `home_page` akışı zaten `PagedListView`. `admin_page` ve `chat_page` builder kullanıyor.

6. **Gradient ve gölgenin her build'de yeniden kurulması.** `LinearGradient(` sayıları: seyir defteri 18, açtığım davalar 12, katıldığım 8, ana sayfa 7, haykır 5. Kart parçası `const` olamıyorsa dekorasyonu `static final` yapmak ayıracı küçültür. Asıl kazanç 4. maddedeki dar `State`.

7. **Önbelleksiz avatar.** `CachedAvatarWidget` dururken ekranlar `CircleAvatar` / `NetworkImage` kuruyor. Sohbet ve yönetim listelerinde aynı URL tekrar iner. Geçiş, yarıçap ve yedek ikon birebir verilerek yapılmalı.

8. **Ana sayfa başlığı ile akışın aynı state'te olması.** `home_page.dart` 4674 satır, 16 `setState`, 68 `SnackBar`. Akış tembel olsa da sol menü veya başlık katlanması tüm iskeleti kurar. Üst üç satır ayrı widget'a (`common_header_widgets` zaten parça parça) ve akış ayrı `StatefulWidget`'a bölünmeli. `setState` hangi alt ağaçtaysa yalnız o kurulur.

### 4.3 Düşük (yine de birikecek)

9. **Eksik `const`.** Dev dosyalarda yüzlerce `const` var; asıl kaçak, `BoxDecoration` ve `TextStyle` kopyaları. Parça çıkarılırken `const` eklenir. Tek başına tur süresini kart rebuild'i kadar düşürmez.

10. **`print` ve gereksiz `SnackBar` kurulumu.** Açtığım dava kartı provider sürümünü `print` ile yazıyor. Bu, performans maddesinden çok gürültü. SnackBar sayısı bakım maliyeti; çizim maliyeti değil.

11. **Kullanılmayan widget'lar.** `CommonDavaCardWidget`, `AnimatedPrimaryButton`, `ModernSectionHeader` paket boyutuna ve derleme süresine küçük bir yük. Silmek yerine, estetik faz hangi API'nin kalacağına karar verene kadar dokunulmaz. Ölü kodu bu seride silmek davranış değiştirmez ama inceleme gürültüsü yaratır.

## 5. Sayfa sayfa göç sırası

Her madde bir inceleme turu. Bir turda ya ortak widget bağlanır ya da tek bir dev dosyadan tek bir parça çıkar. İkisi birden ancak parça zaten o widget ise.

Görünüm kilidi: taşıma öncesi ve sonrası aynı padding, renk, yarıçap, metin, ikon, düğme metni ve `onPressed` hedefi. `AppTheme` ancak ekran zaten onu kullanıyorsa (`user_gamified_score_page` gibi) referans alınır.

### Tur 1 — bu PR

Ortak arşiv kromu (`lib/widgets/shared/`) ve iki küçük sayfa:

- `saved_haykirlar_page.dart`
- `saved_widgets_page.dart`

Liste hâlâ `ListView` + yayılım. Kayıt sayısı kullanıcıya ait ve bu turda kaydırma fiziği (`AlwaysScrollableScrollPhysics`, `RefreshIndicator`) aynı kalsın diye builder'a çevrilmedi. Kart sınıfları (`_SavedHaykirTile`, `_SavedWidgetTile`) dosyada kaldı.

### Tur 2 — istatistik panosu

`statistics_dashboard_page.dart` içindeki `_SearchField`, `_HaykirSearchField`, `_SectionHeader`, `_EmptySearchResultCard`, yükleme ve hata gövdesi Tur 1 sınıflarına bağlanır.

- Arama: `suffixIcon` istatistikteki `Icons.tune_rounded` / `Colors.grey[400]` olarak kalır. Haykır araması aynı sınıf, farklı `hintText`.
- Başlık: `accentColor` tema ana rengi. Varsayılan mor kullanılmaz.
- Boş kart: ikon `Icons.search_off_rounded`, boş metin "Kayıt bulunamadı".
- Aynı turda `_InfoBanner` `AppInfoBanner` olur.
- Liste yayılımları `ListView.builder` yapılır. Hücre hâlâ `_CaseTile` / `_HaykirTile`. Bu, kaydırmayı yalnızca uzun listede iyileştirir; kısa listede aynı hücreler çizilir.

### Tur 3 — "kaç tane" çifti

`gelen_davalar_kactane.dart` ve `katildigim_davalar_kactane.dart`. Ortak kabuk + `MyCheckboxWidget` tek tanıma iner. İki sayfanın sayı kaynağı ve başlık metni parametre kalır. Dosyalar kısa olduğu için farkı incelemek kolay.

### Tur 4 — snack ve diyalog çerçevesi, tek ekran

`AppSnack` ve `AppDialogFrame` eklenir. İlk tüketici `delil_detay_page.dart` (24 `SnackBar`, 3 `showDialog`, 1069 satır) veya `dialog_utils.dart` içindeki kayıtlı dava diyaloğu. `home_page` 68 snack ile bu tura alınmaz; helper oturduktan sonra ayrı tur.

### Tur 5 — avatar

`chat_page.dart`, `chat_detail_page.dart`, sonra `admin_page.dart` içindeki `CircleAvatar` çağrıları `CachedAvatarWidget` olur. Yarıçap, renk ve harf yedeği çağrıdaki değerdir. `home_page` ve `haykir_page` birer çağrı ile daha sonra gelir.

### Tur 6 — `gelen_davalar_page.dart`

1. `Consumer` yalnız dava listesini sarsın; `ZeroWhoboomSearchMessage` ve profil satırı dışarıda kalsın.
2. `FiveCardCaseInformation` bu dosyadan `lib/widgets/gelen_dava_card.dart` dosyasına taşınsın. İsim çakışması bitsin. Diğer yedi kopyaya dokunulmasın.

### Tur 7 — `davetler_page.dart`

`DavetCard` ve `ModernDavaCard` zaten dosyanın altında. Ayrı dosyalara taşı. Snack çağrılarını `AppSnack` ile değiştir (renk ve süre aynı). `ModernInvitationCard` ile ilişkiyi bu turda birleştirme; ikisi yan yana durup fark listesi çıkarılacak.

### Tur 8 — `friendship_management_page.dart`

23 `setState`, 30 snack, 3 diyalog. Liste zaten builder kullanıyor (2 çağrı). Önce diyalog ve satır widget'ını ayır, sonra snack helper.

### Tur 9 — `statistics` sonrası küçük liste ekranları

Sıra: `trend_insights_page.dart` (düz `ListView` ve `_StatChip` yerinde kalır), `albumler_liste_page.dart`, `trend_dava_page.dart`, `uyarilar_page.dart`, `haykirislarim_page.dart`. Her tur bir dosya. Boş durum metni değişmez.

### Tur 10 — `admin_page.dart`

Sekmeler veya bölümler ayrı widget. Üç `ListView.builder` korunur. Diyaloglar `AppDialogFrame` ancak gradient ve başlık metni aynıysa.

### Tur 11 — `haykir_page.dart`

`FiveCardCaseInformation` bu dosyadan `lib/widgets/haykir_case_card.dart` olur. Sosyal sayaç state'i kartta kalır, sayfa state'i küçülür. 44 snack ayrı bir alt turda `AppSnack` olur.

### Tur 12 — `dava_ac_page.dart`

Sıra: `GroupSelectionDialog`, `TreeMenuPageheadlines`, form alanları (`ModernTextField` zaten `modern_dava_form_widgets.dart` içinde; sayfa onu kullanmıyorsa önce kullanım haritası). `FiveCardCaseInformation` en son, çünkü 778 satırlık sınıf formu etkiliyor.

### Tur 13 — `katildigim_davalar_page.dart`

1. Kart dosyaya ayrılır.
2. `Consumer` içindeki microtask yüklemesi `Selector` + tek seferlik yüke çekilir.
3. `FiveCard` sözleşmesi (`davaData` map) korunur. Açtığım davalar kartıyla birleştirilmez.

### Tur 14 — `actigim_davalar_page.dart`

En riskli dosya, en sonda değil; performans maddesi 4.1 yüzünden kart ayrımı erken ama tek başına:

1. Yalnız `ActigimDavaCard` yeni dosyaya. Hive taraması build dışına.
2. `InactiveDavaCard` ve `TreeMenuPageheadlines` ayrı tur.
3. Sayfa iskeleti (`ActigimDavalarPage`) en son, kartlar oturduktan sonra.

### Tur 15 — `home_page.dart`

1. Üst blok (üç satır + seyir başlığı) kendi widget'ında, kendi `setState` ile katlanır.
2. `HaykirCardWidget` `lib/widgets/home_haykir_card.dart`.
3. Kayıtlı davalar boş durumu yerinde kalır; metin ve tokmak ikonu değişmez.
4. Snack helper en son.

### Tur 16 — dev widget'lar

- `ilgililerin_seyir_defteri_widgeti.dart` (sekme / liste / diyalog)
- `cezalar_ceza_unified_panel.dart`
- `modern_hukum_card.dart` (kaydırıcı ve grafik alt sınıfları zaten içeride; dosya bölünür, state daralır)
- `twitter_post_composer.dart`

### Tur 17 — estetik faz (bu serinin dışı)

`AppTheme.cardDecoration`, `primaryButtonStyle` ve metin stilleri ortak sınıfların varsayılanı olur. Mor çubuk, gri kart ve yeşil tema tek palete çekilir. Bu faz başlamadan Tur 1–6 oturmuş olmalı; aksi halde hem yapı hem renk aynı turda değişir ve inceleme körleşir.

## 6. Bu turda bilinçli yapılmayanlar

- `FiveCardCaseInformation` birleştirilmedi.
- İstatistik panosu, tema rengi ve sonek ikonu yüzünden bu tura alınmadı. API buna hazır (`suffixIcon`, `accentColor`).
- `ListView.builder` dönüşümü yok.
- `AppTheme` renkleri arşiv kromuna uygulanmadı.
- Kullanılmayan `CommonDavaCardWidget`, `AnimatedPrimaryButton`, `ModernSectionHeader` silinmedi.
- `*.g.dart` üretilen modeller aynı.

## 7. Sıradaki tek tur

**Tur 2: `statistics_dashboard_page.dart`.** Aynı yedi sınıfı, yukarıdaki parametrelerle bağla. `_CaseTile` / `_HaykirTile` ve iş kuralları dosyada kalsın. Ardından düz `ListView` yayılımlarını builder yap. Başka ekrana dokunma.
