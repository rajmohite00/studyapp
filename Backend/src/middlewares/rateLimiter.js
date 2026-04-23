const rateLimit = require('express-rate-limit');
const { getRedisClient } = require('../config/redis');

// Custom Redis store for express-rate-limit
const createRedisStore = (prefix) => {
  const client = getRedisClient();
  return {
    async increment(key) {
      const fullKey = `${prefix}:${key}`;
      const res = await client.multi().incr(fullKey).expire(fullKey, 60).exec();
      return { totalHits: res[0], resetTime: new Date(Date.now() + 60000) };
    },
    async decrement(key) {
      await client.decr(`${prefix}:${key}`);
    },
    async resetKey(key) {
      await client.del(`${prefix}:${key}`);
    },
  };
};

// General API rate limiter: 300 req / 15 min per user
const globalRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { message: 'Too many requests', code: 'RATE_LIMITED' } },
});

// Strict limiter for auth endpoints: 10 req / 15 min per IP
const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { message: 'Too many auth attempts', code: 'RATE_LIMITED' } },
});

// AI endpoints: 30 req / min per user
const aiRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  keyGenerator: (req) => req.user?.sub || req.ip,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { message: 'AI rate limit exceeded', code: 'RATE_LIMITED' } },
});

module.exports = { globalRateLimiter, authRateLimiter, aiRateLimiter };
