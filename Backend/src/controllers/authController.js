const authService = require('../services/authService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

exports.register = catchAsync(async (req, res) => {
  const result = await authService.register(req.body);
  sendSuccess(res, result, 201);
});

exports.login = catchAsync(async (req, res) => {
  const result = await authService.login(req.body);
  sendSuccess(res, result, 200);
});

exports.refresh = catchAsync(async (req, res) => {
  const { refreshToken } = req.body;
  const tokens = await authService.refreshTokens(refreshToken);
  sendSuccess(res, tokens);
});

exports.logout = catchAsync(async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  await authService.logout(req.user.sub, token);
  sendSuccess(res, { message: 'Logged out successfully' });
});

exports.forgotPassword = catchAsync(async (req, res) => {
  await authService.forgotPassword(req.body.email);
  sendSuccess(res, { message: 'If the email exists, an OTP has been sent.' });
});

exports.resetPassword = catchAsync(async (req, res) => {
  await authService.resetPassword(req.body);
  sendSuccess(res, { message: 'Password reset successfully' });
});

exports.getMe = catchAsync(async (req, res) => {
  const userService = require('../services/userService');
  const user = await userService.getProfile(req.user.sub);
  sendSuccess(res, user);
});
