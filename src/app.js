const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { validationResult } = require('express-validator');
const path = require('path');
const i18next = require('./config/i18n');
const i18nextMiddleware = require('i18next-http-middleware');

const app = express();

// Security Middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable CSP for development to allow inline scripts/styles if needed
}));
app.use(cors());
app.use(express.json());
app.use(i18nextMiddleware.handle(i18next)); // i18n middleware
app.use(express.static(path.join(__dirname, '../public'))); // Serve static files

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Rate Limiting (Global)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date() });
});

// Test Language Route
app.get('/api/test-language', (req, res) => {
  res.json({ 
    message: req.t('welcome'),
    language: req.language 
  });
});

// Routes (Placeholders)
const authRoutes = require('./routes/authRoutes');
const topupRoutes = require('./routes/topupRoutes');
const userRoutes = require('./routes/userRoutes');
const productRoutes = require('./routes/productRoutes');

// Version 1 API
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/topup', topupRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/products', productRoutes);

// Legacy support (optional, or just break it to force update)
// app.use('/api/auth', authRoutes); 


// 404 Handler
app.use((req, res, next) => {
  res.status(404).json({ error: 'Not Found' });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

module.exports = app;
