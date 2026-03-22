import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../sync/sync_service.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final SyncService _syncService;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _metricsTimer;

  ConnectivityService({Connectivity? connectivity, SyncService? syncService})
      : _connectivity = connectivity ?? Connectivity(),
        _syncService = syncService ?? SyncService();

  void startListening({Duration statsInterval = const Duration(minutes: 5)}) {
    _subscription ??= _connectivity.onConnectivityChanged.listen((results) async {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (kDebugMode) {
        debugPrint('Connectivity changed: $result');
      }
      if (result != ConnectivityResult.none) {
        await _syncService.syncPendingOperations(null);
      }
    });

    _metricsTimer ??= Timer.periodic(statsInterval, (_) async {
      if (kDebugMode) {
        debugPrint('ConnectivityService periodic sync trigger');
      }
      await _syncService.syncPendingOperations(null);
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _metricsTimer?.cancel();
    _metricsTimer = null;
  }

  Future<SyncHealth> getCurrentHealth() async {
    return _syncService.getSyncHealth();
  }

  Future<SyncHealth?> getPersistedHealth() async {
    return _syncService.loadPersistedHealth();
  }
}
