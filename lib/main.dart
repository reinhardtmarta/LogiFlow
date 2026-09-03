import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logiflow/models/user.dart';
import 'package:logiflow/services/firebase_service.dart';
import 'package:logiflow/screens/auth/login_screen.dart';
import 'package:logiflow/screens/auth/register_screen.dart';
import 'package:logiflow/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isFlutterTest =
      const bool.fromEnvironment('flutter.test', defaultValue: false);

  if (!isFlutterTest) {
    try {
      // Versão mais segura (recomendada):
      import 'package:logiflow/firebase_options.dart';
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (error, stackTrace) {
      debugPrint('Erro na inicialização do Firebase: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Tratamento global de erros de widget
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

      // --- INTERNACIONALIZAÇÃO ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt'),
        Locale('en'),
      ],

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
    // Se o Firebase não inicializou
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
        // Carregando estado de autenticação
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        // Usuário logado → busca perfil completo
        if (snapshot.hasData) {
          return FutureBuilder<User?>(
            future: _fetchFullUserProfile(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              // Ainda carregando o perfil
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                      child: CircularProgressIndicator(color: Colors.green)),
                );
              }

              // Erro ao buscar o perfil
              if (userSnapshot.hasError) {
                debugPrint('Erro ao carregar perfil: ${userSnapshot.error}');
                return const LoginScreen();
              }

              // Perfil encontrado com sucesso
              if (userSnapshot.hasData && userSnapshot.data != null) {
                return HomeScreen(user: userSnapshot.data!);
              }

              // Perfil não existe no Firestore
              return const LoginScreen();
            },
          );
        }

        // Usuário não logado
        return const LoginScreen();
      },
    );
  }

  /// Busca o perfil completo do usuário (Auth + Firestore)
  Future<User?> _fetchFullUserProfile(String uid) async {
    try {
      final doc =
          await firebaseService.db.collection('profiles').doc(uid).get();

      if (!doc.exists) {
        debugPrint('Perfil não encontrado para o uid: $uid');
        return null;
      }

      final data = doc.data()!;
      return User.fromFirestore(uid, data);
    } catch (e, stackTrace) {
      debugPrint('Erro ao buscar perfil completo: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
