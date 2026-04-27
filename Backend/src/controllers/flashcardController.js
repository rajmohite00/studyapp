const flashcardService = require('../services/flashcardService');

exports.generate = async (req, res, next) => {
  try {
    const { subject, topicContext } = req.body;
    const cards = await flashcardService.generateFlashcards(req.user.id, subject, topicContext);
    res.status(201).json({ success: true, count: cards.length, data: cards });
  } catch (err) {
    next(err);
  }
};

exports.getDue = async (req, res, next) => {
  try {
    const cards = await flashcardService.getDueFlashcards(req.user.id);
    res.status(200).json({ success: true, data: cards });
  } catch (err) {
    next(err);
  }
};

exports.review = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { quality } = req.body;
    const card = await flashcardService.reviewFlashcard(req.user.id, id, quality);
    res.status(200).json({ success: true, data: card });
  } catch (err) {
    next(err);
  }
};
