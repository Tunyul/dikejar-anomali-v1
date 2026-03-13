const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const AuditLog = sequelize.define('AuditLog', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Nullable because some actions might be system actions or pre-login
  },
  action: {
    type: DataTypes.STRING,
    allowNull: false, // e.g., 'LOGIN', 'TOPUP_INIT', 'WALLET_DEBIT'
  },
  entity_type: {
    type: DataTypes.STRING, // e.g., 'User', 'Wallet', 'Transaction'
    allowNull: true,
  },
  entity_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  changes: {
    type: DataTypes.TEXT, // JSON string of before/after or details
    allowNull: true,
  },
  ip_address: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  user_agent: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'audit_logs',
  timestamps: true,
  updatedAt: false, // Logs are immutable
});

module.exports = AuditLog;
