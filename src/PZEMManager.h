#ifndef PZEM_MANAGER_H
#define PZEM_MANAGER_H

#include <Arduino.h>
#include <PZEM004Tv30.h>

struct PZEMMetrics {
    float voltage = 0.0;
    float current = 0.0;
    float power = 0.0;
    float energy = 0.0;
    float frequency = 0.0;
    float pf = 0.0;
};

class PZEMManager {
public:
    PZEMManager(HardwareSerial& serial, int rx, int tx);
    void update();
    void resetEnergy();
    const PZEMMetrics& getMetrics() const { return metrics; }

private:
    PZEM004Tv30 pzem;
    PZEMMetrics metrics;
    unsigned long lastReadTime = 0;
};

#endif
