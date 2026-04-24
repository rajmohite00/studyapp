const Analytics = require('../models/Analytics');
const StudySession = require('../models/StudySession');
const User = require('../models/User');
const { getRedisClient } = require('../config/redis');
const { getTodayDate, startOfWeek, endOfWeek, formatDate } = require('../utils/dateHelper');

const CACHE_TTL = 60; // 60 seconds — keeps data near real-time

const getDashboardSummary = async (userId) => {
  const redis = getRedisClient();
  const cacheKey = `analytics:${userId}:summary`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const today = getTodayDate();
  const weekStart = startOfWeek(today);

  const [todayDoc, weekDocs, user] = await Promise.all([
    Analytics.findOne({ userId, date: today }),
    Analytics.find({ userId, date: { $gte: weekStart, $lte: today } }),
    User.findById(userId).select('streak profile'),
  ]);

  const weekTotal = weekDocs.reduce((sum, d) => sum + d.totalMinutes, 0);
  const result = {
    today: {
      totalMinutes: todayDoc?.totalMinutes || 0,
      sessionCount: todayDoc?.sessionCount || 0,
      goalAchieved: todayDoc?.goalAchieved || false,
      subjectBreakdown: todayDoc?.subjectBreakdown || {},
    },
    week: {
      totalMinutes: weekTotal,
      sessionCount: weekDocs.reduce((sum, d) => sum + (d.sessionCount || 0), 0),
      avgFocusScore:
        weekDocs.length > 0
          ? Math.round(weekDocs.reduce((s, d) => s + d.averageFocusScore, 0) / weekDocs.length)
          : 0,
    },
    streak: user?.streak || {},
    dailyGoalMinutes: user?.profile?.dailyGoalMinutes || 120,
  };

  // Only cache when there's real data — prevents stale zeros blocking fresh reads
  const hasData = result.today.totalMinutes > 0 || result.today.sessionCount > 0 || result.streak.current > 0;
  if (hasData) {
    await redis.setex(cacheKey, CACHE_TTL, JSON.stringify(result));
  }
  return result;
};

const getDailyAnalytics = async (userId, { from, to }) => {
  const filter = { userId };
  if (from || to) {
    filter.date = {};
    if (from) filter.date.$gte = new Date(from);
    if (to) filter.date.$lte = new Date(to);
  }
  return Analytics.find(filter).sort({ date: 1 });
};

const getSubjectBreakdown = async (userId, days = 30) => {
  const from = new Date();
  from.setDate(from.getDate() - days);

  const sessions = await StudySession.find({
    userId,
    status: 'completed',
    startTime: { $gte: from },
  }).select('subject actualDurationMinutes');

  const breakdown = {};
  sessions.forEach((s) => {
    breakdown[s.subject] = (breakdown[s.subject] || 0) + s.actualDurationMinutes;
  });

  return breakdown;
};

const getHeatmap = async (userId) => {
  const redis = getRedisClient();
  const cacheKey = `analytics:${userId}:heatmap`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const yearAgo = new Date();
  yearAgo.setFullYear(yearAgo.getFullYear() - 1);

  const docs = await Analytics.find({ userId, date: { $gte: yearAgo } }).select('date totalMinutes');
  const heatmap = docs.map((d) => ({ date: formatDate(d.date), minutes: d.totalMinutes }));

  await redis.setex(cacheKey, 60 * 60, JSON.stringify(heatmap)); // 1 hour TTL
  return heatmap;
};

// Called after session end — aggregates all completed sessions for today (IST)
const aggregateDailyAnalytics = async (userId) => {
  // IST = UTC+5:30, so IST midnight = 18:30 UTC previous day
  const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;
  const now = new Date();
  // Get IST date string
  const istDateStr = now.toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });
  // IST day starts at 18:30 UTC the previous calendar day
  const dayStartUTC = new Date(`${istDateStr}T00:00:00+05:30`); // midnight IST
  const dayEndUTC   = new Date(dayStartUTC.getTime() + 24 * 60 * 60 * 1000); // next midnight IST

  const sessions = await StudySession.find({
    userId,
    status: 'completed',
    startTime: { $gte: dayStartUTC, $lt: dayEndUTC },
  });

  const subjectBreakdown = {};
  let totalMinutes = 0;
  let totalFocus = 0;

  sessions.forEach((s) => {
    totalMinutes += s.actualDurationMinutes;
    totalFocus += s.focusScore;
    subjectBreakdown[s.subject] = (subjectBreakdown[s.subject] || 0) + s.actualDurationMinutes;
  });

  const user = await User.findById(userId).select('profile streak');
  const goalAchieved = totalMinutes >= (user?.profile?.dailyGoalMinutes || 120);

  // Use IST date as the key for the analytics document
  const today = new Date(`${istDateStr}T00:00:00.000Z`);

  await Analytics.findOneAndUpdate(
    { userId, date: today },
    {
      $set: {
        totalMinutes,
        sessionCount: sessions.length,
        subjectBreakdown,
        averageFocusScore: sessions.length > 0 ? Math.round(totalFocus / sessions.length) : 0,
        goalAchieved,
        streakDay: user?.streak?.current || 0,
      },
    },
    { upsert: true, new: true }
  );

  // Invalidate both summary and heatmap cache
  const redis = getRedisClient();
  await Promise.all([
    redis.del(`analytics:${userId}:summary`),
    redis.del(`analytics:${userId}:heatmap`),
  ]);
};

const getBasicSuggestions = async (userId) => {
  const summary = await getDashboardSummary(userId);
  const suggestions = [];

  if (summary.today.totalMinutes === 0) {
    suggestions.push("You haven't studied yet today. Start a short session to get going!");
  } else if (summary.today.totalMinutes < summary.dailyGoalMinutes) {
    suggestions.push("You studied a bit today, try to increase your time to hit your daily goal.");
  } else if (summary.today.goalAchieved) {
    suggestions.push("Great job! You've reached your daily study goal. Keep it up!");
  }

  if (summary.streak.current >= 3) {
    suggestions.push(`You're on a ${summary.streak.current}-day streak! Consistency is key, keep the momentum going.`);
  } else if (summary.streak.current === 0 && summary.streak.longest > 0) {
    suggestions.push("Your streak reset. Don't worry, start today and build a new one!");
  }

  if (summary.week.avgFocusScore > 0 && summary.week.avgFocusScore < 60) {
    suggestions.push("Your focus score has been a bit low. Try using the Pomodoro mode or putting away distractions.");
  } else if (summary.week.avgFocusScore >= 80) {
    suggestions.push("Excellent focus recently! You are making the most out of your study time.");
  }

  if (suggestions.length === 0) {
    suggestions.push("Keep up the good work! Stay consistent with your schedule.");
  }

  return suggestions;
};

module.exports = { getDashboardSummary, getDailyAnalytics, getSubjectBreakdown, getHeatmap, aggregateDailyAnalytics, getBasicSuggestions };
