const User = require('../models/User');

// ── XP Constants ─────────────────────────────────────────────────────────────
const XP_PER_MINUTE = 10;
const BONUS_GOAL_ACHIEVED = 100;
const BONUS_STREAK_DAY = 50;
const BONUS_TASK_COMPLETE = 30;

// ── Level Thresholds ─────────────────────────────────────────────────────────
// Level 1: 0–100 XP, Level 2: 100–300 XP, Level 3: 300–600, Level 4: 600–1000, etc.
const LEVEL_THRESHOLDS = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5200, 6600];

const getLevelFromXP = (xp) => {
  let level = 1;
  for (let i = 0; i < LEVEL_THRESHOLDS.length; i++) {
    if (xp >= LEVEL_THRESHOLDS[i]) level = i + 1;
    else break;
  }
  return level;
};

const getXPForNextLevel = (level) => {
  return LEVEL_THRESHOLDS[level] ?? LEVEL_THRESHOLDS[LEVEL_THRESHOLDS.length - 1] + (level - LEVEL_THRESHOLDS.length + 1) * 2000;
};

// ── Achievement Definitions ──────────────────────────────────────────────────
const ACHIEVEMENTS = [
  { id: 'first_session',   label: 'First Step',      description: 'Complete your first study session', emoji: '🌱', xpReward: 50 },
  { id: 'streak_3',        label: 'On a Roll',        description: 'Maintain a 3-day study streak',     emoji: '🔥', xpReward: 100 },
  { id: 'streak_7',        label: 'Week Warrior',     description: 'Maintain a 7-day study streak',     emoji: '⚡', xpReward: 200 },
  { id: 'study_10h',       label: 'Ten Hours Strong', description: 'Study for a total of 10 hours',     emoji: '⏱️',  xpReward: 150 },
  { id: 'study_50h',       label: 'Dedicated Scholar',description: 'Study for a total of 50 hours',     emoji: '🎓', xpReward: 500 },
  { id: 'level_5',         label: 'Rising Star',      description: 'Reach Level 5',                     emoji: '⭐', xpReward: 200 },
  { id: 'perfect_focus',   label: 'In the Zone',      description: 'Get 100% focus score in a session', emoji: '🎯', xpReward: 100 },
  { id: 'tasks_10',        label: 'Task Master',      description: 'Complete 10 daily missions',        emoji: '✅', xpReward: 150 },
];

// ── Reward Store Items ────────────────────────────────────────────────────────
const REWARD_STORE_ITEMS = [
  // Badges
  { id: 'badge_star',       label: 'Star Badge',         category: 'badge',  cost: 200, emoji: '⭐', description: 'Show your star status' },
  { id: 'badge_fire',       label: 'Fire Badge',         category: 'badge',  cost: 300, emoji: '🔥', description: 'You are on fire!' },
  { id: 'badge_diamond',    label: 'Diamond Badge',      category: 'badge',  cost: 800, emoji: '💎', description: 'Rare diamond achiever' },
  { id: 'badge_trophy',     label: 'Trophy Badge',       category: 'badge',  cost: 500, emoji: '🏆', description: 'Champion of study' },
  { id: 'badge_rocket',     label: 'Rocket Badge',       category: 'badge',  cost: 400, emoji: '🚀', description: 'Launching to success' },
  // Themes
  { id: 'theme_midnight',   label: 'Midnight Theme',     category: 'theme',  cost: 300, emoji: '🌙', description: 'Dark blue night mode' },
  { id: 'theme_forest',     label: 'Forest Theme',       category: 'theme',  cost: 350, emoji: '🌿', description: 'Calm green tones' },
  { id: 'theme_sunset',     label: 'Sunset Theme',       category: 'theme',  cost: 350, emoji: '🌅', description: 'Warm orange hues' },
  { id: 'theme_ocean',      label: 'Ocean Theme',        category: 'theme',  cost: 400, emoji: '🌊', description: 'Deep teal vibes' },
  // Motivational packs
  { id: 'pack_warrior',     label: 'Warrior Pack',       category: 'pack',   cost: 150, emoji: '⚔️',  description: 'Power-up motivation quotes' },
  { id: 'pack_zen',         label: 'Zen Pack',           category: 'pack',   cost: 150, emoji: '🧘', description: 'Calm focus mantras' },
  { id: 'pack_champion',    label: 'Champion Pack',      category: 'pack',   cost: 250, emoji: '🏅', description: 'Elite study affirmations' },
];

// ── Daily Mission Templates ───────────────────────────────────────────────────
const MISSION_TEMPLATES = [
  { id: 'study_30min', label: 'Study for 30 minutes',  target: 30,  xpReward: 50 },
  { id: 'study_1h',    label: 'Study for 1 hour',      target: 60,  xpReward: 80 },
  { id: 'study_2h',    label: 'Study for 2 hours',     target: 120, xpReward: 120 },
  { id: 'sessions_1',  label: 'Complete 1 session',    target: 1,   xpReward: 40 },
  { id: 'sessions_2',  label: 'Complete 2 sessions',   target: 2,   xpReward: 70 },
  { id: 'sessions_3',  label: 'Complete 3 sessions',   target: 3,   xpReward: 110 },
];

// Deterministically pick 3 missions per day based on date seed
const generateDailyMissions = (dateStr) => {
  const seed = dateStr.split('-').reduce((a, b) => a + parseInt(b), 0);
  const shuffled = [...MISSION_TEMPLATES].sort((a, b) => {
    const ha = ((seed * a.id.length) % MISSION_TEMPLATES.length);
    const hb = ((seed * b.id.length) % MISSION_TEMPLATES.length);
    return ha - hb;
  });
  return shuffled.slice(0, 3).map((m) => ({ ...m, progress: 0, completed: false }));
};

const todayStr = () => new Date().toISOString().slice(0, 10);

// ── Core Update ──────────────────────────────────────────────────────────────
const updateGamification = async (userId, minutesStudied, goalAchieved, streakDay) => {
  try {
    const user = await User.findById(userId);
    if (!user) return;

    const initialXP = user.gamification.xp;

    let baseXpEarned = minutesStudied * XP_PER_MINUTE;
    if (goalAchieved) baseXpEarned += BONUS_GOAL_ACHIEVED;
    if (streakDay > 0) baseXpEarned += BONUS_STREAK_DAY * Math.min(streakDay, 10);

    user.gamification.xp += baseXpEarned;
    user.gamification.coins += Math.floor(baseXpEarned / 10);
    user.gamification.totalStudyMinutes = (user.gamification.totalStudyMinutes || 0) + minutesStudied;

    // Level recalculation
    const newLevel = getLevelFromXP(user.gamification.xp);
    const prevLevel = user.gamification.level;
    user.gamification.level = newLevel;
    user.gamification.rank = getRankForLevel(newLevel);

    // Check achievements
    const newAchievements = await _checkAchievements(user, { streakDay, minutesStudied });

    // Refresh daily missions + update mission progress
    _refreshAndUpdateMissions(user, minutesStudied);

    // Calculate total XP earned across base session + achievements + missions
    const totalXpEarned = user.gamification.xp - initialXP;

    // Recalculate level just in case achievements pushed them over a threshold
    const newLevel = getLevelFromXP(user.gamification.xp);
    const prevLevel = user.gamification.level;
    user.gamification.level = newLevel;
    user.gamification.rank = getRankForLevel(newLevel);

    await user.save();

    return {
      xpEarned: totalXpEarned,
      totalXP: user.gamification.xp,
      newLevel: user.gamification.level,
      prevLevel,
      leveledUp: newLevel > prevLevel,
      newRank: user.gamification.rank,
      newAchievements,
      dailyMissions: user.gamification.dailyMissions.missions,
      coinsTotal: user.gamification.coins,
    };
  } catch (err) {
    console.error('Error updating gamification:', err);
  }
};

// ── Achievement Checker ───────────────────────────────────────────────────────
const _checkAchievements = async (user, { streakDay, minutesStudied }) => {
  const earned = user.gamification.achievements || [];
  const newOnes = [];

  const give = async (id) => {
    if (!earned.includes(id)) {
      const def = ACHIEVEMENTS.find((a) => a.id === id);
      if (def) {
        earned.push(id);
        user.gamification.achievements = earned;
        user.gamification.xp += def.xpReward;
        user.gamification.coins += Math.floor(def.xpReward / 10);
        newOnes.push(def);
      }
    }
  };

  // First session ever
  if (user.gamification.totalStudyMinutes >= minutesStudied) {
    const prevMinutes = user.gamification.totalStudyMinutes - minutesStudied;
    if (prevMinutes === 0) await give('first_session');
  }

  // Streaks
  if (streakDay >= 3) await give('streak_3');
  if (streakDay >= 7) await give('streak_7');

  // Total study time (10h = 600min, 50h = 3000min)
  if (user.gamification.totalStudyMinutes >= 600) await give('study_10h');
  if (user.gamification.totalStudyMinutes >= 3000) await give('study_50h');

  // Level-based
  if (user.gamification.level >= 5) await give('level_5');

  return newOnes;
};

// ── Daily Mission Refresh ─────────────────────────────────────────────────────
const _refreshAndUpdateMissions = (user, minutesStudied) => {
  const today = todayStr();
  const dm = user.gamification.dailyMissions;

  if (!dm || dm.date !== today) {
    // New day — regenerate missions
    const freshMissions = generateDailyMissions(today);
    user.gamification.dailyMissions = { date: today, missions: freshMissions };
    // Apply today's progress to the newly generated missions
    _applySessionToMissions(user, user.gamification.dailyMissions.missions, minutesStudied);
  } else {
    _applySessionToMissions(user, dm.missions, minutesStudied);
  }
};

const _applySessionToMissions = (user, missions, minutesStudied) => {
  for (const m of missions) {
    if (m.completed) continue;
    if (m.id.startsWith('study_')) {
      m.progress = Math.min((m.progress || 0) + minutesStudied, m.target);
    } else if (m.id.startsWith('sessions_')) {
      m.progress = Math.min((m.progress || 0) + 1, m.target);
    }
    
    if (m.progress >= m.target && !m.completed) {
      m.completed = true;
      user.gamification.xp += m.xpReward;
      user.gamification.coins += Math.floor(m.xpReward / 10);
    }
  }
};

// ── Rank Helper ───────────────────────────────────────────────────────────────
const getRankForLevel = (level) => {
  if (level < 3)  return 'Novice';
  if (level < 5)  return 'Apprentice';
  if (level < 8)  return 'Scholar';
  if (level < 11) return 'Adept';
  if (level < 15) return 'Master';
  return 'Grandmaster';
};

// ── Unlock Reward ─────────────────────────────────────────────────────────────
const unlockReward = async (userId, rewardId) => {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');

  const item = REWARD_STORE_ITEMS.find((r) => r.id === rewardId);
  if (!item) throw new Error('Reward item not found');

  const unlocked = user.gamification.rewardsUnlocked || [];
  if (unlocked.includes(rewardId)) throw new Error('Already unlocked');

  if (user.gamification.coins < item.cost) throw new Error('Not enough coins');

  user.gamification.coins -= item.cost;
  user.gamification.rewardsUnlocked = [...unlocked, rewardId];
  await user.save();

  return { success: true, coinsRemaining: user.gamification.coins, unlockedItem: item };
};

// ── Get Gamification State ────────────────────────────────────────────────────
const getGamificationState = async (userId) => {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');

  // Refresh missions if needed (date change)
  const today = todayStr();
  if (!user.gamification.dailyMissions || user.gamification.dailyMissions.date !== today) {
    user.gamification.dailyMissions = {
      date: today,
      missions: generateDailyMissions(today),
    };
    await user.save();
  }

  const g = user.gamification;
  const currentLevel = g.level;
  const currentXP = g.xp;
  const xpForNext = getXPForNextLevel(currentLevel);
  const xpForCurrent = LEVEL_THRESHOLDS[currentLevel - 1] ?? 0;
  const xpProgress = currentXP - xpForCurrent;
  const xpNeeded = xpForNext - xpForCurrent;

  // Map achievement IDs to full definitions
  const earnedAchievements = ACHIEVEMENTS.filter((a) => (g.achievements || []).includes(a.id));
  const allAchievements = ACHIEVEMENTS.map((a) => ({
    ...a,
    earned: (g.achievements || []).includes(a.id),
  }));

  // Map reward IDs to full definitions
  const storeItems = REWARD_STORE_ITEMS.map((r) => ({
    ...r,
    unlocked: (g.rewardsUnlocked || []).includes(r.id),
    canAfford: g.coins >= r.cost,
  }));

  return {
    xp: currentXP,
    level: currentLevel,
    rank: g.rank,
    coins: g.coins,
    totalStudyMinutes: g.totalStudyMinutes || 0,
    xpProgress,
    xpNeeded,
    xpForNext,
    achievements: allAchievements,
    earnedAchievements,
    rewardStore: storeItems,
    rewardsUnlocked: g.rewardsUnlocked || [],
    dailyMissions: g.dailyMissions?.missions || [],
    missionDate: g.dailyMissions?.date || today,
  };
};

module.exports = {
  updateGamification,
  unlockReward,
  getGamificationState,
  ACHIEVEMENTS,
  REWARD_STORE_ITEMS,
  getLevelFromXP,
  getXPForNextLevel,
  LEVEL_THRESHOLDS,
};
