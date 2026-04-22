#include "HealthMonitor.h"

HealthMonitor::HealthMonitor(uint8_t pin) : dht(pin, DHT22) {}

void HealthMonitor::begin() {
    dht.begin();
    preferences.begin("health", false);
    state.autoSleepEnabled = preferences.getBool("autoSleep", false);
    state.tempHigh = preferences.getFloat("th", 28.5);
    state.tempLow = preferences.getFloat("tl", 26.0);
    state.humidHigh = preferences.getFloat("hh", 60.0);
    state.humidLow = preferences.getFloat("hl", 55.0);
    preferences.end();
}

bool HealthMonitor::update() {
    uint32_t now = millis();
    if (now - lastRead >= readInterval) {
        lastRead = now;
        
        float h = dht.readHumidity();
        float t = dht.readTemperature();
        
        if (isnan(h) || isnan(t)) {
            Serial.println("Failed to read from DHT sensor!");
            return false;
        }

        bool changed = (abs(state.temperature - t) > 0.1 || abs(state.humidity - h) > 0.5);
        state.temperature = t;
        state.humidity = h;
        state.lastUpdate = now / 1000;

        // Auto-Sleep Logic (State A: Hot, State B: Cool)
        bool oldHot = state.isHot;
        bool oldHumid = state.isHumid;

        if (state.temperature >= state.tempHigh) state.isHot = true;
        else if (state.temperature <= state.tempLow) state.isHot = false;

        if (state.humidity >= state.humidHigh) state.isHumid = true;
        else if (state.humidity <= state.humidLow) state.isHumid = false;

        if (oldHot != state.isHot || oldHumid != state.isHumid) changed = true;

        return changed;
    }
    return false;
}

void HealthMonitor::setAutoSleep(bool enabled) {
    if (state.autoSleepEnabled != enabled) {
        state.autoSleepEnabled = enabled;
        preferences.begin("health", false);
        preferences.putBool("autoSleep", enabled);
        preferences.end();
    }
}

void HealthMonitor::setThresholds(float th, float tl, float hh, float hl) {
    state.tempHigh = th;
    state.tempLow = tl;
    state.humidHigh = hh;
    state.humidLow = hl;
    preferences.begin("health", false);
    preferences.putFloat("th", th);
    preferences.putFloat("tl", tl);
    preferences.putFloat("hh", hh);
    preferences.putFloat("hl", hl);
    preferences.end();
}
