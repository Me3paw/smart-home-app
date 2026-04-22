#include "ClimateController.h"
#include "DaikinControl.h"

ClimateController::ClimateController(uint8_t irPin) : ac(irPin) {}

void ClimateController::begin() {
    ac.begin();
    loadConfig();
}

bool ClimateController::update(time_t now) {
    if (currentAC.timer > 0) {
        if (now >= (time_t)currentAC.timer) {
            currentAC.power = false;
            sendACCommand();
            currentAC.timer = 0;
            saveConfig();
            return true;
        }
    }
    return false;
}

void ClimateController::sendCommand(const String& cmd) {
    if (cmd == "power_toggle") {
        currentAC.power = !currentAC.power;
        if (!currentAC.power) currentAC.timer = 0;
    }
    else if (cmd == "power_on") {
        currentAC.power = true;
    }
    else if (cmd == "power_off") {
        currentAC.power = false;
        currentAC.timer = 0;
    }
    else if (cmd == "temp_up") { if (currentAC.temp < 32) currentAC.temp++; }
    else if (cmd == "temp_down") { if (currentAC.temp > 18) currentAC.temp--; }
    else if (cmd == "mode_auto") currentAC.mode = kDaikinAuto;
    else if (cmd == "mode_cool") currentAC.mode = kDaikinCool;
    else if (cmd == "mode_heat") currentAC.mode = kDaikinHeat;
    else if (cmd == "mode_dry") currentAC.mode = kDaikinDry;
    else if (cmd == "mode_fan") currentAC.mode = kDaikinFan;
    else if (cmd == "fan_auto") currentAC.fan = kDaikinFanAuto;
    else if (cmd == "fan_silent") currentAC.fan = kDaikinFanQuiet;
    else if (cmd.startsWith("fan_")) {
        currentAC.fan = (uint8_t)atoi(cmd.c_str() + 4);
    }
    else if (cmd == "swingv_toggle") currentAC.swingV = !currentAC.swingV;
    else if (cmd == "swingh_toggle") currentAC.swingH = !currentAC.swingH;
    else if (cmd == "econo_toggle") currentAC.econo = !currentAC.econo;
    else if (cmd == "powerful_toggle") currentAC.powerful = !currentAC.powerful;
    else if (currentAC.quiet) currentAC.quiet = !currentAC.quiet;
    else if (cmd == "comfort_toggle") currentAC.comfort = !currentAC.comfort;
    else if (cmd == "ac_load_preset") { loadPreset(); return; }
    else if (cmd == "sync") { /* Already sends in sendACCommand below */ }

    sendACCommand();
    saveConfig();
}

void ClimateController::setTimer(time_t target) {
    currentAC.timer = (uint32_t)target;
    if (currentAC.timer > 0 && !currentAC.power) {
        currentAC.power = true;
        sendACCommand();
    }
    saveConfig();
}

void ClimateController::savePreset() {
    acPreset = currentAC;
    saveConfig();
}

void ClimateController::savePreset(const ACState& state) {
    acPreset = state;
    saveConfig();
}

void ClimateController::loadPreset() {
    currentAC = acPreset;
    sendACCommand();
    saveConfig();
}

void ClimateController::setAC(bool power, int temp, int fan) {
    currentAC.power = power;
    currentAC.temp = (uint8_t)temp;
    currentAC.fan = (uint8_t)fan;
    sendACCommand();
    saveConfig();
}

void ClimateController::sendACCommand() {
    if (currentAC.power) ac.on(); else ac.off();
    ac.setTemp(currentAC.temp);
    ac.setMode(currentAC.mode);
    ac.setFan(currentAC.fan);
    ac.setSwingVertical(currentAC.swingV);
    ac.setSwingHorizontal(currentAC.swingH);
    ac.setEcono(currentAC.econo);
    ac.setPowerful(currentAC.powerful);
    ac.setQuiet(currentAC.quiet);
    ac.setComfort(currentAC.comfort);
    ac.send();
}

void ClimateController::saveConfig() {
    preferences.begin("smart-home", false);
    preferences.putBytes("ac", &currentAC, sizeof(currentAC));
    preferences.putBytes("ac_preset", &acPreset, sizeof(acPreset));
    preferences.end();
}

void ClimateController::loadConfig() {
    if (!preferences.begin("smart-home", false)) {
        Serial.println("[Climate] Failed to open NVS");
        return;
    }
    if (preferences.isKey("ac")) preferences.getBytes("ac", &currentAC, sizeof(currentAC));
    if (preferences.isKey("ac_preset")) preferences.getBytes("ac_preset", &acPreset, sizeof(acPreset));
    preferences.end();
}
