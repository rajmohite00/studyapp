const StudySession = require('../models/StudySession');
const Analytics = require('../models/Analytics');
const User = require('../models/User');

const getBurnoutStatus = async (userId) => {
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const sessions = await StudySession.find({ userId, startTime: { $gte: sevenDaysAgo } }).sort({ startTime: 1 });
  
  if (sessions.length === 0) {
    return { status: 'Normal', suggestion: 'You have plenty of energy. Time to start studying!' };
  }

  let totalMinutes = 0;
  let consecutiveDays = 0;
  let lastDate = null;
  let daysStudied = new Set();

  for (const session of sessions) {
    totalMinutes += session.actualDurationMinutes;
    const dateStr = session.startTime.toISOString().split('T')[0];
    daysStudied.add(dateStr);
    
    if (lastDate !== dateStr) {
      consecutiveDays++;
      lastDate = dateStr;
    }
  }

  const avgMinutesPerDay = totalMinutes / 7;
  
  if (avgMinutesPerDay > 300 && consecutiveDays >= 6) {
    return { status: 'High Risk', suggestion: 'Take a break! You are studying too much without rest days. Prevent burnout.' };
  } else if (avgMinutesPerDay > 180 && consecutiveDays >= 5) {
    return { status: 'Warning', suggestion: 'You are pushing hard. Make sure to schedule a light day soon.' };
  } else {
    return { status: 'Normal', suggestion: 'Your study pace is healthy. Keep it up!' };
  }
};

const getPrediction = async (userId) => {
  const user = await User.findById(userId).select('streak profile');
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const sessions = await StudySession.find({ userId, status: 'completed', startTime: { $gte: thirtyDaysAgo } });
  
  let totalMinutes = 0;
  let totalFocus = 0;
  
  sessions.forEach(s => {
    totalMinutes += s.actualDurationMinutes;
    totalFocus += s.focusScore;
  });

  const avgFocus = sessions.length ? (totalFocus / sessions.length) : 0;
  const consistencyScore = user?.streak?.current != null ? Math.min(user.streak.current * 2, 20) : 0; 
  
  // Base score 40, focus contributes up to 30, consistency up to 20, raw volume up to 10
  let predictedScore = 40;
  predictedScore += (avgFocus * 0.3); // max 30
  predictedScore += consistencyScore; // max 20
  predictedScore += Math.min((totalMinutes / 1000) * 10, 10); // max 10

  predictedScore = Math.min(Math.round(predictedScore), 100);

  return { 
    predictedScore, 
    suggestion: `At your current pace and focus, your expected performance score is ${predictedScore}%.` 
  };
};

const getInsights = async (userId) => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const sessions = await StudySession.find({ userId, status: 'completed', startTime: { $gte: thirtyDaysAgo } });
  
  if (sessions.length === 0) return { bestTime: 'Unknown', activeDay: 'Unknown', weakSubjects: [], insight: 'Not enough data yet.' };

  const hourCounts = {};
  const dayCounts = {};
  const subjectTime = {};

  sessions.forEach(s => {
    const h = s.startTime.getHours();
    let timeOfDay = 'Night';
    if (h >= 5 && h < 12) timeOfDay = 'Morning';
    else if (h >= 12 && h < 17) timeOfDay = 'Afternoon';
    else if (h >= 17 && h < 22) timeOfDay = 'Evening';
    
    hourCounts[timeOfDay] = (hourCounts[timeOfDay] || 0) + s.actualDurationMinutes;
    
    const day = s.startTime.toLocaleDateString('en-US', { weekday: 'long' });
    dayCounts[day] = (dayCounts[day] || 0) + s.actualDurationMinutes;
    
    subjectTime[s.subject] = (subjectTime[s.subject] || 0) + s.actualDurationMinutes;
  });

  const bestTime = Object.keys(hourCounts).reduce((a, b) => hourCounts[a] > hourCounts[b] ? a : b, 'Unknown');
  const activeDay = Object.keys(dayCounts).reduce((a, b) => dayCounts[a] > dayCounts[b] ? a : b, 'Unknown');
  
  const user = await User.findById(userId).select('profile');
  const allSubjects = user?.profile?.subjects || [];
  
  const weakSubjects = [];
  let weakSuggestion = '';
  if (allSubjects.length > 0) {
    allSubjects.forEach(sub => {
      if (!subjectTime[sub]) subjectTime[sub] = 0; // 0 minutes studied
    });
    
    const sortedSubjects = Object.keys(subjectTime).sort((a, b) => subjectTime[a] - subjectTime[b]);
    weakSubjects.push(...sortedSubjects.slice(0, 2));
    if (weakSubjects.length > 0) {
      weakSuggestion = `You've spent the least time on ${weakSubjects.join(' and ')}. Consider focusing more on them!`;
    }
  }

  return {
    bestTime,
    activeDay,
    weakSubjects,
    insight: `You perform best in the ${bestTime} and are most active on ${activeDay}s. ${weakSuggestion}`
  };
};

const getPerformance = async (userId) => {
  const prediction = await getPrediction(userId);
  let rating = 'Needs Improvement';
  
  if (prediction.predictedScore >= 85) rating = 'Excellent';
  else if (prediction.predictedScore >= 70) rating = 'Good';
  else if (prediction.predictedScore >= 50) rating = 'Average';

  return {
    score: prediction.predictedScore,
    rating,
    suggestion: `Overall Performance: ${rating}. Keep up the consistency.`
  };
};

module.exports = { getBurnoutStatus, getPrediction, getInsights, getPerformance };
