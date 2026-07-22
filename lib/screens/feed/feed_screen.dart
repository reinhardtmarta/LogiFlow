import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/agent_service.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Widget> _feedItems = []; // Aqui guardamos o que aparece na tela

  void _handleSend() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    setState(() {
      _feedItems.add(_buildChatBubble(text, isUser: true));
      _controller.clear();
    });

    // Chama o Agente
    final response = await AgentService.processUserRequest(text);

    setState(() {
      // 1. Adiciona a resposta de texto do agente
      _feedItems.add(_buildChatBubble(response.text, isUser: false));

      // 2. Se o agente decidiu mostrar produtos, injeta os CARDS no feed
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
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: TextStyle(color: Colors.black87)),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: EdgeInsets.all(15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        border: Border.all(color: product.isRescue ? Colors.redAccent : Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (product.isRescue) 
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                  child: Text("RESCATE", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
          SizedBox(height: 5),
          Text("📍 ${product.address}", style: TextStyle(color: Colors.grey)),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("R\$ ${product.price.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              Text("Qtd: ${product.quantity}", style: TextStyle(color: Colors.black54)),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, 
              child: Text("Ver detalhes"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("LogiFlow Agent")),
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
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: TextField(controller: _controller, decoration: InputDecoration(hintText: "Procure alimentos..."))),
          IconButton(icon: Icon(Icons.send, color: Colors.green), onPressed: _handleSend),
        ],
      ),
    );
  }
}
