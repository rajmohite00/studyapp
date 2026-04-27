const gamificationService = require('../services/gamificationService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

// GET /api/v1/gamification/state
exports.getState = catchAsync(async (req, res) => {
  const state = await gamificationService.getGamificationState(req.user.sub);
  sendSuccess(res, state);
});

// POST /api/v1/gamification/unlock-reward
exports.unlockReward = catchAsync(async (req, res) => {
  const { rewardId } = req.body;
  if (!rewardId) {
    return res.status(400).json({ success: false, error: { message: 'rewardId is required' } });
  }
  const result = await gamificationService.unlockReward(req.user.sub, rewardId);
  sendSuccess(res, result);
});

// POST /api/v1/gamification/equip-badge
exports.equipBadge = catchAsync(async (req, res) => {
  const { badgeId } = req.body;
  const result = await gamificationService.equipBadge(req.user.sub, badgeId);
  sendSuccess(res, result);
});

// GET /api/v1/gamification/store
exports.getStore = catchAsync(async (req, res) => {
  const state = await gamificationService.getGamificationState(req.user.sub);
  sendSuccess(res, {
    coins: state.coins,
    storeItems: state.rewardStore,
    rewardsUnlocked: state.rewardsUnlocked,
  });
});

// GET /api/v1/gamification/achievements
exports.getAchievements = catchAsync(async (req, res) => {
  const state = await gamificationService.getGamificationState(req.user.sub);
  sendSuccess(res, {
    achievements: state.achievements,
    earnedCount: state.earnedAchievements.length,
    totalCount: state.achievements.length,
  });
});

// GET /api/v1/gamification/missions
exports.getMissions = catchAsync(async (req, res) => {
  const state = await gamificationService.getGamificationState(req.user.sub);
  sendSuccess(res, {
    missions: state.dailyMissions,
    missionDate: state.missionDate,
  });
});
