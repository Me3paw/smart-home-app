#include "DisplayManager.h"

DisplayManager::DisplayManager(int width, int height, TwoWire* wire, int resetPin) 
    : display(width, height, wire, resetPin) {}

void DisplayManager::begin() {
    // SSD1306_SWITCHCAPVCC = generate display voltage from 3.3V internally
    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println(F("[Display] SSD1306 Fail"));
        return;
    }
    
    Wire.setClock(400000); // Ultra-fast mode
    display.setRotation(2);
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(10, 25);
    display.println(F("SMART HOME BOOTING"));
    display.display();
}

void DisplayManager::update(float power, bool pcOnline) {
    unsigned long now = millis();
    
    // 1. Frame Rate Control
    if (now - lastFrameTime < FRAME_DELAY) return;
    lastFrameTime = now;

    // Dynamic I2C clock based on activity to save bus power/stability
    // 800kHz for high-jitter overload animations, 400kHz for normal operation
    if (power > 1500.0f) {
        Wire.setClock(400000); 
    } else {
        Wire.setClock(400000);
    }

    // 2. State Logic & Animation
    handleAnimations(power);

    // 3. Render
    display.clearDisplay();

    int centerX = 64, centerY = 24, eyeGap = 25;
    drawEye(centerX - eyeGap, centerY, currentHeight, currentPupilX, currentPupilY, power);
    drawEye(centerX + eyeGap, centerY, currentHeight, currentPupilX, currentPupilY, power);

    // Status Area
    display.setTextSize(1);
    display.setCursor(30, 54);
    display.printf("W:%.1f PC:%s", power, pcOnline ? "ON" : "OFF");
    
    display.display();
}

void DisplayManager::handleAnimations(float power) {
    unsigned long now = millis();

    // --- Eye Height Logic (Blinking & Expression) ---
    float baseHeight = 30.0f;
    if (power < 50.0f) baseHeight = 10.0f;       // Sleepy
    else if (power > 1500.0f) baseHeight = 35.0f; // Overload
    else if (power > 300.0f) baseHeight = 32.0f;  // Active

    // Blink Trigger
    if (!isBlinking && (now - lastBlinkTime > nextBlinkInterval)) {
        isBlinking = true;
        isClosing = true;
        lastBlinkTime = now;
        nextBlinkInterval = 2000 + random(5000);
    }

    if (isBlinking) {
        if (isClosing) {
            targetHeight = 2.0f;
            if (currentHeight <= 4.0f) isClosing = false;
        } else {
            targetHeight = baseHeight;
            if (currentHeight >= baseHeight - 1.0f) isBlinking = false;
        }
    } else {
        targetHeight = baseHeight;
    }

    // --- Pupil Movement Logic ---
    if (power > 1500.0f) {
        // Shaking pupil at high power
        targetPupilX = random(-6, 7);
        targetPupilY = random(-4, 8);
    } else {
        // Idle looking around
        if (now - lastLookTime > 2000) {
            if (random(100) < 30) {
                targetPupilX = random(-7, 8);
                targetPupilY = random(-2, 7);
            } else {
                targetPupilX = 0; targetPupilY = 5; // Look center
            }
            lastLookTime = now;
        }
    }

    // --- Interpolation (Lerp) ---
    float hSpeed = isBlinking ? 0.45f : 0.15f;
    currentHeight = lerp(currentHeight, targetHeight, hSpeed);
    currentPupilX = lerp(currentPupilX, targetPupilX, 0.2f);
    currentPupilY = lerp(currentPupilY, targetPupilY, 0.2f);
}

void DisplayManager::drawEye(int x, int y, float height, float pX, float pY, float power) {
    int eyeW = (power > 50 && power <= 300) ? 28 : 24;

    if (height > 4.5f) {
        // Open eye white
        display.fillRoundRect(x - (eyeW/2), y - (int)(height/2), eyeW, (int)height, 8, SSD1306_WHITE);
        // Pupil
        display.fillCircle(x + (int)pX, y + (int)pY, 5, SSD1306_BLACK);
    } else {
        // Closed eye line
        display.drawFastHLine(x - (eyeW/2), y, eyeW, SSD1306_WHITE);
    }
}

float DisplayManager::lerp(float start, float end, float amount) {
    return start + amount * (end - start);
}
