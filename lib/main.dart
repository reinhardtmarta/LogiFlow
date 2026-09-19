import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:logiflow/models/user.dart';
import 'package:logiflow/services/firebase_service.dart';
import 'package:logiflow/screens/auth/login_screen.dart';
import 'package:logiflow/screens/auth/register_screen.dart';
import 'package:logiflow/screens/home/home_screen.dart';
import 'package:logiflow/firebase_options.dart';
import 'package:logiflow/l10n/app_localizations.dart';

bool _firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('Uncaught async error: $error');
    debugPrintStack(stackTrace: stackTrace);
    return true;
  };

  final isFlutterTest =
      const bool.fromEnvironment('flutter.test', defaultValue: false);

  if (!isFlutterTest) {
    try {
      // Se for Linux e não estiver configurado no FirebaseOptions, pula ou loga
      if (defaultTargetPlatform == TargetPlatform.linux) {
         debugPrint('Linux detectado, Firebase não configurado nesta plataforma.');
      } else {
         await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
         _firebaseReady = true;
      }
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

  runZonedGuarded(
    () => runApp(const LogiFlowApp()),
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

class LogiFlowApp extends StatelessWidget {
  const LogiFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogiFlow',
      debugShowCheckedModeBanner: false,

      // --- INTERNACIONALIZAÇÃO ---
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,


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
    // Never access FirebaseAuth/Firestore before Firebase.initializeApp().
    if (!_firebaseReady || Firebase.apps.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Não foi possível conectar ao serviço de autenticação.\nVerifique a configuração do Firebase e tente novamente.',
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
