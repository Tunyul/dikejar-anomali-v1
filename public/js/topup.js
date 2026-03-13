const API_URL = '/api/v1'; // Updated API Version
const token = localStorage.getItem('token');
let selectedProductId = null;
let selectedProductPrice = 0;
let selectedPayment = 'qris';
let isValidUser = false;

// Auto-fill ID if logged in
document.addEventListener('DOMContentLoaded', () => {
    renderAuthSection();
    fetchProducts();
});

function renderAuthSection() {
    const section = document.getElementById('navAuthSection');
    if (!section) return; 
    const user = JSON.parse(localStorage.getItem('user'));

    if (user) {
        section.innerHTML = `
            <a href="index.html" class="btn btn-secondary" style="font-size: 0.9rem; border-radius: 4px; margin-right: 10px; background: #e63946; color: white; border: none;">HOME</a>
            <span style="margin-right: 10px; font-weight: bold; color: #333;">${user.username}</span>
            <button onclick="logout()" class="btn btn-secondary" style="font-size: 0.9rem; padding: 5px 10px;">Keluar</button>
        `;
        document.getElementById('targetUserId').value = user.id;
        validateUser();
    } else {
        section.innerHTML = `
            <a href="index.html" class="btn btn-secondary" style="font-size: 0.9rem; border-radius: 4px; margin-right: 10px; background: #e63946; color: white; border: none;">HOME</a>
            <a href="login.html" class="btn btn-primary" style="font-size: 0.9rem; border-radius: 4px;">Login</a>
        `;
    }
}

function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.reload();
}

async function validateUser() {
    const targetInput = document.getElementById('targetUserId');
    const resultDiv = document.getElementById('validationResult');
    const userId = targetInput.value;

    if (!userId) {
        resultDiv.classList.add('hidden');
        return;
    }

    resultDiv.classList.remove('hidden');
    resultDiv.innerHTML = 'Checking...';
    resultDiv.className = 'validation-status'; 

    try {
        const response = await fetch(`${API_URL}/users/check/${userId}`);
        const data = await response.json();

        if (response.ok) {
            isValidUser = true;
            const displayName = data.username || `User${data.id}`;
            resultDiv.innerHTML = `✅ Account Found: ${displayName}`;
            resultDiv.classList.add('status-valid');
        } else {
            isValidUser = false;
            resultDiv.innerHTML = `❌ User Not Found`;
            resultDiv.classList.add('status-invalid');
        }
    } catch (err) {
        console.error(err);
        resultDiv.innerHTML = `⚠️ Error Checking User`;
        resultDiv.classList.add('status-invalid');
    }
}

async function fetchProducts() {
    try {
        const res = await fetch(`${API_URL}/products`);
        if (res.ok) {
            const products = await res.json();
            renderProducts(products);
        } else {
            console.error('Failed to fetch products');
        }
    } catch (err) {
        console.error('Fetch products error:', err);
    }
}

function renderProducts(products) {
    const grid = document.getElementById('productsGrid');
    grid.innerHTML = ''; // Clear loading

    products.forEach(product => {
        const card = document.createElement('div');
        card.className = 'item-card';
        card.onclick = () => selectItem(card, product.id, product.price);
        
        // Ribbon logic
        let ribbon = '';
        if (product.bonus) {
            ribbon = `<div class="ribbon">${product.bonus}</div>`;
        }

        card.innerHTML = `
            ${ribbon}
            <div class="item-icon">${product.icon}</div>
            <div class="item-amount">${product.name}</div>
            <div class="item-price">Rp ${product.price.toLocaleString('id-ID')}</div>
        `;
        grid.appendChild(card);
    });
}

function selectItem(element, productId, price) {
    selectedProductId = productId;
    selectedProductPrice = price;
    // Reset classes
    document.querySelectorAll('.item-card').forEach(el => el.classList.remove('selected'));
    // Add selected
    element.classList.add('selected');
}

function selectPayment(element, method) {
    selectedPayment = method;
    document.querySelectorAll('.payment-option').forEach(el => el.classList.remove('selected'));
    element.classList.add('selected');
}

async function processTopup() {
    if (!token) {
        alert('Silakan Login terlebih dahulu untuk melakukan Top Up!');
        window.location.href = 'login.html';
        return;
    }

    if (!isValidUser) {
        alert('Please validate User ID first!');
        document.getElementById('targetUserId').focus();
        return;
    }
    if (!selectedProductId) {
        alert('Please select a package!');
        return;
    }

    const confirmMsg = `
    CONFIRM PURCHASE
    ----------------
    User ID: ${document.getElementById('targetUserId').value}
    Item: ${selectedProductId}
    Price: Rp ${selectedProductPrice.toLocaleString()}
    Payment: ${selectedPayment.toUpperCase()}
    
    Proceed?
    `;

    if (!confirm(confirmMsg)) return;

    try {
        const res = await fetch(`${API_URL}/topup/create-order`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ 
                product_id: selectedProductId,
                payment_method: selectedPayment
            })
        });

        const data = await res.json();
        if (res.ok) {
            alert(`Order Created! ID: ${data.data.order_id}\nRedirecting to AirWallet...`);
            console.log('Redirecting to payment provider...');
            
            // Simulate redirect 
            alert('Payment simulation: Success! Gems added.');
            
            // Simulate Webhook Call (For Development/Demo purpose only!)
            // In real world, this is done by Payment Gateway server-to-server
            await simulateWebhook(data.data.order_id, data.data.amount);

            window.location.href = 'dashboard.html';
        } else {
            alert('Error: ' + data.error);
        }
    } catch (err) {
        console.error(err);
        alert('Transaction Failed');
    }
}

// Helper to simulate webhook for immediate feedback in demo
async function simulateWebhook(orderId, amount) {
    try {
        await fetch(`${API_URL}/topup/webhook`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                reference_id: orderId,
                status: 'PAID',
                amount: amount,
                transaction_id: `SIM-${Date.now()}`
            })
        });
    } catch (e) {
        console.log('Webhook simulation failed', e);
    }
}
