# Pure – Smart Air-Purifying Helmet Companion App

<p align="center">
  <img src="assets/images/pure_logo.png" width="128" height="128" alt="Pure Leaf Logo" />
</p>

<p align="center">
  <b>Breathe Clean. Ride Safe.</b><br>
  Real-time environmental telemetry, smart air purification control, and microclimate intelligence for motorcyclists.
</p>

---

## 🌟 Key Features

- **🛡️ Real-Time Microclimate Telemetry**:
  - Live Helmet AQI vs. Ambient Outdoor City AQI
  - Temperature Delta & Relative Humidity Monitoring
  - Helmet Fog Risk intelligence powered by the Magnus-Tetens Dew Point approximation
  - Feels-like Apparent Heat Index & Metal-Oxide Gas Resistance tracking

- **💨 Smart Purifier Control**:
  - Wireless ESP32 Bluetooth Classic integration (`ON` / `OFF` signals)
  - Animated blower UI with real-time haptic feedback
  - Automated ride session lifecycle management

- **📐 Interactive Math Calculation Breakdowns**:
  - Interactive `(ℹ️)` info popups across Home, Info, and History screens
  - Transparent formula explanations, live variable values, step-by-step arithmetic calculations, and official environmental standards references (EPA AQI, NOAA, OSHA)

- **📊 Comprehensive Ride History & Cloud Sync**:
  - Filter efficiency tracking across rides
  - Cumulative clean air volume delivery calculations
  - Firebase Auth (Google Sign-In) & Cloud Firestore persistence

- **🌱 Authentic Pure Leaf Branding**:
  - Custom Pure Leaf icon emblem across Android Launcher (adaptive icon), splash screen, sign-in screen, and app header.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x)
- **State Management**: [Riverpod 2.x](https://riverpod.dev) (`StateNotifierProvider`, `StreamProvider`, `ref.watch/read`)
- **UI & Animations**: `flutter_animate`, `google_fonts` (Sora & Inter), `gap`
- **Charts & Graphs**: `fl_chart`
- **Hardware & Connectivity**: `flutter_bluetooth_serial` (ESP32 Bluetooth Classic SPP), `geolocator`
- **Backend & Cloud**: Firebase Core, Firebase Auth, Cloud Firestore

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.11.1)
- Android SDK (API 26+)
- Physical Android device with Bluetooth Classic support

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ayushdata06-rgb/Pure.git
   cd Pure
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on connected device**:
   ```bash
   flutter run
   ```

---

## 🔌 Hardware Setup (ESP32)

Arduino/ESP32 sketch is provided under [`esp32_example/esp32_bluetooth_serial.ino`](esp32_example/esp32_bluetooth_serial.ino).
- **Device Name**: `PureHelmet`
- **Baud Rate**: 115200
- **Commands**: `ON\n` activates purifier blower; `OFF\n` returns to standby.
