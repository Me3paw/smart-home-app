#include <Arduino.h>
#include <time.h>
#include "SystemCore.h"
#include "RelayController.h"
#include "ClimateController.h"
#include "PZEMManager.h"
#include "PCController.h"
#include "MacroEngine.h"
#include "EnergyAnalytics.h"
#include "DisplayManager.h"
#include "HealthMonitor.h"
#include "FirebaseHandler.h"
#include <PubSubClient.h>

// WiFi
const char* ssid = "WIFI_SSID_PLACEHOLDER";
const char* password = "WIFI_PASS_PLACEHOLDER";

// PC MQTT Broker (for remote logging)
const char* mqtt_server = "MQTT_SERVER_PLACEHOLDER";

// Firebase Credentials
const char* firebase_apiKey = "FIREBASE_API_KEY_PLACEHOLDER"; 
const char* firebase_dbUrl = "FIREBASE_DB_URL_PLACEHOLDER";
const char* user_email = "FIREBASE_USER_EMAIL_PLACEHOLDER";
const char* user_password = "FIREBASE_USER_PASS_PLACEHOLDER";

// Static IP Configuration
IPAddress local_IP(192, 168, 1, 150);
IPAddress gateway(192, 168, 1, 1);
IPAddress subnet(255, 255, 255, 0);
IPAddress dns(8, 8, 8, 8);

// Module Instances
SystemCore systemCore(ssid, password);
RelayController relayController;
ClimateController climateController(21); // IR_SEND_PIN
PZEMManager pzemManager(Serial1, 9, 10); // RX: 9, TX: 10
PCController pcController("PC_MAC_PLACEHOLDER", "MQTT_SERVER_PLACEHOLDER", "PC_SHUTDOWN_URL_PLACEHOLDER");
MacroEngine macroEngine;
EnergyAnalytics energyAnalytics;
HealthMonitor healthMonitor(13); // DHT22 on GPIO 13
DisplayManager displayManager(128, 64, &Wire, -1);
FirebaseHandler firebaseHandler(firebase_apiKey, firebase_dbUrl);

WiFiClient mqttWiFiClient;
PubSubClient mqtt(mqttWiFiClient);

void logToMqtt(String msg) {
    Serial.println(msg);
    if (mqtt.connected()) {
        mqtt.publish("esp32/logs", msg.c_str());
    }
}

void mainTokenStatusCallback(TokenInfo info) {
    if (info.status == token_status_error) {
        String errorMsg = "AUTH ERROR: ";
        errorMsg += info.error.message.c_str();
        logToMqtt(errorMsg);
    } else if (info.status == token_status_ready) {
        logToMqtt("AUTH READY!");
    }
}

void setup() {
    Serial.begin(115200);
    delay(2000);
    Serial.println("\n--- Initializing Modular System ---");
    Serial.printf("Version: %s\n", SystemCore::VERSION);

    // 1. Initialize Hardware
    Wire.begin(5, 4); // SDA: 5, SCL: 4
    displayManager.begin();
    relayController.begin();
    climateController.begin();
    healthMonitor.begin();
    macroEngine.begin();
    energyAnalytics.begin(&pcController);

    // 2. Initialize WiFi
    systemCore.setStaticIP(local_IP, gateway, subnet, dns);
    systemCore.setPingTargets(IPAddress(PING_TARGET_PC), IPAddress(PING_TARGET_PHONE));
    systemCore.begin(); 
    randomSeed(analogRead(0)); // Seed for animations/blinking

    // 3. Setup MQTT Logging
    mqtt.setServer(mqtt_server, 1883);
    unsigned long startMqtt = millis();
    while (!mqtt.connected() && millis() - startMqtt < 5000) {
        if (mqtt.connect("ESP32_Modular_Client")) {
            String startMsg = "--- MODULAR SYSTEM V";
            startMsg += SystemCore::VERSION;
            startMsg += " STARTED ---";
            mqtt.publish("esp32/logs", startMsg.c_str());
        } else { delay(500); }
    }

    // 4. Sync Time (CRITICAL for Firebase SSL)
    logToMqtt("Syncing Time...");
    configTime(7 * 3600, 0, "pool.ntp.org", "time.google.com");
    time_t now = time(nullptr);
    while (now < 8 * 3600 * 2) { delay(500); now = time(nullptr); }
    logToMqtt("Time synced!");

    // 5. Initialize Firebase with Auth
    firebaseHandler.setAuth(user_email, user_password);
    firebaseHandler.setTokenCallback(mainTokenStatusCallback);
    firebaseHandler.begin(relayController, climateController, pzemManager, 
                          pcController, macroEngine, energyAnalytics, healthMonitor);
    
    logToMqtt("System Ready");
}

void loop() {
    systemCore.update();
    mqtt.loop();

    // Check for local sync request from PC
    if (systemCore.isSyncPriceRequested()) {
        energyAnalytics.forcePriceSync();
    }

    time_t now = time(nullptr);

    pzemManager.update();
    bool healthExp = healthMonitor.update();
    bool acExp = climateController.update(now);
    bool pcExp = pcController.update(systemCore, now);
    bool relayExp = relayController.updateTimers(now);

    if (healthExp) firebaseHandler.syncHealth();
    if (acExp) firebaseHandler.syncAC();
    if (pcExp) firebaseHandler.syncPC();
    if (relayExp) firebaseHandler.syncRelays();

    int energyStatus = energyAnalytics.update(pzemManager.getMetrics().energy);
    if (energyStatus > 0) {
        if (energyStatus >= 2) pzemManager.resetEnergy();
        firebaseHandler.syncEnergy(); // Background sync on rollover
    }

    firebaseHandler.update();

    if (macroEngine.updateAutoMacro(systemCore, relayController, pcController, climateController, pzemManager.getMetrics().power)) {
        firebaseHandler.syncNotifyCheck();
        // If auto macro triggered state change, sync it (macro index 5)
        // Since execute() is called inside updateAutoMacro, we should sync all macros
        firebaseHandler.syncState(); 
    }

    if (macroEngine.handleHealthAutomation(healthMonitor.getState(), relayController, climateController)) {
        firebaseHandler.syncAC();
        firebaseHandler.syncRelays();
    }

    displayManager.update(pzemManager.getMetrics().power, pcController.isOnline());
}
