import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/product_model.dart';

enum AgentAction { showProduct, chat, search, unknown }

class AgentResponse {
  final AgentAction action;
  final String text; // Mensagem amigável do agente
  final List<Product>? products;

  AgentResponse({required this.action, required this.text, this.products});
}

class AgentService {
  static GenerativeModel? _model;

  // A mágica acontece aqui: Instrução de Sistema
  static const String _systemInstruction = """
  Você é o Agente LogiFlow, um assistente de sustentabilidade.
  Seu objetivo é ajudar o usuário a encontrar alimentos e reduzir o desperdício.
  
  REGRAS DE COMPORTAMENTO:
  1. Não tente vender. Não use termos como "Compre já", "Promoção imperdível" ou "Aproveite".
  2. Seja informativo e focado em ajuda comunitária e sustentabilidade.
  3. Se o usuário perguntar por um produto, você DEVE responder EXCLUSIVAMENTE em formato JSON.
  
  FORMATO DE RESPOSTA JSON:
  {
    "action": "show_product",
    "text": "Encontrei estes itens próximos a você que podem ser resgatados.",
    "products": [
      {"id": "1", "name": "Leite Orgânico", "price": 4.50, "quantity": 10, "address": "Rua A, 123", "is_rescue": true}
    ]
  }
  
  Se for apenas uma conversa, responda:
  {
    "action": "chat",
    "text": "Sua resposta aqui"
  }
  """;

  static Future<void> initialize(String apiKey) async {
    _model = GenerativeModel(
      model: 'gemma-4-26b-a4b.', 
      apiKey: apiKey,
      systemInstruction: Content.system(_systemInstruction),
    );
  }

  static Future<AgentResponse> processUserRequest(String prompt) async {
    if (_model == null) return AgentResponse(action: AgentAction.unknown, text: "Agente offline");

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final rawJson = response.text ?? '{}';
      
      // Limpeza básica para garantir que pegamos apenas o JSON
      final cleanJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      final actionStr = data['action'] as String;
      AgentAction action = AgentAction.chat;
      if (actionStr == 'show_product') action = AgentAction.showProduct;

      List<Product>? products;
      if (data['products'] != null) {
        products = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
      }

      return AgentResponse(
        action: action,
        text: data['text'] ?? '',
        products: products,
      );
    } catch (e) {
      return AgentResponse(action: AgentAction.chat, text: "Desculpe, tive um problema ao processar. Pode repetir?");
    }
  }
}
