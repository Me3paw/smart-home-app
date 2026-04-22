#include "RelayController.h"

const int RelayController::relayPins[NUM_RELAYS] = {6, 7, 15, 8, 11, 12};

RelayController::RelayController() {
    for (int i = 0; i < NUM_RELAYS; i++) {
        relayStates[i] = false;
        snprintf(relayNames[i], 32, "Relay %d", i + 1);
        startTimers[i] = 0;
        stopTimers[i] = 0;
    }
}

void RelayController::begin() {
    Serial.println("[Relay] Init Pins...");
    for (int i = 0; i < NUM_RELAYS; i++) {
        pinMode(relayPins[i], OUTPUT);
        digitalWrite(relayPins[i], LOW);
    }
    Serial.println("[Relay] Loading Config...");
    loadConfig();
    Serial.println("[Relay] OK");
}

void RelayController::toggle(int index) {
    if (index >= 0 && index < NUM_RELAYS) {
        relayStates[index] = !relayStates[index];
        digitalWrite(relayPins[index], relayStates[index] ? HIGH : LOW);
        saveConfig();
    }
}

void RelayController::set(int index, bool state) {
    if (index >= 0 && index < NUM_RELAYS) {
        relayStates[index] = state;
        digitalWrite(relayPins[index], state ? HIGH : LOW);
        saveConfig();
    }
}

void RelayController::setAll(bool state) {
    for (int i = 0; i < NUM_RELAYS; i++) {
        relayStates[i] = state;
        digitalWrite(relayPins[i], state ? HIGH : LOW);
    }
    saveConfig();
}

bool RelayController::getState(int index) const {
    if (index >= 0 && index < NUM_RELAYS) {
        return relayStates[index];
    }
    return false;
}

const bool* RelayController::getStates() const {
    return relayStates;
}

void RelayController::rename(int index, const char* name) {
    if (index >= 0 && index < NUM_RELAYS && name != nullptr) {
        strncpy(relayNames[index], name, 31);
        relayNames[index][31] = '\0';
        saveConfig();
    }
}

const char* RelayController::getName(int index) const {
    if (index >= 0 && index < NUM_RELAYS) {
        return relayNames[index];
    }
    return "Unknown";
}

void RelayController::setTimers(int index, time_t start, time_t stop) {
    if (index >= 0 && index < NUM_RELAYS) {
        startTimers[index] = start;
        stopTimers[index] = stop;
        saveConfig();
    }
}

bool RelayController::updateTimers(time_t now) {
    bool changed = false;
    for (int i = 0; i < NUM_RELAYS; i++) {
        // Start Timer Logic
        if (startTimers[i] != 0 && now >= startTimers[i]) {
            if (!relayStates[i]) {
                Serial.printf("[Relay %d] Start timer reached. Power ON.\n", i + 1);
                relayStates[i] = true;
                digitalWrite(relayPins[i], HIGH);
            }
            startTimers[i] = 0; // Triggered, clear it
            changed = true;
        }

        // Stop Timer Logic
        if (stopTimers[i] != 0 && now >= stopTimers[i]) {
            if (relayStates[i]) {
                Serial.printf("[Relay %d] Stop timer reached. Power OFF.\n", i + 1);
                relayStates[i] = false;
                digitalWrite(relayPins[i], LOW);
            }
            stopTimers[i] = 0; // Triggered, clear it
            changed = true;
        }
    }
    if (changed) {
        saveConfig();
    }
    return changed;
}

void RelayController::saveConfig() {
    preferences.begin("smart-home", false);
    preferences.putBytes("relays", relayStates, sizeof(relayStates));
    preferences.putBytes("names", relayNames, sizeof(relayNames));
    preferences.putBytes("starts", startTimers, sizeof(startTimers));
    preferences.putBytes("stops", stopTimers, sizeof(stopTimers));
    preferences.end();
}

void RelayController::loadConfig() {
    if (!preferences.begin("smart-home", false)) {
        Serial.println("[Relay] Failed to open NVS");
        return;
    }

    if (preferences.isKey("relays")) preferences.getBytes("relays", relayStates, sizeof(relayStates));
    if (preferences.isKey("names")) preferences.getBytes("names", relayNames, sizeof(relayNames));
    if (preferences.isKey("starts")) preferences.getBytes("starts", startTimers, sizeof(startTimers));
    if (preferences.isKey("stops")) preferences.getBytes("stops", stopTimers, sizeof(stopTimers));

    preferences.end();
    for (int i = 0; i < NUM_RELAYS; i++) {
        pinMode(relayPins[i], OUTPUT);
        digitalWrite(relayPins[i], relayStates[i] ? HIGH : LOW);
    }
}
