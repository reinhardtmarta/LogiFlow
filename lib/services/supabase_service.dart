import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  /// Faz o registro de um usuário.
  /// Retorna a resposta do Supabase (tipo depende da versão do pacote).
  Future<dynamic> signUp(String email, String password, String nome) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nome': nome},
    );
    return response;
  }

  /// Faz login com email e senha.
  Future<dynamic> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Salva ou atualiza dados do usuário na tabela 'profiles'.
  Future<void> saveUserData(Map<String, dynamic> data) async {
    await _client.from('profiles').upsert(data);
  }
}

// Instância única exportada para uso simples em widgets/serviços.
final supabaseService = SupabaseService();
