# TODO — Ações que você precisa fazer

Tudo está commitado e enviado (`main` @ `4948afe`). O que falta é
exclusivamente configuração e deploy do seu lado.

## 1. Mercado Pago (Pix)

```bash
# 1. Crie uma conta em https://www.mercadopago.com.br e gere um
#    Access Token de produção (e um de teste no sandbox).
#
# 2. Configure o secret no Firebase:
firebase functions:secrets:set MP_ACCESS_TOKEN
# (cola o token quando pedir)

# 3. Configure o webhook secret (opcional, recomendado para
#    validar HMAC):
firebase functions:secrets:set MP_WEBHOOK_SECRET
# Use qualquer string longa, ex: openssl rand -hex 32
# Depois, no painel do Mercado Pago, cadastre a URL do webhook:
#   https://us-central1-<seu-projeto>.cloudfunctions.net/mercadopagoWebhook
# e copie o mesmo secret para "Chave de validação".

# 4. Crie as preferências (não precisa fazer manualmente — o
#    Cloud Function createPixPreference já cria on-demand). Mas
#    você PRECISA ter o "Modo de pagamento" configurado como
#    "Pix" nas configurações da conta.
```

## 2. Google Play (fallback)

```bash
# 1. No Google Play Console, crie a app "LogiFlow"
#    (package: com.logiflow).
#
# 2. Em "Produtos > Assinaturas", crie 2 produtos:
#    - ID: logiflow_basic_monthly, preço R$ 10,00/mês
#    - ID: logiflow_pro_monthly,   preço R$ 100,00/mês
#
# 3. Vincule a conta de serviço do Play Console ao Firebase:
#    - Play Console > Setup > API access > Service accounts
#    - Crie/conecte a conta de serviço do seu projeto Firebase
#    - Dê permissão "Financial data" na conta
#
# 4. Sem código adicional — verifyGooglePlayPurchase já valida
#    o purchaseToken com a Publisher API.
```

## 3. Deploy

```bash
# Reinstale deps do Flutter (qr_flutter, in_app_purchase foram
# adicionados/atualizados):
flutter pub get

# Reinstale deps das Cloud Functions (firebase-functions v7):
cd functions && npm install && cd ..

# Rode os testes do Dart (sanity check):
flutter analyze

# Faça o deploy das regras do Firestore:
firebase deploy --only firestore:rules

# Faça o deploy das Cloud Functions:
firebase deploy --only functions

# Build do APK:
flutter build apk --release
```

## 4. Migração opcional de dados existentes

Seus profiles antigos têm `plan: 'free'`, `product_limit: 10`,
`product_count: N`, mas o novo padrão é 50 e usa o enum
`Tier.free`. Os profiles existentes vão automaticamente ser
lidos como `plan=free, product_limit=10` pela nova lógica —
então **sellers existentes ficam com 10 produtos** em vez de
50 até você rodar a migração.

Para migrar:

```bash
# No console do Firestore ou via script:
# Para cada profile, atualize:
#   product_limit: 50  (se plan == 'free' e subscription_status != 'active')
#
# Script Node rápido:
node -e "
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();
db.collection('profiles').get().then(async (snap) => {
  const b = db.batch();
  snap.forEach(d => {
    const p = d.data();
    if ((p.plan === 'free' || !p.plan) && p.subscription_status !== 'active') {
      b.update(d.ref, { product_limit: 50 });
    }
  });
  await b.commit();
  console.log('ok');
});
"
```

## 5. Pendência: build Android no sandbox

Consegui compilar tudo no `flutter analyze` e nas Cloud
Functions, mas o build completo do APK no sandbox trava por
causa de:

- Disco cheio (overlay 19G lotado) — limpei os caches.
- Faltam os AARs dos plugins Firebase no classpath do app. O
  `dev.flutter.flutter-gradle-plugin` v1.0.0 do Flutter 3.44
  deveria injetar via `.flutter-plugins-dependencies`, mas no
  projeto atual não injeta — o `build.gradle.kts` ainda não
  tem a integração que substitui o `app_plugin_loader.gradle`
  legado.

Quando rodar localmente, se o build Android ainda falhar, abra
uma issue e me manda a saída de:

```bash
cd android && ./gradlew app:dependencies --configuration debugCompileClasspath | grep -E "(firebase|cloud_fir|image_pick|shared_pref|in_app)" | head
```

Se a saída for vazia, falta injetar os plugins. Solução:

```kotlin
// android/app/build.gradle.kts — adicionar no final:
include(":cloud_firestore")
project(":cloud_firestore").projectDir = file(
  "/root/.pub-cache/hosted/pub.dev/cloud_firestore-6.9.0/android"
)
// (repetir para cada plugin; ou usar FlutterAppPluginLoader)
// A partir do Flutter 3.45 isso deve vir automático.
```

## 6. Verificação manual do fluxo

Depois de deploy:

1. Criar conta de seller no app.
2. Cadastrar 50 produtos.
3. Tentar cadastrar o 51º → modal de upgrade deve abrir com
   QR Pix.
4. Pagar com conta de teste do Mercado Pago.
5. Webhook processa em até 30s, status muda para `active`.
6. Pode cadastrar até 1000 produtos.
7. Clicar em "Destacar" no dashboard → escolher 1 produto.
8. Abrir como consumidor no Marketplace → produto com badge
   "Destaque" deve aparecer no topo.
9. Para testar expiração, edite manualmente
   `profiles/{uid}.current_period_end` para uma data passada
   no console do Firestore e espere o scheduler rodar (ou
   chame a função manualmente).

## Resumo do que já foi feito

- [x] Cloud Functions (Pix + Play Billing + Webhook + Scheduler)
- [x] Firestore Rules (protege campos sensíveis)
- [x] Flutter: models, services, screens, banner, badge
- [x] Android: removido build.gradle Groovy legado, kts ativo
- [x] Commit + push na `main`
