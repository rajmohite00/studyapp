const mongoose = require('mongoose');

// ── Single Question ────────────────────────────────────────────────────────────
const questionSchema = new mongoose.Schema({
  index:       { type: Number, required: true },
  type:        { type: String, enum: ['mcq','true_false','fill_blank','code_output','scenario','conceptual','short_answer'], default: 'mcq' },
  question:    { type: String, required: true },
  options:     [{ type: String }],          // MCQ / True-False only
  correctAnswer: { type: String, required: true },
  explanation: { type: String, default: '' },
  topic:       { type: String, default: '' },
  difficulty:  { type: String, enum: ['easy','medium','hard'], default: 'medium' },
}, { _id: false });

// ── User Answer ────────────────────────────────────────────────────────────────
const answerSchema = new mongoose.Schema({
  questionIndex: { type: Number, required: true },
  userAnswer:    { type: String, default: null },   // null = skipped
  isCorrect:     { type: Boolean, default: false },
  timeTaken:     { type: Number, default: 0 },      // seconds
}, { _id: false });

// ── AI Analysis ───────────────────────────────────────────────────────────────
const aiAnalysisSchema = new mongoose.Schema({
  overallPerformance: { type: String, default: '' },
  strongTopics:       [{ type: String }],
  weakTopics:         [{ type: String }],
  mistakes:           { type: String, default: '' },
  knowledgeGaps:      { type: String, default: '' },
  conceptsToRevise:   [{ type: String }],
  difficultyAnalysis: { type: String, default: '' },
  learningPattern:    { type: String, default: '' },
  personalizedFeedback: { type: String, default: '' },
  studySuggestions:   [{ type: String }],
  estimatedLevel:     { type: String, default: '' },
  motivationMessage:  { type: String, default: '' },
}, { _id: false });

// ── Revision Plan ─────────────────────────────────────────────────────────────
const revisionPlanSchema = new mongoose.Schema({
  highPriority:   [{ type: String }],
  mediumPriority: [{ type: String }],
  lowPriority:    [{ type: String }],
  studyOrder:     [{ type: String }],
  estimatedHours: { type: Number, default: 0 },
  suggestedNextTest: { type: String, default: '' },
}, { _id: false });

// ── Main Test Schema ──────────────────────────────────────────────────────────
const testSchema = new mongoose.Schema({
  userId:       { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },

  // Config
  subject:      { type: String, required: true, trim: true },
  topics:       [{ type: String, trim: true }],   // empty = entire subject
  testType:     { type: String, enum: ['full_subject','topic_wise'], default: 'full_subject' },
  difficulty:   { type: String, enum: ['easy','medium','hard','mixed'], default: 'mixed' },
  questionCount: { type: Number, required: true },
  timerMinutes: { type: Number, default: 0 },      // 0 = no timer

  // State
  status: {
    type: String,
    enum: ['draft','active','submitted','analysed'],
    default: 'draft',
  },

  // Content
  questions:  [questionSchema],
  answers:    [answerSchema],

  // Timing
  startedAt:    { type: Date, default: null },
  submittedAt:  { type: Date, default: null },
  timeSpentSecs:{ type: Number, default: 0 },

  // Score
  totalQuestions: { type: Number, default: 0 },
  attempted:      { type: Number, default: 0 },
  correct:        { type: Number, default: 0 },
  wrong:          { type: Number, default: 0 },
  skipped:        { type: Number, default: 0 },
  marks:          { type: Number, default: 0 },
  percentage:     { type: Number, default: 0 },
  grade:          { type: String, default: '' },
  passed:         { type: Boolean, default: false },
  accuracy:       { type: Number, default: 0 },      // percent
  avgTimePerQuestion: { type: Number, default: 0 },  // seconds

  // AI
  aiAnalysis:   { type: aiAnalysisSchema, default: null },
  revisionPlan: { type: revisionPlanSchema, default: null },

}, { timestamps: true });

testSchema.index({ userId: 1, createdAt: -1 });
testSchema.index({ userId: 1, subject: 1 });
testSchema.index({ userId: 1, status: 1 });

module.exports = mongoose.model('Test', testSchema);
