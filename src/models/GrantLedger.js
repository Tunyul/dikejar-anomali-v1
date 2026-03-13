const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const GrantLedger = sequelize.define('GrantLedger', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  transaction_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true, // CRITICAL: Prevent double granting for same transaction
  },
  wallet_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  amount: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: false,
  },
  type: {
    type: DataTypes.ENUM('credit', 'debit'),
    allowNull: false,
  },
  reference: {
    type: DataTypes.STRING, // e.g., "topup_123" or "admin_adjustment"
    allowNull: false,
  },
  description: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'grant_ledger',
  timestamps: true, // created_at is sufficient
  updatedAt: false, // Ledger should be immutable mostly
});

module.exports = GrantLedger;
