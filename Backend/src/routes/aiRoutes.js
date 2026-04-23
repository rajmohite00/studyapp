const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { authenticate } = require('../middlewares/authMiddleware');
const { aiRateLimiter } = require('../middlewares/rateLimiter');
const { validate } = require('../middlewares/validateRequest');
const { z } = require('zod');

const chatSchema = z.object({
  message: z.string().min(1).max(2000),
  conversationId: z.string().optional(),
  subject: z.string().optional(),
});

const explainSchema = z.object({
  concept: z.string().min(1).max(300),
  subject: z.string().min(1),
});

const quizSchema = z.object({
  subject: z.string().min(1),
  chapter: z.string().optional(),
  topic: z.string().optional(),
  difficulty: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
  count: z.number().min(1).max(20).optional(),
});

const submitQuizSchema = z.object({
  answers: z.array(z.string()),
});

router.use(authenticate, aiRateLimiter);

router.post('/chat', validate(chatSchema), aiController.chat);
router.get('/conversations', aiController.getConversations);
router.get('/conversations/:id', aiController.getConversation);
router.post('/explain', validate(explainSchema), aiController.explain);
router.post('/quiz', validate(quizSchema), aiController.generateQuiz);
router.post('/quiz/:id/submit', validate(submitQuizSchema), aiController.submitQuiz);
router.get('/recommend', aiController.getRecommendations);
router.get('/weak-topics', aiController.getWeakTopics);

module.exports = router;
