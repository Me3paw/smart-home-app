#include "SystemCore.h"
#include <ESP32Ping.h>

SystemCore::SystemCore(const char* ssid, const char* password) 
    : ssid(ssid), password(password) {}

void SystemCore::setStaticIP(IPAddress local, IPAddress gateway, IPAddress subnet, IPAddress dns) {
    this->localIP = local;
    this->gateway = gateway;
    this->subnet = subnet;
    this->dns = dns;
    this->useStaticIP = true;
}

void SystemCore::setPingTargets(IPAddress pc, IPAddress phone) {
    this->pcIP = pc;
    this->phoneIP = phone;
    Serial.printf("[System] Ping targets set: PC=%s, Phone=%s\n", pc.toString().c_str(), phone.toString().c_str());
}

void SystemCore::begin() {
    setupWiFi();
    setupOTA();
    setupServer();
    configTime(7 * 3600, 0, "pool.ntp.org", "time.google.com");

    // Start background ping task on Core 0
    xTaskCreatePinnedToCore(
        this->pingTask,
        "PingTask",
        4096,
        this,
        1,
        &pingTaskHandle,
        0 // Run on Core 0
    );
}

void SystemCore::pingTask(void* pvParameters) {
    SystemCore* core = (SystemCore*)pvParameters;
    unsigned long lastPcPing = 0;
    unsigned long lastPhonePing = 0;

    while (true) {
        if (WiFi.status() == WL_CONNECTED) {
            unsigned long now = millis();

            // PC Ping logic
            unsigned long pcInterval = core->pcOnline ? 30000 : 5000;
            if (now - lastPcPing > pcInterval) {
                core->pcOnline = Ping.ping(core->pcIP, 1);
                lastPcPing = now;
            }

            // Phone Ping logic
            unsigned long phoneInterval = core->phoneOnline ? 60000 : 5000;
            if (now - lastPhonePing > phoneInterval) {
                bool isAlive = Ping.ping(core->phoneIP, 1);
                if (isAlive) {
                    core->phoneOnline = true;
                    core->phoneStrikes = 0; // Reset strikes if we found the phone
                } else {
                    if (core->phoneOnline) {
                        core->phoneStrikes++;
                        if (core->phoneStrikes >= 3) {
                            core->phoneOnline = false;
                            core->phoneStrikes = 0;
                        }
                    } else {
                        core->phoneStrikes = 0; // Reset strikes if already offline
                    }
                }
                lastPhonePing = now;
            }
        }
        vTaskDelay(pdMS_TO_TICKS(100)); // Yield to other tasks
    }
}

void SystemCore::update() {
    ArduinoOTA.handle();
    server.handleClient();
}

void SystemCore::setupServer() {
    server.on("/sync_price", HTTP_GET, [this]() {
        syncPriceRequested = true;
        server.send(200, "text/plain", "Sync Triggered");
        Serial.println("[System] Local Sync Requested");
    });
    server.begin();
    Serial.println("[System] Local Server Started on port 54380");
}

void SystemCore::setupWiFi() {
    if (useStaticIP) {
        if (!WiFi.config(localIP, gateway, subnet, dns)) {
            Serial.println("STA Failed to configure static IP");
        } else {
            Serial.println("Static IP configured");
        }
    }

    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi connected");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
}

void SystemCore::setupOTA() {
    ArduinoOTA.setHostname("SmartHome-ESP32S3");
    ArduinoOTA.setPassword("admin");
    ArduinoOTA.begin();
}
