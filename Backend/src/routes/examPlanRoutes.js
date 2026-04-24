const express = require('express');
const router = express.Router();
const examPlanController = require('../controllers/examPlanController');
const { authenticate } = require('../middlewares/authMiddleware');

router.use(authenticate);

router.post('/create', examPlanController.createPlan);
router.get('/', examPlanController.getPlan);
router.get('/progress', examPlanController.getProgress);
router.patch('/task', examPlanController.markTask);
router.get('/subject-info', examPlanController.getSubjectInfo);

module.exports = router;
