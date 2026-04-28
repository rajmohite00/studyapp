import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_sync_service.dart';

// ── Singleton sync service provider ─────────────────────────────────────────
// Not autoDispose — must live for the full app session.
final cacheSyncServiceProvider = Provider<CacheSyncService>((ref) {
  final svc = CacheSyncService();
  ref.onDispose(svc.stop);
  return svc;
});
