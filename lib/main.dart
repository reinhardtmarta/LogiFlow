import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logiflow/models/user.dart';
import 'package:logiflow/services/firebase_service.dart';
import 'package:logiflow/screens/auth/login_screen.dart';
import 'package:logiflow/screens/auth/register_screen.dart';
import 'package:logiflow/screens/home/home_screen.dart';

Future<void> main() async {
  // Garante a comunicação com os canais nativos antes de qualquer inicialização
  WidgetsFlutterBinding.ensureInitialized();

  final isFlutterTest = const bool.fromEnvironment('flutter.test', defaultValue: false);

  if (!isFlutterTest) {
    try {
      await Firebase.initializeApp();
    } catch (error, stackTrace) {
      debugPrint('Erro na inicialização do Firebase: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        child: const Center(
          child: Text(
            'Ops! Algo deu errado.\nPor favor, tente novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  };

  runApp(const LogiFlowApp());
}

class LogiFlowApp extends StatelessWidget {
  const LogiFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogiFlow',
      debugShowCheckedModeBanner: false,
      
      // --- CONFIGURAÇÃO DE INTERNACIONALIZAÇÃO ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt'), // Português
        Locale('en'), // Inglês
      ],
      // O próprio Flutter detecta o idioma do sistema a partir de supportedLocales
      // ------------------------------------------

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
      
      home: const AuthWrapper(),

      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
      
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          if (settings.arguments is User) {
            final user = settings.arguments as User;
            return MaterialPageRoute(
              builder: (_) => HomeScreen(user: user),
            );
          } else {
            debugPrint('Erro: Argumentos para /home são inválidos ou nulos.');
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Se o Firebase não tiver inicializado corretamente, evita crash imediato
    if (Firebase.apps.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Falha ao conectar com o serviço de autenticação.\nVerifique a conexão e as credenciais do app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<auth.User?>(
      stream: auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<User?>(
            future: _fetchFullUserProfile(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData) {
                return HomeScreen(user: userSnapshot.data!);
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.green)),
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }

  /// Busca o perfil completo do usuário combinando os dados de Auth e Firestore
  Future<User?> _fetchFullUserProfile(String uid) async {
    try {
      final doc = await firebaseService.db.collection('profiles').doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return User.fromFirestore(uid, data);
    } catch (e) {
      debugPrint("Erro ao buscar perfil completo: $e");
      return null;
    }
  }
}
