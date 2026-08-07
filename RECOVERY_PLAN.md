# Plano de Recuperação e Segurança - LogiFlow

## 🛠️ Compatibilidade de Versões (Android)
Após pesquisa na documentação oficial do Android e Flutter, as seguintes versões foram identificadas como as mais estáveis para o Flutter 3.24+:

- **Gradle:** 8.5 (Estável e compatível com AGP 8.2.x)
- **Android Gradle Plugin (AGP):** 8.2.1
- **Kotlin:** 1.9.22 (Versão robusta antes da transição para o K2/2.0)
- **Java:** JDK 17 (Obrigatório para AGP 8.x)

## 🗄️ Alternativas ao Supabase (Bancos de Dados Gratuitos)
Se o Supabase apresentar limitações, as seguintes alternativas são recomendadas:

1. **Appwrite:** 
   - **Vantagem:** Excelente camada gratuita, open-source e muito amigável para Flutter.
   - **Uso:** Ideal para quem quer uma alternativa direta ao Firebase/Supabase com SQL.
2. **Firebase (Google):**
   - **Vantagem:** Integração nativa com o ecossistema Android e camada gratuita generosa para apps pequenos.
   - **Trade-off:** NoSQL (Firestore), o que pode exigir mudanças na lógica de dados.
3. **PocketBase:**
   - **Vantagem:** Único arquivo executável, SQLite em tempo real. Ótimo para projetos que podem ser auto-hospedados de forma barata.

## 🔒 Melhorias de Segurança Implementadas
1. **Proteção de API Keys:** Removido o hardcoding da `GEMINI_API_KEY`. Agora o app exige a injeção via `--dart-define` em tempo de build.
2. **Tratamento de Erros:** Adicionados blocos `try-catch` e validações de nulo em serviços críticos (`GemmaService`, `SupabaseService`).
3. **Isolamento de Pacotes:** Corrigidos conflitos de namespace Android para evitar ataques de sobreposição ou erros de compilação.

## 🚀 Como Compilar
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=SUA_URL \
  --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE \
  --dart-define=GEMINI_API_KEY=SUA_CHAVE_GEMINI
```
