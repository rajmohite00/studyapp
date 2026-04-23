const mongoose = require('mongoose');

const analyticsSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    date: { type: Date, required: true }, // date-only (no time component)
    totalMinutes: { type: Number, default: 0 },
    sessionCount: { type: Number, default: 0 },
    subjectBreakdown: { type: Map, of: Number, default: {} }, // { physics: 45, math: 30 }
    averageFocusScore: { type: Number, default: 0 },
    goalAchieved: { type: Boolean, default: false },
    streakDay: { type: Number, default: 0 },
  },
  { timestamps: true }
);

// One record per user per day
analyticsSchema.index({ userId: 1, date: 1 }, { unique: true });
analyticsSchema.index({ userId: 1, date: -1 });

module.exports = mongoose.model('Analytics', analyticsSchema);
