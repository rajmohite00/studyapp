const mongoose = require('mongoose');

const subjectBreakdownSchema = new mongoose.Schema({
  subject: String,
  minutes: Number,
  sessionCount: Number,
});

const reportSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    reportType: { type: String, enum: ['daily', 'weekly'], required: true },
    periodStart: { type: Date, required: true },
    periodEnd: { type: Date, required: true },
    totalStudyMinutes: { type: Number, default: 0 },
    subjectBreakdown: [subjectBreakdownSchema],
    avgFocusScore: { type: Number, default: 0 },
    streakAtPeriodEnd: { type: Number, default: 0 },
    aiSuggestions: [{ type: String }],
    exportUrl: { type: String, default: null },
    generatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

reportSchema.index({ userId: 1, reportType: 1, periodStart: -1 });

module.exports = mongoose.model('Report', reportSchema);
