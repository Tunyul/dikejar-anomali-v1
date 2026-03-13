const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Wallet = sequelize.define('Wallet', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true, // One wallet per user
  },
  balance: {
    type: DataTypes.DECIMAL(15, 2), // Supports large numbers with precision
    defaultValue: 0.00,
    allowNull: false,
    validate: {
      min: 0, // Prevent negative balance at database level
    },
  },
  gems: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    allowNull: false,
    validate: {
      min: 0,
    },
  },
  currency: {
    type: DataTypes.STRING(3),
    defaultValue: 'IDR',
    allowNull: false,
  },
  is_locked: {
    type: DataTypes.BOOLEAN,
    defaultValue: false, // Security feature: lock wallet during suspicious activity
  }
}, {
  tableName: 'wallets',
  timestamps: true,
});

module.exports = Wallet;
