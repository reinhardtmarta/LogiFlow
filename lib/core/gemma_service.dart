import 'dart:convert';
 import 'package:logiflow/core/database_helper.dart';
 import 'package:logiflow/models/product.dart';

 enum BotCommand {
   showProduct,
   listProducts,
   searchStock,
   updateStock,
   help,
   chat,
 }

 class BotResponse {
   final BotCommand command;
   final String message;
   final List<Product>?  products;
   final Map<String, dynamic>?  payload;

   BotResponse({
     requiredthis.command,
     requiredthis.message,
     this.products,
     this.payload,
   });
 }

 class GemmaService {
   static bool isInitialized = false;

   static Future<void> initialize() async {
     isInitialized = true;
     print("🤖 Gemma Service (LogiFlow Bot) Ready!");
   }

   static Future<BotResponse> execute(String userInput) async {
     if (!isInitialized) {
       return BotResponse(
         command: BotCommand.chat,
         message: "Bot is loading...",
       );
     }

     final input = userInput.toLowerCase().trim();
     final db = DatabaseHelper.instance;

     try {
       // ==================== HELP ====================
       if (input.contains("help") || 
           input.contains("help") || 
           input.contains("how") || 
           input.contains("command")) {
         return BotResponse(
           command: BotCommand.help,
           message: "Available commands:\n"
               "• 'find milk' or 'do you have milk?'\n"
               "• 'add 10 apples' or 'add 5 bread'\n"
               "• 'update milk to 20' or 'set 15 avocado'\n"
               "• 'list' or 'show all'",
         );
       }

       // ==================== UPDATE STOCK ====================
       if (RegExp(r'(add|add|set|change|update|change|put)').hasMatch(input)) {
         final numberRegex = RegExp(r'\d+');
         final match = numberRegex.firstMatch(input);
         final int?  quantity = match != null ?  int.tryParse(match.group(0)!) : null;

        String? newCondition;
        if (input.contains("limpo") || input.contains("clean")) newCondition = "Cleaned";
        if (input.contains("embalado") || input.contains("pack")) newCondition = "Packaged";
        if (input.contains("novo") || input.contains("new")) newCondition = "New";

        // Extract product name by removing commands and numbers
        String productName = input
            .replaceAll(RegExp(r'(adicionar|add|set|alterar|atualizar|mudar|colocar|para|unidades|qty|quantity|limpo|clean|embalado|pack|novo|new|\d+)'), '')
            .trim();

        if (productName.isNotEmpty) {
          final products = await db.searchProducts(productName);
          
          if (products.isNotEmpty) {
            final target = products.first;
            await db.updateProduct(
              target.id,
              qty: quantity,
              condition: newCondition,
            );

            final String status = [
              if (quantity != null) "$quantity units",
              if (newCondition != null) "status: $newCondition",
            ].join(" and ");

            return BotResponse(
              command: BotCommand.updateStock,
              message: "✅ Updated! ${target.name} ${status.isNotEmpty ? '($status)' : ''}.",
              payload: {"id": target.id},
            );
          }
        }
        return BotResponse(
          command: BotCommand.chat,
          message: "I couldn't identify the item to update.",
        );
      }

      // ==================== SEARCH / FIND ====================
      if (RegExp(r'(encontrar|tem|onde|buscar|listar|mostrar|find|search)').hasMatch(input)) {
        String searchTerm = input
            .replaceAll(RegExp(r'(encontrar|tem|onde está|buscar|listar|mostrar|find|search|me|o|a|os|as|de|do|da)'), '')
            .trim();

        if (searchTerm.isEmpty) searchTerm = "%";  final List<Product> found = await db.searchProducts(searchTerm);

        if (found.isNotEmpty) {
          return BotResponse(
            command: BotCommand.showProduct,
            message: "I found ${found.length} item(s):",
            products: found,
          );
        }
      }

      // ==================== QUICK SEARCH (fallback) ====================
      final List<Product> quickSearch = await db.searchProducts(input);
      if (quickSearch.isNotEmpty) {
        return BotResponse(
          command: BotCommand.showProduct,
          message: "Results for '$userInput':",
          products: quickSearch,
        );
      }

      // ==================== DEFAULT ====================
      return BotResponse(
        command: BotCommand.chat,
        message: "I didn't quite understand that 😕\n"
            "Try: 'find milk', 'add 10 apples', or 'help'.",
      );

    } catch (e) {
      print("❌ Gemma Bot Error: $e");
      return BotResponse(
        command: BotCommand.chat,
        message: "An error occurred while accessing the database.",
      );
    }
  }
 }
