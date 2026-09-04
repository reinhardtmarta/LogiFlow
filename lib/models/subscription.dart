enum Tier { free, basic, pro }

extension TierX on Tier {
  String get id {
    switch (this) {
      case Tier.free:
        return 'free';
      case Tier.basic:
        return 'basic';
      case Tier.pro:
        return 'pro';
    }
  }

  String get label {
    switch (this) {
      case Tier.free:
        return 'Grátis';
      case Tier.basic:
        return 'Basic (até 1000 produtos)';
      case Tier.pro:
        return 'Pro (acima de 1000 produtos)';
    }
  }

  int get amountCents {
    switch (this) {
      case Tier.free:
        return 0;
      case Tier.basic:
        return 1000;
      case Tier.pro:
        return 10000;
    }
  }

  String get priceLabel {
    if (this == Tier.free) return 'R\$ 0,00';
    final reais = amountCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2)}';
  }

  int get productLimit {
    switch (this) {
      case Tier.free:
        return 50;
      case Tier.basic:
        return 1000;
      case Tier.pro:
        return -1;
    }
  }

  String get limitLabel {
    if (this == Tier.pro) return 'Produtos ilimitados';
    return 'Até $productLimit produtos';
  }

  static Tier parse(String? s) {
    switch (s) {
      case 'basic':
        return Tier.basic;
      case 'pro':
        return Tier.pro;
      default:
        return Tier.free;
    }
  }
}

enum SubscriptionStatus { none, active, expired }

extension SubscriptionStatusX on SubscriptionStatus {
  String get id {
    switch (this) {
      case SubscriptionStatus.none:
        return 'none';
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
    }
  }

  String get label {
    switch (this) {
      case SubscriptionStatus.none:
        return 'Sem assinatura';
      case SubscriptionStatus.active:
        return 'Assinatura ativa';
      case SubscriptionStatus.expired:
        return 'Assinatura expirada';
    }
  }

  static SubscriptionStatus parse(String? s) {
    switch (s) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      default:
        return SubscriptionStatus.none;
    }
  }
}

class PixPayment {
  final String preferenceId;
  final String? qrCodeBase64;
  final String? copyPaste;
  final int amountCents;
  final String externalReference;

  PixPayment({
    required this.preferenceId,
    this.qrCodeBase64,
    this.copyPaste,
    required this.amountCents,
    required this.externalReference,
  });

  factory PixPayment.fromMap(Map<String, dynamic> data) {
    return PixPayment(
      preferenceId: (data['preference_id'] ?? '').toString(),
      qrCodeBase64: data['qr_code_base64']?.toString(),
      copyPaste: (data['copy_paste'] ?? data['qr_code'])?.toString(),
      amountCents: (data['amount_cents'] is num)
          ? (data['amount_cents'] as num).toInt()
          : int.tryParse(data['amount_cents']?.toString() ?? '0') ?? 0,
      externalReference: (data['external_reference'] ?? '').toString(),
    );
  }
}

class SellerSubscription {
  final Tier tier;
  final int productLimit;
  final SubscriptionStatus status;
  final DateTime? currentPeriodEnd;
  final String? featuredProductId;

  SellerSubscription({
    required this.tier,
    required this.productLimit,
    required this.status,
    this.currentPeriodEnd,
    this.featuredProductId,
  });

  factory SellerSubscription.fromProfile(Map<String, dynamic> data) {
    final end = data['current_period_end'];
    DateTime? parsedEnd;
    if (end is String) {
      parsedEnd = DateTime.tryParse(end);
    } else if (end is DateTime) {
      parsedEnd = end;
    }
    return SellerSubscription(
      tier: TierX.parse(data['plan']?.toString()),
      productLimit: (data['product_limit'] is num)
          ? (data['product_limit'] as num).toInt()
          : 50,
      status:
          SubscriptionStatusX.parse(data['subscription_status']?.toString()),
      currentPeriodEnd: parsedEnd,
      featuredProductId: data['featured_product_id']?.toString(),
    );
  }

  bool get isActive => status == SubscriptionStatus.active;
}
