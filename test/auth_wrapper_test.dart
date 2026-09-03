import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow/main.dart';
import 'package:logiflow/screens/auth/login_screen.dart';

void main() {
  testWidgets('Verifica se o app tenta carregar a tela de login', (WidgetTester tester) async {
    // Carrega o app principal
    await tester.pumpWidget(const LogiFlowApp());

    // Se o AuthWrapper funcionar, ele deve eventualmente exibir o LoginScreen ou um CircularProgressIndicator
    // Usamos findsWidgets para aceitar um ou outro caso a conexão seja rápida ou lenta
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
