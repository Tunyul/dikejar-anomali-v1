const { sequelize, User, Wallet } = require('./models');
const bcrypt = require('bcrypt');
require('dotenv').config(); // Load env

async function seed() {
  try {
    await sequelize.authenticate();
    await sequelize.sync({ alter: true }); // Ensure tables exist!

    const salt = await bcrypt.genSalt(12);
    const passwordHash = await bcrypt.hash('password123', salt);

    const [user, created] = await User.findOrCreate({
      where: { username: 'gamer1' },
      defaults: {
        email: 'gamer1@example.com',
        password_hash: passwordHash,
        role: 'user',
        is_active: true
      }
    });

    if (created) {
      await Wallet.create({
        user_id: user.id,
        balance: 500000, // Bonus awal 500rb
        currency: 'IDR'
      });
      console.log('User "gamer1" created with password "password123"');
    } else {
      console.log('User "gamer1" already exists');
    }

  } catch (err) {
    console.error('Seed error:', err);
  } finally {
    await sequelize.close(); // Close connection so script exits
  }
}

seed();
