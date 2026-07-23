import 'package:flutter/material.dart';
import 'package:logiflow/core/gemma_service.dart'; // Import correto no topo
import 'package:logiflow/models/user.dart';
import 'package:logiflow/screens/auth/login_screen.dart';
import 'package:logiflow/screens/auth/register_screen.dart';
import 'package:logiflow/screens/home/home_screen.dart';
import 'package:logiflow/screens/seller/seller_dashboard.dart';
import 'package:logiflow/screens/consumer/marketplace_screen.dart';
import 'package:logiflow/screens/ai/ai_assistant_screen.dart';
import 'package:logiflow/screens/feed/general_feed_screen.dart';
import 'package:logiflow/screens/search/search_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mumtyljgtckrulajbwtp.supabase.co',
    anonKey: 'SUA_ANON_KEY',
  );
  runApp(MyApp());
}

final supabase = Supabase.instance.client;

// Cadastro
Future<void> signUp(String email, String password, String nome) async {
  final response = await supabase.auth.signUp(
    email: email,
    password: password,
    data: {'nome': nome}, // dados extras
  );
}

// Login
Future<void> signIn(String email, String password) async {
  await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );
}

// Salvar dados do usuário (exemplo)
Future<void> saveUserData(Map<String, dynamic> data) async {
  await supabase.from('profiles').upsert(data);
}
void main() async {
  // Garante que os plugins do Flutter estejam prontos antes de iniciar o Bot
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Bot de forma segura
  try {
    print("✅ LogiFlow  Loading");
  } catch (e) {
    print("❌ Error: $e");
  }
  
  runApp(const LogiFlowApp());
}

class LogiFlowApp extends StatelessWidget {
  const LogiFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogiFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (_) => HomeScreen(user: user),
          );
        }
        return null;
      },
    );
  }
}
