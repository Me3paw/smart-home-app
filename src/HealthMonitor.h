#ifndef HEALTH_MONITOR_H
#define HEALTH_MONITOR_H

#include <DHT.h>
#include "Models.h"
#include <Preferences.h>

class HealthMonitor {
private:
    DHT dht;
    HealthState state;
    Preferences preferences;
    uint32_t lastRead = 0;
    const uint32_t readInterval = 5000; // 5 seconds
    
public:
    explicit HealthMonitor(uint8_t pin);
    void begin();
    bool update();
    
    HealthState getState() const { return state; }
    void setAutoSleep(bool enabled);
    void setThresholds(float th, float tl, float hh, float hl);
    bool isAutoSleepEnabled() const { return state.autoSleepEnabled; }
};

#endif
