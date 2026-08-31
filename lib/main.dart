import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth; // Adicionado para monitorar login
import 'firebase_options.dart';
import 'package:logiflow/models/user.dart';
import 'package:logiflow/screens/auth/login_screen.dart';
import 'package:logiflow/screens/auth/register_screen.dart';
import 'package:logiflow/screens/home/home_screen.dart';

Future<void> main() async {
  // Garante que os bindings do Flutter estejam prontos antes do Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Tratamento de erro visual para evitar a "Tela Vermelha" em produção
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
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
      
      // SOLUÇÃO DO PROBLEMA 1: Em vez de initialRoute fixo, 
      // usamos o 'home' com um StreamBuilder que observa o Firebase.
      home: const AuthWrapper(),

      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
      
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          // SOLUÇÃO DO PROBLEMA 2: Verificação de segurança para evitar Crash
          if (settings.arguments is User) {
            final user = settings.arguments as User;
            return MaterialPageRoute(
              builder: (_) => HomeScreen(user: user),
            );
          } else {
            // Se os argumentos estiverem errados, redireciona para o login em vez de crashar
            debugPrint('Erro: Argumentos para /home são inválidos ou nulos.');
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        }
        return null;
      },
    );
  }
}

/// Widget que decide se mostra Login ou Home baseado no estado do Firebase
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta as mudanças de autenticação do Firebase em tempo real
    return StreamBuilder<auth.User?>(
      stream: auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Enquanto o Firebase está verificando o status (carregando)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o usuário estiver logado
        if (snapshot.hasData) {
          // Nota: Como seu app usa um modelo customizado 'User', 
          // você precisará converter o user do Firebase para o seu modelo
          // ou ajustar sua HomeScreen para aceitar o user do Firebase.
          // Por enquanto, vamos assumir um redirecionamento seguro.
          
          // Aqui, para não quebrar sua lógica atual, vamos buscar os dados
          // e disparar a rota /home. No ideal, o HomeScreen leria direto do Firebase.
          return FutureBuilder<User?>(
            future: _fetchCustomUser(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData) {
                return HomeScreen(user: userSnapshot.data!);
              }
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          );
        }

        // Se não estiver logado, mostra a tela de Login
        return const LoginScreen();
      },
    );
  }

  // Função auxiliar para converter o User do Firebase no seu modelo customizado
  Future<User?> _fetchCustomUser(String uid) async {
    // Aqui você deve implementar a lógica que busca os dados do seu Firestore
    // para preencher o seu modelo 'User' customizado.
    // Exemplo fictício:
    // final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    // return User.fromFirestore(doc);
    return null; // Substitua pela sua lógica de busca real
  }
}
