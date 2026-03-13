document.addEventListener('DOMContentLoaded', () => {
    // 1. Initialize UI Elements
    const langBtn = document.querySelector('.lang-btn');
    const langDropdown = document.querySelector('.lang-dropdown');
    const currentLangText = document.getElementById('currentLangText');
    const currentLangFlag = document.getElementById('currentLangFlag');
    const langOptions = document.querySelectorAll('.lang-option');

    // 2. Initialize i18next
    if (typeof i18next !== 'undefined') {
        i18next
            .use(i18nextHttpBackend)
            .use(i18nextBrowserLanguageDetector)
            .init({
                fallbackLng: 'en',
                debug: false,
                backend: {
                    loadPath: 'locales/{{lng}}/translation.json',
                },
                detection: {
                    order: ['querystring', 'cookie', 'localStorage', 'navigator'],
                    lookupQuerystring: 'lng',
                    lookupCookie: 'i18next',
                    caches: ['localStorage', 'cookie']
                }
            }, function(err, t) {
                if (err) return console.error('i18next init error:', err);
                updateContent();
                updateActiveLanguage(i18next.language);
            });

        // 3. Handle Language Change
        function changeLanguage(lng) {
            i18next.changeLanguage(lng, (err, t) => {
                if (err) return console.error('Error changing language:', err);
                updateContent();
                updateActiveLanguage(lng);
                
                // Update URL without reload (optional)
                const url = new URL(window.location);
                url.searchParams.set('lng', lng);
                window.history.pushState({}, '', url);
            });
        }

        // 4. Update Content
        function updateContent() {
            document.querySelectorAll('[data-i18n]').forEach(element => {
                const key = element.getAttribute('data-i18n');
                element.innerHTML = i18next.t(key);
            });
            
            // Special handling for placeholders
            document.querySelectorAll('[data-i18n-placeholder]').forEach(element => {
                const key = element.getAttribute('data-i18n-placeholder');
                element.setAttribute('placeholder', i18next.t(key));
            });
        }

        // 5. Update UI State
        function updateActiveLanguage(lng) {
            // Clean up language code (e.g. en-US -> en)
            const shortLng = lng.split('-')[0]; 
            if (currentLangText) currentLangText.textContent = shortLng.toUpperCase();
            if (currentLangFlag) {
                currentLangFlag.className = `fi fi-${shortLng === 'en' ? 'us' : shortLng}`;
            }
            
            // Highlight active option
            langOptions.forEach(opt => {
                const optLang = opt.getAttribute('data-lang');
                if (optLang === shortLng) {
                    opt.style.backgroundColor = 'rgba(255, 204, 0, 0.2)';
                    opt.style.color = '#FFCC00';
                } else {
                    opt.style.backgroundColor = '';
                    opt.style.color = '';
                }
            });
        }

        // 6. Bind Click Events
        langOptions.forEach(opt => {
            opt.addEventListener('click', (e) => {
                const lng = opt.getAttribute('data-lang');
                changeLanguage(lng);
                if (langDropdown) langDropdown.classList.remove('show');
            });
        });
    }

    // 7. Toggle Dropdown
    if (langBtn && langDropdown) {
        langBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            langDropdown.classList.toggle('show');
        });

        document.addEventListener('click', (e) => {
            if (!langBtn.contains(e.target) && !langDropdown.contains(e.target)) {
                langDropdown.classList.remove('show');
            }
        });
    }
});