import 'package:flutter/material.dart';
import '../../models/subscription.dart';
import '../../models/user.dart';
import '../../models/product.dart';
import '../../services/firebase_service.dart';
import 'add_product_screen.dart';
import 'select_featured_screen.dart';
import 'upgrade_screen.dart';

class SellerDashboard extends StatefulWidget {
  final User user;

  const SellerDashboard({
    super.key,
    required this.user,
  });

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  String _getExpiryText(Product product) {
    final now = DateTime.now();

    // Compara apenas a data, evitando problemas causados pelo horário.
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      product.expiryDate.year,
      product.expiryDate.month,
      product.expiryDate.day,
    );

    final days = expiry.difference(today).inDays;

    if (days < 0) {
      final overdueDays = days.abs();
      return overdueDays == 1
          ? 'Expired 1 day ago'
          : 'Expired $overdueDays days ago';
    }

    if (days == 0) {
      return 'Expires today';
    }

    if (days == 1) {
      return 'Expires tomorrow';
    }

    return 'Expires in $days days';
  }

  bool _isExpired(Product product) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      product.expiryDate.year,
      product.expiryDate.month,
      product.expiryDate.day,
    );

    return expiry.isBefore(today);
  }

  bool _expiresSoon(Product product) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      product.expiryDate.year,
      product.expiryDate.month,
      product.expiryDate.day,
    );

    final days = expiry.difference(today).inDays;

    return days >= 0 && days <= 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Dashboard"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getSellerProductsStream(widget.user.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Could not load your products.",
                style: TextStyle(
                  color: Colors.red[700],
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          final expiredProducts =
              products.where(_isExpired).length;

          final expiringSoonProducts =
              products.where(_expiresSoon).length;

          final hiddenCount =
              products.where((p) => p.hidden).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Welcome
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Welcome back, ${widget.user.name}!\n"
                      "Manage your inventory and reduce waste.",
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                StreamBuilder<SellerSubscription>(
                  stream: firebaseService
                      .getSubscriptionStream(widget.user.id!),
                  builder: (context, subSnap) {
                    if (!subSnap.hasData) {
                      return const SizedBox.shrink();
                    }
                    final sub = subSnap.data!;
                    return _buildPlanBanner(sub, products.length, hiddenCount);
                  },
                ),

                const SizedBox(height: 20),

                // Inventory summary
                const Text(
                  "Inventory Overview",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.inventory_2,
                        title: "Products",
                        value: "${products.length}",
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.warning_amber,
                        title: "Expiring",
                        value: "$expiringSoonProducts",
                        warning: expiringSoonProducts > 0,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.error_outline,
                        title: "Expired",
                        value: "$expiredProducts",
                        warning: expiredProducts > 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Products
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "My Products",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${products.length} items",
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        "No products yet.\nTap + to add your first product.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      final expired =
                          _isExpired(product);

                      final expiring =
                          _expiresSoon(product);

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: expired
                                ? Colors.red[100]
                                : expiring
                                    ? Colors.orange[100]
                                    : Colors.green[100],
                            child: Icon(
                              expired
                                  ? Icons.error
                                  : expiring
                                      ? Icons.warning_amber
                                      : Icons.inventory_2,
                              color: expired
                                  ? Colors.red
                                  : expiring
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),

                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Text(
                            "${product.quantity} units • "
                            "${_getExpiryText(product)}",
                          ),

                          trailing: expiring || expired
                              ? const Icon(
                                  Icons.warning_amber,
                                  color: Colors.red,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductScreen(
                user: widget.user,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
    );
  }

  Widget _buildPlanBanner(
    SellerSubscription sub,
    int visibleCount,
    int hiddenCount,
  ) {
    final color = sub.isActive ? Colors.green[50]! : Colors.amber[50]!;
    final iconData =
        sub.isActive ? Icons.workspace_premium : Icons.upgrade;
    final iconColor =
        sub.isActive ? Colors.green[700]! : Colors.orange[800]!;
    final limitText = sub.productLimit < 0
        ? 'ilimitados'
        : 'limite ${sub.productLimit}';

    final title = sub.isActive
        ? 'Plano ${sub.tier.label} ativo'
        : 'Você está no plano Grátis ($limitText)';
    final body = sub.isActive
        ? 'Você pode destacar 1 produto no feed público.'
        : (hiddenCount > 0
            ? 'Você tem $hiddenCount produto(s) oculto(s) por exceder '
                'o limite. Reduza o estoque ou faça upgrade para liberar.'
            : 'Faça upgrade para liberar mais produtos e destacar no feed.');

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(iconData, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (sub.isActive)
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SelectFeaturedScreen(subscription: sub),
                    ),
                  );
                },
                child: const Text('Destacar'),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  final currentCount = visibleCount + hiddenCount;
                  final tierNeeded =
                      currentCount >= 1000 ? Tier.pro : Tier.basic;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpgradeScreen(
                        suggestedTier: tierNeeded,
                        currentCount: currentCount,
                        currentLimit: sub.productLimit,
                        subscription: sub,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upgrade'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    bool warning = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: warning
                  ? Colors.red
                  : Colors.green,
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
