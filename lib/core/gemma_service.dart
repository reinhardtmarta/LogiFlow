import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GemmaService {
  // A chave deve ser passada via --dart-define=GEMINI_API_KEY=SUA_CHAVE
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  static GenerativeModel? _model;
  static bool isInitialized = false;

  /// Inicializa o modelo Gemma 4 com a configuração necessária.
  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      if (_apiKey.isEmpty) {
        throw Exception('A chave GEMINI_API_KEY não foi encontrada. Verifique o comando de execução.');
      }

      // Instancia o modelo com o ID exato que você forneceu
      _model = GenerativeModel(
        model: 'gemma-4-26b-a4b-it', 
        apiKey: _apiKey,
      );

      isInitialized = true;
      print("✅ Gemma Service: Modelo Gemma 4 26B inicializado!");
    } catch (e) {
      isInitialized = false;
      print("❌ Gemma Service: Erro ao inicializar: $e");
      rethrow;
    }
  }

  /// Gera uma resposta baseada em texto e/ou imagem.
  /// [prompt] - O texto da pergunta do usuário.
  /// [imagePath] - O caminho do arquivo de imagem (opcional).
  static Future<String> generateResponse(String prompt, {String? imagePath}) async {
    // Verifica se o serviço está pronto
    if (!isInitialized || _model == null) {
      return "Erro: O serviço Gemma não foi inicializado.";
    }

    try {
      // Criamos a lista de partes (parts) para a mensagem
      final List<Part> promptParts = [TextPart(prompt)];

      // Se houver uma imagem, lemos os bytes e adicionamos como DataPart
      if (imagePath != null && await File(imagePath).exists()) {
        final imageBytes = await File(imagePath).readAsBytes();
        // O Google AI SDK lida com o multipart via DataPart
        promptParts.add(DataPart('image/jpeg', imageBytes));
      }

      // Montamos o conteúdo (Content)
      final content = Content.multi(promptParts);

      // Enviamos para o modelo
      // Nota: generateContent recebe uma lista de 'Content' (para conversas/histórico)
      // Como estamos enviando apenas uma pergunta isolada, passamos uma lista com 1 item.
      final response = await _model!.generateContent([content]);

      return response.text ?? "O modelo retornou uma resposta vazia.";
    } catch (e) {
      print("❌ Gemma Service: Erro na geração: $e");
      return "Erro ao gerar resposta: $e";
    }
  }

  /// Limpa o modelo da memória quando não for mais necessário.
  static void dispose() {
    _model = null;
    isInitialized = false;
    print("🧹 Gemma Service: Serviço resetado.");
  }
}
