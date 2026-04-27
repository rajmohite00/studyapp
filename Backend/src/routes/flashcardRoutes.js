const express = require('express');
const router = express.Router();
const flashcardController = require('../controllers/flashcardController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/generate', flashcardController.generate);
router.get('/due', flashcardController.getDue);
router.post('/:id/review', flashcardController.review);

module.exports = router;
