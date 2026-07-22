import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/agent_service.dart';
import '../../stock_screen.dart'; // Ajuste este caminho se a tela estiver em outra pasta

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Widget> _feedItems = []; 

  void _handleSend() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    setState(() {
      _feedItems.add(_buildChatBubble(text, isUser: true));
      _controller.clear();
    });

    final response = await AgentService.processUserRequest(text);

    setState(() {
      _feedItems.add(_buildChatBubble(response.text, isUser: false));

      if (response.action == AgentAction.showProduct && response.products != null) {
        for (var prod in response.products!) {
          _feedItems.add(_buildProductCard(prod));
        }
      }
    });
  }

  Widget _buildChatBubble(String text, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        border: Border.all(color: product.isRescue ? Colors.redAccent : Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (product.isRescue) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                  child: const Text("RESCATE", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text("📍 ${product.address}", style: const TextStyle(color: Colors.grey)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("R\$ ${product.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              Text("Qtd: ${product.quantity}", style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Ver detalhes"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LogiFlow Agent"),
        // Adição do botão de navegação para o StockScreen
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory),
            tooltip: 'Acessar Estoque',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StockScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _feedItems.length,
              itemBuilder: (context, index) => _feedItems[index],
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller, 
              decoration: const InputDecoration(hintText: "Procure alimentos...")
            )
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green), 
            onPressed: _handleSend
          ),
        ],
      ),
    );
  }
}
