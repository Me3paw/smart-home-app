#include <WiFi.h>
#include <PubSubClient.h>
#include <PZEM004Tv30.h>

// ================= CẤU HÌNH =================
const char* ssid = "WIFI_SSID_PLACEHOLDER"; 
const char* password = "WIFI_PASS_PLACEHOLDER";
const char* mqtt_server = "192.168.1.27"; 

// ================= PINOUT (Hot-glued) =================
// TRÊN S3, 9 VÀ 10 THƯỜNG LÀ CỔNG SERIAL MẶC ĐỊNH
#define PZEM_RX_PIN 9 
#define PZEM_TX_PIN 10  

// ================= KHỞI TẠO =================
WiFiClient espClient;
PubSubClient client(espClient);

// Sử dụng Serial (Hardware Port 0) cho PZEM
PZEM004Tv30 pzem(Serial, PZEM_RX_PIN, PZEM_TX_PIN);

unsigned long lastPzemMsg = 0;

void setup_wifi() {
  // Không dùng Serial.print ở đây vì nó sẽ gửi rác vào PZEM
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }
}

void setup() {
  // KHÔNG GỌI Serial.begin(115200) - Để tránh chiếm dụng chân 9, 10
  
  // 1. WiFi & MQTT
  setup_wifi();
  client.setServer(mqtt_server, 1883);

  // 2. Khởi tạo Serial cho PZEM (Sử dụng chân 9, 10 mặc định)
  // Hardware Serial 0 trên S3 thường là chân 43/44 hoặc 9/10 tùy board
  // Ta ép nó vào 9 và 10
  Serial.begin(9600, SERIAL_8N1, PZEM_RX_PIN, PZEM_TX_PIN);
  delay(2000);
  
  // Reset địa chỉ PZEM về mặc định
  pzem.setAddress(0x01);
}

void reconnect() {
  while (!client.connected()) {
    if (client.connect("ESP32_Smart_S3_Final")) {
      client.publish("smarthome/debug", "{\"msg\":\"ESP32 S3 System Online\"}");
    } else {
      delay(5000);
    }
  }
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    setup_wifi();
    return;
  }

  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long now = millis();

  // Đọc mỗi 3 giây
  if (now - lastPzemMsg > 3000) {
    lastPzemMsg = now;

    float v = pzem.voltage();
    float i = pzem.current();
    float p = pzem.power();

    char payload[200];
    if (isnan(v)) {
      // Nếu lỗi, gửi log qua MQTT thay vì Serial
      sprintf(payload, "{\"status\":\"FAIL\", \"msg\":\"NaN on Pins 9/10. Check if USB-Serial chip is fighting!\"}");
    } else {
      sprintf(payload, "{\"status\":\"OK\", \"V\":%.1f, \"A\":%.3f, \"W\":%.1f}", v, i, p);
    }
    client.publish("smarthome/pzem/data", payload);
  }
}
