import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GemmaService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static GenerativeModel? _model;
  static bool isInitialized = false;

  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      if (_apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY não configurada.');
      }

      // Configuração explícita para o modelo Gemma 4 26B A4B Instruction-Tuned
      _model = GenerativeModel(
        model: 'gemma-4-26b-a4b-it', 
        apiKey: _apiKey,
      );

      isInitialized = true;
      print("✅ conected!");
    } catch (e) {
      print("❌ Error");
      rethrow;
    }
  }

  static Future<String> generateResponse(String prompt, {String? imagePath}) async {
    if (!isInitialized || _model == null) {
      return "Gemma 4 ainda está a carregar...";
    }

    try {
      final List<Content> content = [];

      // Processamento Multimodal (Imagem + Texto)
      if (imagePath != null && await File(imagePath).exists()) {
        final imageBytes = await File(imagePath).readAsBytes();
        
        content.add(Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]));
      } else {
        content.add(Content.text(prompt));
      }

      final response = await _model!.generateContent(content);
      return response.text ?? "Sem resposta";
    } catch (e) {
      return "Erro ao gerar resposta: $e";
    }
  }

  static Future<void> dispose() async {
    _model = null;
    isInitialized = false;
  }
}
