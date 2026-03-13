document.addEventListener('DOMContentLoaded', () => {
    // 0. Render Auth Section for Navbar
    const navLinks = document.querySelector('.nav-links');
    if (navLinks) {
        const user = JSON.parse(localStorage.getItem('user'));
        const loginLink = navLinks.querySelector('a[href="login.html"]');
        
        if (user && loginLink) {
            // Replace Login with Dashboard link or User Menu
            // For now, let's just change Login to "Dashboard"
            loginLink.href = 'dashboard.html';
            loginLink.textContent = 'Dashboard';
            loginLink.setAttribute('data-i18n', 'nav_dashboard'); 
        }
    }

    // 1. Navbar Scroll Effect
    const navbar = document.querySelector('.landing-nav');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    });

    // 2. Mobile Menu Toggle
    const mobileBtn = document.querySelector('.mobile-menu-btn');
    const navLinks = document.querySelector('.nav-links');

    mobileBtn.addEventListener('click', () => {
        navLinks.classList.toggle('active');
        mobileBtn.innerHTML = navLinks.classList.contains('active') ? '<i class="fa-solid fa-xmark"></i>' : '<i class="fa-solid fa-bars"></i>';
    });

    // Close menu when clicking a link
    document.querySelectorAll('.nav-links a').forEach(link => {
        link.addEventListener('click', () => {
            navLinks.classList.remove('active');
            mobileBtn.innerHTML = '<i class="fa-solid fa-bars"></i>';
        });
    });

    // 3. Scroll Reveal Animation (Intersection Observer)
    const observerOptions = {
        threshold: 0.1,
        rootMargin: "0px 0px -50px 0px"
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target); // Only animate once
            }
        });
    }, observerOptions);

    const animatedElements = document.querySelectorAll('.animate-on-scroll');
    animatedElements.forEach(el => observer.observe(el));

    // 4. Hero Background Carousel
    const heroSection = document.querySelector('.hero-section');
    if (heroSection) {
        const images = [
            'assets/landing1.png',
            'assets/landing2.png'
        ];
        
        // Create slides
        images.forEach((img, index) => {
            const slide = document.createElement('div');
            slide.className = `hero-bg-slide ${index === 0 ? 'active' : ''}`;
            slide.style.backgroundImage = `url('${img}')`;
            heroSection.insertBefore(slide, heroSection.firstChild);
        });

        // Auto rotate
        let currentSlide = 0;
        const slides = document.querySelectorAll('.hero-bg-slide');
        
        if (slides.length > 1) {
            setInterval(() => {
                // Keep current slide visible for transition duration
                // But remove 'active' from it to trigger fade out
                const prevSlide = slides[currentSlide];
                
                currentSlide = (currentSlide + 1) % slides.length;
                const nextSlide = slides[currentSlide];
                
                // Activate new slide (fade in)
                nextSlide.classList.add('active');
                
                // Deactivate old slide (fade out)
                prevSlide.classList.remove('active');
                
            }, 6000); // slightly longer interval to account for 2s transition
        }
    }
});
