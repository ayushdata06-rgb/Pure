# Pure Helmet - ESP32 Bluetooth & Firebase Integration Guide

This guide explains how to connect your **ESP32** microcontroller with the **Pure Helmet Companion App** over **Bluetooth Classic (SPP)**, inspect incoming sensor packets live, and link **Google Firebase Firestore**.

---

## 1. Quick Workflow

```
[ ESP32 ] --(Bluetooth Classic / SPP)--> [ Pure Mobile App ]
                                                │
                                    ┌───────────┴───────────┐
                                    ▼                       ▼
                        [ Raw Data Inspector ]    [ Google Firebase ]
                        • Live Monospace Stream   • Automatic sync
                        • HEX / ASCII view        • `esp32_raw_telemetry`
                        • Schema Auto-detection   • Ready for final schema
```

---

## 2. Pairing & Connecting the ESP32

1. **Upload your ESP32 sketch**:
   - An example sketch is available at [`esp32_example/esp32_bluetooth_serial.ino`](file:///d:/helmet/pure/esp32_example/esp32_bluetooth_serial.ino).
   - In Arduino IDE or PlatformIO, ensure `#include "BluetoothSerial.h"` is used and `SerialBT.begin("Pure_Helmet_ESP32")` is called.
2. **Pair in Android Settings**:
   - Open Android **Settings** > **Bluetooth**.
   - Tap your ESP32 device (e.g. `Pure_Helmet_ESP32` or your custom device name) and pair with it.
3. **Open Pure App**:
   - Tap the **"ESP32 Raw Monitor"** button in the top bar or the **Connection Status Chip** on the Home screen.
   - Tap **"Pick ESP32"**, select your paired ESP32 device, and tap **"Connect"**.

---

## 3. Raw Data Inspector & Schema Detection

The **ESP32 Serial Monitor** screen provides:
- **Live Terminal**: High-contrast, real-time scrolling console showing every packet with millisecond timestamps (`[HH:mm:ss.SSS]`), TX/RX direction, and byte length.
- **HEX / ASCII toggle**: Switch between human-readable text and raw hexadecimal bytes.
- **Payload Analyzer**: Automatically identifies whether your incoming stream is **JSON**, **CSV**, **Single Numeric Value**, or **Custom Plaintext**.
- **Bidirectional Command Bar**: Send test commands (e.g. `PING`, `STATUS`, `FAN:1`, `FAN:0`, or custom strings) directly to the ESP32.
- **Copy / Export**: One-tap copy of all received packets to share the exact payload format for schema finalization.

---

## 4. Google Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create or open your project.
2. Enable **Cloud Firestore** in test mode or production mode.
3. Download your `google-services.json` file and place it in:
   ```
   d:/helmet/pure/android/app/google-services.json
   ```
4. The app's [`FirebaseService`](file:///d:/helmet/pure/lib/core/firebase/firebase_service.dart) will automatically store all incoming packets into the `esp32_raw_telemetry` collection.
5. Once we see the exact data format your ESP32 transmits, we will design the structured Firestore collections and Dart schemas.
