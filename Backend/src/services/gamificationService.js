const User = require('../models/User');

const XP_PER_MINUTE = 10;
const BONUS_GOAL_ACHIEVED = 100;
const BONUS_STREAK_DAY = 50;

const updateGamification = async (userId, minutesStudied, goalAchieved, streakDay) => {
  try {
    const user = await User.findById(userId);
    if (!user) return;

    let xpEarned = minutesStudied * XP_PER_MINUTE;
    
    // Bonuses
    if (goalAchieved) xpEarned += BONUS_GOAL_ACHIEVED;
    if (streakDay > 0) xpEarned += (BONUS_STREAK_DAY * Math.min(streakDay, 10)); // Cap streak bonus multiplier at 10

    user.gamification.xp += xpEarned;
    user.gamification.coins += Math.floor(xpEarned / 10); // 1 coin per 10 XP

    // Level calculation: every 1000 XP is a level
    const newLevel = Math.floor(user.gamification.xp / 1000) + 1;
    if (newLevel > user.gamification.level) {
      user.gamification.level = newLevel;
      user.gamification.rank = getRankForLevel(newLevel);
    }

    await user.save();
    return { xpEarned, newLevel: user.gamification.level, newRank: user.gamification.rank };
  } catch (err) {
    console.error('Error updating gamification:', err);
  }
};

const getRankForLevel = (level) => {
  if (level < 5) return 'Novice';
  if (level < 10) return 'Apprentice';
  if (level < 20) return 'Scholar';
  if (level < 35) return 'Adept';
  if (level < 50) return 'Master';
  return 'Grandmaster';
};

module.exports = { updateGamification };
