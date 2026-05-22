import 'package:flutter/material.dart';
import 'core/gemma_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/consumer/marketplace_screen.dart';   // Vamos renomear depois para Feed
import 'screens/seller/seller_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GemmaService.initialize();

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
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Começa na tela de login
    );
  }
}
