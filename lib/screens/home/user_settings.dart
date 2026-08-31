class UserSettings {
  String language; // 'pt', 'en', 'es'
  List<String> interests; // ['vegan', 'organic', 'dairy', 'bakery']
  
  UserSettings({
    this.language = 'pt',
    this.interests = const [],
  });

  // Converte para mapa para salvar no Firestore
  Map<String, dynamic> toMap() => {
    'language': language,
    'interests': interests,
  };
}
