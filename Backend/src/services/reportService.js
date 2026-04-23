const Report = require('../models/Report');
const Analytics = require('../models/Analytics');
const StudySession = require('../models/StudySession');
const User = require('../models/User');
const { AppError } = require('../middlewares/errorMiddleware');
const { startOfWeek, endOfWeek, getTodayDate } = require('../utils/dateHelper');

const generateDailyReport = async (userId, date) => {
  const reportDate = date ? new Date(date) : getTodayDate();
  const nextDay = new Date(reportDate);
  nextDay.setDate(nextDay.getDate() + 1);

  // Check if report already exists
  let report = await Report.findOne({ userId, reportType: 'daily', periodStart: reportDate });
  if (report) return report;

  const [analytics, user] = await Promise.all([
    Analytics.findOne({ userId, date: reportDate }),
    User.findById(userId).select('streak profile'),
  ]);

  const subjectMap = analytics?.subjectBreakdown || {};
  const subjectBreakdown = Object.entries(subjectMap).map(([subject, minutes]) => ({
    subject,
    minutes,
    sessionCount: 0, // enhanced by session query if needed
  }));

  const suggestions = generateSuggestions(analytics, user);

  report = await Report.create({
    userId,
    reportType: 'daily',
    periodStart: reportDate,
    periodEnd: reportDate,
    totalStudyMinutes: analytics?.totalMinutes || 0,
    subjectBreakdown,
    avgFocusScore: analytics?.averageFocusScore || 0,
    streakAtPeriodEnd: user?.streak?.current || 0,
    aiSuggestions: suggestions,
  });

  return report;
};

const generateWeeklyReport = async (userId, weekStartDate) => {
  const weekStart = weekStartDate ? new Date(weekStartDate) : startOfWeek(new Date());
  const weekEnd = endOfWeek(weekStart);

  let report = await Report.findOne({ userId, reportType: 'weekly', periodStart: weekStart });
  if (report) return report;

  const [weekDocs, user] = await Promise.all([
    Analytics.find({ userId, date: { $gte: weekStart, $lte: weekEnd } }),
    User.findById(userId).select('streak profile'),
  ]);

  const totalMinutes = weekDocs.reduce((s, d) => s + d.totalMinutes, 0);
  const avgFocus = weekDocs.length
    ? Math.round(weekDocs.reduce((s, d) => s + d.averageFocusScore, 0) / weekDocs.length)
    : 0;

  // Aggregate subject breakdown across the week
  const subjectMap = {};
  weekDocs.forEach((d) => {
    if (d.subjectBreakdown) {
      d.subjectBreakdown.forEach((val, key) => {
        subjectMap[key] = (subjectMap[key] || 0) + val;
      });
    }
  });

  const subjectBreakdown = Object.entries(subjectMap).map(([subject, minutes]) => ({
    subject,
    minutes,
    sessionCount: 0,
  }));

  const suggestions = generateSuggestions({ totalMinutes, averageFocusScore: avgFocus }, user);

  report = await Report.create({
    userId,
    reportType: 'weekly',
    periodStart: weekStart,
    periodEnd: weekEnd,
    totalStudyMinutes: totalMinutes,
    subjectBreakdown,
    avgFocusScore: avgFocus,
    streakAtPeriodEnd: user?.streak?.current || 0,
    aiSuggestions: suggestions,
  });

  return report;
};

const getReportHistory = async (userId, type, limit = 12) => {
  return Report.find({ userId, reportType: type }).sort({ periodStart: -1 }).limit(limit);
};

// Simple rule-based suggestions (AI-enhanced version calls aiService)
const generateSuggestions = (analytics, user) => {
  const suggestions = [];
  const minutes = analytics?.totalMinutes || 0;
  const goal = user?.profile?.dailyGoalMinutes || 120;
  const focus = analytics?.averageFocusScore || 0;

  if (minutes < goal * 0.5) suggestions.push('You studied less than half your daily goal. Try shorter, more frequent sessions.');
  if (focus < 60) suggestions.push('Your focus score was low. Try enabling Do Not Disturb during sessions.');
  if (minutes >= goal) suggestions.push('Great job hitting your daily goal! Keep the momentum going.');
  if (!suggestions.length) suggestions.push('Consistent effort leads to big results. Keep studying daily!');

  return suggestions;
};

module.exports = { generateDailyReport, generateWeeklyReport, getReportHistory };
