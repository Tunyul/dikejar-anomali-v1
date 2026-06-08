const { google } = require("googleapis");
const db = require("../db");

const auth = new google.auth.GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/androidpublisher"],
});

const androidPublisher = google.androidpublisher({
  version: "v3",
  auth: auth,
});

async function verifyGooglePurchase(req, res) {
  const { product_id, purchase_token, game_user_id } = req.body;
  const packageName = process.env.GOOGLE_PLAY_PACKAGE_NAME;

  if (!product_id || !purchase_token || !game_user_id || !packageName) {
    return res.status(400).json({ error: "missing_parameters" });
  }

  try {
    const response = await androidPublisher.purchases.products.get({
      packageName: packageName,
      productId: product_id,
      token: purchase_token,
    });

    const purchase = response.data;
    if (purchase.purchaseState !== 0) {
      return res.status(400).json({ error: "invalid_purchase_state" });
    }

    const externalOrderId = purchase.orderId || purchase_token;
    const client = await db.connect();

    try {
      await client.query("BEGIN");

      const userRes = await client.query(
        "SELECT id FROM users WHERE game_user_id = $1",
        [game_user_id],
      );
      if (userRes.rows.length === 0) {
        await client.query("ROLLBACK");
        return res.status(404).json({ error: "user_not_found" });
      }
      const userId = userRes.rows[0].id;

      let txnRes = await client.query(
        "SELECT id, status FROM topup_transactions WHERE external_order_id = $1 FOR UPDATE",
        [externalOrderId],
      );

      let txnId;
      if (txnRes.rows.length === 0) {
        const newTxn = await client.query(
          `INSERT INTO topup_transactions (user_id, product_id, channel, provider, provider_txn_id, external_order_id, status, amount)
                     VALUES ($1, $2, 'google_play', 'google', $3, $4, 'paid', 0) RETURNING id`,
          [userId, product_id, purchase_token, externalOrderId],
        );
        txnId = newTxn.rows[0].id;
      } else {
        const txn = txnRes.rows[0];
        if (txn.status === "paid") {
          await client.query("ROLLBACK");
          return res.status(200).json({ status: "already_processed" });
        }
        await client.query(
          "UPDATE topup_transactions SET status = $1, provider_txn_id = $2 WHERE id = $3",
          ["paid", purchase_token, txn.id],
        );
        txnId = txn.id;
      }

      const productRes = await client.query(
        "SELECT grants_json FROM products WHERE id = $1",
        [product_id],
      );
      const grants = productRes.rows[0].grants_json;
      const grantKey = `grant:google:${externalOrderId}`;

      const grantRes = await client.query(
        `INSERT INTO grant_ledger (transaction_id, grant_key, coins_delta, gems_delta, applied_at)
                 VALUES ($1, $2, $3, $4, NOW()) ON CONFLICT (transaction_id) DO NOTHING RETURNING id`,
        [txnId, grantKey, grants.coins || 0, grants.gems || 0],
      );

      if (grantRes.rows.length > 0) {
        await client.query(
          `INSERT INTO wallets (user_id, coins, gems, updated_at)
                     VALUES ($1, $2, $3, NOW())
                     ON CONFLICT (user_id) DO UPDATE
                     SET coins = wallets.coins + EXCLUDED.coins,
                         gems = wallets.gems + EXCLUDED.gems,
                         updated_at = NOW()`,
          [userId, grants.coins || 0, grants.gems || 0],
        );
      }

      if (purchase.acknowledgementState === 0) {
        await androidPublisher.purchases.products.acknowledge({
          packageName: packageName,
          productId: product_id,
          token: purchase_token,
        });
      }

      await client.query("COMMIT");
      return res.status(200).json({ status: "success" });
    } catch (dbErr) {
      await client.query("ROLLBACK");
      throw dbErr;
    } finally {
      client.release();
    }
  } catch (error) {
    return res.status(500).json({ error: "verification_failed" });
  }
}

module.exports = { verifyGooglePurchase };
