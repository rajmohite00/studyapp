const User = require('../models/User');
const { AppError } = require('../middlewares/errorMiddleware');
const { getRedisClient } = require('../config/redis');

const getProfile = async (userId) => {
  const user = await User.findById(userId);
  if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');
  return user;
};

const updateProfile = async (userId, updates) => {
  const allowed = ['name', 'profile', 'preferences', 'fcmToken'];
  const filtered = {};
  allowed.forEach((key) => {
    if (updates[key] !== undefined) filtered[key] = updates[key];
  });

  const user = await User.findByIdAndUpdate(userId, { $set: filtered }, { new: true, runValidators: true });
  if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');

  // Invalidate profile cache
  const redis = getRedisClient();
  await redis.del(`user:${userId}:profile`);

  return user;
};

const changePassword = async (userId, { currentPassword, newPassword }) => {
  const user = await User.findById(userId).select('+passwordHash');
  if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');

  const valid = await user.comparePassword(currentPassword);
  if (!valid) throw new AppError('Current password is incorrect', 400, 'WRONG_PASSWORD');

  user.passwordHash = newPassword;
  await user.save();

  // Invalidate refresh tokens
  const redis = getRedisClient();
  await redis.del(`refresh:${userId}`);
};

const deleteAccount = async (userId) => {
  const user = await User.findByIdAndUpdate(userId, { isDeleted: true });
  if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');

  const redis = getRedisClient();
  await redis.del(`refresh:${userId}`);
  await redis.del(`user:${userId}:profile`);
};

module.exports = { getProfile, updateProfile, changePassword, deleteAccount };
