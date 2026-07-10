# Play Console — yıldız (consumable) IAP

Kodda SKU’lar [`lib/services/play_billing_service.dart`](../lib/services/play_billing_service.dart) içinde `kStarProducts` haritasıyla tanımlıdır.

| Ürün kimliği (SKU)     | Uygulama içi yıldız |
|------------------------|---------------------|
| `whoboom_stars_small`  | 50                  |
| `whoboom_stars_medium` | 150                 |
| `whoboom_stars_large`  | 500                 |

## Google Play Console adımları

1. Play Console’da uygulamanızı seçin → **Grow (Büyüt) / Monetize with Play** (veya menüde **Monetize**) → **Products** → **In-app products** (In-app offers).
2. **Create product** → tür: **Consumable** (tüketilebilir).
3. Her SKU için yukarıdaki **Product ID**’yi aynen girin; görünen ad ve açıklamayı doldurun.
4. Bölgesel fiyatları ayarlayıp ürün durumunu **Active** yapın.
5. **Settings → License testing** (Test edenler) bölümünde Gmail hesapları ekleyerek gerçek kart ücreti olmadan satın almayı test edin.
6. Uygulamanın imzalı bir sürümünü **internal / closed testing** kanalına yükleyin; IAP yalnızca Play’den yüklenmiş build’lerde tam çalışır.

## Yerel geliştirme

- Gerçek ürün yapılandırılmamışsa veya Billing kullanılamıyorsa hediye ekranı **yerel yükleme** ile paket kartlarına dokununca bakiyeyi artırır (simülasyon).

## Güvenlik notu

- Üretimde yıldız bakiyesi yalnızca cihazdaki yerel saklamaya bağlıdır; güvenilir toplamlar için backend doğrulama (Google Play Developer API ile satın alma token’ları) kullanılmalıdır.
