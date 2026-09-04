import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import '../../services/firebase_service.dart';

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

  PaymentMethod _selectedMethod = PaymentMethod.pix;

  PixPayment? _pix;
  bool _generating = false;
  String? _paymentStatus;
  StreamSubscription<PaymentStatusUpdate>? _pollingSub;

  bool _buyingPlay = false;
  String? _playMessage;

  @override
  void dispose() {
    _pollingSub?.cancel();
    super.dispose();
  }

  Future<void> _generatePix() async {
    setState(() {
      _generating = true;
      _paymentStatus = null;
    });
    try {
      final payment = await _service.createPixPayment(widget.suggestedTier);
      setState(() {
        _pix = payment;
        _paymentStatus = 'pending';
      });
      _startPolling(payment.externalReference);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao gerar Pix: $e')),
      );
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

  Future<void> _buyWithGooglePlay() async {
    setState(() {
      _buyingPlay = true;
      _playMessage = null;
    });
    try {
      final products = await _service.queryPlayProducts();
      final productId =
          widget.suggestedTier == Tier.basic
              ? 'logiflow_basic_monthly'
              : 'logiflow_pro_monthly';
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Produto indisponível na Play Store.'),
      );
      final uid = firebaseService.auth.currentUser?.uid ?? '';
      final result = await _service.buyWithGooglePlay(product, uid);
      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assinatura ativada via Google Play.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _playMessage = result.error;
        });
      }
    } catch (e) {
      setState(() {
        _playMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _buyingPlay = false;
        });
      }
    }
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
              'Método de pagamento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.pix,
              groupValue: _selectedMethod,
              onChanged: (v) => setState(() => _selectedMethod = v!),
              title: const Text('Pix (Mercado Pago)'),
              subtitle: const Text('Recomendado • QR Code instantâneo'),
            ),
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.googlePlay,
              groupValue: _selectedMethod,
              onChanged: (v) => setState(() => _selectedMethod = v!),
              title: const Text('Google Play (assinatura mensal)'),
              subtitle: const Text('Fallback se Pix não estiver disponível'),
            ),
            const SizedBox(height: 16),
            if (_selectedMethod == PaymentMethod.pix)
              _buildPixSection()
            else
              _buildGooglePlaySection(),
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

  Widget _buildPixSection() {
    if (_pix == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _generating ? null : _generatePix,
          icon: _generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.qr_code),
          label: Text(
            _generating
                ? 'Gerando QR Code...'
                : 'Gerar QR Code Pix (${widget.suggestedTier.priceLabel})',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    return _buildPixQrCard();
  }

  Widget _buildPixQrCard() {
    final pix = _pix!;
    final reais = (pix.amountCents / 100).toStringAsFixed(2);
    Widget qrImage = Container(
      height: 220,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Text('QR Code indisponível'),
    );
    if (pix.qrCodeBase64 != null && pix.qrCodeBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(pix.qrCodeBase64!);
        qrImage = Image.memory(
          bytes,
          height: 220,
          fit: BoxFit.contain,
        );
      } catch (_) {}
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Escaneie o QR Code ou copie o código abaixo',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            qrImage,
            const SizedBox(height: 12),
            Text(
              'Total: R\$ $reais',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (pix.copyPaste != null)
              SelectableText(
                pix.copyPaste!,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pix.copyPaste == null
                        ? null
                        : () {
                            Clipboard.setData(
                                ClipboardData(text: pix.copyPaste!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Código Pix copiado.')),
                            );
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                  ),
                ),
              ],
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

  Widget _buildGooglePlaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Você será cobrado ${widget.suggestedTier.priceLabel} por mês '
              'via Google Play. Cancelamento a qualquer momento na Play Store.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _buyingPlay ? null : _buyWithGooglePlay,
          icon: _buyingPlay
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.shop),
          label: Text(
            _buyingPlay
                ? 'Abrindo Play Store...'
                : 'Assinar ${widget.suggestedTier.label}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_playMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _playMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
