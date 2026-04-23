const { getTodayDate, diffDays, isSameDay } = require('./dateHelper');

/**
 * Recalculates streak for a user after a session is completed.
 * @param {Object} streak  - Current streak object from User document
 * @param {Date}   sessionDate - Date the session was completed
 * @param {String} timezone - User's timezone
 * @returns {Object} Updated streak object
 */
const recalculateStreak = (streak, sessionDate, timezone = 'Asia/Kolkata') => {
  const today = getTodayDate(timezone);
  const lastStudied = streak.lastStudiedDate ? new Date(streak.lastStudiedDate) : null;

  // Already studied today — no change
  if (lastStudied && isSameDay(lastStudied, today)) {
    return streak;
  }

  const dayDiff = lastStudied ? diffDays(lastStudied, today) : null;

  let newCurrent = streak.current;

  if (!lastStudied || dayDiff > 1) {
    // New streak or broken streak
    newCurrent = 1;
  } else if (dayDiff === 1) {
    // Consecutive day
    newCurrent = streak.current + 1;
  }

  return {
    current: newCurrent,
    longest: Math.max(streak.longest, newCurrent),
    lastStudiedDate: today,
    freezesAvailable: streak.freezesAvailable,
  };
};

/**
 * Apply a streak freeze (user misses a day but uses a freeze token).
 */
const applyStreakFreeze = (streak) => {
  if (streak.freezesAvailable <= 0) {
    return { success: false, message: 'No streak freezes available' };
  }
  return {
    success: true,
    streak: {
      ...streak,
      freezesAvailable: streak.freezesAvailable - 1,
      lastStudiedDate: new Date(), // treat today as studied
    },
  };
};

module.exports = { recalculateStreak, applyStreakFreeze };
