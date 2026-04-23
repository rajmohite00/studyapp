/**
 * Standard success response envelope.
 */
const sendSuccess = (res, data = null, statusCode = 200, meta = null) => {
  const body = { success: true, data };
  if (meta) body.meta = meta;
  return res.status(statusCode).json(body);
};

/**
 * Standard error response envelope.
 */
const sendError = (res, message = 'Something went wrong', statusCode = 500, code = 'INTERNAL_ERROR') => {
  return res.status(statusCode).json({
    success: false,
    error: { message, code },
  });
};

module.exports = { sendSuccess, sendError };
