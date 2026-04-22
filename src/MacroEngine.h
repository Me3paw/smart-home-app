#ifndef MACRO_ENGINE_H
#define MACRO_ENGINE_H

#include <Arduino.h>
#include <Preferences.h>
#include "RelayController.h"
#include "PCController.h"
#include "ClimateController.h"
#include "Models.h"
#include "SystemCore.h"

class MacroEngine {
public:
    MacroEngine();
    void begin();
    bool updateAutoMacro(const SystemCore& core, RelayController& relays, PCController& pc, ClimateController& ac, float currentPower);
    bool handleHealthAutomation(const HealthState& health, RelayController& relays, ClimateController& ac);
    void execute(int index, RelayController& relays, PCController& pc, ClimateController& ac);
    void updateConfig(int index, const MacroConfig& newConfig);
    const MacroConfig* getMacros() const { return macros; }
    bool isPhoneOnline() const { return phoneOnline; }
    bool getNotifyCheck() const { return lastNotifyCheck; }
    bool isAcActive() const { return lastAcActive; }

private:
    MacroConfig macros[6];
    Preferences preferences;
    bool phoneOnline = false;
    bool lastNotifyCheck = false;
    bool lastAcActive = false;

    void saveConfig();
    void loadConfig();
};

#endif
