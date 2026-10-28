/*
  Pure Helmet - ESP32 Bluetooth Serial (SPP) Companion Code
  
  This sketch transmits live air quality (PM2.5), battery percentage,
  and purification status to the Pure mobile app via Bluetooth Classic Serial.
  It also listens for incoming commands from the app (e.g. FAN:1, FAN:0, PING).
*/

#include "BluetoothSerial.h"

// Check if Bluetooth is enabled in the configuration
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run make menuconfig to enable it
#endif

BluetoothSerial SerialBT;

// Configuration
const char* deviceName = "Pure_Helmet_ESP32"; // App looks for this device
const int ledPin = 2;                         // Status LED or Fan PWM pin
unsigned long lastSendTime = 0;
const unsigned long sendInterval = 2000;      // Send telemetry every 2 seconds

// Simulated or Sensor values (replace with your sensor reading logic)
float pm25Value = 35.0;
int batteryLevel = 88;
bool isPurifying = true;

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);

  // Initialize Bluetooth Serial
  SerialBT.begin(deviceName);
  Serial.println("==========================================");
  Serial.print("ESP32 Bluetooth Serial Started: ");
  Serial.println(deviceName);
  Serial.println("Pair with this device in phone Settings > Bluetooth");
  Serial.println("==========================================");
}

void loop() {
  // 1. Listen for incoming commands from Pure App
  if (SerialBT.available()) {
    String incoming = SerialBT.readStringUntil('\n');
    incoming.trim();
    Serial.print("[App -> ESP32 Received]: ");
    Serial.println(incoming);

    if (incoming == "PING") {
      SerialBT.println("PONG");
    } else if (incoming == "FAN:1" || incoming == "STATUS:ON") {
      isPurifying = true;
      digitalWrite(ledPin, HIGH);
      SerialBT.println("{\"status\":\"ok\",\"fan\":\"on\"}");
    } else if (incoming == "FAN:0" || incoming == "STATUS:OFF") {
      isPurifying = false;
      digitalWrite(ledPin, LOW);
      SerialBT.println("{\"status\":\"ok\",\"fan\":\"off\"}");
    } else if (incoming == "READ" || incoming == "STATUS") {
      sendTelemetry();
    }
  }

  // 2. Transmit periodic sensor readings to App
  if (millis() - lastSendTime >= sendInterval) {
    lastSendTime = millis();
    sendTelemetry();
  }
}

void sendTelemetry() {
  // Simulated small fluctuation (Replace with your actual PMS5003 / SDS011 reading)
  pm25Value += (random(-20, 25) / 10.0);
  if (pm25Value < 5.0) pm25Value = 5.0;
  if (pm25Value > 150.0) pm25Value = 150.0;

  // JSON formatted payload
  String payload = "{\"pm25\":" + String(pm25Value, 1) + 
                   ",\"battery\":" + String(batteryLevel) + 
                   ",\"purifying\":" + (isPurifying ? "true" : "false") + "}";

  SerialBT.println(payload);
  Serial.print("[ESP32 -> App Sent]: ");
  Serial.println(payload);
}
