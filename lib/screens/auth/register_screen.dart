import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth; // Import para erros específicos
import 'package:logiflow/services/firebase_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSeller = false;
  bool _isLoading = false;

  // Limpeza de memória para evitar vazamento (Memory Leak)
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // 1. Validação de campos obrigatórios
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar("Por favor, preencha todos os campos obrigatórios", Colors.orange);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar("A senha deve ter pelo menos 6 caracteres", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    auth.UserCredential? userCredential;

    try {
      // 2. Passo 1: Registra no Firebase Authentication
      userCredential = await firebaseService.auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        try {
          // 3. Passo 2: Salva no Firestore
          await firebaseService.saveUserData(user.uid, {
            'uid': user.uid,
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'is_seller': _isSeller,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });

          // Sucesso Total
          if (mounted) {
            _showSnackBar("Conta criada com sucesso! Faça o login.", Colors.green);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } catch (firestoreError) {
          // 4. ROLLBACK: Se o Firestore falhar, deletamos o usuário do Auth 
          // para que ele possa tentar se registrar novamente sem erro de "e-mail em uso"
          debugPrint("Erro ao salvar no Firestore: $firestoreError");
          await user.delete();
          throw Exception("Erro ao salvar perfil. Tente novamente.");
        }
      }
    } on auth.FirebaseAuthException catch (e) {
      // 5. TRATAMENTO DE ERROS ESPECÍFICOS DO FIREBASE
      String errorMessage = "Ocorreu um erro durante o registro.";
      
      if (e.code == 'email-already-in-use') {
        errorMessage = "Este e-mail já está sendo usado.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "O formato do e-mail é inválido.";
      } else if (e.code == 'weak-password') {
        errorMessage = "A senha é muito fraca.";
      } else {
        errorMessage = e.message ?? errorMessage;
      }

      if (mounted) _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      // 6. OUTROS ERROS (Conexão, etc)
      debugPrint("Erro de Registro: $e");
      if (mounted) {
        _showSnackBar("Erro inesperado. Verifique sua conexão.", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper para facilitar o uso de SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Conta"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Junte-se ao LogiFlow",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text("Ajude a reduzir o desperdício de alimentos"),
            const SizedBox(height: 30),

            _buildTextField(_nameController, "Nome Completo *", Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_emailController, "E-mail *", Icons.email, TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, "Senha *", Icons.lock, TextInputType.visiblePassword, isObscure: true),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, "Telefone", Icons.phone),
            const SizedBox(height: 16),
            _buildTextField(_addressController, "Endereço / Localização", Icons.location_on, TextInputType.multiline, maxLines: 2),
            
            const SizedBox(height: 20),

            // Switch para Seller/Producer
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text("Sou Vendedor / Produtor", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Quero vender ou doar produtos"),
                value: _isSeller,
                activeColor: Colors.green,
                onChanged: (value) => setState(() => _isSeller = value),
              ),
            ),

            const SizedBox(height: 30),

            // Botão de Registro
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Criar Conta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Já tem uma conta? Faça Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir campos de texto de forma padronizada
  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    TextInputType type, 
    {bool isObscure = false, int maxLines = 1}
  ) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      ),
    );
  }
}
