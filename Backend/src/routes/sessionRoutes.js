const express = require('express');
const router = express.Router();
const sessionController = require('../controllers/sessionController');
const { authenticate } = require('../middlewares/authMiddleware');
const { validate } = require('../middlewares/validateRequest');
const { z } = require('zod');

const startSessionSchema = z.object({
  subject: z.string().max(100).optional().or(z.literal('')),
  topic: z.string().max(200).optional(),
  mode: z.enum(['pomodoro', 'custom']).optional(),
  plannedDurationMinutes: z.number().min(1).max(480).optional(),
  goal: z.string().max(500).optional(),
});

const updateSessionSchema = z.object({
  action: z.enum(['pause', 'resume', 'end', 'abandon']).optional(),
  subject: z.string().max(100).optional(),
  interruptions: z.number().min(0).optional(),
  notes: z.string().max(2000).optional(),
  rating: z.number().min(1).max(5).optional(),
  goalCompleted: z.boolean().optional(),
});

router.use(authenticate);

router.post('/', validate(startSessionSchema), sessionController.startSession);
router.get('/', sessionController.getSessions);
router.get('/active', sessionController.getActiveSession);
router.get('/:id', sessionController.getSession);
router.patch('/:id', validate(updateSessionSchema), sessionController.updateSession);
router.delete('/:id', sessionController.deleteSession);

module.exports = router;
