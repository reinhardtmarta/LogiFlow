// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'LogiFlow';

  @override
  String get loginButton => 'Entrar';

  @override
  String get registerButton => 'Criar Conta';

  @override
  String get emailLabel => 'Endereço de E-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get phoneLabel => 'Telefone';

  @override
  String get addressLabel => 'Endereço / Localização';

  @override
  String get isSeller => 'Sou Vendedor / Produtor';

  @override
  String get errorEmptyFields =>
      'Por favor, preencha todos os campos obrigatórios';

  @override
  String get errorPasswordShort => 'A senha deve ter pelo menos 6 caracteres';

  @override
  String get errorAccountCreated => 'Conta criada com sucesso! Faça o login.';

  @override
  String get errorGeneric => 'Ocorreu um erro';

  @override
  String get searchHint => 'Buscar pão, leite, frutas...';

  @override
  String get noItemsFound => 'Nenhum item disponível no momento.';

  @override
  String daysLeft(int count) {
    return '$count dias restantes';
  }

  @override
  String get rescueUrgent => 'RESGATE URGENTE';

  @override
  String get healthy => 'SAUDÁVEL';

  @override
  String get premium => 'PREMIUM';
}
