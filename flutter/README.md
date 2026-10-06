# LogiFlow — Flutter Mobile Application (Android & iOS)

Esta pasta contém o projeto móvel nativo em **Flutter / Dart** para o **LogiFlow**.

---

## 🚀 Como Executar

1. Certifique-se de ter o Flutter SDK (>= 3.0.0) instalado.
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Execute no emulador ou dispositivo físico:
   ```bash
   flutter run
   ```

---

## 📁 Estrutura de Pastas

* `lib/models/`: Modelos de dados (`product.dart`, `user.dart`).
* `lib/services/`: Integração com Firebase Auth e Cloud Firestore (`firebase_service.dart`).
* `lib/screens/`: Telas principais (`feed_screen.dart`, `stock_screen.dart`, `profile_screen.dart`).
* `lib/widgets/`: Componentes reutilizáveis como a barra de navegação inferior verde (`bottom_nav.dart`).
