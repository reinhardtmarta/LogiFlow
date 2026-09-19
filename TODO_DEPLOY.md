# TODO - Configuração do Stripe e deploy

O LogiFlow usa Stripe Checkout com cobrança mensal recorrente. A chave
secreta fica somente nas Cloud Functions.

## 1. Stripe

1. Crie uma conta em https://dashboard.stripe.com.
2. No modo de teste, gere uma chave `sk_test_...`.
3. Configure os secrets:

```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
```

4. Faça o deploy para obter a URL do webhook:

```bash
firebase deploy --only functions
```

5. No Stripe Dashboard, crie um endpoint para:

```text
https://us-central1-SEU_PROJETO.cloudfunctions.net/stripeWebhook
```

Selecione os eventos `checkout.session.completed`, `invoice.paid` e
`customer.subscription.deleted`. Copie o signing secret `whsec_...` para
`STRIPE_WEBHOOK_SECRET`.

Os preços são criados no servidor em BRL:

- Basic: R$ 10/mês, até 1000 produtos.
- Pro: R$ 100/mês, produtos ilimitados.

## 2. Deploy

```bash
flutter pub get
cd functions && npm install && cd ..
flutter analyze
cd functions && npm run lint && cd ..
firebase deploy --only firestore:rules,functions
flutter build apk --release
```

O Firebase Functions precisa de um projeto no plano Blaze.

## 3. Teste

Use `sk_test_...` e o cartão `4242 4242 4242 4242`, com qualquer data futura e
CVC válido. Após o Checkout, o webhook deve mudar o perfil para
`subscription_status: active`.

Valide também o upgrade do plano Basic, a renovação via `invoice.paid` e o
cancelamento via `customer.subscription.deleted`.

## 4. Segurança

- Nunca coloque `STRIPE_SECRET_KEY` no Flutter ou no Git.
- Use o signing secret do endpoint correto em `STRIPE_WEBHOOK_SECRET`.
- Use chaves `sk_test_` durante homologação e `sk_live_` somente em produção.
- O preço é definido no backend, e não recebido do cliente.
