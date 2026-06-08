const crypto = require("crypto");
const db = require("../db");

async function handleWebhook(req, res) {
  const provider = req.params.provider;
  const payload = req.body;
  const signature = req.headers["x-webhook-signature"];
  const timestamp = req.headers["x-webhook-timestamp"];

  if (
    !validateSignature(provider, JSON.stringify(payload), signature, timestamp)
  ) {
    return res.status(401).json({ error: "invalid_signature" });
  }

  if (Date.now() - new Date(timestamp).getTime() > 300000) {
    return res.status(401).json({ error: "expired_webhook" });
  }

  const externalOrderId = payload.order_id;
  const providerTxnId = payload.transaction_id;
  const status = payload.status;

  if (status !== "paid") {
    return res.status(200).json({ status: "ignored" });
  }

  const client = await db.connect();
  try {
    await client.query("BEGIN");

    const txnRes = await client.query(
      "SELECT id, user_id, status, product_id FROM topup_transactions WHERE external_order_id = $1 FOR UPDATE",
      [externalOrderId],
    );

    if (txnRes.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ error: "transaction_not_found" });
    }

    const txn = txnRes.rows[0];
    if (txn.status === "paid") {
      await client.query("ROLLBACK");
      return res.status(200).json({ status: "already_processed" });
    }

    await client.query(
      "UPDATE topup_transactions SET status = $1, provider_txn_id = $2, updated_at = NOW() WHERE id = $3",
      ["paid", providerTxnId, txn.id],
    );

    const productRes = await client.query(
      "SELECT grants_json FROM products WHERE id = $1",
      [txn.product_id],
    );
    const grants = productRes.rows[0].grants_json;
    const grantKey = `grant:web:${externalOrderId}`;

    const grantRes = await client.query(
      `INSERT INTO grant_ledger (id, transaction_id, grant_key, coins_delta, gems_delta, applied_at)
             VALUES (gen_random_uuid(), $1, $2, $3, $4, NOW())
             ON CONFLICT (transaction_id) DO NOTHING
             RETURNING id`,
      [txn.id, grantKey, grants.coins || 0, grants.gems || 0],
    );

    if (grantRes.rows.length > 0) {
      await client.query(
        `INSERT INTO wallets (user_id, coins, gems, updated_at)
                 VALUES ($1, $2, $3, NOW())
                 ON CONFLICT (user_id) DO UPDATE
                 SET coins = wallets.coins + EXCLUDED.coins,
                     gems = wallets.gems + EXCLUDED.gems,
                     updated_at = NOW()`,
        [txn.user_id, grants.coins || 0, grants.gems || 0],
      );
    }

    await client.query("COMMIT");
    return res.status(200).json({ status: "success" });
  } catch (error) {
    await client.query("ROLLBACK");
    return res.status(500).json({ error: "internal_error" });
  } finally {
    client.release();
  }
}

function validateSignature(provider, rawBody, signature, timestamp) {
  const secret = process.env[`WEBHOOK_SECRET_${provider.toUpperCase()}`];
  if (!secret) return false;
  const expected = crypto
    .createHmac("sha256", secret)
    .update(`${timestamp}.${rawBody}`)
    .digest("hex");
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
}

module.exports = { handleWebhook };
