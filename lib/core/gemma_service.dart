import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GemmaService {
  // Certifique-se de passar esta chave via --dart-define no terminal
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static GenerativeModel? _model;
  static bool isInitialized = false;

  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      if (_apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY não configurada.');
      }

      // ATENÇÃO: Verifique se este ID de modelo está correto no seu Google AI Studio
      _model = GenerativeModel(
        model: 'gemma-4-26b-a4b-it', 
        apiKey: _apiKey,
      );

      isInitialized = true;
      print("✅ Google AI Studio + Gemma 4 conectado!");
    } catch (e) {
      print("❌ Erro de inicialização: $e");
      isInitialized = false;
      rethrow;
    }
  }

  static Future<String> generateResponse(String prompt, {String? imagePath}) async {
    if (!isInitialized || _model == null) {
      return "Gemma 4 ainda está a carregar...";
    }

    try {
      // Criamos o conteúdo da mensagem (o "turn" de conversa)
      final Content content;

      if (imagePath != null && await File(imagePath).exists()) {
        final imageBytes = await File(imagePath).readAsBytes();
        
        // Para multimodal, usamos Content.multi
        content = Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes), // Se a imagem puder ser PNG, considere tratar o MIME type
        ]);
      } else {
        // Para apenas texto, usamos Content.text
        content = Content.text(prompt);
      }

      // O método generateContent espera uma lista de conteúdos (histórico)
      // Como é uma pergunta única, passamos uma lista contendo apenas o 'content' atual
      final response = await _model!.generateContent([content]);
      
      return response.text ?? "Sem resposta";
    } catch (e) {
      print("❌ Erro no generateResponse: $e");
      return "Erro ao gerar resposta: $e";
    }
  }

  static Future<void> dispose() async {
    _model = null;
    isInitialized = false;
  }
}
