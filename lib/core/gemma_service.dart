import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GemmaService {
  static FlutterGemma? _gemma;
  static bool isInitialized = false;

  static Future<void> initialize() async {
    if (isInitialized) return;

    _gemma = FlutterGemma.instance;

    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/models/gemma-4-E2B-it.litertlm';

    final modelDir = Directory('${dir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    // Baixa o modelo (Gemma 4 E2B - leve e bom para celular)
    if (!await File(modelPath).exists()) {
      await _gemma!.downloadModel(
        ModelFile(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromNetwork(
          'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
        ),
        onProgress: (progress) {
          print("Download: ${(progress * 100).toStringAsFixed(0)}%");
        },
      );
    }

    await _gemma!.loadModel(modelPath);
    isInitialized = true;
    print("✅ Gemma 4 inicializada com sucesso!");
  }

  static Future<String> sendMessage(String prompt, {String? imagePath}) async {
    if (!isInitialized || _gemma == null) {
      return "Gemma ainda está carregando...";
    }

    try {
      final response = await _gemma!.generate(
        prompt,
        imagePath: imagePath,        // Suporte multimodal
        maxTokens: 1024,
        temperature: 0.7,
      );
      return response.text;
    } catch (e) {
      return "Erro: $e";
    }
  }

  static Future<void> dispose() async {
    await _gemma?.dispose();
  }
}
