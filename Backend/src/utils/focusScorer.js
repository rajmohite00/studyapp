/**
 * Calculates focus score (0–100) based on session interruption data.
 * Formula: (uninterrupted_time / total_time) * 100, with decay per interruption.
 *
 * @param {number} totalSeconds  - Total session duration in seconds
 * @param {number} interruptions - Number of interruptions detected
 * @returns {number} Focus score between 0 and 100
 */
const calculateFocusScore = (totalSeconds, interruptions = 0) => {
  if (!totalSeconds || totalSeconds <= 0) return 0;

  // Each interruption costs ~5% of focus (capped at 100% penalty)
  const penalty = Math.min(interruptions * 5, 100);
  const score = Math.max(0, 100 - penalty);

  return Math.round(score);
};

/**
 * Returns a label for the focus score.
 * Poor < 40, Fair 40–59, Good 60–79, Excellent 80–100
 */
const getFocusLabel = (score) => {
  if (score >= 80) return 'Excellent';
  if (score >= 60) return 'Good';
  if (score >= 40) return 'Fair';
  return 'Poor';
};

module.exports = { calculateFocusScore, getFocusLabel };
