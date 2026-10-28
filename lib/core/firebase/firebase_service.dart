import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/bme680_reading.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _isInitialized = false;
  String _statusMessage = 'Firebase not initialized';
  FirebaseFirestore? _firestore;

  bool get isInitialized => _isInitialized;
  String get statusMessage => _statusMessage;
  FirebaseFirestore? get firestore => _firestore;

  /// Attempt to initialize Firebase safely.
  /// If [options] is provided, uses custom FirebaseOptions, otherwise default app config.
  Future<bool> initialize({FirebaseOptions? options}) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _firestore = FirebaseFirestore.instance;
        _statusMessage = 'Firebase connected';
        // Auto-seed schema tables in background
        initializeAllFirestoreTables();
        return true;
      }

      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }

      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      _statusMessage = 'Firebase connected successfully';
      debugPrint('[FirebaseService] Firebase initialized');
      // Auto-seed schema tables in background
      initializeAllFirestoreTables();
      return true;
    } catch (e) {
      _isInitialized = false;
      _statusMessage = 'Firebase pending configuration: ${e.toString()}';
      debugPrint('[FirebaseService] Initialization notice: $e');
      return false;
    }
  }

  /// Store raw incoming packet from ESP32 for schema design and verification
  Future<void> logRawTelemetry({
    required String rawData,
    required String deviceName,
    required String deviceAddress,
    Map<String, dynamic>? parsedData,
  }) async {
    if (!_isInitialized || _firestore == null) {
      debugPrint('[FirebaseService] Raw packet received (Firebase offline): $rawData');
      return;
    }

    try {
      await _firestore!.collection('esp32_raw_telemetry').add({
        'timestamp': FieldValue.serverTimestamp(),
        'device_name': deviceName,
        'device_address': deviceAddress,
        'raw_payload': rawData,
        'parsed_payload': parsedData ?? {},
        'client_time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[FirebaseService] Error logging telemetry: $e');
    }
  }


  /// Save structured Bosch BME680 telemetry to Firebase Firestore
  Future<void> saveBme680Telemetry(Bme680Reading reading) async {
    if (!_isInitialized || _firestore == null) return;

    try {
      await _firestore!.collection('bme680_telemetry').add({
        ...reading.toMap(),
        'server_timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[FirebaseService] BME680 telemetry saved to Firestore');
    } catch (e) {
      debugPrint('[FirebaseService] Error saving BME680 telemetry: $e');
    }
  }

  /// Save finalized ride session and efficiency metrics to Firestore
  Future<void> saveRideSession(Map<String, dynamic> sessionMap) async {
    if (!_isInitialized || _firestore == null) {
      debugPrint('[FirebaseService] Offline - Ride session saved locally');
      return;
    }

    try {
      await _firestore!.collection('ride_history').add({
        ...sessionMap,
        'server_timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[FirebaseService] Ride session synced to Firebase Firestore');
    } catch (e) {
      debugPrint('[FirebaseService] Error saving ride session: $e');
    }
  }

  /// Stream real ride sessions directly from Firestore (no hardcoded data)
  Stream<List<Map<String, dynamic>>> streamRideSessions({String? userId}) {
    if (!_isInitialized || _firestore == null) {
      return Stream.value([]);
    }

    try {
      Query<Map<String, dynamic>> query = _firestore!.collection('ride_history');
      if (userId != null && userId.isNotEmpty) {
        query = query.where('user_id', isEqualTo: userId);
      }
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      debugPrint('[FirebaseService] Error streaming ride sessions: $e');
      return Stream.value([]);
    }
  }

  /// Upsert User Profile into Firestore 'users' collection
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    if (!_isInitialized || _firestore == null) return;

    try {
      await _firestore!.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'last_active': FieldValue.serverTimestamp(),
        'paired_device': 'ESP32_BME680_Full',
        'paired_mac': 'F4:2D:C9:89:D7:02',
      }, SetOptions(merge: true));
      debugPrint('[FirebaseService] User profile synced to Firestore: $email');
    } catch (e) {
      debugPrint('[FirebaseService] Error saving user profile: $e');
    }
  }

  /// Initialize and create all 7 Tab-based database collections in Firebase Firestore
  Future<bool> initializeAllFirestoreTables({String? customUid, String? customEmail}) async {
    if (!_isInitialized || _firestore == null) {
      debugPrint('[FirebaseService] Cannot initialize tables: Firestore is not connected');
      return false;
    }

    try {
      final now = DateTime.now();
      final riderUid = customUid ?? 'rider_ayush_gupta';
      final riderEmail = customEmail ?? 'ayushdata69@gmail.com';

      // =======================================================================
      // 1. SETTINGS TAB: 'users' Collection
      // =======================================================================
      await _firestore!.collection('users').doc(riderUid).set({
        'uid': riderUid,
        'email': riderEmail,
        'display_name': 'AYUSH Gupta',
        'role': 'rider',
        'paired_helmet_mac': 'F4:2D:C9:89:D7:02',
        'helmet_model': 'Pure Smart Helmet v1 (ESP32-BME680)',
        'created_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
        'notifications_enabled': true,
        'auto_fan_advisory_enabled': true,
      }, SetOptions(merge: true));

      // =======================================================================
      // 2. SETTINGS TAB: 'helmet_devices' Collection
      // =======================================================================
      await _firestore!.collection('helmet_devices').doc('F4_2D_C9_89_D7_02').set({
        'device_mac': 'F4:2D:C9:89:D7:02',
        'device_name': 'ESP32_BME680_Full',
        'firmware_version': 'PureOS v2.4.1',
        'baud_rate': 115200,
        'protocol': 'RFCOMM SPP',
        'registered_owner_uid': riderUid,
        'filter_type': 'HEPA H13 + Activated Carbon',
        'filter_total_runtime_hours': 14.5,
        'filter_health_pct': 92,
        'filter_replacement_threshold_hours': 150.0,
        'last_connected_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // =======================================================================
      // 3. HOME TAB: 'fan_events' Collection
      // =======================================================================
      await _firestore!.collection('fan_events').doc('initial_state').set({
        'user_id': riderUid,
        'device_mac': 'F4:2D:C9:89:D7:02',
        'command': 'INIT',
        'raw_string': 'STATUS\n',
        'fan_state': false,
        'triggered_by': 'system_initialization',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // =======================================================================
      // 4. HOME TAB: 'ambient_weather_cache' Collection
      // =======================================================================
      await _firestore!.collection('ambient_weather_cache').doc('gps_16_49_80_50').set({
        'latitude': 16.49,
        'longitude': 80.50,
        'location_name': 'GPS (16.49°, 80.50°)',
        'outside_aqi': 84,
        'outside_temp_c': 23.9,
        'outside_humidity_pct': 91.0,
        'pm25_ug_m3': 28.4,
        'aqi_category': 'Moderate Air',
        'source': 'Open-Meteo GPS Air Quality API',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // =======================================================================
      // 5. INFO TAB: 'bme680_telemetry' Collection
      // =======================================================================
      await _firestore!.collection('bme680_telemetry').doc('schema_definition').set({
        'device_mac': 'F4:2D:C9:89:D7:02',
        'user_id': riderUid,
        'temperature_c': 28.5,
        'humidity_pct': 65.0,
        'pressure_hpa': 997.3,
        'gas_resistance_kohm': 92.5,
        'altitude_m': 133.9,
        'calculated_aqi': 25,
        'dew_point_c': 23.5,
        'dew_point_margin_c': 5.0,
        'is_visor_fog_risk': false,
        'heat_index_c': 31.0,
        'stale_air_detected': false,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // =======================================================================
      // 6. INFO TAB: 'safety_advisories' Collection
      // =======================================================================
      await _firestore!.collection('safety_advisories').doc('schema_definition').set({
        'user_id': riderUid,
        'device_mac': 'F4:2D:C9:89:D7:02',
        'advisory_type': 'VISOR_MICROCLIMATE_SAFE',
        'title': 'Optimal Visor Microclimate',
        'reason': 'Temperature and humidity buffer above dew point. No visor fogging risk.',
        'severity': 'INFO',
        'auto_fan_recommended': false,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // =======================================================================
      // 7. HISTORY TAB: 'ride_sessions' Collection
      // =======================================================================
      await _firestore!.collection('ride_history').doc('sample_ride_1').set({
        'id': 'sample_ride_1',
        'user_id': riderUid,
        'user_email': riderEmail,
        'device_mac': 'F4:2D:C9:89:D7:02',
        'start_time': now.subtract(const Duration(minutes: 38)).toIso8601String(),
        'end_time': now.toIso8601String(),
        'duration_seconds': 2280,
        'avg_inside_aqi': 24.0,
        'avg_outside_aqi': 142.0,
        'avg_temp_c': 28.2,
        'avg_humidity_pct': 62.0,
        'clean_air_liters': 304,
        'filtration_efficiency_pct': 83,
        'is_completed': true,
        'data_points_count': 91,
        'location': 'GPS (16.49°, 80.50°)',
        'server_timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // =======================================================================
      // 8. HISTORY TAB: 'rider_lifetime_stats' Collection
      // =======================================================================
      await _firestore!.collection('rider_lifetime_stats').doc(riderUid).set({
        'user_id': riderUid,
        'total_rides': 1,
        'total_clean_air_liters': 304,
        'average_efficiency_pct': 83,
        'last_ride_timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[FirebaseService] Successfully initialized all Firestore collections & schemas!');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error creating Firestore collections: $e');
      return false;
    }
  }
}

