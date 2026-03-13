const express = require('express');
const router = express.Router();
const topupController = require('../controllers/topupController');
const { verifyToken } = require('../utils/auth');

// Endpoint untuk User membuat order (Butuh Login)
router.post('/create-order', verifyToken, topupController.createOrder);

// Endpoint untuk Webhook (Dipanggil oleh Server AirWallet, tidak butuh login user tapi butuh validasi signature)
router.post('/webhook', topupController.handleWebhook);

module.exports = router;
