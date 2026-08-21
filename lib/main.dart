import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logiflow/models/user.dart';
import 'package:logiflow/screens/auth/login_screen.dart';
import 'package:logiflow/screens/auth/register_screen.dart';
import 'package:logiflow/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    debugPrint('Firebase is not configured: $error');
    debugPrintStack(stackTrace: stackTrace);
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
