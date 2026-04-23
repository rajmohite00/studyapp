const { verifyAccessToken } = require('../utils/jwtHelper');
const { getRedisClient } = require('../config/redis');
const { sendError } = require('../utils/responseHelper');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return sendError(res, 'No token provided', 401, 'NO_TOKEN');
    }

    const token = authHeader.split(' ')[1];

    // Check Redis blocklist
    const redis = getRedisClient();
    const isBlocked = await redis.get(`blocklist:${token}`);
    if (isBlocked) {
      return sendError(res, 'Token has been revoked', 401, 'TOKEN_REVOKED');
    }

    const decoded = verifyAccessToken(token);
    req.user = decoded; // { sub, email, role, iat, exp }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return sendError(res, 'Token expired', 401, 'TOKEN_EXPIRED');
    }
    return sendError(res, 'Invalid token', 401, 'INVALID_TOKEN');
  }
};

module.exports = { authenticate };
