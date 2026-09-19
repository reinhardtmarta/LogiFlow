const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({maxInstances: 10, region: "us-central1"});

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

const TIER_PRICES = {
  basic: {label: "Basic (até 1000 produtos)", amountCents: 1000, limit: 1000},
  pro: {label: "Pro (acima de 1000 produtos)", amountCents: 10000, limit: -1},
};

const FREE_LIMIT = 50;

/**
 * Returns a year-month key in UTC.
 * @param {Date} date Current date.
 * @return {string} Year-month key.
 */
function ymKey(date = new Date()) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  return `${y}-${m}`;
}

/**
 * Hides products that exceed the current subscription limit.
 * @param {string} uid Seller id.
 * @param {number} newLimit Maximum visible products.
 */
async function applySoftLock(uid, newLimit) {
  if (newLimit < 0) {
    const products = await db
        .collection("products")
        .where("seller_id", "==", uid)
        .where("hidden", "==", true)
        .get();
    const batch = db.batch();
    products.forEach((doc) => batch.update(doc.ref, {hidden: false}));
    if (!products.empty) await batch.commit();
    return 0;
  }

  const snap = await db
      .collection("products")
      .where("seller_id", "==", uid)
      .orderBy("created_at", "asc")
      .get();

  const all = snap.docs;
  const toHide = all.slice(newLimit);

  if (toHide.length === 0) {
    const hidden = await db
        .collection("products")
        .where("seller_id", "==", uid)
        .where("hidden", "==", true)
        .get();
    const batch = db.batch();
    hidden.forEach((doc) => batch.update(doc.ref, {hidden: false}));
    if (!hidden.empty) await batch.commit();
    return 0;
  }

  const batch = db.batch();
  toHide.forEach((doc) => batch.update(doc.ref, {hidden: true}));
  await batch.commit();
  return toHide.length;
}

/**
 * Reads a resource from the Stripe API.
 * @param {string} stripeKey Stripe secret key.
 * @param {string} path Stripe API path.
 * @return {Promise<Object>} Stripe response.
 */
async function stripeRequest(stripeKey, path) {
  const response = await fetch(`https://api.stripe.com${path}`, {
    headers: {Authorization: `Bearer ${stripeKey}`},
  });
  if (!response.ok) {
    throw new Error(`Stripe API error: ${response.status}`);
  }
  return response.json();
}

/**
 * Activates or renews a seller subscription after a Stripe event.
 * @param {string} uid Seller id.
 * @param {string} tier Subscription tier.
 * @param {string} externalRef Local payment reference.
 * @param {string} subscriptionId Stripe subscription id.
 * @param {number} periodEndSeconds Subscription end as Unix seconds.
 */
async function activateStripeSubscription(
    uid,
    tier,
    externalRef,
    subscriptionId,
    periodEndSeconds,
) {
  if (!uid || !TIER_PRICES[tier]) return;

  let periodEnd = periodEndSeconds;
  if (!periodEnd && subscriptionId) {
    const subscription = await stripeRequest(
        STRIPE_SECRET_KEY.value(),
        `/v1/subscriptions/${subscriptionId}`,
    );
    periodEnd = subscription.current_period_end;
  }

  const profileRef = db.collection("profiles").doc(uid);
  const profileSnap = await profileRef.get();
  if (!profileSnap.exists) return;

  const profile = profileSnap.data();
  const productCount = profile.product_count || 0;
  const tierInfo = TIER_PRICES[tier];
  const newLimit = productCount > 1000 ? -1 : tierInfo.limit;
  const fallbackEnd = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;

  await profileRef.update({
    subscription_status: "active",
    current_period_end: admin.firestore.Timestamp.fromMillis(
        (periodEnd || fallbackEnd) * 1000,
    ),
    plan: productCount > 1000 ? "pro" : tier,
    product_limit: newLimit,
    stripe_subscription_id: subscriptionId || null,
  });

  await applySoftLock(uid, newLimit);

  if (externalRef) {
    await db.collection("pending_payments").doc(externalRef).set({
      uid,
      tier,
      status: "paid",
      stripe_subscription_id: subscriptionId || null,
      paid_at: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  }
}

exports.createStripeCheckoutSession = onCall(
    {secrets: [STRIPE_SECRET_KEY]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Faça login para continuar.");
      }

      const tier = request.data && request.data.tier;
      if (!TIER_PRICES[tier]) {
        throw new HttpsError("invalid-argument", "Tier inválido.");
      }

      const uid = request.auth.uid;
      const period = ymKey();
      const externalRef = `${uid}:${tier}:${period}`;

      const existing = await db
          .collection("pending_payments")
          .doc(externalRef)
          .get();
      if (existing.exists && existing.get("status") === "paid") {
        throw new HttpsError("already-exists", "Pagamento já confirmado.");
      }

      const stripeKey = STRIPE_SECRET_KEY.value();
      if (!stripeKey) {
        throw new HttpsError(
            "failed-precondition",
            "Stripe não configurado no servidor.",
        );
      }

      const params = new URLSearchParams();
      params.set("mode", "subscription");
      params.set("success_url", "https://stripe.com");
      params.set("cancel_url", "https://stripe.com");
      params.set("client_reference_id", externalRef);
      params.set("metadata[uid]", uid);
      params.set("metadata[tier]", tier);
      params.set("metadata[external_reference]", externalRef);
      params.set("subscription_data[metadata][uid]", uid);
      params.set("subscription_data[metadata][tier]", tier);
      params.set(
          "subscription_data[metadata][external_reference]", externalRef,
      );
      params.set("line_items[0][price_data][currency]", "brl");
      params.set(
          "line_items[0][price_data][unit_amount]",
          String(TIER_PRICES[tier].amountCents),
      );
      params.set("line_items[0][price_data][recurring][interval]", "month");
      params.set(
          "line_items[0][price_data][product_data][name]",
          `LogiFlow ${TIER_PRICES[tier].label}`,
      );
      params.set("line_items[0][quantity]", "1");

      const resp = await fetch("https://api.stripe.com/v1/checkout/sessions", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": `Bearer ${stripeKey}`,
        },
        body: params.toString(),
      });

      if (!resp.ok) {
        const text = await resp.text();
        logger.error("Stripe Checkout error", resp.status, text);
        throw new HttpsError("internal", "Falha ao iniciar checkout Stripe.");
      }

      const session = await resp.json();

      await db
          .collection("pending_payments")
          .doc(externalRef)
          .set({
            uid,
            tier,
            period,
            checkout_session_id: session.id,
            amount_cents: TIER_PRICES[tier].amountCents,
            status: "pending",
            created_at: admin.firestore.FieldValue.serverTimestamp(),
          });

      return {
        checkout_session_id: session.id,
        checkout_url: session.url,
        amount_cents: TIER_PRICES[tier].amountCents,
        external_reference: externalRef,
      };
    },
);

exports.checkPaymentStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Faça login para continuar.");
  }
  const ref = request.data && request.data.external_reference;
  if (!ref || typeof ref !== "string") {
    throw new HttpsError("invalid-argument", "external_reference obrigatório.");
  }
  const doc = await db.collection("pending_payments").doc(ref).get();
  if (!doc.exists) {
    return {status: "not_found"};
  }
  const data = doc.data();
  if (data.uid !== request.auth.uid) {
    throw new HttpsError(
        "permission-denied", "Pagamento não pertence ao usuário.",
    );
  }
  return {status: data.status, tier: data.tier, period: data.period};
});

exports.selectFeaturedProduct = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Faça login para continuar.");
  }
  const productId = request.data && request.data.productId;
  if (!productId) {
    throw new HttpsError("invalid-argument", "productId obrigatório.");
  }

  const uid = request.auth.uid;
  const profileRef = db.collection("profiles").doc(uid);
  const profileSnap = await profileRef.get();
  if (!profileSnap.exists) {
    throw new HttpsError("not-found", "Perfil não encontrado.");
  }
  const profile = profileSnap.data();
  if (profile.subscription_status !== "active") {
    throw new HttpsError(
        "failed-precondition",
        "Apenas assinantes ativos podem destacar produtos.",
    );
  }

  const productRef = db.collection("products").doc(productId);
  const productSnap = await productRef.get();
  if (!productSnap.exists) {
    throw new HttpsError("not-found", "Produto não encontrado.");
  }
  if (productSnap.get("seller_id") !== uid) {
    throw new HttpsError(
        "permission-denied", "Produto não pertence ao vendedor.",
    );
  }

  const oldFeatured = await db
      .collection("products")
      .where("seller_id", "==", uid)
      .where("is_featured", "==", true)
      .get();

  const batch = db.batch();
  oldFeatured.forEach((doc) => batch.update(doc.ref, {is_featured: false}));
  batch.update(productRef, {is_featured: true});
  batch.update(profileRef, {featured_product_id: productId});
  await batch.commit();

  return {ok: true, productId};
});

exports.stripeWebhook = onRequest(
    {secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET]},
    async (req, res) => {
      if (req.method !== "POST") {
        res.status(405).send("Method not allowed");
        return;
      }

      const stripeKey = STRIPE_SECRET_KEY.value();
      const webhookSecret = STRIPE_WEBHOOK_SECRET.value();
      if (!stripeKey || !webhookSecret || !req.rawBody) {
        res.status(500).send("Stripe webhook não configurado");
        return;
      }

      let event;
      try {
        const signature = req.headers["stripe-signature"];
        event = require("stripe")(stripeKey).webhooks.constructEvent(
            req.rawBody,
            signature,
            webhookSecret,
        );
      } catch (error) {
        logger.warn("Invalid Stripe webhook signature", error);
        res.status(400).send("invalid signature");
        return;
      }

      const object = event.data.object;
      if (event.type === "checkout.session.completed") {
        const metadata = object.metadata || {};
        await activateStripeSubscription(
            metadata.uid,
            metadata.tier,
            metadata.external_reference,
            object.subscription,
        );
      } else if (event.type === "invoice.paid") {
        const subscriptionId = object.subscription;
        if (subscriptionId) {
          const subscription = await stripeRequest(
              stripeKey,
              `/v1/subscriptions/${subscriptionId}`,
          );
          const metadata = subscription.metadata || {};
          await activateStripeSubscription(
              metadata.uid,
              metadata.tier,
              metadata.external_reference,
              subscription.id,
              subscription.current_period_end,
          );
        }
      } else if (event.type === "customer.subscription.deleted") {
        const uid = object.metadata && object.metadata.uid;
        if (uid) {
          await db.collection("profiles").doc(uid).update({
            subscription_status: "expired",
            plan: "free",
            product_limit: FREE_LIMIT,
            featured_product_id: null,
          });
          await applySoftLock(uid, FREE_LIMIT);
        }
      }

      res.status(200).send("ok");
    },
);

exports.runDailyPlanExpiryCheck = onSchedule(
    {schedule: "every 24 hours", timeZone: "America/Sao_Paulo"},
    async () => {
      const now = admin.firestore.Timestamp.now();
      const expired = await db
          .collection("profiles")
          .where("subscription_status", "==", "active")
          .where("current_period_end", "<", now)
          .get();

      let count = 0;
      for (const doc of expired.docs) {
        await db.runTransaction(async (tx) => {
          tx.update(doc.ref, {
            subscription_status: "expired",
            plan: "free",
            product_limit: FREE_LIMIT,
            featured_product_id: null,
          });
        });
        await applySoftLock(doc.id, FREE_LIMIT);
        count += 1;
      }
      logger.info(`Expiry check: ${count} profile(s) expired.`);
    },
);
