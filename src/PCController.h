#ifndef PC_CONTROLLER_H
#define PC_CONTROLLER_H

#include <Arduino.h>
#include <WiFiUdp.h>
#include <HTTPClient.h>
#include "SystemCore.h"

#include <time.h>

class PCController {
public:
    explicit PCController(const char* mac, const char* ip, const char* shutdownUrl);
    void wake();
    void shutdown();
    bool update(const SystemCore& core, time_t now = 0);
    bool isOnline() const { return online; }

    void setTimers(time_t start, time_t stop);
    time_t getStartTimer() const { return startTimer; }
    time_t getStopTimer() const { return stopTimer; }

private:
    char macAddressStr[18];
    uint8_t macAddress[6];
    IPAddress ipAddress;
    String shutdownUrl;
    bool online = false;
    
    time_t startTimer = 0;
    time_t stopTimer = 0;

    void parseMacAddress(const char* mac);
};

#endif
