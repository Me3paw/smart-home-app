#ifndef CLIMATE_CONTROLLER_H
#define CLIMATE_CONTROLLER_H

#include <Arduino.h>
#include <Preferences.h>
#include "Models.h"
#include "DaikinControl.h"

class ClimateController {
public:
    explicit ClimateController(uint8_t irPin);
    void begin();
    bool update(time_t now = 0);
    void sendCommand(const String& cmd);
    void setTimer(time_t target);
    void savePreset();
    void savePreset(const ACState& state);
    void loadPreset();
    void setAC(bool power, int temp, int fan);
    const ACState& getState() const { return currentAC; }
    const ACState& getPreset() const { return acPreset; }

private:
    IRDaikinESP ac;
    ACState currentAC, acPreset;
    Preferences preferences;
    
    time_t acTimerTarget = 0;

    void sendACCommand();
    void saveConfig();
    void loadConfig();
};

#endif
