import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'analytics_service.dart';
import 'gamification_service.dart';
import '../models/analytics_model.dart';

// ── CacheSyncService ──────────────────────────────────────────────────────────
/// Runs a periodic background timer (every 15 min) that silently refreshes the
/// core cached endpoints: gamification state, analytics dashboard, streak, and
/// weekly report.
///
/// The service writes JSON-encoded payloads directly into the Hive box via
/// [StorageService] using the same cache keys the individual service classes
/// read. This means every [FutureProvider.autoDispose] consumer that uses
/// offline-fallback logic (cached_dashboard, cached_streak, etc.) will
/// automatically serve fresh data on the next page visit without any explicit
/// user interaction.
class CacheSyncService {
  static const _interval = Duration(minutes: 15);
  static const _tag = '[CacheSyncService]';

  Timer? _timer;
  bool _running = false;

  final _analytics = AnalyticsService();
  final _gamification = GamificationService();

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  void start() {
    if (_running) return;
    _running = true;
    debugPrint('$_tag started — interval every ${_interval.inMinutes} min');
    // Run once immediately, then every 15 minutes.
    _sync();
    _timer = Timer.periodic(_interval, (_) => _sync());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    debugPrint('$_tag stopped');
  }

  bool get isRunning => _running;

  // ── Core Sync ───────────────────────────────────────────────────────────────

  Future<void> _sync() async {
    debugPrint('$_tag sync at ${DateTime.now().toIso8601String()}');
    // Run all syncs concurrently; individual failures don't abort others.
    await Future.wait([
      _syncGamification(),
      _syncDashboard(),
      _syncStreak(),
      _syncWeeklyReport(),
    ], eagerError: false);
    await StorageService.put('last_sync_ts', DateTime.now().toIso8601String());
    debugPrint('$_tag sync complete');
  }

  Future<void> _syncGamification() async {
    try {
      // GamificationService.getState() already writes cached_gamification.
      await _gamification.getState();
      debugPrint('$_tag ✓ gamification');
    } catch (e) {
      debugPrint('$_tag ✗ gamification: $e');
    }
  }

  Future<void> _syncDashboard() async {
    try {
      // AnalyticsService.getDashboard() already writes cached_dashboard.
      await _analytics.getDashboard();
      debugPrint('$_tag ✓ dashboard');
    } catch (e) {
      debugPrint('$_tag ✗ dashboard: $e');
    }
  }

  Future<void> _syncStreak() async {
    try {
      final streak = await _analytics.getStreak();
      // Write with the same key used by getStreak()'s own cache.
      await StorageService.put('cached_streak', jsonEncode({
        'current': streak.current,
        'longest': streak.longest,
        'freezesAvailable': streak.freezesAvailable,
        'nextMilestone': streak.nextMilestone,
      }));
      debugPrint('$_tag ✓ streak');
    } catch (e) {
      debugPrint('$_tag ✗ streak: $e');
    }
  }

  Future<void> _syncWeeklyReport() async {
    try {
      // AnalyticsService.getWeeklyReport() already writes cached_weekly_report.
      await _analytics.getWeeklyReport();
      debugPrint('$_tag ✓ weekly report');
    } catch (e) {
      debugPrint('$_tag ✗ weekly report: $e');
    }
  }

  // ── Public helpers ──────────────────────────────────────────────────────────

  /// Force an immediate out-of-band sync (e.g. on app foreground resume).
  Future<void> syncNow() => _sync();

  /// ISO-8601 timestamp of the last completed sync, or null if never run.
  static String? get lastSyncTs => StorageService.get<String>('last_sync_ts');
}
