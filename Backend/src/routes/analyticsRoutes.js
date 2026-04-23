const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { authenticate } = require('../middlewares/authMiddleware');

router.use(authenticate);

router.get('/summary', analyticsController.getDashboard);
router.get('/daily', analyticsController.getDailyAnalytics);
router.get('/subjects', analyticsController.getSubjectBreakdown);
router.get('/streak', analyticsController.getStreak);
router.get('/heatmap', analyticsController.getHeatmap);
router.get('/reports/daily', analyticsController.getDailyReport);
router.get('/reports/weekly', analyticsController.getWeeklyReport);
router.get('/reports/history', analyticsController.getReportHistory);
router.get('/suggestions', analyticsController.getBasicSuggestions);

module.exports = router;
