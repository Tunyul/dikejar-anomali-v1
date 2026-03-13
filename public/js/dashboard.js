const API_URL = '/api/v1';
const token = localStorage.getItem('token');

if (!token) {
    window.location.href = 'login.html';
}

// Load Initial Data
document.addEventListener('DOMContentLoaded', () => {
    const user = JSON.parse(localStorage.getItem('user'));
    if (user) {
        document.getElementById('usernameDisplay').innerText = (user.username || 'PLAYER').toUpperCase();
    }
    
    fetchWallet();
    fetchTransactions();
});

// Expose fetchTransactions globally for the refresh button
window.loadTransactions = fetchTransactions;

async function fetchWallet() {
    try {
        const res = await fetch(`${API_URL}/users/wallet`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (res.ok) {
            const data = await res.json();
            // Backend now returns gems!
            const coins = data.balance || 0;
            const gems = data.gems || 0;

            animateValue('coinBalanceDisplay', 0, coins, 1000);
            animateValue('gemBalanceDisplay', 0, gems, 1000);
        } else {
            console.error('Failed to fetch wallet');
        }
    } catch (err) {
        console.error('Wallet fetch error', err);
    }
}

async function fetchTransactions() {
    const list = document.getElementById('transactionList');
    list.innerHTML = '<li style="text-align: center; color: var(--text-muted); padding: 1rem;">Loading...</li>';

    try {
        // Try to fetch real transactions if endpoint exists, otherwise show placeholder
        // currently backend doesn't seem to have /transactions endpoint
        // const res = await fetch(`${API_URL}/users/transactions`, { ... });
        
        // Mock data for now to match UI spec
        const mockTransactions = [
            { id: 'tx_1', type: 'TOPUP', amount: 100, currency: 'GEMS', date: '2023-10-25', status: 'SUCCESS' },
            { id: 'tx_2', type: 'GAME_REWARD', amount: 500, currency: 'COINS', date: '2023-10-24', status: 'SUCCESS' }
        ];

        setTimeout(() => {
            renderTransactions(mockTransactions);
        }, 500);

    } catch (err) {
        list.innerHTML = '<li style="text-align: center; color: var(--danger);">Failed to load history</li>';
    }
}

function renderTransactions(transactions) {
    const list = document.getElementById('transactionList');
    if (transactions.length === 0) {
        list.innerHTML = '<li style="text-align: center; color: var(--text-muted); padding: 1rem;">No transactions found</li>';
        return;
    }

    list.innerHTML = transactions.map(tx => {
        const isGem = tx.currency === 'GEMS';
        const icon = isGem ? '<i class="fa-solid fa-gem" style="color: #00AEEF;"></i>' : '<i class="fa-solid fa-coins" style="color: #FFCC00;"></i>';
        
        return `
        <li class="transaction-item">
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="width: 40px; height: 40px; background: #f0f0f0; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 2px solid black;">
                    ${icon}
                </div>
                <div>
                    <div style="font-weight: bold; color: var(--text-main); font-family: 'Fredoka', sans-serif;">${tx.type.replace('_', ' ')}</div>
                    <small style="color: var(--text-muted);">${tx.date}</small>
                </div>
            </div>
            <div style="text-align: right;">
                <div style="color: ${isGem ? 'var(--secondary)' : 'var(--primary)'}; font-weight: bold; font-family: 'Fredoka', sans-serif; -webkit-text-stroke: 0.5px black;">
                    + ${tx.amount} ${isGem ? 'Permata' : 'Koin'}
                </div>
                <small style="color: green; font-weight: bold;">${tx.status === 'SUCCESS' ? 'Berhasil' : tx.status}</small>
            </div>
        </li>
    `}).join('');
}

function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = 'login.html';
}

// Utility: Number Animation
function animateValue(id, start, end, duration) {
    const obj = document.getElementById(id);
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        const value = Math.floor(progress * (end - start) + start);
        obj.innerHTML = value.toLocaleString('id-ID');
        if (progress < 1) {
            window.requestAnimationFrame(step);
        }
    };
    window.requestAnimationFrame(step);
}
