const express = require('express');
const router = express.Router();
const gamificationController = require('../controllers/gamificationController');
const { authenticate } = require('../middlewares/authMiddleware');

router.use(authenticate);

// Full gamification state (XP, level, achievements, missions, store)
router.get('/state', gamificationController.getState);

// Reward store
router.get('/store', gamificationController.getStore);
router.post('/unlock-reward', gamificationController.unlockReward);
router.post('/equip-badge', gamificationController.equipBadge);

// Achievements
router.get('/achievements', gamificationController.getAchievements);

// Daily missions
router.get('/missions', gamificationController.getMissions);

module.exports = router;
