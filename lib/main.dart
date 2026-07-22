import 'package:flutter/material.dart';
import 'core/gemma_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/seller/seller_dashboard.dart';
import 'screens/consumer/marketplace_screen.dart';
import 'screens/ai/ai_assistant_screen.dart';
import 'screens/feed/general_feed_screen.dart';
import 'screens/search/search_screen.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Primeiro, certifique-se de que o import está no topo do arquivo!
import 'package:logiflow/services/gemma_service.dart'; 

// ... dentro do main
LogiFlowBotService.initialize().catchError((_) {});
  
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
