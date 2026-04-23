const Analytics = require('../models/Analytics');
const StudySession = require('../models/StudySession');
const User = require('../models/User');
const { getRedisClient } = require('../config/redis');
const { getTodayDate, startOfWeek, endOfWeek, formatDate } = require('../utils/dateHelper');

const CACHE_TTL = 60 * 10; // 10 min

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
      avgFocusScore:
        weekDocs.length > 0
          ? Math.round(weekDocs.reduce((s, d) => s + d.averageFocusScore, 0) / weekDocs.length)
          : 0,
    },
    streak: user?.streak || {},
    dailyGoalMinutes: user?.profile?.dailyGoalMinutes || 120,
  };

  await redis.setex(cacheKey, CACHE_TTL, JSON.stringify(result));
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

// Called by Bull worker after session end
const aggregateDailyAnalytics = async (userId) => {
  const today = getTodayDate();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const sessions = await StudySession.find({
    userId,
    status: 'completed',
    startTime: { $gte: today, $lt: tomorrow },
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

  // Invalidate cache
  const redis = getRedisClient();
  await redis.del(`analytics:${userId}:summary`);
};

module.exports = { getDashboardSummary, getDailyAnalytics, getSubjectBreakdown, getHeatmap, aggregateDailyAnalytics };
