import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

import '../models/subscription.dart';

class SubscriptionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<StripeCheckoutSession> createStripeCheckoutSession(Tier tier) async {
    final result = await _functions
        .httpsCallable('createStripeCheckoutSession')
        .call({'tier': tier.id});
    final data = (result.data as Map).cast<String, dynamic>();
    return StripeCheckoutSession.fromMap(data);
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
}

class PaymentStatusUpdate {
  final String status;
  const PaymentStatusUpdate(this.status);
}

