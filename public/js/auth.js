const API_URL = '/api/v1';

document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const identifier = document.getElementById('identifier').value;
    const password = document.getElementById('password').value;
    const errorMsg = document.getElementById('errorMsg');

    try {
        const res = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ identifier, password })
        });

        const data = await res.json();

        if (res.ok) {
            // Simpan token
            localStorage.setItem('token', data.accessToken);
            localStorage.setItem('user', JSON.stringify(data.user));
            // Check if there is a redirect URL
            const urlParams = new URLSearchParams(window.location.search);
            const redirect = urlParams.get('redirect');
            window.location.href = redirect || 'dashboard.html';
        } else {
            errorMsg.innerText = data.error || 'Login gagal';
            errorMsg.style.display = 'block';
        }
    } catch (err) {
        console.error(err);
        errorMsg.innerText = 'Server Error';
        errorMsg.style.display = 'block';
    }
});

function toggleAuthMode() {
    alert('Fitur Register via Frontend akan segera hadir! Gunakan API Postman untuk register user pertama.');
}
