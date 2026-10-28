import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/firebase/firebase_service.dart';
import '../data/models/ride_session.dart';

class RideSessionState {
  final RideSession? activeSession;
  final List<RideSession> pastSessions;

  const RideSessionState({
    this.activeSession,
    this.pastSessions = const [],
  });

  bool get isRideActive => activeSession != null;

  int get totalRides => pastSessions.length;

  int get totalCleanAirLiters =>
      pastSessions.fold(0, (sum, s) => sum + s.cleanAirVolumeLiters);

  int get averageEfficiency {
    if (pastSessions.isEmpty) return 0;
    final sum = pastSessions.fold(0, (sum, s) => sum + s.filtrationEfficiency);
    return (sum / pastSessions.length).round();
  }

  RideSessionState copyWith({
    RideSession? activeSession,
    bool clearActiveSession = false,
    List<RideSession>? pastSessions,
  }) {
    return RideSessionState(
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      pastSessions: pastSessions ?? this.pastSessions,
    );
  }
}

final rideSessionProvider =
    StateNotifierProvider<RideSessionNotifier, RideSessionState>((ref) {
  return RideSessionNotifier();
});

class RideSessionNotifier extends StateNotifier<RideSessionState> {
  Timer? _snapshotTimer;
  StreamSubscription? _firestoreSub;

  RideSessionNotifier()
      : super(const RideSessionState(
          pastSessions: [],
        )) {
    _listenToFirebase();
  }

  void _listenToFirebase() {
    try {
      _firestoreSub = FirebaseService.instance.streamRideSessions().listen((rawList) {
        if (rawList.isNotEmpty) {
          final sessions = rawList.map((m) => RideSession.fromMap(m)).toList();
          sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
          state = state.copyWith(pastSessions: sessions);
        }
      });
    } catch (e) {
      debugPrint('[RideSession] Error listening to Firestore: $e');
    }
  }

  /// Start a new ride session when Helmet Fan is turned ON
  void startSession({
    required int insideAqi,
    required int outsideAqi,
    required double temperature,
    required double humidity,
  }) {
    if (state.activeSession != null) return; // already active

    final now = DateTime.now();
    final newSession = RideSession(
      id: 'ride_${now.millisecondsSinceEpoch}',
      startTime: now,
      duration: Duration.zero,
      averageInsideAqi: insideAqi.toDouble(),
      averageOutsideAqi: outsideAqi.toDouble(),
      averageTemperature: temperature,
      averageHumidity: humidity,
      cleanAirVolumeLiters: 0,
      filtrationEfficiency: _calcEfficiency(insideAqi.toDouble(), outsideAqi.toDouble()),
      isCompleted: false,
      dataPoints: [
        RideDataPoint(
          timestamp: now,
          insideAqi: insideAqi,
          outsideAqi: outsideAqi,
          temperature: temperature,
          humidity: humidity,
        ),
      ],
    );

    state = state.copyWith(activeSession: newSession);
    debugPrint('[RideSession] Session started: ${newSession.id}');

    // Start 25-second snapshot timer
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      // Snapshot timer updates live elapsed duration
      _tickLiveDuration();
    });
  }

  void _tickLiveDuration() {
    final active = state.activeSession;
    if (active == null) return;

    final now = DateTime.now();
    final updatedDuration = now.difference(active.startTime);
    final airLiters = (updatedDuration.inSeconds * (8.0 / 60.0)).round();

    final updated = RideSession(
      id: active.id,
      startTime: active.startTime,
      duration: updatedDuration,
      averageInsideAqi: active.averageInsideAqi,
      averageOutsideAqi: active.averageOutsideAqi,
      averageTemperature: active.averageTemperature,
      averageHumidity: active.averageHumidity,
      cleanAirVolumeLiters: airLiters,
      filtrationEfficiency: active.filtrationEfficiency,
      isCompleted: false,
      dataPoints: active.dataPoints,
    );

    state = state.copyWith(activeSession: updated);
  }

  /// Record periodic telemetry snapshot during the active session
  void recordSnapshot({
    required int insideAqi,
    required int outsideAqi,
    required double temperature,
    required double humidity,
  }) {
    final active = state.activeSession;
    if (active == null) return;

    final now = DateTime.now();
    final newPoints = [
      ...active.dataPoints,
      RideDataPoint(
        timestamp: now,
        insideAqi: insideAqi,
        outsideAqi: outsideAqi,
        temperature: temperature,
        humidity: humidity,
      ),
    ];

    // Recalculate running averages
    double sumInside = 0;
    double sumOutside = 0;
    double sumTemp = 0;
    double sumHum = 0;

    for (final pt in newPoints) {
      sumInside += pt.insideAqi;
      sumOutside += pt.outsideAqi;
      sumTemp += pt.temperature;
      sumHum += pt.humidity;
    }

    final count = newPoints.length;
    final avgIn = sumInside / count;
    final avgOut = sumOutside / count;
    final avgT = sumTemp / count;
    final avgH = sumHum / count;
    final eff = _calcEfficiency(avgIn, avgOut);
    final dur = now.difference(active.startTime);
    final airLiters = (dur.inSeconds * (8.0 / 60.0)).round();

    final updated = RideSession(
      id: active.id,
      startTime: active.startTime,
      duration: dur,
      averageInsideAqi: avgIn,
      averageOutsideAqi: avgOut,
      averageTemperature: avgT,
      averageHumidity: avgH,
      cleanAirVolumeLiters: airLiters,
      filtrationEfficiency: eff,
      isCompleted: false,
      dataPoints: newPoints,
    );

    state = state.copyWith(activeSession: updated);
  }

  /// End active session when Helmet Fan is turned OFF
  void endSession() {
    final active = state.activeSession;
    if (active == null) return;

    _snapshotTimer?.cancel();
    _snapshotTimer = null;

    final now = DateTime.now();
    var dur = now.difference(active.startTime);
    if (dur.inSeconds < 10) {
      // Minimum duration clamp for demonstration
      dur = const Duration(minutes: 1);
    }

    final airLiters = (dur.inMinutes * 8).clamp(8, 2000);

    final completed = RideSession(
      id: active.id,
      startTime: active.startTime,
      endTime: now,
      duration: dur,
      averageInsideAqi: active.averageInsideAqi,
      averageOutsideAqi: active.averageOutsideAqi,
      averageTemperature: active.averageTemperature,
      averageHumidity: active.averageHumidity,
      cleanAirVolumeLiters: airLiters,
      filtrationEfficiency: active.filtrationEfficiency,
      isCompleted: true,
      dataPoints: active.dataPoints,
    );

    // Save locally and sync to Firebase Firestore
    state = state.copyWith(
      clearActiveSession: true,
      pastSessions: [completed, ...state.pastSessions],
    );

    FirebaseService.instance.saveRideSession(completed.toMap());
    debugPrint('[RideSession] Session completed & saved: ${completed.id}');
  }

  static int _calcEfficiency(double inside, double outside) {
    if (outside <= 0) return 0;
    final delta = outside - inside;
    return ((delta / outside) * 100).clamp(0, 99).round();
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}
