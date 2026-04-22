#ifndef RELAY_CONTROLLER_H
#define RELAY_CONTROLLER_H

#include <Arduino.h>
#include <Preferences.h>

#include <time.h>

class RelayController {
public:
    static const int NUM_RELAYS = 6;
    RelayController();
    void begin();
    void toggle(int index);
    void set(int index, bool state);
    void setAll(bool state);
    bool getState(int index) const;
    const bool* getStates() const;

    void rename(int index, const char* name);
    const char* getName(int index) const;
    void setTimers(int index, time_t start, time_t stop);
    time_t getStartTimer(int index) const { return startTimers[index]; }
    time_t getStopTimer(int index) const { return stopTimers[index]; }
    bool updateTimers(time_t now);

private:
    static const int relayPins[NUM_RELAYS];
    bool relayStates[NUM_RELAYS];
    char relayNames[NUM_RELAYS][32];
    time_t startTimers[NUM_RELAYS];
    time_t stopTimers[NUM_RELAYS];
    Preferences preferences;

    void saveConfig();
    void loadConfig();
};

#endif
