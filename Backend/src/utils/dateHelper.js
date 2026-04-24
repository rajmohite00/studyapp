/**
 * Returns a Date object set to midnight IST (00:00:00 IST = 18:30 UTC previous day).
 * Used to compute "today" consistently for streak and analytics.
 */
const getTodayDate = (timezone = 'Asia/Kolkata') => {
  const now = new Date();
  const localStr = now.toLocaleDateString('en-CA', { timeZone: timezone }); // YYYY-MM-DD in IST
  // Parse as UTC midnight of that local date — consistent key for DB queries
  return new Date(`${localStr}T00:00:00.000Z`);
};

const addDays = (date, days) => {
  const d = new Date(date);
  d.setUTCDate(d.getUTCDate() + days);
  return d;
};

const isSameDay = (d1, d2) =>
  d1.toISOString().slice(0, 10) === d2.toISOString().slice(0, 10);

const diffDays = (d1, d2) =>
  Math.floor((d2 - d1) / (1000 * 60 * 60 * 24));

const formatDate = (date) => new Date(date).toISOString().slice(0, 10);

const startOfWeek = (date) => {
  const d = new Date(date);
  const day = d.getUTCDay();
  d.setUTCDate(d.getUTCDate() - day);
  d.setUTCHours(0, 0, 0, 0);
  return d;
};

const endOfWeek = (date) => {
  const start = startOfWeek(date);
  return addDays(start, 6);
};

module.exports = { getTodayDate, addDays, isSameDay, diffDays, formatDate, startOfWeek, endOfWeek };
