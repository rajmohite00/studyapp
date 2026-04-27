const User = require('../models/User');
const { recalculateStreak } = require('../utils/streakCalculator');
const { getTodayDate } = require('../utils/dateHelper');

const STREAK_MILESTONES = [7, 30, 60, 100, 365];

const updateStreakAfterSession = async (userId) => {
  const user = await User.findById(userId);
  if (!user) return;

  const timezone = user.preferences?.timezone || 'Asia/Kolkata';
  const updatedStreak = recalculateStreak(user.streak, new Date(), timezone);

  user.streak = updatedStreak;
  await user.save({ validateBeforeSave: false });

  // Check milestone
  const milestone = STREAK_MILESTONES.find((m) => m === updatedStreak.current);
  if (milestone) {
    const notificationService = require('./notificationService');
    const fcmToken = user.fcmToken;
    if (fcmToken) {
      await notificationService.sendStreakMilestoneNotification(fcmToken, milestone);
    }
    console.log(`User ${userId} hit ${milestone}-day streak milestone!`);
  }

  return updatedStreak;
};

const getStreakInfo = async (userId) => {
  const user = await User.findById(userId).select('streak preferences');
  if (!user) return null;
  return {
    ...user.streak.toObject(),
    milestones: STREAK_MILESTONES,
    nextMilestone: STREAK_MILESTONES.find((m) => m > user.streak.current) || null,
  };
};

const useStreakFreeze = async (userId) => {
  const user = await User.findById(userId);
  if (!user) return { success: false };
  if (user.streak.freezesAvailable <= 0) {
    return { success: false, message: 'No freezes available' };
  }
  user.streak.freezesAvailable -= 1;
  user.streak.lastStudiedDate = getTodayDate(user.preferences?.timezone);
  await user.save({ validateBeforeSave: false });
  return { success: true, streak: user.streak };
};

module.exports = { updateStreakAfterSession, getStreakInfo, useStreakFreeze };
