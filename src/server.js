require('dotenv').config();
const app = require('./app');
const { sequelize } = require('./models'); // Import from models/index.js to get associations

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // Test Database Connection
    await sequelize.authenticate();
    console.log('Database connection has been established successfully.');

    // Sync Database (in development)
    if (process.env.NODE_ENV === 'development') {
        // HACK: SQLite sync({alter:true}) sering konflik jika tabel sudah ada data
        // Kita disable dulu karena tabel sudah terbentuk sempurna
        // await sequelize.sync({ alter: true }); 
        console.log('Database synced (Skipped to prevent SQLite lock).');
    }

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    process.exit(1);
  }
}

startServer();
