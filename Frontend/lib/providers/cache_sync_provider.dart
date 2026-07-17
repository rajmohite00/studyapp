import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_sync_service.dart';

final cacheSyncServiceProvider = Provider<CacheSyncService>((ref) {
  final svc = CacheSyncService();
  ref.onDispose(svc.stop);
  return svc;
});
