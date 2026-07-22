import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

// 1. Definimos os comandos que o BOT pode disparar para o App
enum BotCommand {
  showProduct,   // Comando para renderizar um card de produto
  listProducts,  // Comando para listar uma categoria
  searchStock,   // Comando para busca de estoque
  help,          // Comando de ajuda
  chat           // Fallback para conversas simples
}

// 2. O objeto que o BOT retorna (Não é apenas texto, é uma instrução de sistema)
class BotResponse {
  final BotCommand command;
  final String message; // O que o bot diz para o usuário
  final Map<String, dynamic>? payload; // Os dados (id, valor, qtd) para o App usar

  BotResponse({
    required this.command,
    required this.message,
    this.payload,
  });
}

class LogiFlowBotService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static GenerativeModel? _model;
  static bool isInitialized = false;

  // A "Programação" do Bot: Aqui definimos que ele é um controlador de comandos, não um falador.
  static const String _botInstructions = """
  Você é o BOT OPERACIONAL do LogiFlow. Sua única função é converter pedidos de usuários em COMANDOS JSON.
  Você não deve conversar casualmente, a menos que o comando seja 'chat'.
  
  REGRAS DE OURO:
  1. Se o usuário quiser ver um item, use o comando 'showProduct'.
  2. Se o usuário quiser saber sobre estoque ou procurar algo, use 'searchStock'.
  3. Se o usuário perguntar sobre categorias, use 'listProducts'.
  4. Se o usuário for apenas educado ou perguntar algo fora do escopo, use 'chat'.

  FORMATO DE RESPOSTA OBRIGATÓRIO (JSON):
  {
    "command": "showProduct" | "listProducts" | "searchStock" | "help" | "chat",
    "message": "Frase curta e direta para o usuário",
    "payload": { 
       "id": "opcional",
       "query": "opcional",
       "category": "opcional"
    }
  }
  """;

  static Future<void> initialize() async {
    if (isInitialized) return;
    try {
      if (_apiKey.isEmpty) throw Exception('API Key não configurada.');

      _model = GenerativeModel(
        model: 'gemini-1.5-flash', // Flash é ideal para bots de comando (rápido e estruturado)
        apiKey: _apiKey,
        systemInstruction: Content.system(_botInstructions),
      );

      isInitialized = true;
      print("🤖 LogiFlow Bot Ready!");
    } catch (e) {
      print("❌ Bot Init Error: $e");
      rethrow;
    }
  }

  // O MÉTODO PRINCIPAL: O Bot interpreta e decide o que o App deve fazer
  static Future<BotResponse> execute(String userInput) async {
    if (!isInitialized || _model == null) {
      return BotResponse(command: BotCommand.chat, message: "Bot carregando...");
    }

    try {
      final response = await _model!.generateContent([Content.text(userInput)]);
      final String rawJson = response.text ?? '{}';
      
      // Limpeza para garantir que o JSON seja válido (remove markdown se a IA colocar)
      final String cleanJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> decoded = jsonDecode(cleanJson);

      // Mapeamento do comando string -> enum
      BotCommand command;
      switch (decoded['command']) {
        case 'showProduct': command = BotCommand.showProduct; break;
        case 'listProducts': command = BotCommand.listProducts; break;
        case 'searchStock': command = BotCommand.searchStock; break;
        case 'help': command = BotCommand.help; break;
        default: command = BotCommand.chat;
      }

      return BotResponse(
        command: command,
        message: decoded['message'] ?? '',
        payload: decoded['payload'],
      );
    } catch (e) {
      print("Bot Error: $e");
      return BotResponse(command: BotCommand.chat, message: "Erro ao processar comando.");
    }
  }
}
