import 'package:logiflow/core/database_helper.dart';
import 'package:logiflow/models/product.dart';

// 1. Comandos que o App entende para mudar a interface
enum BotCommand {
  showProduct,   // Mostrar um card de produto
  listProducts,  // Listar todos os produtos
  searchStock,   // Buscar um item específico
  updateStock,   // COMANDO NOVO: Atualizar quantidade ou status
  help,          // Ajuda
  chat           // Conversa simples
}

// 2. O objeto que o BOT retorna
class BotResponse {
  final BotCommand command;
  final String message;
  final List<Product>? products;
  final Map<String, dynamic>? payload; // Usado para passar ID e novos valores

  BotResponse({
    required this.command,
    required this.message,
    this.products,
    this.payload,
  });
}

class LogiFlowBotService {
  static bool isInitialized = false;

  static Future<void> initialize() async {
    isInitialized = true;
    print("🤖 LogiFlow Local Bot Ready (Offline Mode)");
  }

  static Future<BotResponse> execute(String userInput) async {
    if (!isInitialized) {
      return BotResponse(command: BotCommand.chat, message: "Bot is loading...");
    }

    final input = userInput.toLowerCase();
    final db = DatabaseHelper.instance;

    try {
      // --- CASO 1: AJUDA ---
      if (input.contains("help") || input.contains("how") || input.contains("command")) {
        return BotResponse(
          command: BotCommand.help,
          message: "Commands: 'find [item]', 'add [qty] [item]', 'set [item] to [status]', 'list all'.",
        );
      }

      // --- CASO 2: ATUALIZAÇÃO DE ESTOQUE (Update Intent) ---
      // Detecta padrões como: "add 10 apples", "set milk to 5", "change apple to cleaned"
      if (input.contains("add") || input.contains("set") || input.contains("change") || input.contains("update")) {
        
        // Tenta extrair um número da frase (ex: "10")
        final numberRegex = RegExp(r'\d+');
        final numberMatch = numberRegex.firstMatch(input);
        final int? newQty = numberMatch != null ? int.parse(numberMatch.group(0)!) : null;

        // Tenta detectar status de limpeza/embalagem
        String? newStatus;
        if (input.contains("cleaned") || input.contains("clean")) newStatus = "Cleaned";
        if (input.contains("packaged") || input.contains("pack")) newStatus = "Packaged";
        if (input.contains("new")) newStatus = "New";

        // Tenta encontrar qual produto o usuário está falando (removendo palavras de comando)
        String cleanQuery = input
            .replaceAll(RegExp(r'\d+'), '') // remove números
            .replaceAll(RegExp(r'(add|set|change|update|to|units|qty|quantity|cleaned|packaged|new|apple|milk|avocado|bread|item|item|the)'), '')
            .trim();

        if (cleanQuery.isNotEmpty) {
          // Busca o produto no banco para pegar o ID real
          final products = await db.searchProducts(cleanQuery);
          
          if (products.isNotEmpty) {
            final targetProduct = products.first;
            
            // Executa a atualização no banco
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

      // --- CASO 3: BUSCA DE PRODUTOS (Search Intent) ---
      if (input.contains("find") || input.contains("is there") || input.contains("where") || input.contains("search")) {
        String searchTerm = input
            .replaceAll("find", "")
            .replaceAll("is there", "")
            .replaceAll("where is", "")
            .replaceAll("search", "")
            .replaceAll("?", "")
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

      // BUSCA PADRÃO: Se o usuário digitar apenas o nome (ex: "milk")
      final List<Product> quickSearch = await db.searchProducts(input);
      if (quickSearch.isNotEmpty) {
        return BotResponse(
          command: BotCommand.showProduct,
          message: "Found these items:",
          products: quickSearch,
        );
      }

      // CASO 4: Fallback para conversa
      return BotResponse(
        command: BotCommand.chat,
        message: "I'm here to help you manage your stock and find items in the feed. Try saying 'find milk' or 'add 10 apples'.",
      );

    } catch (e) {
      print("Bot Error: $e");
      return BotResponse(command: BotCommand.chat, message: "Error accessing the database.");
    }
  }
}
