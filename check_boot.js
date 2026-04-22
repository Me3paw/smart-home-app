const http = require('http');
const { execSync } = require('child_process');

async function checkApp() {
    console.log("Checking Smart Home App Status...");

    // 1. Check Metro Packager
    const checkMetro = () => new Promise((resolve) => {
        const req = http.get('http://localhost:8081/status', (res) => {
            resolve(res.statusCode === 200);
        });
        req.on('error', () => resolve(false));
        req.setTimeout(2000, () => resolve(false));
    });

    const metroActive = await checkMetro();
    console.log(`- Metro Packager: ${metroActive ? 'ACTIVE' : 'OFFLINE'}`);

    // 2. Check Android App Installation
    try {
        const packages = execSync('adb shell pm list packages com.smarthomeapp').toString();
        const isInstalled = packages.includes('com.smarthomeapp');
        console.log(`- Android App: ${isInstalled ? 'INSTALLED' : 'NOT FOUND'}`);
    } catch (e) {
        console.log("- Android App: ADB ERROR (Emulator might be starting)");
    }

    if (metroActive) {
        console.log("\nSUCCESS: App environment is ready.");
    } else {
        console.log("\nWAITING: Build still in progress or starting up...");
    }
}

checkApp();
