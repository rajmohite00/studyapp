const StudySession = require('../models/StudySession');
const { AppError } = require('../middlewares/errorMiddleware');
const { calculateFocusScore } = require('../utils/focusScorer');
const { buildCursorPage, parsePagination } = require('../utils/pagination');
const streakService = require('./streakService');
const analyticsService = require('./analyticsService');
const gamificationService = require('./gamificationService');

const startSession = async (userId, { subject, topic, mode, plannedDurationMinutes, goal }) => {
  // Check for existing active session
  const active = await StudySession.findOne({ userId, status: 'active' });
  if (active) throw new AppError('You already have an active session', 409, 'SESSION_ACTIVE');

  const session = await StudySession.create({
    userId,
    subject: subject && subject.trim() !== '' ? subject : 'General',
    topic: topic || null,
    mode: mode || 'custom',
    plannedDurationMinutes: plannedDurationMinutes || 25,
    goal: goal || null,
    startTime: new Date(),
    status: 'active',
  });

  return session;
};

const updateSession = async (userId, sessionId, updates) => {
  const session = await StudySession.findOne({ _id: sessionId, userId });
  if (!session) throw new AppError('Session not found', 404, 'SESSION_NOT_FOUND');

  const { action, subject, interruptions, notes, rating, goalCompleted } = updates;

  if (subject !== undefined && subject.trim() !== '') {
    session.subject = subject.trim();
  }

  if (action === 'pause') {
    if (session.status !== 'active') throw new AppError('Session is not active', 400, 'INVALID_STATUS');
    session.status = 'paused';
  }

  if (action === 'resume') {
    if (session.status !== 'paused') throw new AppError('Session is not paused', 400, 'INVALID_STATUS');
    session.status = 'active';
  }

  if (action === 'end' || action === 'abandon') {
    const endTime = new Date();
    const durationSeconds = Math.floor((endTime - session.startTime) / 1000);
    const actualDurationMinutes = Math.round(durationSeconds / 60);

    session.endTime = endTime;
    session.durationSeconds = durationSeconds;
    session.actualDurationMinutes = actualDurationMinutes;
    session.status = action === 'end' ? 'completed' : 'abandoned';
    session.interruptions = interruptions || 0;
    session.focusScore = calculateFocusScore(durationSeconds, interruptions || 0);

    if (notes !== undefined) session.notes = notes;
    if (rating !== undefined) session.rating = rating;
    if (goalCompleted !== undefined) session.goalCompleted = goalCompleted;

    // Update streak for any completed session (any duration counts)
    let currentStreak = 0;
    if (action === 'end' && actualDurationMinutes > 0) {
      const streakResult = await streakService.updateStreakAfterSession(userId);
      currentStreak = streakResult?.current || 0;
    }
    
    let gamificationResult = null;
    if (action === 'end' && actualDurationMinutes > 0) {
      // We don't check for goalAchieved here perfectly, but we can pass false for now 
      // or we can fetch the user to check the daily goal. Let's pass false and let analytics handle it if needed.
      gamificationResult = await gamificationService.updateGamification(userId, actualDurationMinutes, false, currentStreak).catch(err => console.error(err));
    }

    await session.save();

    if (action === 'end') {
      // Fire-and-forget — don't block response. Analytics finishes in background.
      analyticsService.aggregateDailyAnalytics(userId).catch(err =>
        console.error('Analytics aggregation error:', err)
      );
    }

    const sessionObj = session.toObject();
    if (gamificationResult) {
      sessionObj.gamificationResult = gamificationResult;
    }
    return sessionObj;
  }

  await session.save();
  return session;
};

const getSessions = async (userId, query) => {
  const { subject, status, from, to, cursor, limit: rawLimit } = query;
  const limit = Math.min(parseInt(rawLimit) || 20, 100);

  const filter = { userId };
  if (subject) filter.subject = subject;
  if (status) filter.status = status;
  if (from || to) {
    filter.startTime = {};
    if (from) filter.startTime.$gte = new Date(from);
    if (to) filter.startTime.$lte = new Date(to);
  }
  if (cursor) filter._id = { $lt: cursor };

  const docs = await StudySession.find(filter).sort({ _id: -1 }).limit(limit + 1);
  return buildCursorPage(docs, limit);
};

const getSession = async (userId, sessionId) => {
  const session = await StudySession.findOne({ _id: sessionId, userId });
  if (!session) throw new AppError('Session not found', 404, 'SESSION_NOT_FOUND');
  return session;
};

const getActiveSession = async (userId) => {
  return StudySession.findOne({ userId, status: 'active' });
};

const deleteSession = async (userId, sessionId) => {
  const session = await StudySession.findOneAndDelete({ _id: sessionId, userId });
  if (!session) throw new AppError('Session not found', 404, 'SESSION_NOT_FOUND');
};

module.exports = { startSession, updateSession, getSessions, getSession, getActiveSession, deleteSession };
