import 'dio_client.dart';
import '../models/user_model.dart';

class GamificationService {
  final _dio = DioClient.instance;

  Future<GamificationState> getState() async {
    final res = await _dio.get('/gamification/state');
    return GamificationState.fromJson(res.data['data']);
  }

  Future<Map<String, dynamic>> unlockReward(String rewardId) async {
    final res = await _dio.post('/gamification/unlock-reward', data: {'rewardId': rewardId});
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<AchievementItem>> getAchievements() async {
    final res = await _dio.get('/gamification/achievements');
    final list = res.data['data']['achievements'] as List;
    return list.map((a) => AchievementItem.fromJson(a)).toList();
  }

  Future<List<DailyMission>> getMissions() async {
    final res = await _dio.get('/gamification/missions');
    final list = res.data['data']['missions'] as List;
    return list.map((m) => DailyMission.fromJson(m)).toList();
  }
}
