#ifndef FIREBASE_HANDLER_H
#define FIREBASE_HANDLER_H

#include <Arduino.h>
#include <Firebase_ESP_Client.h>
#include <ArduinoJson.h>

class RelayController;
class ClimateController;
class PZEMManager;
class PCController;
class MacroEngine;
class EnergyAnalytics;
class HealthMonitor;

class FirebaseHandler {
public:
    FirebaseHandler(const char* apiKey, const char* databaseUrl);
    void begin(RelayController& r, ClimateController& ac, PZEMManager& p, 
               PCController& pc, MacroEngine& m, EnergyAnalytics& e, HealthMonitor& h);
    void update();
    void syncState();
    void syncPZEM();
    void syncRelays();
    void syncAC();
    void syncPC();
    void syncEnergy();
    void syncHealth();
    void syncNotifyCheck();
    void setAuth(const char* email, const char* password);
    void setTokenCallback(void (*callback)(TokenInfo));

private:
    const char* apiKey;
    const char* databaseUrl;
    const char* userEmail = "";
    const char* userPassword = "";
    
    FirebaseData fbdo;
    FirebaseData streamDo;
    FirebaseAuth auth;
    FirebaseConfig config;
    
    RelayController* relays;
    ClimateController* climate;
    PZEMManager* pzem;
    PCController* pc;
    MacroEngine* macros;
    EnergyAnalytics* energy;
    HealthMonitor* health;

    unsigned long lastSync = 0;
    bool isReady = false;
    bool firstSyncDone = false;
    bool pzemStreamActive = false;
    unsigned long lastPzemSync = 0;

    void handleCommands();
};

#endif
