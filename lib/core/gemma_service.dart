import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logiflow/core/database_helper.dart';
import 'package:logiflow/models/product.dart';

// 1. Comandos que o App entende para mudar a interface
enum BotCommand {
  showProduct,   // Mostrar um card de produto
  listProducts,  // Listar todos os produtos
  searchStock,   // Buscar um item específico
  updateStock,   // Atualizar quantidade ou status
  help,          // Ajuda
  chat           // Conversa simples
}

// 2. O objeto que o BOT retorna
class BotResponse {
  final BotCommand command;
  final String message; // A resposta em texto para o usuário
  final List<Product>? products; // Os produtos reais encontrados no banco
  final Map<String, dynamic>? payload; 

  BotResponse({
    required this.command,
    required this.message,
    this.products,
    this.payload,
  });
}

class LogiFlowBotService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static GenerativeModel? _model;
  static bool isInitialized = false;

  // Instrução de Sistema que define o comportamento e o formato
  static const String _systemInstruction = """
  You are the LogiFlow Intelligent Agent. 
  Your job is to act as a bridge between the user and the inventory database.
  
  RULES:
  1. You will be provided with a list of real products (The Inventory).
  2. Use ONLY the provided inventory to answer questions about stock or items.
  3. If a user asks to update something (e.g., 'add 10 apples'), return an 'updateStock' command.
  4. If a user asks for a product, return 'showProduct' and the product data.
  5. Always respond in valid JSON format.

  JSON FORMAT:
  {
    "command": "showProduct" | "listProducts" | "searchStock" | "updateStock" | "help" | "chat",
    "message": "Your friendly response in English or Portuguese",
    "payload": { "id": 1, "qty": 10, "item_name": "name", "status": "cleaned" }
  }
  """;

  static Future<void> initialize() async {
    if (isInitialized) return;
    try {
      if (_apiKey.isEmpty) throw Exception('API Key missing!');

      _model = GenerativeModel(
        model: 'gemini-1.5-flash', // Flash é perfeito para RAG (rápido e barato)
        apiKey: _apiKey,
        systemInstruction: Content.system(_systemInstruction),
      );

      isInitialized = true;
      print("🤖 LogiFlow RAG Bot Ready!");
    } catch (e) {
      print("❌ Bot Init Error: $e");
      rethrow;
    }
  }

  static Future<BotResponse> execute(String userInput) async {
    if (!isInitialized || _model == null) {
      return BotResponse(command: BotCommand.chat, message: "Bot is loading...");
    }

    try {
      // --- PASSO 1: BUSCAR OS DADOS REAIS DO BANCO (O SEGREDO DO RAG) ---
      final db = DatabaseHelper.instance;
      final List<Product> allProducts = await db.getAllProducts();
      
      // Transformamos a lista de produtos em uma string de texto para a IA ler
      String inventoryContext = "CURRENT INVENTORY:\n";
      if (allProducts.isEmpty) {
        inventoryContext += "No products in stock.";
      } else {
        for (var p in allProducts) {
          inventoryContext += "- ID: ${p.id}, Name: ${p.name}, Qty: ${p.quantity}, Price: ${p.price}, Status: ${p.condition}, Expiry: ${p.expiryDate}\n";
        }
      }

      // --- PASSO 2: MONTAR O PROMPT COM O CONTEXTO ---
      // Enviamos o contexto do banco + a pergunta do usuário
      final fullPrompt = """
$inventoryContext

USER REQUEST: $userInput
""";

      // --- PASSO 3: CHAMADA DA IA ---
      final response = await _model!.generateContent([Content.text(fullPrompt)]);
      final String rawJson = response.text ?? '{}';
      
      // Limpeza de Markdown (remove ```json ... ```)
      final String cleanJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> decoded = jsonDecode(cleanJson);

      // Mapeamento do comando
      BotCommand command;
      switch (decoded['command']) {
        case 'showProduct': command = BotCommand.showProduct; break;
        case 'listProducts': command = BotCommand.listProducts; break;
        case 'searchStock': command = BotCommand.searchStock; break;
        case 'updateStock': command = BotCommand.updateStock; break;
        case 'help': command = BotCommand.help; break;
        default: command = BotCommand.chat;
      }

      // --- PASSO 4: TRATAR O RESULTADO ---
      
      // Se o comando for mostrar produto, buscamos os detalhes reais do banco usando o ID que a IA sugeriu
      List<Product>? products;
      if (command == BotCommand.showProduct && decoded['payload'] != null) {
        final String? idStr = decoded['payload']['id']?.toString();
        if (idStr != null) {
          final int targetId = int.parse(idStr);
          final allItems = await db.getAllProducts();
          products = allItems.where((p) => p.id == targetId).toList();
        }
      }

      return BotResponse(
        command: command,
        message: decoded['message'] ?? '',
        products: products,
        payload: decoded['payload'],
      );

    } catch (e) {
      print("Bot Error: $e");
      return BotResponse(command: BotCommand.chat, message: "Error accessing inventory data.");
    }
  }
}
