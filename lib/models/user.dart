// lib/models/user.dart

/// Classe que armazena as preferências de experiência do usuário.
/// Usada para internacionalização e personalização do feed.
class UserSettings {
  String language;
  List<String> interests;

  UserSettings({
    this.language = 'pt', // Padrão: Português
    this.interests = const [],
  });

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'interests': interests,
    };
  }

  /// Cria um objeto UserSettings a partir de um Map (vindo do Firestore)
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      language: map['language'] ?? 'pt',
      interests: List<String>.from(map['interests'] ?? []),
    );
  }
}

/// Classe principal que representa o Usuário no sistema LogiFlow.
class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String address;
  final bool isSeller;
  final UserSettings settings; // O objeto de configurações integrado

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.isSeller,
    required this.settings, // Obrigatório para garantir que o app sempre saiba o idioma
  });

  /// Converte um documento do Firestore para o objeto User.
  /// Essencial para o login e para o AuthWrapper carregar o perfil.
  factory User.fromFirestore(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: '', // Segurança: A senha nunca deve ser lida do banco de dados
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      isSeller: data['is_seller'] == true || data['is_seller'] == 1,
      // Mapeia as configurações de idioma e interesses do Firestore
      settings: UserSettings.fromMap(data['settings'] ?? {}),
    );
  }

  /// Converte o objeto para Map para salvar no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'is_seller': isSeller,
      'settings': settings.toMap(), // Salva as configurações aninhadas
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Compatibilidade com SQLite/Map para integração com outros sistemas.
  Map<String, dynamic> toMap() {
    final map = toFirestore();
    map['id'] = id;
    return map;
  }

  /// Cria um objeto User a partir de um Map (útil para SQLite ou conversões rápidas).
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      isSeller: map['is_seller'] == true || map['is_seller'] == 1,
      settings: UserSettings.fromMap(map['settings'] ?? {}),
    );
  }
}
