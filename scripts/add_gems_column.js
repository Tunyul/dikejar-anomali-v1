const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, '../database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log('Adding gems column to wallets table...');

db.serialize(() => {
    // Check if column exists first to avoid error
    db.all("PRAGMA table_info(wallets)", [], (err, columns) => {
        if (err) {
            console.error('Error getting table info:', err);
            return;
        }
        
        const hasGems = columns.some(c => c.name === 'gems');
        if (hasGems) {
            console.log('Column "gems" already exists.');
        } else {
            console.log('Column "gems" missing. Adding it...');
            // Add column
            // Default value 0, NOT NULL constraint might be tricky if table has data, but SQLite supports ADD COLUMN with DEFAULT.
            db.run("ALTER TABLE wallets ADD COLUMN gems INTEGER NOT NULL DEFAULT 0", (err) => {
                if (err) {
                    console.error('Error adding column:', err);
                } else {
                    console.log('Successfully added "gems" column.');
                }
            });
        }
    });
});

setTimeout(() => {
    db.close();
}, 1000);
