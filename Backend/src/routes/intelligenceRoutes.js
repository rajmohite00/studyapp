const express = require('express');
const router = express.Router();
const intelligenceController = require('../controllers/intelligenceController');
const { authenticate } = require('../middlewares/authMiddleware');

router.use(authenticate);

router.get('/burnout', intelligenceController.getBurnout);
router.get('/prediction', intelligenceController.getPrediction);
router.get('/insights', intelligenceController.getInsights);
router.get('/performance', intelligenceController.getPerformance);

module.exports = router;
