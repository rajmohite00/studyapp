const mongoose = require('mongoose');

const flashcardSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  subject: {
    type: String,
    required: true,
    trim: true,
  },
  term: {
    type: String,
    required: true,
  },
  definition: {
    type: String,
    required: true,
  },
  // Spaced Repetition System (SM-2) fields
  nextReviewDate: {
    type: Date,
    default: Date.now,
  },
  interval: {
    type: Number, // in days
    default: 0,
  },
  easeFactor: {
    type: Number,
    default: 2.5, // minimum 1.3
  },
  repetitions: {
    type: Number,
    default: 0,
  },
}, { timestamps: true });

// Index for efficient querying of due cards
flashcardSchema.index({ userId: 1, nextReviewDate: 1 });

module.exports = mongoose.model('Flashcard', flashcardSchema);
