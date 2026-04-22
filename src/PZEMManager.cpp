#include "PZEMManager.h"

PZEMManager::PZEMManager(HardwareSerial& serial, int rx, int tx) : pzem(serial, rx, tx) {}

void PZEMManager::update() {
    if (millis() - lastReadTime < 2000) return;
    lastReadTime = millis();

    float v = pzem.voltage();
    float a = pzem.current();
    float w = pzem.power();
    float e = pzem.energy();
    float hz = pzem.frequency();
    float pf = pzem.pf();

    metrics.voltage = isnan(v) ? 0.0 : v;
    metrics.current = isnan(a) ? 0.0 : a;
    metrics.power = isnan(w) ? 0.0 : w;
    metrics.energy = isnan(e) ? 0.0 : e;
    metrics.frequency = isnan(hz) ? 0.0 : hz;
    metrics.pf = isnan(pf) ? 0.0 : pf;
}

void PZEMManager::resetEnergy() {
    pzem.resetEnergy();
}
