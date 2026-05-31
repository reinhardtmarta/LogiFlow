import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

class GemmaService {
  static final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static late GenerativeModel _model;
  static bool isInitialized = false;

  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      if (_apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY environment variable not set');
      }

      _model = GenerativeModel(
        model: 'gemma-4-26b-a4b-it',
        apiKey: _apiKey,
      );

      isInitialized = true;
      print("✅ Gemma 4 loaded successfully!");
    } catch (e) {
      print("❌ Error initializing Gemma 4: $e");
      rethrow;
    }
  }

  static Future<String> generateResponse(String prompt, {String? imagePath}) async {
    if (!isInitialized) return "Gemma 4 is still loading. Please wait...";

    try {
      final content = <Content>[];

      if (imagePath != null && await File(imagePath).exists()) {
        final imageBytes = await File(imagePath).readAsBytes();
        content.add(Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]));
      } else {
        content.add(Content.text(prompt));
      }

      final response = await _model.generateContent(content);
      return response.text?.trim() ?? "No response generated";
    } catch (e) {
      return "Sorry, I couldn't generate a response right now. Error: $e";
    }
  }

  static Future<void> dispose() async {
    isInitialized = false;
  }
}
