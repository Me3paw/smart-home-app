#include "FirebaseHandler.h"
#include "RelayController.h"
#include "ClimateController.h"
#include "PZEMManager.h"
#include "PCController.h"
#include "EnergyAnalytics.h"
#include "MacroEngine.h"
#include "HealthMonitor.h"

FirebaseHandler::FirebaseHandler(const char* apiKey, const char* databaseUrl)
    : apiKey(apiKey), databaseUrl(databaseUrl) {}

void FirebaseHandler::setAuth(const char* email, const char* password) {
    userEmail = email;
    userPassword = password;
}

void FirebaseHandler::setTokenCallback(void (*callback)(TokenInfo)) {
    config.token_status_callback = callback;
}

void FirebaseHandler::begin(RelayController& r, ClimateController& ac, PZEMManager& p, 
                            PCController& pc, MacroEngine& m, EnergyAnalytics& e, HealthMonitor& h) {
    relays = &r;
    climate = &ac;
    pzem = &p;
    this->pc = &pc;
    macros = &m;
    energy = &e;
    health = &h;

    config.api_key = apiKey;
    config.database_url = databaseUrl;
    
    // Maintain the 8192 buffer size as requested
    fbdo.setResponseSize(8192);
    streamDo.setResponseSize(1024);
    
    auth.user.email = userEmail;
    auth.user.password = userPassword;

    Serial.println("Connecting to Firebase");
    Firebase.reconnectWiFi(true);
    Firebase.begin(&config, &auth);
    isReady = true;
}

void FirebaseHandler::update() {
    if (!Firebase.ready() || !isReady) return;

    // Initial push to create nodes in Firebase
    if (!firstSyncDone) {
        Serial.println("[Firebase] Performing initial state sync");
        syncState();
        firstSyncDone = true;
    }

    unsigned long now = millis();

    // Periodic command checking
    if (now - lastSync > 2000) {
        handleCommands();
        lastSync = now;
    }

    // High-frequency stream for PZEM if requested by UI
    if (pzemStreamActive && (now - lastPzemSync > 1500)) {
        syncPZEM();
        lastPzemSync = now;
    }
}

void FirebaseHandler::syncPZEM() {
    const PZEMMetrics& m = pzem->getMetrics();
    FirebaseJson json;
    json.add("v", m.voltage); json.add("a", m.current); json.add("w", m.power);
    json.add("e", m.energy); json.add("hz", m.frequency); json.add("pf", m.pf);
    Firebase.RTDB.setJSON(&streamDo, "/device/state/pzem", &json);
}

void FirebaseHandler::syncNotifyCheck() {
    FirebaseJson json;
    json.add("active", macros->getNotifyCheck());
    json.add("acActive", macros->isAcActive());
    json.add("phoneOnline", macros->isPhoneOnline());
    Firebase.RTDB.setJSON(&fbdo, "/device/state/notifyCheck", &json);
}

void FirebaseHandler::syncRelays() {
    FirebaseJsonArray arr;
    for (int i = 0; i < 6; i++) {
        FirebaseJson relay;
        relay.add("state", relays->getState(i));
        relay.add("name", relays->getName(i));
        relay.add("start", (double)relays->getStartTimer(i));
        relay.add("stop", (double)relays->getStopTimer(i));
        arr.add(relay);
    }
    Firebase.RTDB.setArray(&fbdo, "/device/state/relays", &arr);
}

void FirebaseHandler::syncAC() {
    const ACState& acs = climate->getState();
    const ACState& pre = climate->getPreset();
    FirebaseJson json;
    json.add("power", acs.power); json.add("temp", acs.temp);
    json.add("mode", acs.mode); json.add("fan", acs.fan);
    json.add("swingV", acs.swingV); json.add("swingH", acs.swingH);
    json.add("econo", acs.econo); json.add("powerful", acs.powerful);
    json.add("quiet", acs.quiet); json.add("comfort", acs.comfort);
    json.add("timer", acs.timer);
    
    FirebaseJson preset;
    preset.add("power", pre.power); preset.add("temp", pre.temp);
    preset.add("mode", pre.mode); preset.add("fan", pre.fan);
    preset.add("swingV", pre.swingV); preset.add("swingH", pre.swingH);
    preset.add("econo", pre.econo); preset.add("powerful", pre.powerful);
    preset.add("quiet", pre.quiet); preset.add("comfort", pre.comfort);
    json.add("preset", preset);

    Firebase.RTDB.setJSON(&fbdo, "/device/state/ac", &json);
}

void FirebaseHandler::syncPC() {
    FirebaseJson json;
    json.add("online", pc->isOnline());
    json.add("start", (double)pc->getStartTimer());
    json.add("stop", (double)pc->getStopTimer());
    Firebase.RTDB.setJSON(&fbdo, "/device/state/pc", &json);
}

void FirebaseHandler::syncHealth() {
    const HealthState& h = health->getState();
    FirebaseJson json;
    json.add("temp", h.temperature);
    json.add("humid", h.humidity);
    json.add("autoSleep", h.autoSleepEnabled);
    json.add("isHot", h.isHot);
    json.add("isHumid", h.isHumid);
    json.add("lastUpdate", (double)h.lastUpdate);
    json.add("th", h.tempHigh);
    json.add("tl", h.tempLow);
    json.add("hh", h.humidHigh);
    json.add("hl", h.humidLow);
    Firebase.RTDB.setJSON(&fbdo, "/device/state/health", &json);
}

void FirebaseHandler::syncEnergy() {
    FirebaseJson json;
    FirebaseJsonArray tierArr;
    const float* tiers = energy->getTierPrices();
    for (int i = 0; i < 5; i++) tierArr.add(tiers[i]);
    json.add("tierPrices", tierArr);
    
    FirebaseJsonArray monthArr;
    const float* monthly = energy->getMonthlyEnergy();
    for(int i=0; i<31; i++) monthArr.add(monthly[i]);
    json.add("monthly", monthArr);

    FirebaseJsonArray hourArr;
    const float* hourly = energy->getHourlyEnergy();
    for(int i = 0; i < 24; i++) hourArr.add(hourly[i]);
    json.add("hourly", hourArr);
    json.add("dailyUsed", energy->getDailyEnergyUsed());
    Firebase.RTDB.updateNode(&fbdo, "/device/state", &json);
}

void FirebaseHandler::syncState() {
    syncPZEM();
    syncRelays();
    syncAC();
    syncPC();
    syncHealth();
    syncEnergy();
    syncNotifyCheck();
    
    FirebaseJsonArray arr;
    const MacroConfig* mList = macros->getMacros();
    for (int i = 0; i < 6; i++) {
        FirebaseJson m;
        m.add("name", mList[i].name);
        m.add("color", mList[i].color);
        m.add("active", mList[i].is_active);
        
        FirebaseJsonArray r;
        for (int j = 0; j < 6; j++) {
            if (mList[i].relayMask & (1 << j)) r.add(j);
        }
        m.add("relays", r);
        m.add("wake_pc", mList[i].wake_pc);
        m.add("ac_on", mList[i].ac_on);
        arr.add(m);
    }
    Firebase.RTDB.setArray(&fbdo, "/device/state/macros", &arr);
}

void FirebaseHandler::handleCommands() {
    if (Firebase.ready() && Firebase.RTDB.getJSON(&fbdo, "/device/cmd")) {
        if (fbdo.dataType() == "json" && fbdo.jsonString() != "null") {
            // First parse the JSON into a document to safely clear the buffer
            JsonDocument doc;
            DeserializationError error = deserializeJson(doc, fbdo.jsonString());

            if (error) {
                Serial.printf("[Firebase] Deserialization failed: %s\n", error.c_str());
                // Even on error, we might want to clear the node if it's corrupting things
                // But let's only clear if we successfully parsed or if we use a separate object
            }

            // Use a separate FirebaseData to delete the node so fbdo's JSON remains valid until parsed
            // Actually, we already parsed into 'doc', so we can use fbdo now.
            if (!Firebase.RTDB.deleteNode(&fbdo, "/device/cmd")) {
                Serial.printf("[Firebase] Failed to clear command queue: %s\n", fbdo.errorReason().c_str());
                // If deletion fails, we return to avoid re-processing the same commands
                // However, 'fbdo' is now clobbered by the delete result.
                return; 
            }

            if (error) return; // Exit if parsing failed after trying to clear

            JsonObject root = doc.as<JsonObject>();

            bool relayChanged = false;
            bool acChanged = false;
            bool pcChanged = false;

            for (JsonPair p : root) {
                JsonObject cmd = p.value().as<JsonObject>();
                if (!cmd.containsKey("type")) continue;
                
                String type = cmd["type"];
                if (type == "relay_toggle") {
                    relays->toggle(cmd["index"]);
                    relayChanged = true;
                }
                else if (type == "relay_set") {
                    relays->set(cmd["index"], cmd["state"]);
                    relayChanged = true;
                }
                else if (type == "relay_all") {
                    relays->setAll(cmd["state"]);
                    relayChanged = true;
                }
                else if (type == "relay_rename") {
                    relays->rename(cmd["index"], cmd["name"]);
                    relayChanged = true;
                }
                else if (type == "relay_timer") {
                    relays->setTimers(cmd["index"], cmd["start"], cmd["stop"]);
                    relayChanged = true;
                }
                else if (type == "ac_cmd") {
                    climate->sendCommand(cmd["cmd"]);
                    acChanged = true;
                }
                else if (type == "ac_timer") {
                    climate->setTimer(cmd["target"]);
                    acChanged = true;
                }
                else if (type == "pc_cmd") {
                    String action = cmd["action"];
                    if (action == "wake") pc->wake();
                    else if (action == "shutdown") pc->shutdown();
                    pcChanged = true;
                }
                else if (type == "pc_timer") {
                    pc->setTimers(cmd["start"], cmd["stop"]);
                    pcChanged = true;
                }
                else if (type == "health_cmd") {
                    if (cmd.containsKey("autoSleep")) {
                        health->setAutoSleep(cmd["autoSleep"]);
                        syncHealth();
                    }
                }
                else if (type == "health_thresholds") {
                    float th = cmd["th"] | 28.5f;
                    float tl = cmd["tl"] | 26.0f;
                    float hh = cmd["hh"] | 60.0f;
                    float hl = cmd["hl"] | 55.0f;
                    health->setThresholds(th, tl, hh, hl);
                    syncHealth();
                }
                else if (type == "health_sim") {
                    float t = cmd["temp"] | 0.0f;
                    float h = cmd["humid"] | 0.0f;
                    HealthState fake;
                    fake.temperature = t;
                    fake.humidity = h;
                    fake.autoSleepEnabled = true; // Force test for logic verification
                    if (macros->handleHealthAutomation(fake, *relays, *climate)) {
                        syncAC();
                        syncRelays();
                    }
                }
                else if (type == "ac_save_preset") {
                    if (cmd.containsKey("power")) {
                        ACState s;
                        s.power = cmd["power"];
                        s.temp = cmd["temp"] | 24;
                        s.mode = cmd["mode"] | kDaikinCool;
                        s.fan = cmd["fan"] | kDaikinFanAuto;
                        s.swingV = cmd["swingV"] | false;
                        s.swingH = cmd["swingH"] | false;
                        s.econo = cmd["econo"] | false;
                        s.powerful = cmd["powerful"] | false;
                        s.quiet = cmd["quiet"] | false;
                        s.comfort = cmd["comfort"] | false;
                        climate->savePreset(s);
                    } else {
                        climate->savePreset();
                    }
                    syncAC();
                    syncState();
                }
                else if (type == "macro_update") {
                    int idx = cmd["index"];
                    JsonObject configData = cmd["config"];
                    MacroConfig m;
                    
                    String name = configData["name"] | "Empty";
                    String color = configData["color"] | "white";
                    strncpy(m.name, name.c_str(), sizeof(m.name) - 1);
                    strncpy(m.color, color.c_str(), sizeof(m.color) - 1);
                    m.name[sizeof(m.name)-1] = '\0';
                    m.color[sizeof(m.color)-1] = '\0';

                    m.wake_pc = configData["wake_pc"];
                    m.ac_on = configData["ac_on"];
                    m.is_active = false; // Reset state on update

                    uint8_t mask = 0;
                    JsonArray relaysArr = configData["relays"];
                    for (int r : relaysArr) {
                        if (r >= 0 && r < 6) mask |= (1 << r);
                    }
                    m.relayMask = mask;

                    macros->updateConfig(idx, m);
                    syncState();
                }
                else if (type == "sync_prices") {
                    energy->forcePriceSync();
                }
                else if (type == "sync") {
                    String target = cmd["target"] | "none";
                    if (target == "ac") syncAC();
                    else if (target == "pzem") syncPZEM();
                    else if (target == "relays") syncRelays();
                    else if (target == "pc") syncPC();
                    else if (target == "energy") syncEnergy();
                    else if (target == "all") syncState();
                }
                else if (type == "start_stream") {
                    pzemStreamActive = true;
                }
                else if (type == "stop_stream") {
                    pzemStreamActive = false;
                }
                // No need to delete individually anymore
            }
            
            if (relayChanged) syncRelays();
            if (acChanged) syncAC();
            if (pcChanged) syncPC();
        }
    } else {
        // If it's not "path not found" error, log it
        if (fbdo.errorReason() != "path not found") {
            Serial.printf("[Firebase] getJSON error: %s\n", fbdo.errorReason().c_str());
        }
    }
}
