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

  // Inicialização agora é apenas um sinalizador de que o Bot está pronto
  static Future<void> initialize() async {
    isInitialized = true;
    print("🤖 LogiFlow Local Bot Ready (Offline Mode - No API)");
  }

  // O MÉTODO PRINCIPAL: O "Cérebro" baseado em padrões de texto (Regex)
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
      // Detecta: "add 10 apples", "set milk to 5", "change apple to cleaned"
      if (input.contains("add") || input.contains("set") || input.contains("change") || input.contains("update")) {
        
        // 1. Extrair número (quantidade)
        final numberRegex = RegExp(r'\d+');
        final numberMatch = numberRegex.firstMatch(input);
        final int? newQty = numberMatch != null ? int.parse(numberMatch.group(0)!) : null;

        // 2. Detectar status
        String? newStatus;
        if (input.contains("cleaned") || input.contains("clean")) newStatus = "Cleaned";
        if (input.contains("packaged") || input.contains("pack")) newStatus = "Packaged";
        if (input.contains("new")) newStatus = "New";

        // 3. Limpar a frase para pegar o NOME do produto
        // Remove comandos, números e status para sobrar apenas o nome do item
        String cleanQuery = input
            .replaceAll(RegExp(r'\d+'), '') 
            .replaceAll(RegExp(r'(add|set|change|update|to|units|qty|quantity|cleaned|packaged|new|item|the|is|at|at|to)'), '')
            .trim();

        if (cleanQuery.isNotEmpty) {
          final products = await db.searchProducts(cleanQuery);
          
          if (products.isNotEmpty) {
            final targetProduct = products.first;
            
            // Atualiza o banco de dados real
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
      if (input.contains("find") || input.contains("is there") || input.contains("where") || input.contains("search")) {
        
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

      // --- CASO 4: BUSCA DIRETA (Caso o usuário digite apenas o nome) ---
      final List<Product> quickSearch = await db.searchProducts(input);
      if (quickSearch.isNotEmpty) {
        return BotResponse(
          command: BotCommand.showProduct,
          message: "Found these items:",
          products: quickSearch,
        );
      }

      // --- CASO 5: CONVERSA (CHAT FALLBACK) ---
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
