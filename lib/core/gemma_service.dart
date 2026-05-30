import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GemmaService {
  static final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static late GenerativeModel _model;
  static bool isInitialized = false;

  /// Initialize Gemma 4 using Google Generative AI
  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      if (_apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY environment variable not set');
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash', // Efficient model for mobile
        apiKey: _apiKey,
      );

      isInitialized = true;
      print("✅ Gemma 4 (Gemini) loaded successfully!");
    } catch (e) {
      print("❌ Error initializing Gemma: $e");
      rethrow;
    }
  }

  /// Send message to Gemma 4 (with optional image support)
  static Future<String> generateResponse(
    String prompt, {
    String? imagePath, // For multimodal (photo of product)
  }) async {
    if (!isInitialized) {
      return "Gemma is still loading. Please wait a moment...";
    }

    try {
      final content = <Content>[];

      // Add text prompt
      content.add(Content.text(prompt));

      // Add image if provided
      if (imagePath != null && await File(imagePath).exists()) {
        final imageBytes = await File(imagePath).readAsBytes();
        content.add(
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ]),
        );
      }

      final response = await _model.generateContent(content);

      return response.text?.trim() ?? "No response generated";
    } catch (e) {
      return "Sorry, I couldn't generate a response right now. Error: $e";
    }
  }

  static Future<void> dispose() async {
    // Cleanup if needed
    isInitialized = false;
  }
}
