const { Sequelize } = require('sequelize');
const path = require('path');

// Determine storage path based on environment or default
const storagePath = process.env.DB_STORAGE || path.join(__dirname, '../../database.sqlite');

const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: storagePath,
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
});

module.exports = { sequelize };
