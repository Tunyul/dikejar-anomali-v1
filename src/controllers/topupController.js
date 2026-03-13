const { TopupTransaction, GrantLedger, Wallet, AuditLog, sequelize } = require('../models');
const crypto = require('crypto');
const products = require('../utils/products');

// --- Helper: Verify AirWallet Signature ---
const verifySignature = (payload, signature) => {
  // Pastikan Anda menyimpan AIRWALLET_SECRET_KEY di .env
  const secret = process.env.AIRWALLET_SECRET_KEY;
  if (!secret) return false;

  // Sesuaikan dengan format signature AirWallet (contoh umum: HMAC-SHA256 dari body)
  const hmac = crypto.createHmac('sha256', secret);
  const calculatedSignature = hmac.update(JSON.stringify(payload)).digest('hex');
  
  // Gunakan timingSafeEqual untuk mencegah timing attacks
  return crypto.timingSafeEqual(
    Buffer.from(signature), 
    Buffer.from(calculatedSignature)
  );
};

// --- 1. Create Top-up Order ---
exports.createOrder = async (req, res) => {
  const { product_id, payment_method } = req.body;
  const userId = req.user.id; // Dari JWT

  // Validate Product
  const product = products.find(p => p.id === product_id);
  if (!product) {
      return res.status(400).json({ error: 'Invalid Product ID' });
  }

  const t = await sequelize.transaction();

  try {
    // Generate Order ID Unik
    const orderId = `TOPUP-${Date.now()}-${userId}`;

    // Buat Transaksi Pending
    // Amount is the Price (IDR)
    const transaction = await TopupTransaction.create({
      user_id: userId,
      order_id: orderId,
      amount: product.price, 
      status: 'pending',
      payment_method: payment_method || 'airwallet',
      metadata: JSON.stringify({ 
          provider: 'airwallet',
          product_id: product.id,
          product_name: product.name,
          gems_amount: product.amount
      })
    }, { transaction: t });

    // Log Audit
    await AuditLog.create({
      user_id: userId,
      action: 'TOPUP_INIT',
      entity_type: 'TopupTransaction',
      entity_id: orderId,
      changes: JSON.stringify({ product_id, amount: product.price }),
      ip_address: req.ip
    }, { transaction: t });

    await t.commit();

    // Di sini kita akan mengembalikan data yang dibutuhkan Frontend 
    // untuk redirect ke halaman pembayaran AirWallet
    // Biasanya berupa Payment URL atau Token
    
    // Simulasi Response AirWallet (Nanti diganti integrasi real)
    res.status(201).json({
      message: 'Order berhasil dibuat',
      data: {
        order_id: orderId,
        amount: product.price,
        payment_url: `https://airwallet-dummy-url.com/pay?order_id=${orderId}` // Placeholder
      }
    });

  } catch (error) {
    await t.rollback();
    console.error('Create Order Error:', error);
    res.status(500).json({ error: 'Gagal membuat order top-up' });
  }
};

// --- 2. Webhook Handler (Menerima Callback dari AirWallet) ---
exports.handleWebhook = async (req, res) => {
  const payload = req.body;
  const signature = req.headers['x-airwallet-signature']; // Sesuaikan header dari dokumentasi AirWallet

  // 1. Validasi Signature (Security)
  // ENABLED FOR PRODUCTION
  // if (!verifySignature(payload, signature)) {
  //   return res.status(403).json({ error: 'Invalid Signature' });
  // }

  // Asumsi payload dari AirWallet: { reference_id: 'TOPUP-xxx', status: 'PAID', amount: 10000 }
  const { reference_id, status, amount } = payload; 
  
  console.log(`Webhook received: ${reference_id} - ${status}`);

  // Idempotency Check: Cek apakah transaksi ini sudah diproses sebelumnya
  const transaction = await TopupTransaction.findOne({ 
    where: { order_id: reference_id } 
  });

  if (!transaction) {
    return res.status(404).json({ error: 'Transaksi tidak ditemukan' });
  }

  if (transaction.status === 'success') {
    return res.status(200).json({ message: 'Transaksi sudah diproses sebelumnya' });
  }

  const t = await sequelize.transaction();

  try {
    if (status === 'PAID' || status === 'SUCCESS') {
      // 2. Update Status Transaksi
      transaction.status = 'success';
      transaction.external_ref = payload.transaction_id || 'airwallet-ref';
      await transaction.save({ transaction: t });

      // 3. Tambah Saldo User (Grant Balance/Gems)
      const wallet = await Wallet.findOne({ where: { user_id: transaction.user_id } });
      
      const metadata = JSON.parse(transaction.metadata || '{}');
      let grantAmount = 0;
      let grantType = 'balance'; // default

      if (metadata.product_id) {
          // It's a product purchase (Gems)
          const product = products.find(p => p.id === metadata.product_id);
          if (product) {
              grantAmount = product.amount;
              grantType = 'gems';
              await wallet.increment('gems', { by: grantAmount, transaction: t });
          } else {
              // Fallback if product not found in list (deprecated product?)
              // Use metadata backup if available
              grantAmount = metadata.gems_amount || 0;
              grantType = 'gems';
              await wallet.increment('gems', { by: grantAmount, transaction: t });
          }
      } else {
          // Legacy or Direct Balance Topup
          grantAmount = amount; // Money
          await wallet.increment('balance', { by: grantAmount, transaction: t });
      }

      // 4. Catat di Ledger (PENTING: Mencegah double insert)
      await GrantLedger.create({
        transaction_id: transaction.id,
        wallet_id: wallet.id,
        amount: grantAmount,
        type: 'credit',
        reference: `TOPUP_AIRWALLET_${reference_id}`,
        description: `Top-up ${grantType} via AirWallet`
      }, { transaction: t });

      // 5. Audit Log
      await AuditLog.create({
        user_id: transaction.user_id,
        action: 'TOPUP_SUCCESS',
        entity_type: 'Wallet',
        entity_id: wallet.id.toString(),
        changes: JSON.stringify({ amount_added: grantAmount, type: grantType }),
        ip_address: req.ip
      }, { transaction: t });

    } else if (status === 'FAILED' || status === 'EXPIRED') {
        transaction.status = 'failed';
        await transaction.save({ transaction: t });
    }

    await t.commit();
    res.status(200).json({ status: 'ok' });

  } catch (error) {
    await t.rollback();
    console.error('Webhook Error:', error);
    
    // Jika duplicate entry ledger (race condition), tetap return 200 agar AirWallet tidak retry terus
    if (error.name === 'SequelizeUniqueConstraintError') {
       return res.status(200).json({ message: 'Event already processed' });
    }

    res.status(500).json({ error: 'Internal Server Error' });
  }
};
