# LogiFlow: Planos de assinatura de estoque com Pix (Mercado Pago)

## 1. Contexto e objetivo

O LogiFlow é um marketplace Flutter + Firebase de alimentos "rescue". Hoje
(`lib/services/firebase_service.dart:22-77`, `lib/models/product.dart`) todo
vendedor nasce com `plan: 'free'`, `product_limit: 10` e `product_count: 0`.
**Não existe nenhum fluxo de pagamento** no app: o `in_app_purchase` em
`pubspec.yaml:37` está declarado mas nunca é usado; não há carrinho, checkout
ou função em `functions/index.js`.

O usuário quer cobrar dos **vendedores** (B2B, não do consumidor final) por
uso de estoque, e que assinantes apareçam em destaque no feed. Decisões já
fechadas:

| Decisão | Valor |
|---|---|
| Provider | Pix via Mercado Pago (chamadas server-side em Cloud Function) |
| Moeda | BRL (R$) |
| Free | até 50 produtos |
| Tier 1 (R$10/mês) | 51–1000 produtos |
| Tier 2 (R$100/mês) | 1001+ produtos |
| Cobrança | Pagamento mensal avulso (sem recorrência automática); vendedor gera novo QR todo mês |
| Gatilho do upgrade | Modal dispara ao tentar salvar o 51º produto em `addProduct` |
| Destaque no feed | 1 produto por vendedor, escolhido por ele |
| Expiração do plano | Soft-lock: excedentes ficam `hidden=true`; lembrete para reduzir antes de renovar |
| Auth | Firebase Auth já existente; só vamos ler `request.auth.uid` nas Callable Functions |

## 2. Modelo de dados (Firestore)

### `profiles/{uid}` — campos novos (além dos atuais)
```
plan: 'free' | 'basic' | 'pro'         // derivado do limite vigente
product_limit: 50 | 1000 | -1         // -1 = ilimitado
current_period_end: Timestamp | null  // fim do mês pago atual
subscription_status: 'none' | 'active' | 'expired'
featured_product_id: string | null     // 1 doc de products/{pid} em destaque
```
Regras de derivação (no cliente e em Cloud Function):
- `count <= 50` e `subscription_status != 'active'` → `plan='free'`, `limit=50`
- `count <= 1000` e status `active` → `plan='basic'`, `limit=1000`
- `count > 1000` e status `active` → `plan='pro'`, `limit=-1` (ilimitado)
- status `expired` ou `none` → volta para `free/50`, mesmo se count > 50

### `products/{pid}` — campos novos
```
hidden: bool                          // soft-lock: true quando plano expira e count > 50
```
(O `is_featured` que `getProductsStream` já ordena em `firebase_service.dart:368`
passa a ser derivado: `products.where('featured_product_id' == pid).limit(1)` no
cliente, ou um campo `is_featured` mantido por Cloud Function no ato de salvar.)

## 3. Server-side (Firebase Cloud Functions v2)

Arquivo: `functions/index.js` (atualmente placeholder, 32 linhas).
Dependência nova: `mercadopago` (npm) — chave em
`functions.config().mercadopago.access_token`, configurada via
`firebase functions:config:set mercadopago.access_token=...`.

### 3.1 `createPixPreference` (callable, `onCall`)
- **Input:** `{ tier: 'basic' | 'pro' }`, lido de `context.auth.uid`.
- **Ação:**
  1. Gera `external_reference = `${uid}:${tier}:${mesAno}``.
  2. Chama `POST https://api.mercadopago.com/checkout/preferences` com
     `payment_methods.excluded_payment_types = [{id:'credit_card'},
     {id:'debit_card'},{id:'ticket'}]` (forçar só Pix) e
     `payment_methods.installments = 0` na preference.
  3. Grava `pending_payments/{uid}:{mesAno}` com `{ tier, preference_id,
     created_at, status:'pending' }`.
  4. Retorna `{ qr_code_base64, qr_code, copy_paste, preference_id,
     amount_cents }`.
- **Preço:** R$10,00 = 1000 cents (basic), R$100,00 = 10000 cents (pro).
- **Auth:** exige `context.auth.token.email_verified === true`.

### 3.2 `mercadopagoWebhook` (HTTP `onRequest`)
- Recebe notificações IPN/webhook do Mercado Pago.
- Valida assinatura (header `x-signature` + `x-request-id` contra
  `v1:webhook-secret`).
- Busca `payment` por `external_reference`. Se `status === 'approved'`:
  1. Carrega `profiles/{uid}`.
  2. Define `subscription_status = 'active'`, `current_period_end =
     now + 30 dias`.
  3. Recalcula `plan` e `product_limit` (regra da seção 2).
  4. Aplica soft-lock se count > novo limit: seta `hidden=true` nos produtos
     excedentes (os mais antigos por `created_at` ficam visíveis, os mais
     novos viram `hidden=true`).
  5. Marca `pending_payments/{ref}` como `status:'paid'`.

### 3.3 `selectFeaturedProduct` (callable, `onCall`)
- Input: `{ productId }`, valida `seller_id === context.auth.uid` e que
  `subscription_status === 'active'`.
- Limpa `is_featured=true` em todos os outros produtos do seller, seta
  `is_featured=true` no `productId`, salva `featured_product_id` no profile.

### 3.4 `runDailyPlanExpiryCheck` (scheduler `onSchedule` 'every 24 hours')
- Para cada `profiles/{uid}` com `subscription_status == 'active'` e
  `current_period_end < now`: seta `subscription_status='expired'`,
  recalcula `plan='free'`, `product_limit=50`, aplica soft-lock nos
  excedentes, manda FCM push `"Seu plano expirou — reduza para 50 produtos
  ou renove para continuar"`.

## 4. Cliente (Flutter)

### 4.1 Novos arquivos
- `lib/services/subscription_service.dart` — wrapper sobre
  `cloud_functions` para `createPixPreference` e `selectFeaturedProduct`,
  polling de status (5s, máx 5min).
- `lib/screens/seller/upgrade_screen.dart` — modal/página full-screen com:
  tier atual, tier sugerido, botão "Gerar Pix", `Image.memory` do QR
  (`qr_code_base64`), `SelectableText(copy_paste)`, botão "Copiar",
  estado de polling, e ao virar `active` fecha e dá snackbar de sucesso.
- `lib/screens/seller/select_featured_screen.dart` — lista produtos do
  seller, "Selecionar como destaque" (visível só se `status=='active'`).
- `lib/models/subscription.dart` — `Tier`, `SubscriptionStatus`,
  `PixPayment`, `fromMap`.

### 4.2 Mudanças
- `lib/services/firebase_service.dart`:
  - `addProduct` (linha 317) passa a checar `canAddProduct(uid)` que vira
    `count < effectiveLimit(uid)`. Se o seller tentar salvar o 51º,
    `addProduct` lança `ProductLimitReachedException` (classe nova) com o
    `tierNeeded` populado pelo `getProductLimit` derivado (não mais o
    hardcoded "10" / "premium" das linhas 119-180 — refatorar
    `getProductLimit` e `getPhotosPerProduct` para usar a tabela de tiers).
  - `getProductsStream` (linha 365) ganha `.where('hidden', '==', false)`
    **e** `where('is_featured', '==', true)` OU `false` — manter o
    `orderBy('is_featured', descending: true)` que já existe, e
    adicionar `.where('is_featured', '==', false)` como union via segunda
    query não é nativo; em vez disso, no cliente filtra `hidden==false`
    pós-stream e o `orderBy` já puxa os destacados primeiro.
- `lib/screens/seller/add_product_screen.dart` (atual) — `try/catch` em
  volta de `firebaseService.addProduct(...)` que, ao pegar
  `ProductLimitReachedException`, faz `Navigator.push` para
  `UpgradeScreen(tierNeeded: e.tierNeeded)`.
- `lib/screens/seller/seller_dashboard.dart` — banner persistente no topo
  quando `status != 'active'`: "Plano free — X/50 produtos. Fazer upgrade
  para liberar limite maior e destacar no feed." → `UpgradeScreen`.
- `lib/screens/consumer/marketplace_screen.dart` — `Card` ganha `Badge`
  "Destaque" quando `product.isFeatured` (e badge "Resgate" continua).
- `lib/models/product.dart` — adicionar `hidden: bool` ao construtor,
  `fromFirestore` e `toFirestore` (default `false`).

## 5. Segurança (Firestore Rules)

Atualizar `firestore.rules` (não visto neste plano — o agente implementador
deve ler a versão atual antes):

- `profiles/{uid}`: cliente pode `update` apenas dos campos
  `featured_product_id`, `name`, `phone`, `address`, `settings`; NUNCA
  `plan`, `product_limit`, `subscription_status`, `current_period_end`,
  `product_count` (último é só `increment` por Cloud Function).
- `products/{pid}`: regra `create` valida
  `request.resource.data.seller_id == request.auth.uid`; o campo
  `is_featured` e `hidden` NÃO podem ser escritos pelo cliente
  (validação `!('is_featured' in request.resource.data) &&
  !('hidden' in request.resource.data)` no `create`, e a mesma
  restrição no `update` exceto para Cloud Functions via service account).
- `pending_payments/{id}`: read/write só para Cloud Functions
  (`match /pending_payments/{id} { allow read, write: if false; }`).
- Cloud Functions usam Admin SDK, que ignora Rules; webhook só aceita
  o IP do Mercado Pago e valida HMAC.

## 6. Fluxos fim-a-fim

### Fluxo A — Vendedor tenta cadastrar o 51º produto
1. UI chama `firebaseService.addProduct(product)`.
2. `addProduct` lê profile: `count=50`, `effectiveLimit(50)`,
   `canAdd=false`. Lança `ProductLimitReachedException(tierNeeded='basic')`.
3. UI exibe `UpgradeScreen` com QR Pix de R$10.
4. Seller paga no banco; webhook atualiza `subscription_status='active'`,
   `product_limit=1000`, `current_period_end=+30d`.
5. UI volta, `addProduct` re-chamado, sucesso.

### Fluxo B — Vendedor quer destacar 1 produto
1. Em `select_featured_screen`, clica no produto, chama
   `selectFeaturedProduct(productId)`.
2. Cloud Function limpa `is_featured` em todos do seller e seta no
   escolhido; grava `featured_product_id` no profile.
3. `getProductsStream` já ordena por `is_featured desc` → aparece no topo.

### Fluxo C — Plano expira
1. `runDailyPlanExpiryCheck` (3.4) roda, seta `expired`, `plan=free`,
   `product_limit=50`, marca excedentes como `hidden=true`.
2. Seller entra no app → banner mostra "X produtos ocultos. Reduza
   para 50 ou renove." + botão "Renovar".
3. Renovação gera novo QR Pix; após pagamento, excedentes viram
   `hidden=false` automaticamente (a função 3.2 só seta status; a
   reversão do `hidden` é feita por Cloud Function na renovação se
   count <= novo limit, ou se mantém hidden se count > novo limit).

## 7. Validação e testes

- `flutter test test/subscription_service_test.dart` — mock das callable
  functions, verificar polling e parsing de `PixPayment`.
- `flutter test test/upgrade_screen_test.dart` — golden test do QR code,
  copiar/colar, transição de estados pending/active/expired.
- Em `functions/`, escrever `test/createPixPreference.test.js` com
  `firebase-functions-test` cobrindo: rejeição sem auth, valor correto
  por tier, external_reference com formato `${uid}:${tier}:${yyyy-MM}`.
- Manual: criar seller, cadastrar 50 produtos, cadastrar 51º → modal,
  pagar Pix em sandbox, ver contador subir para 1000, escolher destaque,
  expirar plano (ajustar `current_period_end` manualmente no console),
  ver excedentes ocultos.

## 8. Riscos e fora-de-escopo

- **Fora-de-escopo (MVP):** assinatura recorrente automática (preapproval),
  cupons, refunds, histórico de faturas em PDF, invoice/receipt para o
  seller, webhooks de chargeback, multi-moeda.
- **Risco 1:** `in_app_purchase` no `pubspec.yaml:37` continua declarado
  sem uso. Removê-lo do pubspec (remove ~2MB de binário) ou documentar
  que foi deixado para futura monetização de consumidor (B2C). Decisão
  recomendada: **remover** para evitar Play Store/IAP review de algo
  não configurado.
- **Risco 2:** Mercado Pago sandbox exige `test_user` aprovados; sem
  isso o seller não consegue testar em homologação. Documentar em
  `README` como criar usuário de teste.
- **Risco 3:** o webhook do Mercado Pago é assíncrono; se o seller
  fechar o app antes de pagar, o pagamento é processado e o `status`
  muda, mas o app precisa reabrir para ver. Mitigação: FCM push
  no momento que `subscription_status` muda para `active` (já coberto
  em 3.2 se implementarmos o push, opcional para o MVP).
- **Risco 4:** a regra de soft-lock "ocultar excedentes mais recentes"
  depende de `created_at` em `products`. Hoje
  `lib/models/product.dart:186-214` salva `updated_at` mas não
  `created_at`. Precisamos adicionar `created_at` em `toFirestore` na
  primeira gravação (campo novo, sem migração de dados existentes).

## 9. Checklist de implementação (ordem)

1. `functions/`: adicionar dep `mercadopago`, escrever 3.1, 3.3, 3.4.
2. `functions/`: escrever 3.2 com validação HMAC.
3. Firestore Rules: aplicar restrições da seção 5.
4. `pubspec.yaml`: remover `in_app_purchase` (ou marcar como
   `# used for future B2C monetization`).
5. `lib/models/subscription.dart` (novo).
6. `lib/models/product.dart`: adicionar `hidden`, `created_at`.
7. `lib/services/firebase_service.dart`: refatorar `getProductLimit`,
   lançar `ProductLimitReachedException`, ajustar `getProductsStream`
   com `where('hidden','==',false)`.
8. `lib/services/subscription_service.dart` (novo).
9. `lib/screens/seller/upgrade_screen.dart` (novo).
10. `lib/screens/seller/select_featured_screen.dart` (novo).
11. `lib/screens/seller/add_product_screen.dart`: catch + push upgrade.
12. `lib/screens/seller/seller_dashboard.dart`: banner.
13. `lib/screens/consumer/marketplace_screen.dart`: badge "Destaque".
14. Testes (seção 7).
15. Deploy: `firebase deploy --only functions,firestore:rules` e
    `flutter build apk --release`.
