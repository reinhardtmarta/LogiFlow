// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LogiFlow';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Create Account';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get addressLabel => 'Address / Location';

  @override
  String get isSeller => 'I am a Seller / Producer';

  @override
  String get errorEmptyFields => 'Please fill all required fields';

  @override
  String get errorPasswordShort => 'Password must be at least 6 characters';

  @override
  String get errorAccountCreated =>
      'Account created successfully! Please login.';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get searchHint => 'Search for bread, milk, fruits...';

  @override
  String get noItemsFound => 'No items available at the moment.';

  @override
  String daysLeft(int count) {
    return '$count days left';
  }

  @override
  String get rescueUrgent => 'RESCUE URGENT';

  @override
  String get healthy => 'HEALTHY';

  @override
  String get premium => 'PREMIUM';
}
