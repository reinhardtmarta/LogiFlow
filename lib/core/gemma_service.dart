import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

// 1. Commands mapped to the application flow
enum BotCommand { 
showProduct, 
listProducts, 
updateStock, 
help, 
chat, 
error 
}

// 2. Standardized response structure
class BotResponse {
final BotCommand command;

final String message;

final Map<String, dynamic>? payload;

BotResponse({
required this.command, 
required this.message, 
this.payload

});

}

// 3. Gemma Main Service
class LogiFkGemmaService {
static const String _apiKey = 'GEMINI_API_KEY';

 static const String _modelName = 'gemma-4-26b-a4b';

   late GenerativeModel _model;

   GemmaService() {

_model = GenerativeModel(
model: _modelName,
apiKey: _apiKey,

// Configuration to force predictable responses in JSON format
generationConfig: GenerationConfig(
temperature: 0.0, // Absolute zero to avoid creative or invented responses
responseMimeType: 'application/json',

),

// System Instructions (Business Rules)

systemInstruction: Content.system('''

You are a technical inventory search agent.

REQUIRED CONTEXT: 
This application is strictly a BRIDGE between sellers. 
You are NOT a store.

OPERATING RULES:

1. Exclusive Focus: Respond ONLY to the existence and location of products.

2. Sales Prohibition: NEVER make sales, NEVER quote final prices, and NEVER offer discounts.

3. Privacy: NEVER  Answer questions about users, customers, or personal data. If prompted, refuse.

4. Size: The "message" field must have a maximum of 15 words. State only the facts.

5. Format: Generate ONLY one valid JSON object.

JSON STRUCTURE:

{
"command": "<showProduct, listProducts, updateStock, help, chat>",

"message": "<your short answer of up to 15 words>",

"payload": {"query": "<technical name or id of the extracted product>"}

}
'''),

);

}

// 4. Function that sends the message and processes the return

Future<BotResponse> processQuery(String input) async {

try {

final content = [Content.text(input)];

final response = await _model.generateContent(content);

 // Security validation: if empty

if (response.text == null || response.text!.isEmpty) {

return BotResponse(
command: BotCommand.error, 
message: 'Failure: No information received from the model.'

);

}

// Converts the raw JSON text into a data map (Map)
final Map<String, dynamic> jsonResponse = jsonDecode(response.text!);

// Maps the string command to the BotCommand Enum
final commandString = jsonResponse['command'] as String?;

final command = BotCommand.values.firstWhere(

(e) => e.name == commandString,

orElse: () => BotCommand.chat, // Default if not recognized

);

 // Returns the cleaned object for your user interface to read

return BotResponse(
command: command,

message: jsonResponse['message'] ?? 'Search processed.',

payload: jsonResponse['payload'] as Map<String, dynamic>?,

);

} catch (e) {

// If the AI misinterprets the format or there is a network error, the app doesn't break

return BotResponse(
command: BotCommand.error,

message: 'Data processing failure (structural error).',

);

}

}

  
