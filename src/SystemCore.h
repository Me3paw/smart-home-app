#ifndef SYSTEM_CORE_H
#define SYSTEM_CORE_H

#include <Arduino.h>
#include <WiFi.h>
#include <ArduinoOTA.h>
#include <WebServer.h>

class SystemCore {
public:
    static constexpr const char* VERSION = "2.1.0";
    SystemCore(const char* ssid, const char* password);
    void setStaticIP(IPAddress local, IPAddress gateway, IPAddress subnet, IPAddress dns);
    void setPingTargets(IPAddress pc, IPAddress phone);
    void begin();
    void update();
    bool isConnected() const { return WiFi.status() == WL_CONNECTED; }
    bool isSyncPriceRequested() { if(syncPriceRequested) { syncPriceRequested = false; return true; } return false; }
    
    // Status getters for controllers
    bool isPcOnline() const { return pcOnline; }
    bool isPhoneOnline() const { return phoneOnline; }

private:
    const char* ssid;
    const char* password;
    
    bool useStaticIP = false;
    IPAddress localIP;
    IPAddress gateway;
    IPAddress subnet;
    IPAddress dns;

    // Ping targets and status
    IPAddress pcIP;
    IPAddress phoneIP;
    volatile bool pcOnline = false;
    volatile bool phoneOnline = false;
    int phoneStrikes = 0;
    TaskHandle_t pingTaskHandle = NULL;

    WebServer server{54380};
    bool syncPriceRequested = false;

    void setupWiFi();
    void setupOTA();
    void setupServer();
    static void pingTask(void* pvParameters);
};

#endif
