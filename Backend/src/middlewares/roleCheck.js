const { sendError } = require('../utils/responseHelper');

/**
 * Role-based access control middleware.
 * Usage: authorize('admin') or authorize('admin', 'student')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return sendError(res, 'Not authenticated', 401, 'NOT_AUTHENTICATED');
    }
    if (!roles.includes(req.user.role)) {
      return sendError(res, 'Access denied. Insufficient permissions.', 403, 'FORBIDDEN');
    }
    next();
  };
};

module.exports = { authorize };
