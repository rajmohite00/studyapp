/**
 * Builds a cursor-based pagination result for session lists.
 * @param {Array}  docs     - Query results
 * @param {number} limit    - Requested page size
 * @returns {{ data, nextCursor, hasMore }}
 */
const buildCursorPage = (docs, limit) => {
  const hasMore = docs.length > limit;
  const data = hasMore ? docs.slice(0, limit) : docs;
  const nextCursor = hasMore ? data[data.length - 1]._id : null;
  return { data, nextCursor, hasMore };
};

/**
 * Builds standard offset pagination meta.
 */
const buildOffsetMeta = (total, page, limit) => ({
  total,
  page,
  limit,
  totalPages: Math.ceil(total / limit),
  hasNext: page * limit < total,
  hasPrev: page > 1,
});

/**
 * Parses and sanitizes page/limit from query params.
 */
const parsePagination = (query, defaultLimit = 20, maxLimit = 100) => {
  const page = Math.max(1, parseInt(query.page) || 1);
  const limit = Math.min(maxLimit, Math.max(1, parseInt(query.limit) || defaultLimit));
  const skip = (page - 1) * limit;
  return { page, limit, skip };
};

module.exports = { buildCursorPage, buildOffsetMeta, parsePagination };
