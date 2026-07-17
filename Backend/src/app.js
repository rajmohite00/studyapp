const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const sessionRoutes = require('./routes/sessionRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const aiRoutes = require('./routes/aiRoutes');
const intelligenceRoutes = require('./routes/intelligenceRoutes');
const examPlanRoutes = require('./routes/examPlanRoutes');
const gamificationRoutes = require('./routes/gamificationRoutes');
const flashcardRoutes = require('./routes/flashcardRoutes');
const testRoutes = require('./routes/testRoutes');
const { errorMiddleware } = require('./middlewares/errorMiddleware');
const { globalRateLimiter } = require('./middlewares/rateLimiter');

const app = express();

// ── Security & Parsing ──────────────────────────────────────────────────────
app.use(helmet());

// Allow any origin if CLIENT_ORIGIN is '*' or not set — useful for web/mobile clients.
// Set CLIENT_ORIGIN to a specific URL in production for tighter security.
const corsOrigin = process.env.CLIENT_ORIGIN === '*' || !process.env.CLIENT_ORIGIN
  ? '*'
  : process.env.CLIENT_ORIGIN;

app.use(cors({
  origin: corsOrigin,
  credentials: corsOrigin !== '*',
}));
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(process.env.NODE_ENV === 'development' ? 'dev' : 'combined'));

// ── Global Rate Limiter ─────────────────────────────────────────────────────
app.use('/api', globalRateLimiter);

// ── Health Check ────────────────────────────────────────────────────────────
app.get('/', (_req, res) => {
  res.json({ 
    success: true, 
    message: 'Study Coach API is running',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      api: '/api/v1'
    }
  });
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ── API Routes ───────────────────────────────────────────────────────────────
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/sessions', sessionRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/intelligence', intelligenceRoutes);
app.use('/api/v1/exam-plan', examPlanRoutes);
app.use('/api/v1/gamification', gamificationRoutes);
app.use('/api/v1/flashcards', flashcardRoutes);
app.use('/api/v1/tests', testRoutes);

// ── 404 ──────────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, error: 'Route not found' });
});

// ── Global Error Handler ─────────────────────────────────────────────────────
app.use(errorMiddleware);

module.exports = app;
