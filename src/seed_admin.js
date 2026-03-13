const { sequelize, User, Wallet } = require('./models');
const bcrypt = require('bcrypt');
require('dotenv').config();

async function seed() {
  try {
    await sequelize.authenticate();
    // SKIP sync({alter:true}) karena menyebabkan konflik di SQLite saat tabel sudah ada data
    // await sequelize.sync({ alter: true }); 

    const salt = await bcrypt.genSalt(12);
    // Password khusus untuk admin: ano8899
    const passwordHash = await bcrypt.hash('ano8899', salt);

    // Cek manual apakah user sudah ada
    let user = await User.findOne({ where: { username: 'rush1111' } });

    if (!user) {
        // Buat User Baru
        user = await User.create({
            username: 'rush1111',
            email: 'admin@anomali-rush.com',
            password_hash: passwordHash,
            role: 'admin',
            is_active: true
        });

        // Buat Wallet Baru
        await Wallet.create({
            user_id: user.id,
            balance: 999999999, // Saldo Sultan
            currency: 'IDR'
        });

        console.log('✅ Admin "rush1111" created successfully!');
    } else {
        console.log('⚠️ Admin "rush1111" already exists. Updating password...');
        
        // Update password & role
        user.password_hash = passwordHash;
        user.role = 'admin';
        await user.save();
        console.log('🔄 Password updated for "rush1111".');
    }

    console.log('🔑 Pass: ano8899');

  } catch (err) {
    console.error('❌ Seed error:', err);
  } finally {
    await sequelize.close();
  }
}

seed();
