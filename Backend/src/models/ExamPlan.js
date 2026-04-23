const mongoose = require('mongoose');

const pyqSchema = new mongoose.Schema({
  question: { type: String, required: true },
  year: { type: Number },
  frequency: { type: Number, default: 1 }, // how often asked
  isHighlighted: { type: Boolean, default: false },
}, { _id: false });

const importantTopicSchema = new mongoose.Schema({
  name: { type: String, required: true },
  priority: { type: String, enum: ['high', 'medium', 'low'], default: 'medium' },
  frequencyScore: { type: Number, default: 0 }, // simulated PYQ frequency
  pyqs: [pyqSchema],
}, { _id: false });

const dailyTaskSchema = new mongoose.Schema({
  day: { type: Number, required: true }, // 1-indexed
  date: { type: String, required: true }, // ISO date string YYYY-MM-DD
  subject: { type: String, required: true },
  topic: { type: String, required: true },
  durationMinutes: { type: Number, required: true },
  isRevision: { type: Boolean, default: false },
  isCompleted: { type: Boolean, default: false },
  completedAt: { type: Date, default: null },
}, { _id: false });

const examPlanSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    subjects: [{ type: String, required: true, trim: true }],
    examDate: { type: Date, required: true },
    totalDays: { type: Number, required: true },
    dailyStudyHours: { type: Number, default: 4 },
    generatedPlan: [dailyTaskSchema],
    importantTopics: [importantTopicSchema],
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

examPlanSchema.index({ userId: 1, isActive: 1 });
examPlanSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('ExamPlan', examPlanSchema);
