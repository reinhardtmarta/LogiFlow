import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/subscription.dart';
import '../../services/subscription_service.dart';

class UpgradeScreen extends StatefulWidget {
  final Tier suggestedTier;
  final int currentCount;
  final int currentLimit;
  final SellerSubscription subscription;

  const UpgradeScreen({
    super.key,
    required this.suggestedTier,
    required this.currentCount,
    required this.currentLimit,
    required this.subscription,
  });

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final SubscriptionService _service = SubscriptionService();

  StripeCheckoutSession? _checkout;
  bool _generating = false;
  String? _paymentStatus;
  StreamSubscription<PaymentStatusUpdate>? _pollingSub;

  @override
  void dispose() {
    _pollingSub?.cancel();
    super.dispose();
  }

  Future<void> _startStripeCheckout() async {
    setState(() {
      _generating = true;
      _paymentStatus = null;
    });
    try {
      final payment = await _service
          .createStripeCheckoutSession(widget.suggestedTier);
      final opened = await launchUrl(
        Uri.parse(payment.checkoutUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw Exception('Não foi possível abrir o checkout Stripe.');
      }
      setState(() {
        _checkout = payment;
        _paymentStatus = 'pending';
      });
      _startPolling(payment.externalReference);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao iniciar o Stripe: $e')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _startPolling(String externalRef) {
    _pollingSub?.cancel();
    _pollingSub = _service
        .watchPaymentStatus(externalRef)
        .listen((update) {
      if (!mounted) return;
      setState(() {
        _paymentStatus = update.status;
      });
      if (update.status == 'paid') {
        _pollingSub?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento confirmado! Plano ativado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (update.status == 'timeout') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tempo esgotado aguardando pagamento.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer upgrade'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildPlanCard(Tier.basic),
            const SizedBox(height: 8),
            _buildPlanCard(Tier.pro),
            const SizedBox(height: 16),
            const Text(
              'Pagamento seguro',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A assinatura será concluída no Checkout Stripe. O pagamento é'
              ' recorrente mensal e pode ser cancelado pelo portal do cliente.',
            ),
            const SizedBox(height: 16),
            _buildStripeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final suggested = widget.suggestedTier;
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Você atingiu o limite do plano atual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Produtos: ${widget.currentCount}'
              '${widget.currentLimit < 0 ? '' : ' / ${widget.currentLimit}'}',
            ),
            const SizedBox(height: 4),
            Text('Plano atual: ${widget.subscription.tier.label}'),
            const SizedBox(height: 4),
            Text('Status: ${widget.subscription.status.label}'),
            const SizedBox(height: 12),
            Text(
              'Recomendamos o plano ${suggested.label} por ${suggested.priceLabel}/mês.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Tier tier) {
    final selected = widget.suggestedTier == tier;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? Colors.green : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          tier == Tier.pro ? Icons.workspace_premium : Icons.star_border,
          color: selected ? Colors.green : null,
        ),
        title: Text(tier.label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tier.limitLabel),
        trailing: Text(
          tier.priceLabel,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
    );
  }

  Widget _buildStripeSection() {
    if (_checkout == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _generating ? null : _startStripeCheckout,
          icon: _generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.lock),
          label: Text(
            _generating
                ? 'Abrindo Stripe...'
                : 'Assinar com Stripe (${widget.suggestedTier.priceLabel}/mês)',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    final checkout = _checkout!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.open_in_browser, size: 40, color: Colors.indigo),
            const SizedBox(height: 8),
            const Text(
              'Checkout Stripe aberto. Conclua o pagamento e volte ao app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(checkout.checkoutUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir checkout novamente'),
            ),
            const SizedBox(height: 8),
            if (_paymentStatus != null) _buildStatusChip(_paymentStatus!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'paid':
        color = Colors.green;
        label = 'Pago';
        break;
      case 'expired':
        color = Colors.red;
        label = 'Expirado';
        break;
      case 'timeout':
        color = Colors.orange;
        label = 'Tempo esgotado';
        break;
      default:
        color = Colors.amber;
        label = 'Aguardando pagamento...';
    }
    return Chip(
      avatar: Icon(
        status == 'paid' ? Icons.check_circle : Icons.hourglass_top,
        color: Colors.white,
        size: 18,
      ),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

}
