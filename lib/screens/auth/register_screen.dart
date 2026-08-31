import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    // Limpeza de memória para evitar vazamento (Memory Leak)
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // 1. Validação de campos obrigatórios no lado do cliente
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar("Please fill all required fields", Colors.orange);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar("Password must be at least 6 characters", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Chamada ÚNICA ao serviço centralizado. 
      // O FirebaseService agora cuida do Auth + Firestore + Rollback de segurança.
      await firebaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        isSeller: _isSeller,
      );

      // 3. Sucesso
      if (mounted) {
        _showSnackBar("Account created successfully! Please login.", Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // 4. Tratamento de erros (Ex: E-mail já em uso, erro de rede, etc)
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
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
        title: const Text("Create Account"),
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
              "Join LogiFlow",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text("Help reduce food waste together"),
            const SizedBox(height: 30),

            _buildTextField(_nameController, "Full Name *", Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_emailController, "Email Address *", Icons.email, TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, "Create Password *", Icons.lock, TextInputType.visiblePassword, isObscure: true),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, "Phone Number", Icons.phone),
            const SizedBox(height: 16),
            _buildTextField(_addressController, "Address / Location", Icons.location_on, TextInputType.multiline, maxLines: 2),
            const SizedBox(height: 20),

            // Switch para Seller/Producer
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text("I am a Seller / Producer", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("I want to sell or donate products"),
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
                    : const Text("Create Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Already have an account? Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construção de campos padronizada
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}
