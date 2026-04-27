const User = require('../models/User');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../utils/jwtHelper');
const { getRedisClient } = require('../config/redis');
const { AppError } = require('../middlewares/errorMiddleware');
const { v4: uuidv4 } = require('uuid');

const REFRESH_TTL = 60 * 60 * 24 * 30; // 30 days in seconds

const register = async ({ name, email, password }) => {
  const existing = await User.findOne({ email });
  if (existing) throw new AppError('Email already registered', 409, 'EMAIL_EXISTS');

  const user = await User.create({ name, email, passwordHash: password });

  const payload = { sub: user._id.toString(), email: user.email, role: user.role };
  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken({ ...payload, jti: uuidv4() });

  // Store refresh token in Redis
  const redis = getRedisClient();
  await redis.setex(`refresh:${user._id}`, REFRESH_TTL, refreshToken);

  return { user: sanitizeUser(user), accessToken, refreshToken };
};

const login = async ({ email, password }) => {
  const user = await User.findOne({ email }).select('+passwordHash');
  if (!user) throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');

  const valid = await user.comparePassword(password);
  if (!valid) throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');

  const payload = { sub: user._id.toString(), email: user.email, role: user.role };
  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken({ ...payload, jti: uuidv4() });

  const redis = getRedisClient();
  await redis.setex(`refresh:${user._id}`, REFRESH_TTL, refreshToken);

  return { user: sanitizeUser(user), accessToken, refreshToken };
};

const refreshTokens = async (token) => {
  let decoded;
  try {
    decoded = verifyRefreshToken(token);
  } catch {
    throw new AppError('Invalid or expired refresh token', 401, 'INVALID_REFRESH_TOKEN');
  }

  const redis = getRedisClient();
  const stored = await redis.get(`refresh:${decoded.sub}`);
  if (!stored || stored !== token) {
    throw new AppError('Refresh token reuse detected', 401, 'TOKEN_REUSE');
  }

  const user = await User.findById(decoded.sub);
  if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');

  const payload = { sub: user._id.toString(), email: user.email, role: user.role };
  const newAccess = signAccessToken(payload);
  const newRefresh = signRefreshToken({ ...payload, jti: uuidv4() });

  await redis.setex(`refresh:${user._id}`, REFRESH_TTL, newRefresh);

  return { accessToken: newAccess, refreshToken: newRefresh };
};

const logout = async (userId, accessToken) => {
  const redis = getRedisClient();
  await redis.del(`refresh:${userId}`);
  // Blocklist current access token
  await redis.setex(`blocklist:${accessToken}`, 60 * 15, '1'); // TTL = access token lifetime
};

const forgotPassword = async (email) => {
  const user = await User.findOne({ email });
  if (!user) return; // Silent — don't reveal if email exists

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expires = new Date(Date.now() + 10 * 60 * 1000); // 10 min

  user.passwordResetOtp = otp;
  user.passwordResetOtpExpires = expires;
  await user.save({ validateBeforeSave: false });

  const notificationService = require('./notificationService');
  await notificationService.sendOtpEmail(email, otp);
  return otp; // returned for dev/testing; remove in prod
};

const resetPassword = async ({ email, otp, newPassword }) => {
  const user = await User.findOne({ email }).select('+passwordResetOtp +passwordResetOtpExpires');
  if (!user || user.passwordResetOtp !== otp) {
    throw new AppError('Invalid or expired OTP', 400, 'INVALID_OTP');
  }
  if (user.passwordResetOtpExpires < Date.now()) {
    throw new AppError('OTP expired', 400, 'OTP_EXPIRED');
  }

  user.passwordHash = newPassword;
  user.passwordResetOtp = undefined;
  user.passwordResetOtpExpires = undefined;
  await user.save();

  // Invalidate all refresh tokens
  const redis = getRedisClient();
  await redis.del(`refresh:${user._id}`);
};

const sanitizeUser = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  role: user.role,
  isVerified: user.isVerified,
  profile: user.profile,
  streak: user.streak,
  subscription: user.subscription,
});

module.exports = { register, login, refreshTokens, logout, forgotPassword, resetPassword };
