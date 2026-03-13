const { User, Wallet, AuditLog, sequelize } = require('../models');
const bcrypt = require('bcrypt');
const { generateTokens } = require('../utils/auth');
const { validationResult } = require('express-validator');

exports.register = async (req, res) => {
  // Validasi Input
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email, username, password } = req.body;
  const t = await sequelize.transaction();

  try {
    // 1. Cek duplikasi
    const existingUser = await User.findOne({
      where: sequelize.or({ email }, { username }),
      transaction: t // Optimization: check within transaction context isn't strictly necessary but good practice
    });

    if (existingUser) {
      await t.rollback();
      return res.status(409).json({ error: 'Email atau Username sudah digunakan.' });
    }

    // 2. Hash Password
    const salt = await bcrypt.genSalt(12);
    const password_hash = await bcrypt.hash(password, salt);

    // 3. Buat User
    const newUser = await User.create({
      email,
      username,
      password_hash,
    }, { transaction: t });

    // 4. Buat Wallet (Otomatis saat registrasi - UX Friendly)
    await Wallet.create({
      user_id: newUser.id,
      balance: 0,
    }, { transaction: t });

    // 5. Catat Audit Log
    await AuditLog.create({
      user_id: newUser.id,
      action: 'REGISTER',
      entity_type: 'User',
      entity_id: newUser.id.toString(),
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
    }, { transaction: t });

    await t.commit();

    // Auto-login setelah register (Opsional, tapi bagus untuk UX Game)
    const tokens = generateTokens(newUser);

    res.status(201).json({
      message: 'Registrasi berhasil',
      user: {
        id: newUser.id,
        username: newUser.username,
        email: newUser.email,
      },
      ...tokens,
    });

  } catch (error) {
    await t.rollback();
    console.error('Register Error:', error);
    res.status(500).json({ error: 'Terjadi kesalahan internal server' });
  }
};

exports.login = async (req, res) => {
  const { identifier, password } = req.body;

  try {
    // Login bisa pakai Email atau Username (Fleksibel)
    const user = await User.findOne({
      where: sequelize.or({ email: identifier }, { username: identifier })
    });

    if (!user) {
      return res.status(401).json({ error: 'Kredensial salah' });
    }

    const isValid = await user.checkPassword(password);
    if (!isValid) {
      return res.status(401).json({ error: 'Kredensial salah' });
    }

    const tokens = generateTokens(user);

    // Audit Login
    await AuditLog.create({
      user_id: user.id,
      action: 'LOGIN',
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
    });

    res.json({
      message: 'Login berhasil',
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
      },
      ...tokens,
    });

  } catch (error) {
    console.error('Login Error:', error);
    res.status(500).json({ error: 'Terjadi kesalahan internal server' });
  }
};
