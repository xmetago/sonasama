# WhoBoom arayüz yeniden yapılandırma planı

Bu belge Adım 1 denetiminin kaydıdır. Amaç, `lib/screens` altındaki ekranları ve `lib/widgets` altındaki parçaları ortak bir bileşen kütüphanesine taşımak, kopyayı azaltmak ve performansı sayfa sayfa düzeltmektir. Görünüm ve davranış bu seride kendiliğinden değişmez. Estetik birleştirme sonraki bir fazdır; o faz `lib/utils/app_theme.dart` paletine yaslanır. Bu adımda yeşil temayı mor arşiv çubuğunun veya gri kartların yerine geçirmedik, çünkü bu pikselleri değiştirir.

Denetim `lib/` altındaki elle yazılmış Dart dosyaları üzerinde yapıldı. Üretilmiş `*.g.dart` dosyalarına dokunulmadı. Sayımlar dosya içeriğinden alındı (satır sayısı, `setState`, `Consumer`, `ListView` / `ListView.builder`, `SnackBar`, `showDialog`, `CircleAvatar`, `LinearGradient`).

## 1. Envanter

`lib/screens` altında 45 Dart dosyası, `lib/widgets` altında 58 Dart dosyası var. Ekranların büyük kısmı tek `State` sınıfında toplanmış. En büyük dosyalar:

| Dosya | Satır | `setState` | Not |
| --- | ---: | ---: | --- |
| `lib/screens/actigim_davalar_page.dart` | 4857 | 35 | Kart `build` içindeki Hive taraması Tur 2'de önbelleğe alındı. `Consumer` duruyor |
| `lib/screens/home_page.dart` | 4674 | 16 | Akış `PagedListView` (tembel). Başlık ve gövde aynı `setState` |
| `lib/widgets/ilgililerin_seyir_defteri_widgeti.dart` | 4510 | 31 | Ekran kadar büyük widget |
| `lib/screens/katildigim_davalar_page.dart` | 3824 | 30 | Kart `build` içinde `Consumer<DavaProvider>` |
| `lib/screens/dava_ac_page.dart` | 3086 | 34 | Form, menü ve diyalog aynı dosyada |
| `lib/widgets/cezalar_ceza_unified_panel.dart` | 3080 | 19 | |
| `lib/screens/haykir_page.dart` | 2568 | 22 | 44 `SnackBar` |
| `lib/screens/admin_page.dart` | 2327 | 14 | 9 `showDialog`, 3 `CircleAvatar` |
| `lib/widgets/modern_hukum_card.dart` | 2296 | 22 | |
| `lib/screens/friendship_management_page.dart` | ~1950 | 23 | Tur 8: kategori diyaloğu ayrı widget |
| `lib/screens/statistics_dashboard_page.dart` | ~1838 | 14 | Tur 2: ortak krom + `ListView.builder` |
| `lib/screens/davetler_page.dart` | ~1286 | 22 | Tur 7: `DavetCard` ve `ModernDavaCard` ayrıldı. 48 snack duruyor |
| `lib/screens/gelen_davalar_page.dart` | ~490 | 13 | Tur 6: dış `Consumer` kalktı. Kart `gelen_dava_card.dart` |
| `lib/widgets/twitter_post_composer.dart` | 1632 | 18 | |
| `lib/screens/delil_ekle_page.dart` | 1577 | 6 | 40 `SnackBar` |

`gelen_davalar_kactane.dart` ve `katildigim_davalar_kactane.dart` yaklaşık %92 aynıydı. Ortak iskelet `DavaCountHeadlinePage` oldu. Her sayfada yalnız başlık satırı (`MyCheckboxWidget`) kaldı. `sekiz_hukum_page.dart` gelen sayfadaki `MyCheckboxWidget` sınıfını kullanmaya devam eder.

## 2. Tekrar eden arayüz kalıpları

Aynı isim, aynı widget anlamına gelmez. Aşağıdaki gruplar gerçek kopya ile yalnızca ada benzeyen parçaları ayırır.

### 2.1 Birebir kopyalanan arşiv kromu

Üç dosya aynı özel sınıfları yeniden yazmıştı. Üçü de ortak sınıflara bağlandı:

- `lib/screens/saved_haykirlar_page.dart`
- `lib/screens/saved_widgets_page.dart`
- `lib/screens/statistics_dashboard_page.dart` (eski `_SearchField`, `_HaykirSearchField`, `_SectionHeader`, `_EmptySearchResultCard`, `_InfoBanner`, yükleme ve hata gövdesi)

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

`gelen_davalar_kactane.dart` ile `katildigim_davalar_kactane.dart` yaklaşık %92 aynıydı. Ortak kabuk `DavaCountHeadlinePage`. Fark, başlık satırında.

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
| `AppSearchField` | İki kaydedilenler sayfası ve istatistik panosu | İstatistikte dava araması `suffixIcon: Icons.tune_rounded`. Haykır aramasında sonek yok |
| `AppAccentSectionHeader` | İki kaydedilenler sayfası (mor varsayılan) ve istatistik panosu | İstatistik `accentColor: Theme.primaryColor` geçirir |
| `AppEmptyResultCard` | İki kaydedilenler sayfası ve istatistik panosu | İstatistik ikonu `Icons.search_off_rounded`, boş metin "Kayıt bulunamadı" |
| `AppLoadingMessage` | İki kaydedilenler sayfası ve istatistik panosu | |
| `AppErrorRetryView` | İki kaydedilenler sayfası ve istatistik panosu | |
| `AppInfoBanner` | İstatistik panosu | "Bugün açılan … bulunamadı" şeridi |
| `AppStatBadge` | Kaydedilen haykır kartı | Yeni rozet ihtiyacı. `_StatChip` (trend) ayrı kalır |
| `AppRefreshTitleBar` | İki kaydedilenler sayfası | İstatistik başlığı farklı kurulduğu için zorlanmaz |
| `DavaCountHeadlinePage` | Gelen ve katıldığım "kaç tane" sayfaları | Başlık satırı parametre. Izgara, profil ve sol ikonlar ortak |
| `showAppSnack` | `delil_detay_page.dart` (12 çağrı) | Süre verilmezse 4 saniye. Renk ve süre çağrıda | `home_page` bu seride en son |
| `AppDialogFrame` | `dialog_utils.dart` kayıtlı dava diyaloğu | 24 köşe, gradient başlık, kapat, gövde `child` | Başka gradient diyalog ancak ölçü ve başlık aynıysa |

### 3.2 Sonraki sınıflar (henüz yazılmadı)

Her biri kendi adımında, ilk kullanımındaki piksel ölçüsüne kilitlenerek eklenir.

| Sınıf | Konum | Ne işe yarar | İlk taşınacak yer |
| --- | --- | --- | --- |
| `AppCachedAvatar` | mevcut `cached_avatar_widget.dart` sarmalayıcısı | `CircleAvatar` + ağ URL'si için tek giriş | Sohbet yerleşimi kişi ikonu çizdiği için bu turda atlandı |
| `AppOutlinedCard` | `shared/app_outlined_card.dart` | Yükseklik 0, 16 köşe, `grey[200]` kenar, 16 padding. İçerik `child` | İstatistik `_CaseTile` / `_HaykirTile` kabuğu, kaydedilen kartların dış kabuğu |
| Dava kartı ailesi | `widgets/dava/` | `FiveCard*` birleştirilmez. Önce ortak alt parçalar: künye satırı, süre şeridi, rol seçimi | Her ekrandan tek alt parça |

`EmptySearchResult` kategori araması için yerinde kalır. Estetik faz onu `AppEmptyResultCard` ile birleştirmeye karar verirse ikon ve metin parametreleri yeter; renk şimdi yeşil, arşiv kartı gri.

## 4. Performans bulguları (etki sırası)

Ölçüm yok; sıralama yeniden çizim kapsamı ve build içinde yapılan işe göre. Görünümü değiştirmeden yapılacak işler ayrıca işaretlendi.

### 4.1 Yüksek

1. **Kart `build` içinde Hive taraması — bu turda kapatıldı.** `ActigimDavaCard` açılış tarihini `_kunyeOpenedAt` alanında tutar. Kutu `initState`, `didUpdateWidget`, `setState` ve hediye diyaloğu açılırken bir kez okunur. Giriş animasyonunun kareleri ve `build` artık kutuyu tarama. Künye metni ve 72 saatlik UZLAŞMA hesabı aynı tarihi kullanır. Kart dosyası henüz ayrılmadı (Tur 14).

2. **`build` içinde yan etki.** `ActigimDavaCard` ve katıldığım dava kartı `Consumer<DavaProvider>` kuruyor, sürüm değişince `Future.microtask` ile yükleme ve ardından `setState` planlıyor. Provider her bildirildiğinde kart yeniden kurulur, yükleme yeniden tetiklenebilir. Dinlemeyi `hukumUpdateVersion` için `Selector` ile sınırlamak ve yüklemeyi `didChangeDependencies` / sürüm karşılaştırmasının tek yerine almak aynı veriyi daha az turda gösterir.

3. **Sayfanın tamamını dinleyen `Consumer` — gelen davalar sayfasında kapatıldı.** Üst şerit artık `DavaProvider` bildirimiyle kurulmuyor. Sayı rozeti kendi `Consumer`'ında. `home_page.dart` provider'ı çoğunlukla `listen: false` okur; asıl maliyet orada `setState`.

4. **Dev durum sınıfları.** `actigim` (35), `dava_ac` (34), `katildigim` (30), `seyir defteri` (31), `haykir` (22), `davetler` (22), `modern_hukum_card` (22) `setState` çağrısı, binlerce satırlık `build` ağacını işaretler. Bir anahtar veya sayaç değişince başlık, liste ve diyalog kurulumu aynı turda çalışır. Çözüm, sayfayı küçük `StatefulWidget` parçalarına bölmek. Bu, davranış değiştirmeden yapılabilir: aynı callback, aynı koşullu ağaç, daha dar `State`.

### 4.2 Orta

5. **Tembel olmayan listeler.** İstatistik panosundaki dört yayılım `ListView.builder` oldu. Kalanlar: iki kaydedilenler sayfası, `trend_insights_page` içinde dört düz `ListView`, `albumler_liste_page` içinde iki düz `ListView`. Kayıt sayısı küçükken maliyeti düşük. `home_page` akışı zaten `PagedListView`. `admin_page` ve `chat_page` builder kullanıyor.

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

### Tur 2 — istatistik panosu (yapıldı)

`statistics_dashboard_page.dart` ortak kromu kullanır.

- Dava araması `suffixIcon` olarak `Icons.tune_rounded` / `Colors.grey[400]` taşır. Haykır araması aynı sınıf, sonek yok, farklı `hintText`.
- Başlık `accentColor` tema ana rengidir. Varsayılan mor kullanılmaz.
- Boş kart: ikon `Icons.search_off_rounded`, boş metin "Kayıt bulunamadı".
- `_InfoBanner` `AppInfoBanner` oldu.
- Dört yayılım `ListView.builder` oldu. Hücre hâlâ `_CaseTile` / `_HaykirTile`. Üst şerit, özet kartları ve diyaloglar duruyor.
- "Veri bulunamadı" boş hali (kutu ikonu, 80 px) bu kromdan farklı olduğu için yerinde kaldı.

### Tur 3 — "kaç tane" çifti (yapıldı)

Ortak kabuk `lib/widgets/shared/dava_count_headline_page.dart`. İki sayfa kendi başlık satırını `headline` olarak verir. Gelen sayfadaki `MyCheckboxWidget` dışa açık kaldı; `sekiz_hukum_page.dart` onu import eder. Izgara sayısı her iki sayfada 13.

### Tur 4 — snack ve diyalog çerçevesi (yapıldı)

- `showAppSnack` (`lib/widgets/shared/app_snack.dart`): metin, isteğe bağlı `backgroundColor` ve `duration`. Süre verilmezse 4 saniye. Kuyruk `showSnackBar` ile aynı.
- Kanıt: `delil_detay_page.dart` içindeki 12 snack. Kırmızı ve yeşil renkler, 2 saniyelik başarı süresi duruyor. `AlertDialog` bilgi pencereleri çerçeveye alınmadı; onlar Material diyalog.
- `AppDialogFrame`: 24 köşe, gradient başlık, kapat, gövde `child`. Kanıt: `dialog_utils.dart` kayıtlı dava diyaloğu. Başlık "Dava Düzenle", alt yazı `"$n dava "`, ikon `gavel_rounded`, ölçü 0.88 × 0.78.
- `home_page` snack'leri bu turda bağlanmadı.

### Tur 5 — avatar

`chat_page.dart`, `chat_detail_page.dart`, sonra `admin_page.dart` içindeki `CircleAvatar` çağrıları `CachedAvatarWidget` olur. Yarıçap, renk ve harf yedeği çağrıdaki değerdir. `home_page` ve `haykir_page` birer çağrı ile daha sonra gelir.

### Tur 6 — `gelen_davalar_page.dart` (yapıldı)

1. Sayfanın tamamını saran `Consumer<DavaProvider>` kalktı. Liste `_davaList` ve `setState` ile güncelleniyor; sayı rozeti kendi `Consumer`'ında (`incomingDavaCount`). Üst şerit artık her provider bildiriminde kurulmuyor.
2. `Dava`, `FiveCardCaseInformation` ve `DashedLinePainter` `lib/widgets/gelen_dava_card.dart` dosyasına taşındı. Sözleşme ve gövde aynı. Sayfa bu üç adı yeniden dışa aktarır; eski importlar bozulmaz. `yargila_page`, `actigim_davalar_page` ve `haykir_page` içindeki aynı isimler sayfa importunda gizlendi. Diğer yedi kopyaya dokunulmadı. Kullanılmayan `_buildModernRow` uyarısı kartla birlikte duruyor.

### Tur 7 — `davetler_page.dart` (kartlar ayrıldı)

`DavetCard` → `lib/widgets/davet_card.dart`. `ModernDavaCard` → `lib/widgets/modern_dava_card.dart`. Gövde aynı. Sayfa her iki adı yeniden dışa aktarır; `home_page.dart` içindeki `show ModernDavaCard` importu durur. Snack'ler yerinde: arka plan kırmızı, turuncu, yeşil, mavi ve gri; süre 2 veya 3 saniye. `showAppSnack` bu farkları tek varsayılanla ezmez. `ModernInvitationCard` ile birleştirilmedi.

### Tur 8 — `friendship_management_page.dart` (diyalog ayrıldı)

Kategori seçme penceresi `lib/widgets/friendship_category_dialog.dart`. Sayfa mevcut kategoriyi, limiti, sayacı ve kaydı callback ile verir. Dolu kategoride yüzen kırmızı snack duruyor. Gelen istek `AlertDialog`'u, kullanıcı kartı ve snack'ler yerinde. Kullanılmayan `_sendFriendshipRequest` uyarısı duruyor.

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

Hive taraması build dışına alındı. Kalan iş yapısal:

1. `ActigimDavaCard` yeni dosyaya. Önbellek davranışı aynı kalsın. `FiveCardCaseInformation` bu turda `actigim_case_card.dart` oldu.
2. `InactiveDavaCard` ve `TreeMenuPageheadlines` ayrı tur.
3. Sayfa iskeleti (`ActigimDavalarPage`) en son, kartlar oturduktan sonra.
4. `Consumer` içindeki `Future.microtask` yüklemesi ayrı tur (madde 4.1.2).

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

## 6. Bu turlarda bilinçli yapılmayanlar

- `FiveCardCaseInformation` birleştirilmedi.
- İstatistikteki "Veri bulunamadı" gövdesi (80 px kutu ikonu) `AppEmptyResultCard` ile değiştirilmedi. Piksel farklı.
- Kaydedilenler listeleri hâlâ `ListView` + yayılım. Kayıt sayısı kullanıcıya ait.
- `AppTheme` renkleri arşiv kromuna uygulanmadı. İstatistik başlığı tema ana rengini parametre olarak alır.
- Kullanılmayan `CommonDavaCardWidget`, `AnimatedPrimaryButton`, `ModernSectionHeader` silinmedi.
- `ActigimDavaCard` dosyası ayrılmadı. Yalnız açılış tarihi taraması `build` dışına çıktı.
- Sohbet avatarları `CachedAvatarWidget` olmadı. Mevcut `CircleAvatar` bazı adreslerde fotoğrafın üstüne kişi ikonu çiziyor; ortak widget bu yerleşimi üretmez.
- `*.g.dart` üretilen modeller aynı.

## 7. Sıradaki tek tur

**Sıradaki:** `ActigimDavaCard` `lib/widgets/actigim_dava_card.dart` dosyasına çıksın. Hive açılış tarihi önbelleği aynı kalsın. `InactiveDavaCard` ve `TreeMenuPageheadlines` ayrı tur. Microtask yüklemesi bu turda değişmez.

`FiveCardCaseInformation` kopyaları kendi dosyalarında: gelen, masraf, delil, yargıla, haykır, dava aç, katıldığım, açtığım. Sözleşmeler birleşmedi. `GroupSelectionDialog` `group_selection_dialog.dart` içinde.
