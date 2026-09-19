import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth; // Import para capturar erros específicos
import 'package:logiflow/services/firebase_service.dart';
import '../../models/user.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Função principal de Login
  Future<void> _login() async {
    // 1. Validação básica de campos vazios
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha todos os campos")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Tentativa de autenticação no Firebase Auth
      final credential = await firebaseService.auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Falha na autenticação: Usuário não encontrado.');
      }

      // 3. Busca o perfil completo no Firestore (Onde a maioria dos erros ocorre)
      final profile = await firebaseService.getUserProfile(firebaseUser.uid);

      // VERIFICAÇÃO CRÍTICA: O usuário existe no Auth mas não tem documento no Firestore?
      if (profile == null) {
        throw Exception('Usuário autenticado, mas perfil não encontrado no banco de dados. Entre em contato com o suporte.');
      }

      // 4. Mapeamento seguro dos dados para o seu modelo customizado 'User'
      final user = User(
        id: firebaseUser.uid,
        name: profile['name'] ?? 'Usuário',
        email: firebaseUser.email ?? _emailController.text.trim(),
        password: '', // Segurança: nunca carregue a senha no modelo de dados
        phone: profile['phone'] ?? '',
        address: profile['address'] ?? '',
        // Tratamento de tipo para is_seller (pode vir como bool ou int do Firestore)
        isSeller: profile['is_seller'] == true || profile['is_seller'] == 1,
      );

      // 5. Navegação segura (Verifica se o widget ainda está na tela)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: user),
          ),
        );
      }
    } on auth.FirebaseAuthException catch (e) {
      // 6. TRATAMENTO DE ERROS ESPECÍFICOS DO FIREBASE (Melhor UX)
      String errorMessage = "Erro ao fazer login";
      
      if (e.code == 'user-not-found') {
        errorMessage = "Usuário não encontrado.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Senha incorreta.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "O formato do e-mail é inválido.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "Este usuário foi desativado.";
      } else {
        errorMessage = e.message ?? "Erro de autenticação.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // 7. TRATAMENTO DE OUTROS ERROS (Rede, Firestore, etc)
      debugPrint("Erro detalhado no Login: $e"); // Log para o desenvolvedor
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 8. Finaliza o estado de loading independente de sucesso ou erro
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.eco, size: 100, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                "LogiFlow",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text(
                "AI-Driven Food Rescue",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // Campo de Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Campo de Senha
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // Botão de Login
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Login", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 16),
              
              // Link para Cadastro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text("Don't have an account? Create one"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
