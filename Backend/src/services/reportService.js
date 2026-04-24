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

  const suggestions = await generateSuggestions(analytics, user, subjectBreakdown);

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

  const suggestions = await generateSuggestions({ totalMinutes, averageFocusScore: avgFocus }, user, subjectBreakdown);

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

// ── Real AI suggestions using Groq LLM ───────────────────────────────────────
const generateSuggestions = async (analytics, user, subjectBreakdown = []) => {
  const minutes = analytics?.totalMinutes || 0;
  const focus   = analytics?.averageFocusScore || 0;
  const goal    = user?.profile?.dailyGoalMinutes || 120;
  const streak  = user?.streak?.current || 0;

  // Build a rich context string from real student data
  const subjectLines = subjectBreakdown.length
    ? subjectBreakdown.map(s => `  - ${s.subject}: ${s.minutes} min`).join('\n')
    : '  - No subjects recorded yet';

  const prompt = `You are an expert academic study coach AI. A student's real weekly data is below.
Give exactly 3 SHORT, specific, and actionable suggestions to help them improve. 
Each suggestion must be 1 sentence max. Be warm and encouraging. No bullet points, just return a JSON array of 3 strings.

Student Data:
- Total study time this week: ${minutes} minutes (goal: ${goal} min/day = ${goal * 7} min/week)
- Average focus score: ${focus}%  (ideal: 75%+)
- Current streak: ${streak} days
- Subject breakdown:
${subjectLines}
- Name: ${user?.name || 'Student'}

Return ONLY a JSON array like: ["suggestion 1", "suggestion 2", "suggestion 3"]`;

  try {
    const { getOpenAIClient } = require('../config/openai');
    const openai = getOpenAIClient();

    const response = await openai.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 300,
      temperature: 0.6,
    });

    const content = response.choices[0].message.content.trim();
    // Extract JSON array safely
    const match = content.match(/\[[\s\S]*\]/);
    if (match) {
      const parsed = JSON.parse(match[0]);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
  } catch (err) {
    console.error('AI suggestions fallback to rules:', err.message);
  }

  // ── Fallback: rule-based (if AI call fails) ──────────────────────────────
  const fallback = [];
  if (minutes < goal * 0.5) fallback.push('You studied less than half your weekly goal — try 3 focused 30-min sessions this week to get back on track!');
  if (focus < 60) fallback.push('Your focus score was low — try a quiet space and enable Do Not Disturb during study sessions.');
  if (minutes >= goal * 7) fallback.push('Amazing — you hit your weekly goal! Challenge yourself with a harder topic next week.');
  if (!fallback.length) fallback.push('Consistency is your superpower — keep showing up daily and results will follow!');
  return fallback;
};

module.exports = { generateDailyReport, generateWeeklyReport, getReportHistory };
