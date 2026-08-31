import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../../core/gemma_service.dart';
import '../../screens/chat/chat_screen.dart';

class GeneralFeedScreen extends StatefulWidget {
  final User user;
  const GeneralFeedScreen({super.key, required this.user});

  @override
  State<GeneralFeedScreen> createState() => _GeneralFeedScreenState();
}

class _GeneralFeedScreenState extends State<GeneralFeedScreen> {
  // Estado para armazenar o insight gerado pela IA
  String? _aiInsightMessage;
  bool _isAnalyzing = false;

  /// Função que chama a Gemma para analisar o feed atual e gerar um insight
  Future<void> _generateSmartInsight(List<Product> products) async {
    if (products.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      // Chamada ao serviço da Gemma (usando o novo modelo de intenção/análise)
      // Aqui passamos a lista de produtos para ela analisar
      final result = await GemmaService().getInsights(
        products: products,
        userSettings: widget.user.settings, // Supondo que seu User tenha settings
      );

      if (mounted) {
        setState(() {
          _aiInsightMessage = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao gerar insight: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiFlow Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 2,
        actions: [
          // Botão para o usuário pedir uma nova análise da IA
          IconButton(
            icon: Icon(_isAnalyzing ? Icons.hourglass_empty : Icons.auto_awesome, color: Colors.white),
            onPressed: _isAnalyzing ? null : () async {
              // Pegamos a lista atual para a IA analisar
              // Nota: Em um app real, você passaria a lista que já está no Stream
              // Para este exemplo, vamos assumir que a lista é acessível.
            },
          ),
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

          // Dispara a análise da IA assim que os produtos carregam pela primeira vez
          if (_aiInsightMessage == null && !_isAnalyzing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _generateSmartInsight(products);
            });
          }

          return Column(
            children: [
              // --- ABA DE SUGESTÕES DA GEMMA (O NOVO COMPONENTE) ---
              if (_aiInsightMessage != null)
                _buildAIInsightBanner(),
              
              // O Feed de Produtos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final days = p.expiryDate.difference(DateTime.now()).inDays;
                    final isUrgent = days <= 3;
                    final isPremium = p.isFeatured;

                    return _buildProductCard(p, isUrgent, isPremium, days);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Widget do Banner de Inteligência (Aba de Sugestões)
  Widget _buildAIInsightBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DICA DA GEMMA",
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  _aiInsightMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: () => setState(() => _aiInsightMessage = null),
          )
        ],
      ),
    );
  }

  /// Widget para construir o Card de cada produto
  Widget _buildProductCard(Product p, bool isUrgent, bool isPremium, int days) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPremium ? Colors.green.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
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
          receiverName: 'Vendedor',
        ),
      ),
    );
  }
}
