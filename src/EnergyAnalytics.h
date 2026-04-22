#ifndef ENERGY_ANALYTICS_H
#define ENERGY_ANALYTICS_H

#include <Arduino.h>
#include <Preferences.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "PCController.h"

class EnergyAnalytics {
public:
    EnergyAnalytics();
    void begin(PCController* pc = nullptr);
    /**
     * @return 0: No change, 1: Hour rollover, 2: Day rollover, 3: Month rollover
     */
    int update(float totalEnergy);
    
    // Manual overrides from UI
    void forceDayRoll(float totalEnergy);
    void forceMonthRoll();
    void forcePriceSync() { fetchElectricityPrice(); }

    // Getters for sync
    const float* getTierPrices() const { return tierPrices; }
    const float* getMonthlyEnergy() const { return monthlyEnergy; }
    const float* getHourlyEnergy() const { return hourlyEnergy; }
    float getDailyEnergyUsed() const { return dailyEnergyUsed; }
    int getCurrentHour() const { return currentHour; }

private:
    float tierPrices[5] = {1984, 2380, 2998, 3571, 3967};
    float monthlyEnergy[31] = {0.0};
    float hourlyEnergy[24] = {0.0};
    
    float dailyEnergyUsed = 0.0;
    
    int currentDay = -1;
    int currentMonth = -1;
    int currentHour = -1;
    
    bool pushPending = false;
    unsigned long lastPushAttempt = 0;
    unsigned long lastDataLog = 0;
    unsigned long lastWakeAttempt = 0;

    Preferences preferences;
    PCController* pcController = nullptr;

    void saveConfig();
    void loadConfig();
    void fetchElectricityPrice();
    void pushMonthlyData();
};

#endif
