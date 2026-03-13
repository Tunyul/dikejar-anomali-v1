const fs = require('fs');
const path = require('path');

const assetsDir = path.join(__dirname, '../public/assets');

// Ensure assets directory exists
if (!fs.existsSync(assetsDir)) {
    fs.mkdirSync(assetsDir, { recursive: true });
}

// 1. Generate Glitch Logo (SVG)
const generateLogo = () => {
    const width = 200;
    const height = 200;
    
    // Random glitch rectangles
    let glitchRects = '';
    for (let i = 0; i < 15; i++) {
        const rw = Math.random() * 100 + 20;
        const rh = Math.random() * 10 + 2;
        const rx = Math.random() * (width - rw);
        const ry = Math.random() * (height - rh);
        const opacity = Math.random() * 0.5 + 0.2;
        const color = Math.random() > 0.5 ? '#00ff00' : '#ff00ff';
        glitchRects += `<rect x="${rx}" y="${ry}" width="${rw}" height="${rh}" fill="${color}" opacity="${opacity}" />`;
    }

    const svgContent = `
<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#1a1a1a" />
    <text x="50%" y="50%" font-family="monospace" font-size="24" fill="#00ff00" text-anchor="middle" dy=".3em" font-weight="bold">ANOMALY</text>
    <text x="52%" y="50%" font-family="monospace" font-size="24" fill="#ff00ff" text-anchor="middle" dy=".3em" font-weight="bold" opacity="0.5">ANOMALY</text>
    ${glitchRects}
    <path d="M0,0 L${width},${height}" stroke="#00ff00" stroke-width="2" opacity="0.3" />
    <path d="M${width},0 L0,${height}" stroke="#ff00ff" stroke-width="2" opacity="0.3" />
</svg>`;

    fs.writeFileSync(path.join(assetsDir, 'logo.svg'), svgContent.trim());
    console.log('Generated public/assets/logo.svg');
};

// 2. Generate Cyber Grid Background (SVG)
const generateBackground = () => {
    const width = 800;
    const height = 600;
    const gridSize = 40;

    let gridLines = '';
    // Vertical lines
    for (let x = 0; x <= width; x += gridSize) {
        gridLines += `<line x1="${x}" y1="0" x2="${x}" y2="${height}" stroke="#00ff00" stroke-width="1" opacity="0.1" />`;
    }
    // Horizontal lines
    for (let y = 0; y <= height; y += gridSize) {
        gridLines += `<line x1="0" y1="${y}" x2="${width}" y2="${y}" stroke="#00ff00" stroke-width="1" opacity="0.1" />`;
    }

    // Random noise dots
    let dots = '';
    for (let i = 0; i < 100; i++) {
        const cx = Math.random() * width;
        const cy = Math.random() * height;
        const r = Math.random() * 2;
        dots += `<circle cx="${cx}" cy="${cy}" r="${r}" fill="#00ff00" opacity="0.3" />`;
    }

    const svgContent = `
<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#0a0a0a" />
    ${gridLines}
    ${dots}
</svg>`;

    fs.writeFileSync(path.join(assetsDir, 'bg-pattern.svg'), svgContent.trim());
    console.log('Generated public/assets/bg-pattern.svg');
};

// 3. Generate Item Placeholder (SVG)
const generatePlaceholder = () => {
    const width = 300;
    const height = 200;

    const svgContent = `
<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#222" />
    <rect x="10" y="10" width="${width-20}" height="${height-20}" fill="none" stroke="#444" stroke-width="2" stroke-dasharray="10,5" />
    <text x="50%" y="50%" font-family="sans-serif" font-size="20" fill="#666" text-anchor="middle" dy=".3em">NO IMAGE</text>
    <circle cx="${width/2}" cy="${height/2}" r="40" stroke="#444" stroke-width="2" fill="none" />
</svg>`;

    fs.writeFileSync(path.join(assetsDir, 'placeholder.svg'), svgContent.trim());
    console.log('Generated public/assets/placeholder.svg');
};

generateLogo();
generateBackground();
generatePlaceholder();
