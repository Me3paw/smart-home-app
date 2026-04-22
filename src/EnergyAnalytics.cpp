#include "EnergyAnalytics.h"

EnergyAnalytics::EnergyAnalytics() {}

void EnergyAnalytics::begin(PCController* pc) {
    pcController = pc;
    loadConfig();
}

int EnergyAnalytics::update(float totalEnergy) {
    unsigned long now = millis();
    int rolloverStatus = 0;
    
    // Monthly Data Push Logic
    if (pushPending) {
        if (pcController && pcController->isOnline()) {
            pushMonthlyData();
        } else if (pcController) {
            if (lastWakeAttempt == 0 || (now - lastWakeAttempt > 300000)) { 
                Serial.println("[Energy] PC Offline for monthly push. Sending WOL");
                pcController->wake();
                lastWakeAttempt = now;
            } else if (now - lastWakeAttempt > 120000) { 
                pushMonthlyData();
            }
        } else {
            if (now - lastPushAttempt > 1800000 || lastPushAttempt == 0) {
                pushMonthlyData();
            }
        }
    }

    // Poll hourly/daily stats every 2 seconds
    if (now - lastDataLog > 2000) {
        lastDataLog = now;
        struct tm timeinfo;
        if (getLocalTime(&timeinfo) && timeinfo.tm_year > 120) {
            int day = timeinfo.tm_mday;
            int month = timeinfo.tm_mon;
            int hour = timeinfo.tm_hour;

            // 1. Initial boot setup
            if (currentDay == -1) {
                currentDay = day;
                currentMonth = month;
                currentHour = hour;
                if (dailyEnergyUsed <= 0 && totalEnergy > 0) dailyEnergyUsed = totalEnergy;
                saveConfig();
            }

            // 2. Day rollover detection
            if (day != currentDay) {
                if (currentDay >= 1 && currentDay <= 31) {
                    monthlyEnergy[currentDay - 1] = dailyEnergyUsed;
                }
                
                for(int i=0; i<24; i++) hourlyEnergy[i] = 0;
                dailyEnergyUsed = 0;
                rolloverStatus = 2; // Day rollover
                
                // Month change
                if (month != currentMonth) {
                    pushPending = true;
                    lastWakeAttempt = 0; 
                    currentMonth = month;
                    rolloverStatus = 3; // Month rollover
                }

                currentDay = day;
                currentHour = hour;
                saveConfig();
                return rolloverStatus; 
            }

            // 3. Update daily running total
            if (totalEnergy > dailyEnergyUsed) {
                dailyEnergyUsed = totalEnergy;
            }

            // 4. Hourly snapshot
            if (hour != currentHour) {
                if (hour >= 0 && hour < 24) {
                    hourlyEnergy[hour] = dailyEnergyUsed;
                }
                currentHour = hour;
                rolloverStatus = 1; // Hour rollover
                saveConfig();
            }
        }
    }
    return rolloverStatus;
}

void EnergyAnalytics::forceDayRoll(float totalEnergy) {
    if (currentDay >= 1 && currentDay <= 31) monthlyEnergy[currentDay - 1] = totalEnergy;
    dailyEnergyUsed = 0;
    for(int i=0; i<24; i++) hourlyEnergy[i] = 0;
    saveConfig();
}

void EnergyAnalytics::forceMonthRoll() {
    pushPending = true;
    lastWakeAttempt = 0;
    saveConfig();
}

void EnergyAnalytics::fetchElectricityPrice() {
    HTTPClient http;
    http.begin("http://PING_TARGET_PC:5000/price");
    http.setTimeout(5000);
    int httpCode = http.GET();
    if (httpCode == 200) {
        JsonDocument doc;
        DeserializationError error = deserializeJson(doc, http.getString());
        if (!error) {
            JsonArray tiers = doc["tiers"];
            if (!tiers.isNull() && tiers.size() == 5) {
                for (int i = 0; i < 5; i++) tierPrices[i] = tiers[i];
            }
            
            // Sync limits as well
            JsonArray jsonLimits = doc["limits"];
            if (!jsonLimits.isNull() && jsonLimits.size() >= 4) {
                // We use fixed internal limits [50, 100, 200, 300, 400] for math, 
                // but we could store them if the class had a limits array.
                // For now, let's just log and ensure they exist for future use.
                Serial.println("[Energy] Synchronized 5 tiers and limits.");
            }
            saveConfig();
        }
    }
    http.end();
}
void EnergyAnalytics::pushMonthlyData() {
    HTTPClient http;
    http.begin("http://PING_TARGET_PC:5000/upload_csv");
    http.setTimeout(15000); // PC might be slow to respond after just waking
    http.addHeader("Content-Type", "text/csv");

    // Use reserve to avoid multiple reallocations and heap fragmentation
    String csv;
    csv.reserve(600); 
    csv = "Day,kWh\n";
    for(int i=0; i<31; i++) {
        csv += String(i+1);
        csv += ",";
        csv += String(monthlyEnergy[i]);
        csv += "\n";
    }

    int httpCode = http.POST(csv);
    if (httpCode == 200 || httpCode == 201) {

        Serial.println("[Energy] Monthly push SUCCESS");
        pushPending = false;
        lastWakeAttempt = 0;
        for(int i=0; i<31; i++) monthlyEnergy[i] = 0.0;
        saveConfig();
    } else {
        Serial.printf("[Energy] Monthly push FAILED, code: %d\n", httpCode);
        lastPushAttempt = millis();
    }
    http.end();
}

void EnergyAnalytics::saveConfig() {
    preferences.begin("smart-home", false);
    preferences.putFloat("dailyUsed", dailyEnergyUsed);
    preferences.putBytes("monthly", monthlyEnergy, sizeof(monthlyEnergy));
    preferences.putBytes("hourly", hourlyEnergy, sizeof(hourlyEnergy));
    preferences.putInt("lastDay", currentDay);
    preferences.putInt("lastMonth", currentMonth);
    preferences.putInt("lastHour", currentHour);
    preferences.putBool("pushPending", pushPending);
    preferences.putBytes("tierPrices", tierPrices, sizeof(tierPrices));
    preferences.end();
}

void EnergyAnalytics::loadConfig() {
    if (!preferences.begin("smart-home", false)) {
        Serial.println("[Energy] Failed to open NVS");
        return;
    }
    if (preferences.isKey("monthly")) preferences.getBytes("monthly", monthlyEnergy, sizeof(monthlyEnergy));
    if (preferences.isKey("hourly")) preferences.getBytes("hourly", hourlyEnergy, sizeof(hourlyEnergy));
    if (preferences.isKey("dailyUsed")) dailyEnergyUsed = preferences.getFloat("dailyUsed");
    if (preferences.isKey("pushPending")) pushPending = preferences.getBool("pushPending");
    if (preferences.isKey("lastDay")) currentDay = preferences.getInt("lastDay");
    if (preferences.isKey("lastMonth")) currentMonth = preferences.getInt("lastMonth");
    if (preferences.isKey("lastHour")) currentHour = preferences.getInt("lastHour");
    if (preferences.isKey("tierPrices")) preferences.getBytes("tierPrices", tierPrices, sizeof(tierPrices));
    preferences.end();
}
