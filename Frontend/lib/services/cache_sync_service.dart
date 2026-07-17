import 'dart:async';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Lightweight background sync — only keeps auth token alive.
/// Analytics, gamification, sessions removed.
class CacheSyncService {
  static const _tag = '[CacheSyncService]';

  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    debugPrint('$_tag started');
  }

  void stop() {
    _running = false;
    debugPrint('$_tag stopped');
  }

  bool get isRunning => _running;

  Future<void> syncNow() async {
    await StorageService.put('last_sync_ts', DateTime.now().toIso8601String());
  }
}
