#include "PCController.h"

PCController::PCController(const char* mac, const char* ip, const char* shutdownUrl) 
    : shutdownUrl(shutdownUrl) {
    strncpy(macAddressStr, mac, sizeof(macAddressStr) - 1);
    macAddressStr[sizeof(macAddressStr) - 1] = '\0';
    parseMacAddress(mac);
    ipAddress.fromString(ip);
}

void PCController::wake() {
    Serial.println("[PC] Sending WOL");
    WiFiUDP udp;
    uint8_t magicPacket[102];
    for (int i = 0; i < 6; i++) magicPacket[i] = 0xFF;
    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 6; j++) {
            magicPacket[6 + (i * 6) + j] = macAddress[j];
        }
    }
    
    IPAddress broadcastIP = WiFi.broadcastIP();

    for (int i = 0; i < 5; i++) {
        udp.beginPacket(broadcastIP, 9);
        udp.write(magicPacket, sizeof(magicPacket));
        udp.endPacket();
        delay(10);
    }
}

void PCController::shutdown() {
    Serial.println("[PC] Sending Shutdown command");
    HTTPClient http;
    http.begin(shutdownUrl);
    http.setTimeout(2000);
    http.GET();
    http.end();
}
bool PCController::update(const SystemCore& core, time_t now) {
    bool changed = false;
    // Read status from background task in SystemCore
    online = core.isPcOnline();

    if (now != 0) {
        // Start Timer Logic
        if (startTimer != 0 && now >= startTimer) {
            if (!online) {
                Serial.println("[PC] Start timer reached. Waking UP.");
                wake();
            }
            startTimer = 0; // Triggered
            changed = true;
        }

        // Stop Timer Logic
        if (stopTimer != 0 && now >= stopTimer) {
            if (online) {
                Serial.println("[PC] Stop timer reached. Shutting DOWN.");
                shutdown();
            }
            stopTimer = 0; // Triggered
            changed = true;
        }
    }
    return changed;
}

void PCController::setTimers(time_t start, time_t stop) {
    startTimer = start;
    stopTimer = stop;
    Serial.printf("[PC] Timers set: Start=%ld, Stop=%ld\n", (long)startTimer, (long)stopTimer);
}

void PCController::parseMacAddress(const char* mac) {
    unsigned int values[6];
    if (6 == sscanf(mac, "%x:%x:%x:%x:%x:%x", &values[0], &values[1], &values[2], &values[3], &values[4], &values[5])) {
        for (int i = 0; i < 6; ++i) macAddress[i] = (uint8_t)values[i];
    }
}
