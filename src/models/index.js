const { sequelize } = require('../config/database');
const User = require('./User');
const Wallet = require('./Wallet');
const TopupTransaction = require('./TopupTransaction');
const GrantLedger = require('./GrantLedger');
const AuditLog = require('./AuditLog');

// Define Associations

// User <-> Wallet (One-to-One)
User.hasOne(Wallet, { foreignKey: 'user_id', as: 'wallet' });
Wallet.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// User <-> TopupTransaction (One-to-Many)
User.hasMany(TopupTransaction, { foreignKey: 'user_id', as: 'transactions' });
TopupTransaction.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// TopupTransaction <-> GrantLedger (One-to-One)
// A transaction should only result in one ledger entry for the grant
TopupTransaction.hasOne(GrantLedger, { foreignKey: 'transaction_id', as: 'ledger_entry' });
GrantLedger.belongsTo(TopupTransaction, { foreignKey: 'transaction_id', as: 'transaction' });

// Wallet <-> GrantLedger (One-to-Many)
Wallet.hasMany(GrantLedger, { foreignKey: 'wallet_id', as: 'ledger_entries' });
GrantLedger.belongsTo(Wallet, { foreignKey: 'wallet_id', as: 'wallet' });

// User <-> AuditLog (One-to-Many)
User.hasMany(AuditLog, { foreignKey: 'user_id', as: 'audit_logs' });
AuditLog.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

module.exports = {
  sequelize,
  User,
  Wallet,
  TopupTransaction,
  GrantLedger,
  AuditLog
};
