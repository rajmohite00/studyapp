const testService = require('../services/testService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

// POST /tests/create
exports.createTest = catchAsync(async (req, res) => {
  const data = await testService.createTest(req.user.sub, req.body);
  sendSuccess(res, data, 201);
});

// POST /tests/:id/start
exports.startTest = catchAsync(async (req, res) => {
  const data = await testService.startTest(req.user.sub, req.params.id);
  sendSuccess(res, data);
});

// PATCH /tests/:id/answer
exports.saveAnswer = catchAsync(async (req, res) => {
  const data = await testService.saveAnswer(req.user.sub, req.params.id, req.body);
  sendSuccess(res, data);
});

// PATCH /tests/:id/answers/bulk
exports.saveBulkAnswers = catchAsync(async (req, res) => {
  const data = await testService.saveBulkAnswers(req.user.sub, req.params.id, req.body.answers);
  sendSuccess(res, data);
});

// POST /tests/:id/submit
exports.submitTest = catchAsync(async (req, res) => {
  const data = await testService.submitTest(req.user.sub, req.params.id, req.body);
  sendSuccess(res, data);
});

// POST /tests/:id/analyse
exports.analyseTest = catchAsync(async (req, res) => {
  const data = await testService.analyseTest(req.user.sub, req.params.id);
  sendSuccess(res, data);
});

// GET /tests/history
exports.getHistory = catchAsync(async (req, res) => {
  const data = await testService.getHistory(req.user.sub, req.query);
  sendSuccess(res, data);
});

// GET /tests/:id
exports.getTest = catchAsync(async (req, res) => {
  const data = await testService.getTest(req.user.sub, req.params.id);
  sendSuccess(res, data);
});

// GET /tests/stats
exports.getStats = catchAsync(async (req, res) => {
  const data = await testService.getStats(req.user.sub);
  sendSuccess(res, data);
});

// DELETE /tests/:id
exports.deleteTest = catchAsync(async (req, res) => {
  const data = await testService.deleteTest(req.user.sub, req.params.id);
  sendSuccess(res, data);
});

// GET /tests/draft/active
exports.getActiveDraft = catchAsync(async (req, res) => {
  const data = await testService.getActiveDraft(req.user.sub);
  sendSuccess(res, data);
});
