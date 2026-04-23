const sessionService = require('../services/sessionService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

exports.startSession = catchAsync(async (req, res) => {
  const session = await sessionService.startSession(req.user.sub, req.body);
  sendSuccess(res, session, 201);
});

exports.updateSession = catchAsync(async (req, res) => {
  const session = await sessionService.updateSession(req.user.sub, req.params.id, req.body);
  sendSuccess(res, session);
});

exports.getSessions = catchAsync(async (req, res) => {
  const { data, nextCursor, hasMore } = await sessionService.getSessions(req.user.sub, req.query);
  sendSuccess(res, data, 200, { nextCursor, hasMore });
});

exports.getSession = catchAsync(async (req, res) => {
  const session = await sessionService.getSession(req.user.sub, req.params.id);
  sendSuccess(res, session);
});

exports.getActiveSession = catchAsync(async (req, res) => {
  const session = await sessionService.getActiveSession(req.user.sub);
  sendSuccess(res, session || null);
});

exports.deleteSession = catchAsync(async (req, res) => {
  await sessionService.deleteSession(req.user.sub, req.params.id);
  sendSuccess(res, { message: 'Session deleted' });
});
