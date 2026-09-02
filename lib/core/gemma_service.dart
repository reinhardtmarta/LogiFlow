import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/product.dart';
import '../models/user.dart';

enum SearchIntent { search, outOfContext, itemNotFound }

class IntentResult {
  final SearchIntent intent;
  final String query; // O termo de busca limpo
  final String message; // Resposta em caso de erro ou out of context

  IntentResult({required this.intent, this.query = '', this.message = ''});
}

class GemmaService {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _modelName = 'gemini-3.5-flash-lite';

  GenerativeModel? _model;

  GenerativeModel get model {
    if (_apiKey.isEmpty) throw Exception('API Key missing');
    _model ??= GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
      ),
    );
    return _model!;
  }

  Future<IntentResult> parseUserIntent({
    required String userInput,
    required UserSettings settings,
    required List<String> availableProducts,
  }) async {
    try {
      final response = await model.generateContent([
        Content.system('''
          Você é um assistente do LogiFlow. Responda apenas em JSON.
          Se a solicitação não for sobre alimentos ou desperdício, retorne:
          {"intent": "outOfContext", "message": "Sou um assistente de produtos do LogiFlow."}
          Caso queira buscar um item, retorne:
          {"intent": "search", "query": "${userInput.trim()}"}
        '''),
        Content.text(userInput),
      ]);

      final jsonResponse = jsonDecode(response.text ?? '{}');
      final intentString = jsonResponse['intent'];

      SearchIntent detectedIntent;
      if (intentString == 'itemNotFound') {
        detectedIntent = SearchIntent.itemNotFound;
      } else if (intentString == 'outOfContext') {
        detectedIntent = SearchIntent.outOfContext;
      } else {
        detectedIntent = SearchIntent.search;
      }

      return IntentResult(
        intent: detectedIntent,
        query: jsonResponse['query'] ?? userInput,
        message: jsonResponse['message'] ?? userInput,
      );
    } catch (_) {
      return IntentResult(intent: SearchIntent.outOfContext, message: 'Erro de processamento.');
    }
  }

  Future<String> processQuery(String query, [UserSettings? settings]) async {
    if (_apiKey.isEmpty) return query;

    try {
      final safeSettings = settings ?? UserSettings();
      final result = await parseUserIntent(
        userInput: query,
        settings: safeSettings,
        availableProducts: const [],
      );
      return result.query.isNotEmpty ? result.query : query;
    } catch (_) {
      return query;
    }
  }

  Future<String> getInsights({
    required List<Product> products,
    required UserSettings userSettings,
  }) async {
    if (products.isEmpty) return 'Ainda não há itens para analisar.';

    final preview = products.take(5).map((p) => '${p.name} (${p.quantity} unidades)').join('; ');
    return 'Resumo do feed: $preview';
  }
}
