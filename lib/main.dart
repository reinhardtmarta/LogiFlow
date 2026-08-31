import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_localizations/flutter_localizations.dart'; // IMPORTANTE
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // IMPORTANTE: Gerado pelo flutter gen-l10n
import 'firebase_options.dart';
import 'package:logiflow/models/user.dart';
import 'package:logiflow/services/firebase_service.dart'; // Para buscar dados do Firestore
import 'package:logiflow/screens/auth/login_screen.dart';
import 'package:logiflow/screens/auth/register_screen.dart';
import 'package:logiflow/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Text(
            'Ops! Algo deu errado.\nPor favor, tente novamente.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
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
        AppLocalizations.delegate, // Seus arquivos .arb
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt'), // Português
        Locale('en'), // Inglês
      ],
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
    return StreamBuilder<auth.User?>(
      stream: auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        if (snapshot.hasData) {
          // O usuário está autenticado no Auth, agora buscamos o Perfil + Settings
          return FutureBuilder<User?>(
            future: _fetchFullUserProfile(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData) {
                return HomeScreen(user: userSnapshot.data!);
              }
              // Enquanto busca os dados no Firestore, mostra o loading
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
      // 1. Busca o documento do usuário no Firestore
      final doc = await firebaseService.db.collection('profiles').doc(uid).get();

      if (!doc.exists) {
        return null; // Usuário autenticado mas sem perfil no banco
      }

      final data = doc.data()!;

      // 2. Converte o documento do Firestore para o seu objeto 'User' do modelo
      // Note: Estamos mapeando os campos que você definiu no seu modelo User
      return User(
        id: uid,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        password: '', // Segurança: senha nunca vem do banco
        phone: data['phone'] ?? '',
        address: data['address'] ?? '',
        isSeller: data['is_seller'] == true || data['is_seller'] == 1,
        // Adicionando o Settings aqui para que o app saiba o idioma e interesses
        settings: UserSettings(
          language: data['language'] ?? 'pt',
          interests: List<String>.from(data['interests'] ?? []),
        ),
      );
    } catch (e) {
      debugPrint("Erro ao buscar perfil completo: $e");
      return null;
    }
  }
}
