const intelligenceService = require('../services/intelligenceService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

exports.getBurnout = catchAsync(async (req, res) => {
  const data = await intelligenceService.getBurnoutStatus(req.user.sub);
  sendSuccess(res, data);
});

exports.getPrediction = catchAsync(async (req, res) => {
  const data = await intelligenceService.getPrediction(req.user.sub);
  sendSuccess(res, data);
});

exports.getInsights = catchAsync(async (req, res) => {
  const data = await intelligenceService.getInsights(req.user.sub);
  sendSuccess(res, data);
});

exports.getPerformance = catchAsync(async (req, res) => {
  const data = await intelligenceService.getPerformance(req.user.sub);
  sendSuccess(res, data);
});
