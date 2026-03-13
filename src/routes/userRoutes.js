const express = require('express');
const router = express.Router();
const { verifyToken } = require('../utils/auth');
const { Wallet, User } = require('../models');

const { Op } = require('sequelize');

// Check User Exists (Public Endpoint for Topup Validation)
router.get('/check/:identifier', async (req, res) => {
  try {
    const { identifier } = req.params;
    
    // Cari user berdasarkan ID atau Username
    // Asumsi identifier bisa ID (integer) atau username (string)
    const user = await User.findOne({
      where: {
        [Op.or]: [
            { id: identifier },
            { username: identifier }
        ]
      },
      attributes: ['id', 'username'] // Only return necessary fields
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.json({
      valid: true,
      username: user.username,
      id: user.id
    });
  } catch (error) {
    console.error('Check User Error:', error);
    return res.status(500).json({ error: 'Server Error' });
  }
});

// Get User Profile & Wallet
router.get('/wallet', verifyToken, async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ where: { user_id: req.user.id } });
    if (!wallet) return res.status(404).json({ error: 'Wallet not found' });
    
    res.json({
      balance: wallet.balance,
      gems: wallet.gems,
      currency: wallet.currency
    });
  } catch (error) {
    res.status(500).json({ error: 'Server Error' });
  }
});

module.exports = router;
