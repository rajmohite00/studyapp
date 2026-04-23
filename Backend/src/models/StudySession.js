const mongoose = require('mongoose');

const studySessionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    subject: { type: String, required: true, trim: true },
    topic: { type: String, default: null, trim: true },
    mode: { type: String, enum: ['pomodoro', 'custom'], default: 'custom' },
    status: {
      type: String,
      enum: ['active', 'paused', 'completed', 'abandoned'],
      default: 'active',
    },

    startTime: { type: Date, required: true, default: Date.now },
    endTime: { type: Date, default: null },
    plannedDurationMinutes: { type: Number, default: 25 },
    actualDurationMinutes: { type: Number, default: 0 },
    durationSeconds: { type: Number, default: 0 },

    focusScore: { type: Number, min: 0, max: 100, default: 0 },
    interruptions: { type: Number, default: 0 },
    breakCount: { type: Number, default: 0 },

    notes: { type: String, default: null, maxlength: 2000 },
    tags: [{ type: String }],
    rating: { type: Number, min: 1, max: 5, default: null },

    goal: { type: String, default: null, maxlength: 500 },
    goalCompleted: { type: Boolean, default: false },

    aiInteractions: { type: Number, default: 0 },
  },
  { timestamps: true }
);

studySessionSchema.index({ userId: 1, startTime: -1 });
studySessionSchema.index({ userId: 1, subject: 1 });
studySessionSchema.index({ status: 1 });
studySessionSchema.index({ notes: 'text', tags: 'text' });

module.exports = mongoose.model('StudySession', studySessionSchema);
