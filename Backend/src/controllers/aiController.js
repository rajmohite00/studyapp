const aiService = require('../services/aiService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

exports.chat = catchAsync(async (req, res) => {
  const result = await aiService.chat(req.user.sub, req.body);
  sendSuccess(res, result);
});

exports.getConversations = catchAsync(async (req, res) => {
  const data = await aiService.getConversations(req.user.sub);
  sendSuccess(res, data);
});

exports.getConversation = catchAsync(async (req, res) => {
  const data = await aiService.getConversation(req.user.sub, req.params.id);
  sendSuccess(res, data);
});

exports.explain = catchAsync(async (req, res) => {
  const data = await aiService.explain(req.user.sub, req.body);
  sendSuccess(res, data);
});

exports.generateQuiz = catchAsync(async (req, res) => {
  const data = await aiService.generateQuiz(req.user.sub, req.body);
  sendSuccess(res, data, 201);
});

exports.submitQuiz = catchAsync(async (req, res) => {
  const data = await aiService.submitQuiz(req.user.sub, req.params.id, req.body.answers);
  sendSuccess(res, data);
});

exports.getRecommendations = catchAsync(async (req, res) => {
  const data = await aiService.getRecommendations(req.user.sub);
  sendSuccess(res, data);
});

exports.getWeakTopics = catchAsync(async (req, res) => {
  const data = await aiService.getWeakTopics(req.user.sub);
  sendSuccess(res, data);
});
