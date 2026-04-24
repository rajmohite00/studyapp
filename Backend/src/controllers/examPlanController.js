const examPlanService = require('../services/examPlanService');
const aiService = require('../services/aiService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

exports.createPlan = catchAsync(async (req, res) => {
  const { subjects, examDate, dailyStudyHours } = req.body;
  const plan = await examPlanService.createExamPlan(req.user.sub, { subjects, examDate, dailyStudyHours });
  sendSuccess(res, plan, 201);
});

exports.getPlan = catchAsync(async (req, res) => {
  const plan = await examPlanService.getExamPlan(req.user.sub);
  sendSuccess(res, plan);
});

exports.getProgress = catchAsync(async (req, res) => {
  const progress = await examPlanService.getPlanProgress(req.user.sub);
  sendSuccess(res, progress);
});

exports.markTask = catchAsync(async (req, res) => {
  const { planId, taskIndex, completed } = req.body;
  const plan = await examPlanService.markTaskCompleted(req.user.sub, planId, taskIndex, completed);
  sendSuccess(res, { generatedPlan: plan.generatedPlan });
});

exports.getSubjectInfo = catchAsync(async (req, res) => {
  const { subject } = req.query;
  if (!subject) return res.status(400).json({ success: false, error: { message: 'subject query param required' } });
  const info = await aiService.getSubjectInfo(subject);
  sendSuccess(res, info);
});
