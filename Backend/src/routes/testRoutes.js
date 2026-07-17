const express = require('express');
const router = express.Router();
const testController = require('../controllers/testController');
const { authenticate } = require('../middlewares/authMiddleware');
const { aiRateLimiter } = require('../middlewares/rateLimiter');
const { validate, validateQuery } = require('../middlewares/validateRequest');
const { z } = require('zod');

// ── Validation Schemas ─────────────────────────────────────────────────────────

const createSchema = z.object({
  subject:       z.string().min(1).max(100),
  topics:        z.array(z.string()).optional().default([]),
  testType:      z.enum(['full_subject', 'topic_wise']).optional().default('full_subject'),
  difficulty:    z.enum(['easy', 'medium', 'hard', 'mixed']).optional().default('mixed'),
  questionCount: z.coerce.number().int().min(5).max(100),
  timerMinutes:  z.coerce.number().int().min(0).max(180).optional().default(0),
});

const answerSchema = z.object({
  questionIndex: z.number().int().min(0),
  userAnswer:    z.string().nullable().optional(),
});

const bulkAnswersSchema = z.object({
  answers: z.array(answerSchema),
});

const submitSchema = z.object({
  answers:       z.array(answerSchema).optional().default([]),
  timeSpentSecs: z.number().int().min(0).optional().default(0),
});

const historyQuerySchema = z.object({
  subject:    z.string().optional(),
  difficulty: z.enum(['easy','medium','hard','mixed']).optional(),
  grade:      z.string().optional(),
  passed:     z.string().optional(),
  dateFrom:   z.string().optional(),
  dateTo:     z.string().optional(),
});

// ── All routes require auth ────────────────────────────────────────────────────
router.use(authenticate);

// Stats & draft (must come BEFORE /:id routes)
router.get('/stats',        testController.getStats);
router.get('/draft/active', testController.getActiveDraft);
router.get('/history',      validateQuery(historyQuerySchema), testController.getHistory);

// Create (AI generation — rate limited)
router.post('/create', aiRateLimiter, validate(createSchema), testController.createTest);

// Per-test operations
router.get   ('/:id',              testController.getTest);
router.post  ('/:id/start',        testController.startTest);
router.patch ('/:id/answer',       validate(answerSchema), testController.saveAnswer);
router.patch ('/:id/answers/bulk', validate(bulkAnswersSchema), testController.saveBulkAnswers);
router.post  ('/:id/submit',       validate(submitSchema), testController.submitTest);
router.post  ('/:id/analyse',      aiRateLimiter, testController.analyseTest);
router.delete('/:id',              testController.deleteTest);

module.exports = router;
