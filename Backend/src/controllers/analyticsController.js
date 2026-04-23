const analyticsService = require('../services/analyticsService');
const reportService = require('../services/reportService');
const streakService = require('../services/streakService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

exports.getDashboard = catchAsync(async (req, res) => {
  const data = await analyticsService.getDashboardSummary(req.user.sub);
  sendSuccess(res, data);
});

exports.getDailyAnalytics = catchAsync(async (req, res) => {
  const data = await analyticsService.getDailyAnalytics(req.user.sub, req.query);
  sendSuccess(res, data);
});

exports.getSubjectBreakdown = catchAsync(async (req, res) => {
  const days = parseInt(req.query.days) || 30;
  const data = await analyticsService.getSubjectBreakdown(req.user.sub, days);
  sendSuccess(res, data);
});

exports.getStreak = catchAsync(async (req, res) => {
  const data = await streakService.getStreakInfo(req.user.sub);
  sendSuccess(res, data);
});

exports.getHeatmap = catchAsync(async (req, res) => {
  const data = await analyticsService.getHeatmap(req.user.sub);
  sendSuccess(res, data);
});

exports.getDailyReport = catchAsync(async (req, res) => {
  const report = await reportService.generateDailyReport(req.user.sub, req.query.date);
  sendSuccess(res, report);
});

exports.getWeeklyReport = catchAsync(async (req, res) => {
  const report = await reportService.generateWeeklyReport(req.user.sub, req.query.weekStart);
  sendSuccess(res, report);
});

exports.getReportHistory = catchAsync(async (req, res) => {
  const { type = 'weekly', limit } = req.query;
  const reports = await reportService.getReportHistory(req.user.sub, type, parseInt(limit) || 12);
  sendSuccess(res, reports);
});
