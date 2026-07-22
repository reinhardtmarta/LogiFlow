import 'package:logiflow/core/database_helper.dart';
import 'package:logiflow/models/product.dart';

// 1. Commands that the App interprets to change the UI
enum BotCommand {
  showProduct,   // Command to render a product card
  listProducts,  // Command to list a category
  searchStock,   // Command to search inventory
  updateStock,
  help,          // Command for assistance
  chat           // Fallback for simple text
}

// 2. The object returned by the BOT (Structured data, not just text)
class BotResponse {
  final BotCommand command;
  final String message; // What the bot says to the user
  final List<Product>? products; // The actual products found in the DB

  BotResponse({
    required this.command,
    required this.message,
    this.products,
  });
}

class LogiFlowBotService {
  static bool isInitialized = false;

  // Instant initialization (No API needed, works offline)
  static Future<void> initialize() async {
    isInitialized = true;
    print("🤖 LogiFlow Local Bot Ready (Offline Mode)");
  }

  // MAIN METHOD: The "Brain" that interprets user intent via keyword matching
  static Future<BotResponse> execute(String userInput) async {
    if (!isInitialized) {
      return BotResponse(command: BotCommand.chat, message: "Bot is loading...");
    }

    final input = userInput.toLowerCase();
    final db = DatabaseHelper.instance;

    try {
      // CASE 1: User wants help
      if (input.contains("help") || input.contains("how") || input.contains("command")) {
        return BotResponse(
          command: BotCommand.help,
          message: "You can ask about products (e.g., 'is there milk?') or ask to list items.",
        );
      }

      // CASE 2: User is looking for a specific item (Search Intent)
      // We assume if they type a word, they want to search that term in the DB
      final List<Product> foundProducts = await db.searchProducts(input); 

      if (foundProducts.isNotEmpty) {
        // If items were found, trigger the 'showProduct' command
        return BotResponse(
          command: BotCommand.showProduct,
          message: "I found ${foundProducts.length} item(s) for you:",
          products: foundProducts,
        );
      }

      // CASE 3: If nothing was found in the database
      return BotResponse(
        command: BotCommand.chat,
        message: "Sorry, I couldn't find anything matching that name in our local stock.",
      );

    } catch (e) {
      print("Bot Error: $e");
      return BotResponse(
        command: BotCommand.chat, 
        message: "Error while accessing the local database."
      );
    }
  }
}
