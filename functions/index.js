const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const crypto = require("node:crypto");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({maxInstances: 10, region: "us-central1"});

const MP_ACCESS_TOKEN = defineSecret("MP_ACCESS_TOKEN");
const MP_WEBHOOK_SECRET = defineSecret("MP_WEBHOOK_SECRET");

const TIER_PRICES = {
  basic: {label: "Basic (até 1000 produtos)", amountCents: 1000, limit: 1000},
  pro: {label: "Pro (acima de 1000 produtos)", amountCents: 10000, limit: -1},
};

const FREE_LIMIT = 50;

function ymKey(date = new Date()) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  return `${y}-${m}`;
}

function recomputePlan(profile, productCount) {
  const status = profile.subscription_status || "none";
  const now = admin.firestore.Timestamp.now();
  const periodEnd = profile.current_period_end;
  const isActive = status === "active" &&
    periodEnd &&
    periodEnd.toMillis() > now.toMillis();

  if (isActive) {
    const limit = productCount > 1000 ? -1 : 1000;
    return {
      plan: productCount > 1000 ? "pro" : "basic",
      product_limit: limit,
      subscription_status: "active",
    };
  }
  return {
    plan: "free",
    product_limit: FREE_LIMIT,
    subscription_status: status === "active" ? "expired" : status,
  };
}

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

exports.createPixPreference = onCall(
  {secrets: [MP_ACCESS_TOKEN]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Faça login para continuar.");
    }

    const tier = request.data?.tier;
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

    const accessToken = MP_ACCESS_TOKEN.value();
    if (!accessToken) {
      throw new HttpsError(
        "failed-precondition",
        "Mercado Pago não configurado no servidor.",
      );
    }

    const body = {
      items: [
        {
          title: `LogiFlow ${TIER_PRICES[tier].label}`,
          quantity: 1,
          unit_price: TIER_PRICES[tier].amountCents / 100,
          currency_id: "BRL",
        },
      ],
      payment_methods: {
        excluded_payment_types: [
          {id: "credit_card"},
          {id: "debit_card"},
          {id: "ticket"},
        ],
        installments: 0,
      },
      external_reference: externalRef,
      notification_url: `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/mercadopagoWebhook`,
    };

    const resp = await fetch(
      "https://api.mercadopago.com/checkout/preferences",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(body),
      },
    );

    if (!resp.ok) {
      const text = await resp.text();
      logger.error("MP preference error", resp.status, text);
      throw new HttpsError("internal", "Falha ao gerar preferência Pix.");
    }

    const pref = await resp.json();

    await db
      .collection("pending_payments")
      .doc(externalRef)
      .set({
        uid,
        tier,
        period,
        preference_id: pref.id,
        amount_cents: TIER_PRICES[tier].amountCents,
        status: "pending",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      preference_id: pref.id,
      qr_code_base64: pref.point_of_interaction?.transaction_data?.qr_code_base64 || null,
      qr_code: pref.point_of_interaction?.transaction_data?.qr_code || null,
      copy_paste: pref.point_of_interaction?.transaction_data?.qr_code || null,
      amount_cents: TIER_PRICES[tier].amountCents,
      external_reference: externalRef,
    };
  },
);

exports.checkPaymentStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Faça login para continuar.");
  }
  const ref = request.data?.external_reference;
  if (!ref || typeof ref !== "string") {
    throw new HttpsError("invalid-argument", "external_reference obrigatório.");
  }
  const doc = await db.collection("pending_payments").doc(ref).get();
  if (!doc.exists) {
    return {status: "not_found"};
  }
  const data = doc.data();
  if (data.uid !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Pagamento não pertence ao usuário.");
  }
  return {status: data.status, tier: data.tier, period: data.period};
});

exports.selectFeaturedProduct = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Faça login para continuar.");
  }
  const productId = request.data?.productId;
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
    throw new HttpsError("permission-denied", "Produto não pertence ao vendedor.");
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

exports.mercadopagoWebhook = onRequest(
  {secrets: [MP_WEBHOOK_SECRET]},
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    const secret = MP_WEBHOOK_SECRET.value();
    if (secret) {
      const xSignature = req.headers["x-signature"] || "";
      const xRequestId = req.headers["x-request-id"] || "";
      const dataId = req.query?.data_id || (req.body && req.body.data && req.body.data.id);
      const manifest = `id:${dataId};request-id:${xRequestId};ts:${(xSignature.split(",").find((p) => p.startsWith("ts=")) || "").split("=")[1] || ""}`;
      const hash = crypto
        .createHmac("sha256", secret)
        .update(manifest)
        .digest("hex");
      if (hash !== xSignature.split(",").find((p) => p.startsWith("v1="))?.split("=")[1]) {
        logger.warn("Invalid MP webhook signature");
        res.status(401).send("invalid signature");
        return;
      }
    }

    const type = req.query?.type || req.body?.type;
    const dataId = req.query?.data_id || req.body?.data?.id;
    if (type !== "payment" || !dataId) {
      res.status(200).send("ignored");
      return;
    }

    const accessToken = MP_ACCESS_TOKEN.value();
    const paymentResp = await fetch(
      `https://api.mercadopago.com/v1/payments/${dataId}`,
      {headers: {Authorization: `Bearer ${accessToken}`}},
    );
    if (!paymentResp.ok) {
      res.status(502).send("mp error");
      return;
    }
    const payment = await paymentResp.json();
    if (payment.status !== "approved") {
      res.status(200).send("not approved");
      return;
    }

    const externalRef = payment.external_reference;
    if (!externalRef) {
      res.status(200).send("no ref");
      return;
    }

    const pendingRef = db.collection("pending_payments").doc(externalRef);
    const pendingSnap = await pendingRef.get();
    if (!pendingSnap.exists) {
      res.status(200).send("unknown payment");
      return;
    }
    const pending = pendingSnap.data();
    if (pending.status === "paid") {
      res.status(200).send("already processed");
      return;
    }

    const uid = pending.uid;
    const tier = pending.tier;
    const tierInfo = TIER_PRICES[tier];
    if (!tierInfo) {
      res.status(200).send("unknown tier");
      return;
    }

    const profileRef = db.collection("profiles").doc(uid);
    const profileSnap = await profileRef.get();
    if (!profileSnap.exists) {
      res.status(200).send("no profile");
      return;
    }
    const profile = profileSnap.data();
    const productCount = profile.product_count || 0;

    const newLimit = productCount > 1000 ? -1 : tierInfo.limit;
    const now = admin.firestore.Timestamp.now();
    const periodEnd = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + 30 * 24 * 60 * 60 * 1000,
    );

    await profileRef.update({
      subscription_status: "active",
      current_period_end: periodEnd,
      plan: productCount > 1000 ? "pro" : "basic",
      product_limit: newLimit,
    });

    await applySoftLock(uid, newLimit);

    await pendingRef.update({
      status: "paid",
      paid_at: admin.firestore.FieldValue.serverTimestamp(),
      payment_id: payment.id,
    });

    res.status(200).send("ok");
  },
);

const PLAY_PRODUCT_TO_TIER = {
  "logiflow_basic_monthly": "basic",
  "logiflow_pro_monthly": "pro",
};

exports.verifyGooglePlayPurchase = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Faça login para continuar.");
  }
  const {productId, purchaseToken, orderId} = request.data || {};
  if (!productId || !purchaseToken) {
    throw new HttpsError("invalid-argument", "productId e purchaseToken são obrigatórios.");
  }
  const tier = PLAY_PRODUCT_TO_TIER[productId];
  if (!tier) {
    throw new HttpsError("invalid-argument", "Produto desconhecido.");
  }
  const tierInfo = TIER_PRICES[tier];

  const packageName = process.env.GCLOUD_PROJECT
    ? `${process.env.GCLOUD_PROJECT}.android`
    : null;
  if (!packageName) {
    throw new HttpsError("failed-precondition", "Pacote Android não configurado.");
  }

  const resp = await fetch(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`,
    {headers: {Authorization: `Bearer ${(await admin.credential.applicationDefault()).getAccessToken().then((t) => t.access_token)}`}},
  );
  if (!resp.ok) {
    logger.warn("Play verify failed", resp.status, await resp.text());
    throw new HttpsError("failed-precondition", "Compra não pôde ser verificada no Google Play.");
  }
  const sub = await resp.json();
  if (sub.paymentState === undefined) {
    throw new HttpsError("failed-precondition", "Pagamento ainda não confirmado.");
  }

  const uid = request.auth.uid;
  const profileRef = db.collection("profiles").doc(uid);
  const profileSnap = await profileRef.get();
  if (!profileSnap.exists) {
    throw new HttpsError("not-found", "Perfil não encontrado.");
  }
  const productCount = profileSnap.get("product_count") || 0;
  const newLimit = productCount > 1000 ? -1 : tierInfo.limit;
  const expiryMs = sub.expiryTimeMillis
    ? Number(sub.expiryTimeMillis)
    : Date.now() + 30 * 24 * 60 * 60 * 1000;

  await profileRef.update({
    subscription_status: "active",
    current_period_end: admin.firestore.Timestamp.fromMillis(expiryMs),
    plan: productCount > 1000 ? "pro" : "basic",
    product_limit: newLimit,
  });

  await applySoftLock(uid, newLimit);

  await db.collection("play_purchases").doc(`${uid}:${orderId || purchaseToken}`).set({
    uid,
    tier,
    product_id: productId,
    purchase_token: purchaseToken,
    order_id: orderId || null,
    expiry: admin.firestore.Timestamp.fromMillis(expiryMs),
    verified_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {ok: true, tier, current_period_end_ms: expiryMs};
});

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
      const data = doc.data();
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
