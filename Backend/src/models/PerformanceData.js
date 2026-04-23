const mongoose = require('mongoose');

const testEntrySchema = new mongoose.Schema({
  testId: mongoose.Schema.Types.ObjectId,
  dateTaken: { type: Date, default: Date.now },
  score: Number,
  totalQuestions: Number,
  correctAnswers: Number,
  difficulty: { type: String, enum: ['beginner', 'intermediate', 'advanced'] },
  timeTakenMinutes: Number,
});

const performanceDataSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    subject: { type: String, required: true },
    chapter: { type: String, default: '' },
    topic: { type: String, default: '' },
    tests: [testEntrySchema],
    averageAccuracy: { type: Number, default: 0 },
    isWeakTopic: { type: Boolean, default: false },
    lastUpdated: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

performanceDataSchema.index({ userId: 1, subject: 1, topic: 1 });
performanceDataSchema.index({ userId: 1, isWeakTopic: 1 });

module.exports = mongoose.model('PerformanceData', performanceDataSchema);
