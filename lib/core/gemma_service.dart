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

class GemmaService {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  // Segurança: Nunca hardcodar chaves. Usa String.fromEnvironment para injetar via --dart-define
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _modelName = 'gemini-1.5-flash'; 

  GenerativeModel? _model;

  GenerativeModel get model {
    if (_apiKey.isEmpty || _apiKey == 'GEMINI_API_KEY') {
      throw Exception('GEMINI_API_KEY not configured. Use --dart-define=GEMINI_API_KEY=your_key');
    }
    _model ??= GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        responseMimeType: 'application/json',
      ),
    );
    return _model!;
  }

  Future<String?> perguntarGemma(String query) async {
    try {
      final response = await processQuery(query);
      return response.message;
    } catch (e) {
      return "Erro ao processar consulta: ${e.toString()}";
    }
  }

  Future<BotResponse> processQuery(String input) async {
    if (_apiKey.isEmpty || _apiKey == 'GEMINI_API_KEY') {
      return BotResponse(
        command: BotCommand.error,
        message: 'API Key not configured. Please use --dart-define=GEMINI_API_KEY=...',
      );
    }

    try {
      final content = [Content.text(input)];
      final response = await model.generateContent(content);

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
        message: 'Data processing failure: ${e.toString()}',
      );
    }
  }
}
