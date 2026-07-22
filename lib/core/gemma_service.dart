import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

enum BotCommand { 
  showProduct, 
  listProducts, 
  updateStock, 
  help, 
  chat, 
  error 
}

class BotResponse {
  final BotCommand command;
  final String message;
  final Map<String, dynamic>? payload;

  BotResponse({
    required this.command, 
    required this.message, 
    this.payload,
  });
}

class LogiFlowGemmaService {
  static const String _apiKey = 'GEMINI_API_KEY';
  static const String _modelName = 'gemma-4-26b-a4b';

  late GenerativeModel _model;

  LogiFlowGemmaService() {
    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.0,
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system('''
You are a technical inventory search agent.
REQUIRED CONTEXT: This application is strictly a BRIDGE between sellers. You are NOT a store.
OPERATING RULES:
1. Exclusive Focus: Respond ONLY to the existence and location of products.
2. Sales Prohibition: NEVER make sales, NEVER quote final prices, and NEVER offer discounts.
3. Privacy: NEVER Answer questions about users, customers, or personal data. If prompted, refuse.
4. Size: The "message" field must have a maximum of 15 words. State only the facts.
5. Format: Generate ONLY one valid JSON object.

JSON STRUCTURE:
{
"command": "<showProduct, listProducts, updateStock, help, chat>",
"message": "<your short answer of up to 15 words>",
"payload": {"query": "<technical name or id of the extracted product>"}
}
'''),
    );
  }

  Future<BotResponse> processQuery(String input) async {
    try {
      final content = [Content.text(input)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return BotResponse(
          command: BotCommand.error, 
          message: 'Failure: No information received from the model.',
        );
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.text!);
      final commandString = jsonResponse['command'] as String?;

      final command = BotCommand.values.firstWhere(
        (e) => e.name == commandString,
        orElse: () => BotCommand.chat,
      );

      return BotResponse(
        command: command,
        message: jsonResponse['message'] ?? 'Search processed.',
        payload: jsonResponse['payload'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return BotResponse(
        command: BotCommand.error,
        message: 'Data processing failure (structural error).',
      );
    }
  }
} // Chave final adicionada aqui
