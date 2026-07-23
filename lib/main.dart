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
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// Use um getter para pegar o client quando necessário (evita acessar antes da inicialização)
supabase.SupabaseClient get supabaseClient => supabase.Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pega as variáveis em tempo de compilação via --dart-define.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'SUPABASE_URL e SUPABASE_ANON_KEY não foram fornecidos. Passe-os com --dart-define (ex: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...) ou configure seu proc[...]
    );
  }

  // Inicializa o Supabase antes de rodar a aplicação
  await supabase.Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
