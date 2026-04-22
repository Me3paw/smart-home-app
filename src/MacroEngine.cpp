#include "MacroEngine.h"

MacroEngine::MacroEngine() {}

void MacroEngine::begin() {
    loadConfig();
}

bool MacroEngine::updateAutoMacro(const SystemCore& core, RelayController& relays, PCController& pc, ClimateController& ac, float currentPower) {
    bool notifyChanged = false;
    
    // Read status from background task in SystemCore (already stabilized with 3 strikes)
    bool currentOnline = core.isPhoneOnline();
    
    if (currentOnline != phoneOnline) {
        phoneOnline = currentOnline;
        notifyChanged = true;
        
        // Auto Macro (Index 5) trigger: Execute exactly once on transition
        // Logic inside execute() handles the toggle behavior
        execute(5, relays, pc, ac);
    }
    
    // Notify check: power > 30W
    bool notifyCheck = (currentPower > 30.0f);
    if (notifyCheck != lastNotifyCheck) {
        lastNotifyCheck = notifyCheck;
        notifyChanged = true;
    }
    
    // Track AC power state
    bool currentAcActive = ac.getState().power;
    if (currentAcActive != lastAcActive) {
        lastAcActive = currentAcActive;
        notifyChanged = true;
    }

    return notifyChanged;
}

bool MacroEngine::handleHealthAutomation(const HealthState& health, RelayController& relays, ClimateController& ac) {
    if (!health.autoSleepEnabled) return false;

    bool changed = false;
    float t = health.temperature;
    float h = health.humidity;
    
    // 1. Temperature-based Automation (Auto-Sleep)
    // Condition A: Hot (>= tempHigh) -> AC ON (25°C, Fan 5), Relay 6 ON
    if (t >= health.tempHigh) {
        const ACState& s = ac.getState();
        if (!s.power || s.temp != 25 || s.fan != 5) {
            ac.setAC(true, 25, 5);
            changed = true;
        }
        if (!relays.getState(5)) {
            relays.set(5, true);
            changed = true;
        }
    } 
    // Condition B: Normal (between tempLow and tempHigh) -> Relay 6 ON
    else if (t > health.tempLow) {
        if (!relays.getState(5)) {
            relays.set(5, true);
            changed = true;
        }
    }
    // Condition C: Cool (<= tempLow) -> AC ON (27°C, Fan 1), Relay 6 OFF
    else {
        const ACState& s = ac.getState();
        if (!s.power || s.temp != 27 || s.fan != 1) {
            ac.setAC(true, 27, 1);
            changed = true;
        }
        if (relays.getState(5)) {
            relays.set(5, false);
            changed = true;
        }
    }

    // 2. Humidity-based Automation (Separate)
    // If > humidHigh -> OFF, If < humidLow -> ON
    if (h > health.humidHigh) {
        if (relays.getState(4)) {
            relays.set(4, false);
            changed = true;
        }
    } else if (h < health.humidLow) {
        if (!relays.getState(4)) {
            relays.set(4, true);
            changed = true;
        }
    }

    return changed;
}

void MacroEngine::execute(int index, RelayController& relays, PCController& pc, ClimateController& ac) {
    if (index < 0 || index >= 6) return;
    
    macros[index].is_active = !macros[index].is_active;
    
    if (macros[index].is_active) {
        for (int i = 0; i < 6; i++) {
            if (macros[index].relayMask & (1 << i)) {
                if (!relays.getState(i)) relays.toggle(i);
            }
        }
        if (macros[index].wake_pc) pc.wake();
        if (macros[index].ac_on) ac.loadPreset();
    } else {
        for (int i = 0; i < 6; i++) {
            if (macros[index].relayMask & (1 << i)) {
                if (relays.getState(i)) relays.toggle(i);
            }
        }
        if (macros[index].wake_pc) pc.shutdown();
        if (macros[index].ac_on) ac.sendCommand("power_toggle"); // Turn off AC
    }
    saveConfig();
}

void MacroEngine::updateConfig(int index, const MacroConfig& newConfig) {
    if (index >= 0 && index < 6) {
        bool currentActive = macros[index].is_active;
        macros[index] = newConfig;
        macros[index].is_active = currentActive;
        saveConfig();
    }
}

void MacroEngine::saveConfig() {
    preferences.begin("smart-home", false);
    for (int i = 0; i < 6; i++) {
        char key[10]; snprintf(key, sizeof(key), "m%d", i);
        preferences.putBytes(key, &macros[i], sizeof(macros[i]));
    }
    preferences.end();
}

void MacroEngine::loadConfig() {
    if (!preferences.begin("smart-home", false)) {
        Serial.println("[Macro] Failed to open NVS");
        return;
    }
    for (int i = 0; i < 6; i++) {
        char key[10]; snprintf(key, sizeof(key), "m%d", i);
        if (preferences.isKey(key)) preferences.getBytes(key, &macros[i], sizeof(macros[i]));
    }
    preferences.end();
}
