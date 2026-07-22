import 'dart:convert';
import 'package:logiflow/core/database_helper.dart';
import 'package:logiflow/models/product.dart';

enum BotCommand {
  showProduct,
  listProducts,
  searchStock,
  updateStock,
  help,
  chat
}

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

  static Future<void> initialize() async {
    isInitialized = true;
    print("🤖 LogiFlow Local Bot Ready!");
  }

  static Future<BotResponse> execute(String userInput) async {
    if (!isInitialized) {
      return BotResponse(command: BotCommand.chat, message: "Bot is loading...");
    }

    final input = userInput.toLowerCase();
    final db = DatabaseHelper.instance;

    try {
      if (input.contains("help") || input.contains("how") || input.contains("command")) {
        return BotResponse(
          command: BotCommand.help,
          message: "Commands: 'find [item]', 'add [qty] [item]', 'set [item] to [status]', 'list all'.",
        );
      }

      if (input.contains("add") || input.contains("set") || input.contains("change") || input.contains("update")) {
        final numberRegex = RegExp(r'\d+');
        final numberMatch = numberRegex.firstMatch(input);
        final int? newQty = numberMatch != null ? int.parse(numberMatch.group(0)!) : null;

        String? newStatus;
        if (input.contains("cleaned") || input.contains("clean")) newStatus = "Cleaned";
        if (input.contains("packaged") || input.contains("pack")) newStatus = "Packaged";
        if (input.contains("new")) newStatus = "New";

        String cleanQuery = input
            .replaceAll(RegExp(r'\d+'), '')
            .replaceAll(RegExp(r'(add|set|change|update|to|units|qty|quantity|cleaned|packaged|new|apple|milk|avocado|bread|item|item|the)'), '')
            .trim();

        if (cleanQuery.isNotEmpty) {
          final products = await db.searchProducts(cleanQuery);
          if (products.isNotEmpty) {
            final targetProduct = products.first;
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

      final List<Product> quickSearch = await db.searchProducts(input);
      if (quickSearch.isNotEmpty) {
        return BotResponse(
          command: BotCommand.showProduct,
          message: "Found these items:",
          products: quickSearch,
        );
      }

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
