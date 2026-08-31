import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../../screens/chat/chat_screen.dart';

class GeneralFeedScreen extends StatefulWidget {
  final User user;
  const GeneralFeedScreen({super.key, required this.user});

  @override
  State<GeneralFeedScreen> createState() => _GeneralFeedScreenState();
}

class _GeneralFeedScreenState extends State<GeneralFeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiFlow Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 2,
        actions: [
          // Ícone para o usuário ver o seu próprio perfil/estoque se necessário
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Lógica para ir para o perfil
            },
          )
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar produtos: ${snapshot.error}"));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhum item disponível no momento.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              
              // Lógica de Urgência
              final days = p.expiryDate.difference(DateTime.now()).inDays;
              final isUrgent = days <= 3;
              
              // Lógica de Destaque (Monetização)
              final isPremium = p.isFeatured; // Assume que seu modelo Product tem esse campo

              return _buildProductCard(p, isUrgent, isPremium, days);
            },
          );
        },
      ),
    );
  }

  /// Widget para construir o Card de cada produto de forma modular e elegante
  Widget _buildProductCard(Product p, bool isUrgent, bool isPremium, int days) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPremium ? Colors.green.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Borda colorida se for Premium ou Urgente
        border: Border.all(
          color: isPremium 
              ? Colors.amber.shade600 
              : (isUrgent ? Colors.red.shade300 : Colors.transparent),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => _navigateToChat(p),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha de Badges (Destaque e Urgência)
                  Row(
                    children: [
                      if (isPremium)
                        _buildBadge(Icons.star, "PREMIUM", Colors.amber),
                      if (isUrgent)
                        _buildBadge(Icons.warning_amber_rounded, "RESGATE URGENTE", Colors.red),
                      if (!isPremium && !isUrgent)
                        _buildBadge(Icons.eco, "SAUDÁVEL", Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nome e Preço
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                        ),
                      ),
                      Text(
                        "\$${p.price.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Informações de Localização e Quantidade
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.address,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${p.quantity} un", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Linha de Vencimento (Footer do Card)
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Vence em: $days dias",
                        style: TextStyle(
                          color: isUrgent ? Colors.red : Colors.grey.shade600,
                          fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para criar os pequenos selos (badges)
  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: p.userId,
          receiverName: 'Vendedor', // No futuro, busque o nome real do vendedor no Firestore
        ),
      ),
    );
  }
}
