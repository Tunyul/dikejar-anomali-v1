const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const TopupTransaction = sequelize.define('TopupTransaction', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  order_id: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true, // Important for idempotency
  },
  amount: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: false,
  },
  currency: {
    type: DataTypes.STRING(3),
    defaultValue: 'IDR',
  },
  status: {
    type: DataTypes.ENUM('pending', 'success', 'failed', 'expired'),
    defaultValue: 'pending',
  },
  payment_method: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  external_ref: {
    type: DataTypes.STRING, // Reference from payment gateway
    allowNull: true,
  },
  metadata: {
    type: DataTypes.TEXT, // JSON string for extra data
    allowNull: true,
  },
}, {
  tableName: 'topup_transactions',
  timestamps: true,
  indexes: [
    {
      unique: true,
      fields: ['order_id']
    },
    {
      fields: ['user_id', 'status']
    }
  ]
});

module.exports = TopupTransaction;
