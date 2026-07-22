import 'dart:convert';
import 'package:logiflow/core/database_helper.dart';
import 'package:logiflow/models/product.dart';

// 1. Comandos que o App interpreta para mudar a interface
enum BotCommand {
  showProduct,   // Comando para renderizar um card de produto
  listProducts,  // Comando para listar todos os produtos
  searchStock,   // Comando para busca de estoque
  updateStock,   // Comando para atualizar quantidade ou status
  help,          // Comando de ajuda
  chat           // Fallback para conversas simples
}

// 2. O objeto que o BOT retorna
class BotResponse {
  final BotCommand command;
  final String message;
  final List<Product>? products;
  final Map<String, dynamic>? payload; 

  BotResponse({
    required this.command,
    required this.message,
    this.products,
    this.payload,
  });
}

class LogiFlowBotService {
  static bool isInitialized = false;

  // Inicialização rápida (Offline Mode)
  static Future<void> initialize() async {
    isInitialized = true;
    print("🤖 LogiFlow Local Bot Ready (Offline Mode)");
  }

  // MÉTODO PRINCIPAL: O "Cérebro" que interpreta a intenção do usuário
  static Future<BotResponse> execute(String userInput) async {
    if (!isInitialized) {
      return BotResponse(command: BotCommand.chat, message: "Bot is loading...");
    }

    final input = userInput.toLowerCase();
    final db = DatabaseHelper.instance;

    try {
      // --- CASO 1: AJUDA (HELP) ---
      if (input.contains("help") || input.contains("how") || input.contains("command")) {
        return BotResponse(
          command: BotCommand.help,
          message: "Commands: 'find [item]', 'add [qty] [item]', 'set [item] to [status]', 'list all'.",
        );
      }

      // --- CASO 2: ATUALIZAÇÃO DE ESTOQUE (UPDATE INTENT) ---
      // Detecta padrões como: "add 10 apples", "set milk to 5", "change apple to cleaned"
      if (input.contains("add") || input.contains("set") || input.contains("change") || input.contains("update")) {
        
        // 1. Extrair o número (quantidade)
        final numberRegex = RegExp(r'\d+');
        final numberMatch = numberRegex.firstMatch(input);
        final int? newQty = numberMatch != null ? int.parse(numberMatch.group(0)!) : null;

        // 2. Detectar status de limpeza/embalagem
        String? newStatus;
        if (input.contains("cleaned") || input.contains("clean")) newStatus = "Cleaned";
        if (input.contains("packaged") || input.contains("pack")) newStatus = "Packaged";
        if (input.contains("new")) newStatus = "New";

        // 3. Limpar a frase para encontrar o NOME do produto
        // Removemos números, comandos e palavras de status para sobrar apenas o nome do item
        String cleanQuery = input
            .replaceAll(RegExp(r'\d+'), '') // remove números
            .replaceAll(RegExp(r'(add|set|change|update|to|units|qty|quantity|cleaned|packaged|new|item|the|is|at)'), '')
            .trim();

        if (cleanQuery.isNotEmpty) {
          // Busca o produto real no banco de dados usando o nome limpo
          final products = await db.searchProducts(cleanQuery);
          
          if (products.isNotEmpty) {
            final targetProduct = products.first;
            
            // Executa a atualização no banco de dados
            await db.updateProduct(
              targetProduct.id, 
              qty: newQty, 
              condition: newStatus
            );

            String statusMsg = newQty != null ? "$newQty units " : "";
            statusMsg += newStatus != null ? "and status to $newStatus" : "";

            return BotResponse(
              command: BotCommand.updateStock,
              message: "Done! Updated ${targetProduct.name} ($statusMsg).",
              payload: {"id": targetProduct.id},
            );
          }
        }
        return BotResponse(command: BotCommand.chat, message: "I couldn't find that item to update.");
      }

      // --- CASO 3: BUSCA DE PRODUTOS (SEARCH INTENT) ---
      // Se o usuário quiser procurar algo ("find milk", "where is apple")
      if (input.contains("find") || input.contains("is there") || input.contains("where") || input.contains("search")) {
        
        // Limpamos a frase para obter apenas o termo de busca
        String searchTerm = input
            .replaceAll(RegExp(r'(find|is there|where is|search|show|me|the|a|an|?)'), '')
            .trim();

        if (searchTerm.isEmpty) searchTerm = "%";

        final List<Product> foundItems = await db.searchProducts(searchTerm);

        if (foundItems.isNotEmpty) {
          return BotResponse(
            command: BotCommand.showProduct,
            message: "I found ${foundItems.length} item(s) in the feed:",
            products: foundItems,
          );
        }
      }

      // --- CASO 4: BUSCA DIRETA (NOME DO PRODUTO) ---
      // Se o usuário digitar apenas o nome (ex: "milk")
      final List<Product> quickSearch = await db.searchProducts(input);
      if (quickSearch.isNotEmpty) {
        return BotResponse(
          command: BotCommand.showProduct,
          message: "Found these items:",
          products: quickSearch,
        );
      }

      // --- CASO 5: FALLBACK (CONVERSA) ---
      return BotResponse(
        command: BotCommand.chat,
        message: "I'm here to help you manage your stock and find items in the feed. Try saying 'find milk' or 'add 10 apples'.",
      );

    } catch (e) {
      print("Bot Error: $e");
      return BotResponse(command: BotCommand.chat, message: "Error accessing the local database.");
    }
  }
}
