const Flashcard = require('../models/Flashcard');
const { getOpenAIClient } = require('../config/openai');
const { AppError } = require('../middlewares/errorMiddleware');

// SuperMemo-2 (SM-2) Spaced Repetition Algorithm
// grade: 0-5 (0=blackout, 1=wrong, 2=hard, 3=good, 4=easy, 5=perfect)
const calculateSM2 = (quality, repetitions, previousInterval, previousEaseFactor) => {
  let interval;
  let easeFactor;

  if (quality >= 3) {
    if (repetitions === 0) {
      interval = 1;
    } else if (repetitions === 1) {
      interval = 6;
    } else {
      interval = Math.round(previousInterval * previousEaseFactor);
    }
    repetitions++;
  } else {
    repetitions = 0;
    interval = 1;
  }

  easeFactor = previousEaseFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  if (easeFactor < 1.3) easeFactor = 1.3;

  return { interval, easeFactor, repetitions };
};

const generateFlashcards = async (userId, subject, topicContext) => {
  const openai = getOpenAIClient();
  const prompt = `Based on the following study context for the subject "${subject}", generate 5 highly effective flashcards.
Context: "${topicContext}"

Extract the most important terms or concepts.
Return ONLY a valid JSON array exactly like this:
[
  { "term": "Concept Name", "definition": "Clear, concise explanation" }
]`;

  let response;
  try {
    response = await openai.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 1000,
      temperature: 0.3,
      response_format: { type: 'json_object' }
    });
  } catch (err) {
     response = await openai.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 1000,
      temperature: 0.3,
      response_format: { type: 'json_object' }
    });
  }

  let cards = [];
  try {
    const parsed = JSON.parse(response.choices[0].message.content);
    // Handle both { "cards": [...] } and [...] formats just in case
    cards = Array.isArray(parsed) ? parsed : (parsed.flashcards || parsed.cards || Object.values(parsed)[0]);
  } catch (e) {
    throw new AppError('Failed to parse AI flashcards', 500, 'AI_PARSE_ERROR');
  }

  const flashcardDocs = cards.map(c => ({
    userId,
    subject,
    term: c.term,
    definition: c.definition,
    nextReviewDate: new Date(), // Due immediately
  }));

  const inserted = await Flashcard.insertMany(flashcardDocs);
  return inserted;
};

const getDueFlashcards = async (userId) => {
  const now = new Date();
  return Flashcard.find({ userId, nextReviewDate: { $lte: now } }).sort({ nextReviewDate: 1 }).limit(20);
};

const reviewFlashcard = async (userId, cardId, quality) => {
  const card = await Flashcard.findOne({ _id: cardId, userId });
  if (!card) throw new AppError('Flashcard not found', 404);

  // quality should be 0-5
  const q = Math.max(0, Math.min(5, quality));
  
  const { interval, easeFactor, repetitions } = calculateSM2(
    q,
    card.repetitions,
    card.interval,
    card.easeFactor
  );

  card.interval = interval;
  card.easeFactor = easeFactor;
  card.repetitions = repetitions;
  
  // Calculate next review date
  const nextDate = new Date();
  nextDate.setDate(nextDate.getDate() + interval);
  card.nextReviewDate = nextDate;

  await card.save();
  return card;
};

module.exports = {
  generateFlashcards,
  getDueFlashcards,
  reviewFlashcard,
};
