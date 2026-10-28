import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/outdoor_service.dart';
import '../data/models/outdoor_data.dart';

final outdoorDataProvider =
    StateNotifierProvider<OutdoorDataNotifier, OutdoorData>((ref) {
  return OutdoorDataNotifier();
});

class OutdoorDataNotifier extends StateNotifier<OutdoorData> {
  Timer? _timer;

  OutdoorDataNotifier() : super(OutdoorData.initial()) {
    refresh();
    // Refresh GPS weather and AQI every 10 minutes
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => refresh());
  }

  Future<void> refresh() async {
    final updated = await OutdoorService.instance.fetchOutdoorData();
    state = updated;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
