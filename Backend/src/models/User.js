const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, select: false },
    authProvider: { type: String, enum: ['local', 'google', 'apple'], default: 'local' },
    googleId: { type: String, select: false },
    role: { type: String, enum: ['student', 'admin'], default: 'student' },
    isVerified: { type: Boolean, default: false },
    isDeleted: { type: Boolean, default: false },
    fcmToken: { type: String, default: null },

    profile: {
      grade: { type: String, default: '' },
      targetExam: { type: String, default: '' },
      subjects: [{ type: String }],
      dailyGoalMinutes: { type: Number, default: 120 },
    },

    preferences: {
      notificationsEnabled: { type: Boolean, default: true },
      timezone: { type: String, default: 'Asia/Kolkata' },
      theme: { type: String, enum: ['light', 'dark'], default: 'light' },
    },

    subscription: {
      plan: { type: String, enum: ['free', 'premium'], default: 'free' },
      expiresAt: { type: Date, default: null },
    },

    streak: {
      current: { type: Number, default: 0 },
      longest: { type: Number, default: 0 },
      lastStudiedDate: { type: Date, default: null },
      freezesAvailable: { type: Number, default: 1 },
    },

    passwordResetOtp: { type: String, select: false },
    passwordResetOtpExpires: { type: Date, select: false },
    emailVerificationOtp: { type: String, select: false },
  },
  { timestamps: true }
);

// Hash password before save
userSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash')) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
  next();
});

// Compare password
userSchema.methods.comparePassword = async function (plainPassword) {
  return bcrypt.compare(plainPassword, this.passwordHash);
};

// Exclude soft-deleted users from queries
userSchema.pre(/^find/, function (next) {
  this.find({ isDeleted: { $ne: true } });
  next();
});

module.exports = mongoose.model('User', userSchema);
