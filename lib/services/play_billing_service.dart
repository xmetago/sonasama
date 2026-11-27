import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'star_purchase_credit.dart';
import 'user_star_balance_store.dart';

/// Google Play (ve iOS üzerinden aynı API) — tüketilebilir yıldız paketleri.
///
/// ### Play Console (özet)
/// 1. **Monetize → Subscriptions ve uygulama içi ürünler** (veya Eski Play Console'da **Uygulama içi ürünler**).
/// 2. **Ürün yönetimi → Uygulama içi ürünler** → **Ürün oluştur**.
/// 3. Her biri için **Tüketilebilir** (consumable), **SKU** olarak aşağıdaki kimlikleri girin:
///    - `whoboom_stars_small` → içerik: 50 yıldız
///    - `whoboom_stars_medium` → 150 yıldız
///    - `whoboom_stars_large` → 500 yıldız
/// 4. Fiyatları bölgenize göre ayarlayıp ürünü **Etkin** yapın.
/// 5. **Test → Lisans testi**: test hesapları ekleyerek gerçek ücret kesilmeden satın alma deneyebilirsiniz.
/// 6. Uygulama imzalı ve yüklü APK/AAB (internal/IAA test kanalı veya yükleme) ile test edilir.
///
/// SKU’lar mağazada yoksa [buyConsumable] false döner; arayüz yerel yükleme (geliştirme) yoluna düşebilir.
class PlayBillingService {
  PlayBillingService();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  void Function(int stars)? _onStarsDelivered;
  bool _streamAttached = false;
  String? _creditEmail;
  final Set<String> _creditedPurchaseIds = <String>{};
  final StreamController<PurchaseCreditOutcome> _outcomes =
      StreamController<PurchaseCreditOutcome>.broadcast();

  /// Başarılı, iptal ve hatalı satın almalar bu akıştan okunur.
  Stream<PurchaseCreditOutcome> get purchaseOutcomes => _outcomes.stream;

  /// Play Console SKU → uygulamaya yansıtılacır yıldız miktarı.
  static const Map<String, int> kStarProducts = <String, int>{
    'whoboom_stars_small': 50,
    'whoboom_stars_medium': 150,
    'whoboom_stars_large': 500,
  };

  static String? productIdForStarAmount(int amount) {
    for (final MapEntry<String, int> e in kStarProducts.entries) {
      if (e.value == amount) return e.key;
    }
    return null;
  }

  /// Mağaza erişilirse true. [onStarsDelivered] yalnızca başarılı teslimattan sonra çağrılır.
  /// Yıldız bakiyesini bu servis yazar; geri çağıran yalnızca arayüzü günceller.
  Future<bool> init(
    void Function(int stars) onStarsDelivered, {
    String? creditEmail,
  }) async {
    _onStarsDelivered = onStarsDelivered;
    if (creditEmail != null && creditEmail.trim().isNotEmpty) {
      _creditEmail = creditEmail.trim();
    }
    if (kIsWeb) return false;
    final bool available = await _iap.isAvailable().timeout(
      const Duration(seconds: 4),
      onTimeout: () => false,
    );
    if (!available) return false;

    if (!_streamAttached) {
      await _sub?.cancel();
      _sub = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (_) {},
      );
      _streamAttached = true;
    }
    return true;
  }

  /// Akış zaten dinleniyorsa yeniden bağlamaz. Satın alacak e-postayı günceller.
  Future<bool> ensureReady({String? creditEmail}) async {
    if (creditEmail != null && creditEmail.trim().isNotEmpty) {
      _creditEmail = creditEmail.trim();
    }
    if (_streamAttached) return !kIsWeb;
    return init(_onStarsDelivered ?? (_) {}, creditEmail: _creditEmail);
  }

  String _purchaseKey(PurchaseDetails purchase) {
    final String? id = purchase.purchaseID;
    if (id != null && id.isNotEmpty) return id;
    return '${purchase.productID}|${purchase.transactionDate ?? ''}|${purchase.status.name}';
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      final int stars = kStarProducts[purchase.productID] ?? 0;
      final String? email = _creditEmail?.trim();
      final bool eligible =
          stars > 0 && email != null && email.isNotEmpty;
      final bool canWrite = eligible &&
          decideStarCredit(
            status: purchase.status,
            currentBalance: 0,
            starAmount: stars,
            purchaseId: _purchaseKey(purchase),
            alreadyCreditedIds: _creditedPurchaseIds,
          ).credit;
      if (canWrite) {
        await UserStarBalanceStore.addYellowStars(email, stars);
        _onStarsDelivered?.call(stars);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      if (!_outcomes.isClosed) {
        _outcomes.add(
          PurchaseCreditOutcome(
            status: purchase.status,
            productId: purchase.productID,
            purchaseId: purchase.purchaseID,
            stars: stars,
            credited: canWrite,
          ),
        );
      }
    }
  }

  /// Play / App Store’da tanımlı tüketilebilir ürünü başlatır.
  /// [creditEmail] başarılı satın almada yıldızın yazılacağı hesaptır.
  Future<bool> buyConsumable(String productId, {String? creditEmail}) async {
    if (creditEmail != null && creditEmail.trim().isNotEmpty) {
      _creditEmail = creditEmail.trim();
    }
    if (kIsWeb || !kStarProducts.containsKey(productId)) return false;
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(<String>{productId}).timeout(
      const Duration(seconds: 8),
      onTimeout: () => ProductDetailsResponse(
        productDetails: const <ProductDetails>[],
        notFoundIDs: <String>[productId],
      ),
    );
    if (response.error != null || response.productDetails.isEmpty) return false;
    final ProductDetails details = response.productDetails.single;
    final PurchaseParam param =
        PurchaseParam(productDetails: details);
    return _iap.buyConsumable(purchaseParam: param);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _streamAttached = false;
    _onStarsDelivered = null;
  }
}

/// Uygulama genelinde tek örnek; hediye masraf akışında başlatılır.
final PlayBillingService globalPlayBilling = PlayBillingService();
