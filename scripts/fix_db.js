const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, '../database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log('Checking for backup tables...');
db.serialize(() => {
    db.all("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%_backup'", [], (err, tables) => {
        if (err) {
            console.error('Error listing tables:', err);
            return;
        }

        if (tables.length === 0) {
            console.log('No backup tables found.');
        } else {
            console.log('Found backup tables:', tables.map(t => t.name));
            tables.forEach(t => {
                db.run(`DROP TABLE IF EXISTS ${t.name}`, (err) => {
                    if (err) console.error(`Error dropping ${t.name}:`, err);
                    else console.log(`Dropped ${t.name}`);
                });
            });
        }
    });
});
// db.close() will happen when process exits or garbage collected, or I can call it inside callback if I nest properly.
// But for a short script, letting process exit is fine. 
// Actually, let's just close it in a timeout or not at all.
// Or better:
setTimeout(() => {
    db.close((err) => {
        if (err) console.error('Error closing DB:', err);
        else console.log('Database connection closed.');
    });
}, 1000);
