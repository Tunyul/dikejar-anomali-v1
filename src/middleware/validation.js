const { body } = require('express-validator');

const registerValidation = [
  body('email').isEmail().withMessage('Format email tidak valid'),
  body('username')
    .isLength({ min: 3 })
    .withMessage('Username minimal 3 karakter')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username hanya boleh huruf, angka, dan underscore'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password minimal 6 karakter'),
];

const loginValidation = [
  body('identifier').notEmpty().withMessage('Email atau Username wajib diisi'),
  body('password').notEmpty().withMessage('Password wajib diisi'),
];

module.exports = {
  registerValidation,
  loginValidation,
};
