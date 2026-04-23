const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate } = require('../middlewares/authMiddleware');
const { validate } = require('../middlewares/validateRequest');
const { z } = require('zod');

const updateProfileSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  fcmToken: z.string().optional(),
  profile: z
    .object({
      grade: z.string().optional(),
      targetExam: z.string().optional(),
      subjects: z.array(z.string()).optional(),
      dailyGoalMinutes: z.number().min(10).max(720).optional(),
    })
    .optional(),
  preferences: z
    .object({
      notificationsEnabled: z.boolean().optional(),
      timezone: z.string().optional(),
      theme: z.enum(['light', 'dark']).optional(),
    })
    .optional(),
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(8),
});

router.use(authenticate); // All user routes require auth

router.get('/profile', userController.getProfile);
router.patch('/profile', validate(updateProfileSchema), userController.updateProfile);
router.patch('/password', validate(changePasswordSchema), userController.changePassword);
router.delete('/account', userController.deleteAccount);

module.exports = router;
