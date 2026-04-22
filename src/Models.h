#ifndef MODELS_H
#define MODELS_H

#include <Arduino.h>
#include "DaikinControl.h"

struct ACState {
    bool power = false;
    uint8_t temp = 24;
    uint8_t mode = kDaikinCool;
    uint8_t fan = kDaikinFanAuto;
    bool swingV = false;
    bool swingH = false;
    bool econo = false;
    bool powerful = false;
    bool quiet = false;
    bool comfort = false;
    uint32_t timer = 0; // Remaining seconds
};

struct MacroConfig {
    char name[20] = "Empty";
    char color[10] = "white";
    uint8_t relayMask = 0;
    bool wake_pc = false;
    bool ac_on = false;
    bool is_active = false;
};

struct HealthState {
    float temperature = 0.0;
    float humidity = 0.0;
    bool autoSleepEnabled = false;
    bool isHot = false; // State A
    bool isHumid = false;
    uint32_t lastUpdate = 0;

    // Editable Thresholds (Defaults)
    float tempHigh = 28.5;
    float tempLow = 26.0;
    float humidHigh = 60.0;
    float humidLow = 55.0;
};

#endif
