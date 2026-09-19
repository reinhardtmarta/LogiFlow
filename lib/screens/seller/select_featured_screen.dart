import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/subscription.dart';
import '../../services/firebase_service.dart';
import '../../services/subscription_service.dart';

class SelectFeaturedScreen extends StatefulWidget {
  final SellerSubscription subscription;

  const SelectFeaturedScreen({super.key, required this.subscription});

  @override
  State<SelectFeaturedScreen> createState() => _SelectFeaturedScreenState();
}

class _SelectFeaturedScreenState extends State<SelectFeaturedScreen> {
  final SubscriptionService _service = SubscriptionService();
  bool _saving = false;

  Future<void> _select(Product p) async {
    if (p.id == null) return;
    setState(() => _saving = true);
    try {
      await _service.selectFeaturedProduct(p.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto em destaque no feed!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = firebaseService.auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Faça login para destacar produtos.')),
      );
    }
    if (!widget.subscription.isActive) {
      return Scaffold(
        appBar: AppBar(title: const Text('Destacar produto')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Apenas assinantes ativos podem destacar 1 produto no feed.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher produto em destaque'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getSellerProductsStream(
          uid,
          includeHidden: false,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('Cadastre produtos antes de destacar.'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              final isFeatured = p.isFeatured;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(p.name),
                  subtitle: Text(
                    'R\$ ${p.price.toStringAsFixed(2)} • '
                    'qtd ${p.quantity}',
                  ),
                  trailing: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ElevatedButton(
                          onPressed: _saving || isFeatured
                              ? null
                              : () => _select(p),
                          child: Text(isFeatured ? 'Atual' : 'Destacar'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
