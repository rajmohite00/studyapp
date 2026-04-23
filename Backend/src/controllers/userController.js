const userService = require('../services/userService');
const { catchAsync } = require('../middlewares/errorMiddleware');
const { sendSuccess } = require('../utils/responseHelper');

exports.getProfile = catchAsync(async (req, res) => {
  const user = await userService.getProfile(req.user.sub);
  sendSuccess(res, user);
});

exports.updateProfile = catchAsync(async (req, res) => {
  const user = await userService.updateProfile(req.user.sub, req.body);
  sendSuccess(res, user);
});

exports.changePassword = catchAsync(async (req, res) => {
  await userService.changePassword(req.user.sub, req.body);
  sendSuccess(res, { message: 'Password changed successfully' });
});

exports.deleteAccount = catchAsync(async (req, res) => {
  await userService.deleteAccount(req.user.sub);
  sendSuccess(res, { message: 'Account deleted successfully' });
});
