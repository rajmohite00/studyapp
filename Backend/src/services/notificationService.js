const { getAdmin } = require('../config/firebase');

/**
 * Send a push notification to a single device via FCM.
 * @param {string} fcmToken  - Device FCM token
 * @param {string} title     - Notification title
 * @param {string} body      - Notification body text
 * @param {Object} data      - Optional key-value payload
 */
const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken) return;
  try {
    const admin = getAdmin();
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data,
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    console.error('FCM send error:', err.message);
  }
};

/**
 * Send daily goal achievement notification.
 */
const sendGoalAchievedNotification = async (fcmToken) => {
  await sendPushNotification(fcmToken, '🎉 Daily Goal Reached!', "You've hit your study goal for today. Keep it up!", { type: 'GOAL_ACHIEVED' });
};

/**
 * Send streak milestone notification.
 */
const sendStreakMilestoneNotification = async (fcmToken, days) => {
  await sendPushNotification(fcmToken, `🔥 ${days}-Day Streak!`, `Amazing! You've maintained a ${days}-day study streak.`, { type: 'STREAK_MILESTONE', days: String(days) });
};

/**
 * Send session reminder notification.
 */
const sendSessionReminder = async (fcmToken, subject) => {
  await sendPushNotification(fcmToken, '📚 Time to Study!', `Don't forget your ${subject} session today.`, { type: 'SESSION_REMINDER' });
};

module.exports = { sendPushNotification, sendGoalAchievedNotification, sendStreakMilestoneNotification, sendSessionReminder };
