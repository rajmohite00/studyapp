import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/gamification_service.dart';

// ── Service Provider ──────────────────────────────────────────────────────────
final gamificationServiceProvider = Provider((_) => GamificationService());

// ── Full Gamification State ───────────────────────────────────────────────────
final gamificationStateProvider = FutureProvider.autoDispose<GamificationState>((ref) async {
  return ref.watch(gamificationServiceProvider).getState();
});

// ── Achievements ──────────────────────────────────────────────────────────────
final achievementsProvider = FutureProvider.autoDispose<List<AchievementItem>>((ref) async {
  final state = await ref.watch(gamificationStateProvider.future);
  return state.achievements;
});

// ── Reward Store ──────────────────────────────────────────────────────────────
final rewardStoreProvider = FutureProvider.autoDispose<List<RewardItem>>((ref) async {
  final state = await ref.watch(gamificationStateProvider.future);
  return state.rewardStore;
});

// ── Daily Missions ────────────────────────────────────────────────────────────
final dailyMissionsProvider = FutureProvider.autoDispose<List<DailyMission>>((ref) async {
  final state = await ref.watch(gamificationStateProvider.future);
  return state.dailyMissions;
});

// ── Unlock Reward (Notifier) ──────────────────────────────────────────────────
class RewardUnlockNotifier extends StateNotifier<AsyncValue<void>> {
  final GamificationService _service;
  final Ref _ref;

  RewardUnlockNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<String?> unlock(String rewardId) async {
    state = const AsyncValue.loading();
    try {
      await _service.unlockReward(rewardId);
      // Invalidate so state refreshes
      _ref.invalidate(gamificationStateProvider);
      state = const AsyncValue.data(null);
      return null; // success
    } catch (e) {
      final msg = _parseError(e);
      state = AsyncValue.error(msg, StackTrace.current);
      return msg; // error message
    }
  }

  String _parseError(dynamic e) {
    try {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error']['message'] ?? 'Failed to unlock reward';
      }
    } catch (_) {}
    return e.toString();
  }
}

final rewardUnlockProvider = StateNotifierProvider.autoDispose<RewardUnlockNotifier, AsyncValue<void>>(
  (ref) => RewardUnlockNotifier(ref.read(gamificationServiceProvider), ref),
);
