import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GemmaService {
  static FlutterGemma? _gemma;
  static bool isInitialized = false;

  /// Initialize Gemma 4 (E2B - efficient version for mobile)
  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      _gemma = FlutterGemma.instance;

      final dir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${dir.path}/models');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final modelPath = '${dir.path}/models/gemma-4-E2B-it.litertlm';

      // Download model if not exists (only once)
      if (!await File(modelPath).exists()) {
        print("Downloading Gemma 4 model... (this may take a while)");

        await _gemma!.downloadModel(
          ModelFile(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          ).fromNetwork(
            'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
          ),
          onProgress: (progress) {
            print("Download progress: ${(progress * 100).toStringAsFixed(1)}%");
          },
        );
      }

      await _gemma!.loadModel(modelPath);

      isInitialized = true;
      print("✅ Gemma 4 loaded successfully!");
    } catch (e) {
      print("❌ Error initializing Gemma: $e");
    }
  }

  /// Send message to Gemma 4 (with optional image support)
  static Future<String> generateResponse(
    String prompt, {
    String? imagePath, // For multimodal (photo of product)
  }) async {
    if (!isInitialized || _gemma == null) {
      return "Gemma is still loading. Please wait a moment...";
    }

    try {
      final response = await _gemma!.generate(
        prompt,
        imagePath: imagePath,
        maxTokens: 800,
        temperature: 0.75,
      );

      return response.text.trim();
    } catch (e) {
      return "Sorry, I couldn't generate a response right now. Error: $e";
    }
  }

  static Future<void> dispose() async {
    await _gemma?.dispose();
  }
}
