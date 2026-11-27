import 'package:in_app_purchase/in_app_purchase.dart';

/// Satın alma akışının yıldıza çevrilip çevrilmeyeceği.
///
/// İptal, hata ve bekleyen işlemler bakiye yazmaz. Aynı satın alma kimliği
/// ikinci kez gelirse de yazılmaz.
class StarCreditDecision {
  const StarCreditDecision({required this.credit, required this.balance});

  final bool credit;
  final int balance;
}

StarCreditDecision decideStarCredit({
  required PurchaseStatus status,
  required int currentBalance,
  required int starAmount,
  String? purchaseId,
  required Set<String> alreadyCreditedIds,
}) {
  final bool succeeded = status == PurchaseStatus.purchased ||
      status == PurchaseStatus.restored;
  if (!succeeded || starAmount <= 0) {
    return StarCreditDecision(credit: false, balance: currentBalance);
  }
  final String? key =
      (purchaseId != null && purchaseId.isNotEmpty) ? purchaseId : null;
  if (key != null && alreadyCreditedIds.contains(key)) {
    return StarCreditDecision(credit: false, balance: currentBalance);
  }
  if (key != null) {
    alreadyCreditedIds.add(key);
  }
  return StarCreditDecision(
    credit: true,
    balance: currentBalance + starAmount,
  );
}

/// Satın alma akışının dinleyiciye bildirdiği sonuç.
class PurchaseCreditOutcome {
  const PurchaseCreditOutcome({
    required this.status,
    required this.productId,
    required this.purchaseId,
    required this.stars,
    required this.credited,
  });

  final PurchaseStatus status;
  final String productId;
  final String? purchaseId;
  final int stars;
  final bool credited;
}
