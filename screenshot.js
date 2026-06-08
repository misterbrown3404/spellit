const puppeteer = require('puppeteer');

const projects = [
    { id: 'deenai', url: 'https://deenai.app' },
    { id: 'amanatech', url: 'https://amanatech.org' },
    { id: 'stratum', url: 'http://stratumblackridge.com/' },
    { id: 'nysc', url: 'https://nysc-main.vercel.app' },
    { id: 'nysc-app', url: 'https://nysc-main-app.vercel.app/' },
    { id: 'draw', url: 'https://draw-33538.web.app/' },
    { id: 'spellit', url: 'https://spellit.infinityfree.me' }
];

(async () => {
    const browser = await puppeteer.launch();
    for (const project of projects) {
        try {
            console.log(`Taking screenshot of ${project.id}...`);
            const page = await browser.newPage();
            // Set viewport based on whether it's mostly phone or browser.
            // A simple 1280x800 for web and 400x800 for mobile
            if (project.id === 'deenai' || project.id === 'nysc-app' || project.id === 'draw' || project.id === 'spellit') {
                await page.setViewport({ width: 400, height: 800 });
            } else {
                await page.setViewport({ width: 1280, height: 800 });
            }
            await page.goto(project.url, { waitUntil: 'networkidle2', timeout: 30000 });
            await page.screenshot({ path: `lib/assets/images/${project.id}.png` });
            await page.close();
        } catch (e) {
            console.error(`Failed to take screenshot for ${project.id}:`, e.message);
        }
    }
    await browser.close();
    console.log('Screenshots completed.');
})();
