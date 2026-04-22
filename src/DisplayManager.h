#ifndef DISPLAY_MANAGER_H
#define DISPLAY_MANAGER_H

#include <Arduino.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>

class DisplayManager {
public:
    DisplayManager(int width, int height, TwoWire* wire, int resetPin);
    void begin();
    void update(float power, bool pcOnline);

private:
    Adafruit_SSD1306 display;
    
    // Animation Timing
    unsigned long lastFrameTime = 0;
    const uint8_t FPS = 40; 
    const uint16_t FRAME_DELAY = 1000 / FPS;

    // Eye State & Interpolation (Current values)
    float currentHeight = 30.0f;
    float currentPupilX = 0.0f;
    float currentPupilY = 5.0f;

    // Animation Targets
    float targetHeight = 30.0f;
    float targetPupilX = 0.0f;
    float targetPupilY = 5.0f;
    
    // Blinking Logic
    unsigned long lastBlinkTime = 0;
    unsigned long nextBlinkInterval = 4000;
    bool isBlinking = false;
    bool isClosing = true;

    // Movement Logic
    unsigned long lastLookTime = 0;

    void handleAnimations(float power);
    void drawEye(int x, int y, float height, float pupilX, float pupilY, float power);
    float lerp(float start, float end, float amount);
};

#endif
