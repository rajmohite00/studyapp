const { z } = require('zod');
const { sendError } = require('../utils/responseHelper');

/**
 * Middleware factory — validates req.body against a Zod schema.
 * Usage: validate(myZodSchema)
 */
const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body);
  if (!result.success) {
    const errors = result.error.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    }));
    return res.status(422).json({
      success: false,
      error: { message: 'Validation failed', code: 'VALIDATION_ERROR', details: errors },
    });
  }
  req.body = result.data; // replace with parsed + coerced data
  next();
};

/**
 * Validates req.query against a Zod schema.
 */
const validateQuery = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.query);
  if (!result.success) {
    const errors = result.error.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    }));
    return res.status(422).json({
      success: false,
      error: { message: 'Invalid query parameters', code: 'VALIDATION_ERROR', details: errors },
    });
  }
  req.query = result.data;
  next();
};

module.exports = { validate, validateQuery };
