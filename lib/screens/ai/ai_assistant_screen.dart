import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class GemmaService {
  static const String _apiKey = String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static bool isInitialized = false;

  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      if (_apiKey.isEmpty) {
        throw Exception('OPENROUTER_API_KEY not set');
      }

      // Testa conexão
      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        isInitialized = true;
        print("✅ OpenRouter + Gemma 4 conectado!");
      } else {
        throw Exception('Falha na conexão: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Erro: $e");
      rethrow;
    }
  }

  static Future<String> generateResponse(String prompt, {String? imagePath}) async {
    if (!isInitialized) return "Gemma 4 ainda está a carregar...";

    try {
      List<Map<String, dynamic>> messages = [];

      // Adiciona imagem se existir
      if (imagePath != null && await File(imagePath).exists()) {
        final imageBytes = await File(imagePath).readAsBytes();
        final base64Image = base64Encode(imageBytes);
        messages.add({
          "role": "user",
          "content": [
            {"type": "text", "text": prompt},
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
            }
          ]
        });
      } else {
        messages.add({"role": "user", "content": prompt});
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://github.com/reinhardtmarta/LogiFlow',
          'X-Title': 'LogiFlow',
        },
        body: jsonEncode({
          "model": "google/gemma-4-31b-it:free",
          "messages": messages,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['choices'][0]['message']['content']?.trim() ?? "Sem resposta";
      } else {
        return "Erro ${response.statusCode}: ${data['error']?['message'] ?? 'Desconhecido'}";
      }
    } catch (e) {
      return "Erro ao gerar resposta: $e";
    }
  }

  static Future<void> dispose() async {
    isInitialized = false;
  }
}
