import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
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
  static const String _modelName = 'gemini-1.5-flash'; 

  GenerativeModel? _model;

  GenerativeModel get model {
    if (_apiKey.isEmpty) throw Exception('API Key missing');
    _model ??= GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Temperatura baixíssima para evitar "alucinações"
        responseMimeType: 'application/json',
      ),
    );
    return _model!;
  }

  /// O MÉTODO PRINCIPAL: Traduz o que o usuário digitou em uma intenção de busca
  Future<IntentResult> parseUserIntent({
    required String userInput,
    required UserSettings settings,
    required List<String> availableProducts, // Enviamos os nomes para ela saber o que existe
  }) async {
    
    // O PROMPT DE SISTEMA (A regra de ouro do seu app)
    final systemInstruction = '''
      Você é o motor de busca semântica do LogiFlow. 
      Sua função é converter o texto do usuário em um comando de busca estruturado.

      CONFIGURAÇÕES DO USUÁRIO:
      - Idioma de resposta: ${settings.language}
      - Interesses do usuário: ${settings.interests.join(', ')}

      PRODUTOS DISPONÍVEIS NO FEED:
      [${availableProducts.join(', ')}]

      REGRAS DE RESPOSTA (Responda APENAS em JSON):
      1. Se o usuário pedir algo que NÃO está na lista de produtos disponíveis, retorne:
         {"intent": "itemNotFound", "message": "Item não encontrado"}
      
      2. Se o usuário perguntar algo que não tem relação com comida, produtos ou LogiFlow (ex: clima, política, piadas), retorne:
         {"intent": "outOfContext", "message": "Sou apenas um filtro para encontrar produtos no LogiFlow."}

      3. Se o usuário quiser buscar algo que EXISTE na lista, retorne:
         {"intent": "search", "query": "termo de busca limpo"}

      REGRAS DE IDIOMA:
      - A chave "message" deve estar sempre em ${settings.language}.
    ''';

    try {
      final response = await model.generateContent([
        Content.system(systemInstruction),
        Content.text(userInput),
      ]);

      final jsonResponse = jsonDecode(response.text!);

      final intentString = jsonResponse['intent'];
      
      // Mapeamento da intenção
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
        query: jsonResponse['query'] ?? '',
        message: jsonResponse['message'] ?? '',
      );
    } catch (e) {
      return IntentResult(intent: SearchIntent.outOfContext, message: "Erro de processamento.");
    }
  }

  /// Processa uma query de busca usando o AI
  Future<String> processQuery(String query, UserSettings settings) async {
    try {
      final result = await parseUserIntent(
        userInput: query,
        settings: settings,
        availableProducts: [],
      );
      return result.query.isNotEmpty ? result.query : query;
    } catch (e) {
      return query;
    }
  }
}
