const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  role: { type: String, enum: ['user', 'assistant', 'system'], required: true },
  content: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
});

const aiConversationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'StudySession', default: null },
    subject: { type: String, default: null },
    documentContext: { type: String, default: null },
    messages: [messageSchema],
    tokensUsed: { type: Number, default: 0 },
    type: { type: String, enum: ['chat', 'quiz', 'explain', 'recommend'], default: 'chat' },
  },
  { timestamps: true }
);

aiConversationSchema.index({ userId: 1, createdAt: -1 });
aiConversationSchema.index({ sessionId: 1 });

module.exports = mongoose.model('AiConversation', aiConversationSchema);
