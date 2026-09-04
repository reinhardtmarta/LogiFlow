import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription.dart';

enum PaymentMethod { pix, googlePlay }

class SubscriptionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final InAppPurchase _iap = InAppPurchase.instance;

  static const Map<String, String> productIdToTier = {
    'logiflow_basic_monthly': 'basic',
    'logiflow_pro_monthly': 'pro',
  };

  Future<PixPayment> createPixPayment(Tier tier) async {
    final result = await _functions
        .httpsCallable('createPixPreference')
        .call({'tier': tier.id});
    final data = (result.data as Map).cast<String, dynamic>();
    return PixPayment.fromMap(data);
  }

  Future<String> checkPaymentStatus(String externalReference) async {
    final result = await _functions
        .httpsCallable('checkPaymentStatus')
        .call({'external_reference': externalReference});
    final data = (result.data as Map).cast<String, dynamic>();
    return (data['status'] ?? 'pending').toString();
  }

  Stream<PaymentStatusUpdate> watchPaymentStatus(String externalReference,
      {Duration interval = const Duration(seconds: 5)}) async* {
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(deadline)) {
      try {
        final status = await checkPaymentStatus(externalReference);
        yield PaymentStatusUpdate(status);
        if (status == 'paid') return;
      } catch (_) {
        // ignore network blips, keep polling
      }
      await Future.delayed(interval);
    }
    yield const PaymentStatusUpdate('timeout');
  }

  Future<void> selectFeaturedProduct(String productId) async {
    await _functions
        .httpsCallable('selectFeaturedProduct')
        .call({'productId': productId});
  }

  // --------------------- Google Play / In-App Purchase ---------------------

  Future<List<ProductDetails>> queryPlayProducts() async {
    final ids = productIdToTier.keys.toList();
    final response = await _iap.queryProductDetails(ids.toSet());
    return response.productDetails;
  }

  Future<PurchaseResult> buyWithGooglePlay(
    ProductDetails product,
    String uid,
  ) async {
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: uid,
    );
    final stream = _iap.purchaseStream;
    final completer = Completer<PurchaseResult>();
    late final StreamSubscription<List<PurchaseDetails>> sub;
    sub = stream.listen((purchases) async {
      for (final p in purchases) {
        if (p.productID != product.id) continue;
        if (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored) {
          try {
            await _verifyWithBackend(p, product.id);
            if (!completer.isCompleted) {
              completer.complete(PurchaseResult.success(product.id));
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(PurchaseResult.failure(e.toString()));
            }
          }
          await sub.cancel();
          return;
        } else if (p.status == PurchaseStatus.error) {
          if (!completer.isCompleted) {
            completer.complete(
                PurchaseResult.failure(p.error?.message ?? 'unknown'));
          }
          await sub.cancel();
          return;
        }
      }
    });
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        sub.cancel();
        return PurchaseResult.failure('timeout');
      },
    );
  }

  Future<void> _verifyWithBackend(
    PurchaseDetails purchase,
    String productId,
  ) async {
    final result = await _functions
        .httpsCallable('verifyGooglePlayPurchase')
        .call({
      'productId': productId,
      'purchaseToken': purchase.verificationData.serverVerificationData,
      'orderId': purchase.verificationData.localVerificationData,
    });
    final data = (result.data as Map).cast<String, dynamic>();
    if (data['ok'] != true) {
      throw Exception('Verification failed');
    }
  }
}

class PaymentStatusUpdate {
  final String status;
  const PaymentStatusUpdate(this.status);
}

class PurchaseResult {
  final bool success;
  final String? productId;
  final String? error;

  const PurchaseResult._(this.success, this.productId, this.error);

  factory PurchaseResult.success(String productId) =>
      PurchaseResult._(true, productId, null);

  factory PurchaseResult.failure(String error) =>
      PurchaseResult._(false, null, error);
}
