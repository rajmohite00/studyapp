const ExamPlan = require('../models/ExamPlan');
const { AppError } = require('../middlewares/errorMiddleware');
const { getTodayDate } = require('../utils/dateHelper');

// ── PYQ Mock Database (topic → frequency score + PYQs) ──────────────────────
const PYQ_DATABASE = {
  // Mathematics
  'Calculus': {
    priority: 'high', frequency: 95,
    pyqs: [
      { question: 'Find the derivative of f(x) = x³ - 3x² + 2x using first principles.', year: 2023, frequency: 5, isHighlighted: true },
      { question: 'Evaluate the definite integral ∫₀¹ (x² + 1) dx.', year: 2022, frequency: 4, isHighlighted: true },
      { question: 'Find the maxima and minima of f(x) = 2x³ - 3x² - 12x + 5.', year: 2021, frequency: 3, isHighlighted: false },
      { question: 'Using L\'Hôpital\'s rule, evaluate lim(x→0) [sin(x)/x].', year: 2020, frequency: 4, isHighlighted: true },
    ],
  },
  'Linear Algebra': {
    priority: 'high', frequency: 88,
    pyqs: [
      { question: 'Find the eigenvalues and eigenvectors of the matrix [[2,1],[1,2]].', year: 2023, frequency: 4, isHighlighted: true },
      { question: 'Prove that the rank of a matrix equals the rank of its transpose.', year: 2022, frequency: 3, isHighlighted: false },
      { question: 'Solve the system of linear equations using Cramer\'s rule.', year: 2021, frequency: 5, isHighlighted: true },
    ],
  },
  'Probability': {
    priority: 'high', frequency: 90,
    pyqs: [
      { question: 'A bag contains 5 red, 3 blue balls. Find probability of 2 red balls in 3 draws.', year: 2023, frequency: 5, isHighlighted: true },
      { question: 'Define and prove Bayes\' theorem with an example.', year: 2022, frequency: 4, isHighlighted: true },
      { question: 'Find the mean and variance of binomial distribution B(n,p).', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
  // Physics
  'Mechanics': {
    priority: 'high', frequency: 92,
    pyqs: [
      { question: 'Derive the equations of motion under uniform acceleration.', year: 2023, frequency: 5, isHighlighted: true },
      { question: 'A projectile is launched at 45°. Find range and max height.', year: 2022, frequency: 4, isHighlighted: true },
      { question: 'State and prove the law of conservation of momentum.', year: 2021, frequency: 4, isHighlighted: true },
    ],
  },
  'Thermodynamics': {
    priority: 'high', frequency: 87,
    pyqs: [
      { question: 'State the first and second laws of thermodynamics with examples.', year: 2023, frequency: 4, isHighlighted: true },
      { question: 'Explain Carnot cycle and derive its efficiency formula.', year: 2022, frequency: 5, isHighlighted: true },
      { question: 'What is entropy? Explain its significance.', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
  'Electromagnetism': {
    priority: 'medium', frequency: 75,
    pyqs: [
      { question: 'State and prove Gauss\'s law for electric fields.', year: 2023, frequency: 3, isHighlighted: false },
      { question: 'Derive the expression for magnetic force on a current-carrying conductor.', year: 2022, frequency: 3, isHighlighted: false },
      { question: 'Explain Faraday\'s laws of electromagnetic induction.', year: 2021, frequency: 4, isHighlighted: true },
    ],
  },
  // Chemistry
  'Organic Chemistry': {
    priority: 'high', frequency: 93,
    pyqs: [
      { question: 'Write the mechanism of SN1 and SN2 reactions with examples.', year: 2023, frequency: 5, isHighlighted: true },
      { question: 'Explain Markovnikov\'s rule with an example.', year: 2022, frequency: 4, isHighlighted: true },
      { question: 'What are isomers? Classify with examples.', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
  'Physical Chemistry': {
    priority: 'high', frequency: 85,
    pyqs: [
      { question: 'Derive the integrated rate law for first-order reactions.', year: 2023, frequency: 4, isHighlighted: true },
      { question: 'Explain colligative properties and their applications.', year: 2022, frequency: 3, isHighlighted: false },
      { question: 'State Raoult\'s law. What are ideal and non-ideal solutions?', year: 2021, frequency: 4, isHighlighted: true },
    ],
  },
  'Inorganic Chemistry': {
    priority: 'medium', frequency: 70,
    pyqs: [
      { question: 'Explain hybridization of carbon in methane, ethene, and ethyne.', year: 2023, frequency: 3, isHighlighted: false },
      { question: 'Describe periodic trends in ionization energy and electronegativity.', year: 2022, frequency: 4, isHighlighted: true },
    ],
  },
  // Computer Science
  'Data Structures': {
    priority: 'high', frequency: 96,
    pyqs: [
      { question: 'Implement a binary search tree and explain in-order traversal.', year: 2023, frequency: 5, isHighlighted: true },
      { question: 'Compare Stack and Queue. Write push/pop operations.', year: 2022, frequency: 4, isHighlighted: true },
      { question: 'Explain dynamic programming with 0/1 knapsack problem.', year: 2021, frequency: 5, isHighlighted: true },
    ],
  },
  'Algorithms': {
    priority: 'high', frequency: 94,
    pyqs: [
      { question: 'Analyze time complexity of QuickSort and MergeSort.', year: 2023, frequency: 5, isHighlighted: true },
      { question: 'Explain Dijkstra\'s algorithm with a weighted graph example.', year: 2022, frequency: 4, isHighlighted: true },
      { question: 'What is Big-O notation? Give examples of O(1), O(n), O(n²).', year: 2021, frequency: 4, isHighlighted: true },
    ],
  },
  'Operating Systems': {
    priority: 'medium', frequency: 78,
    pyqs: [
      { question: 'Explain process scheduling algorithms: FCFS, SJF, Round Robin.', year: 2023, frequency: 4, isHighlighted: true },
      { question: 'What is deadlock? Explain Banker\'s algorithm.', year: 2022, frequency: 3, isHighlighted: false },
      { question: 'Explain virtual memory and page replacement algorithms.', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
  'Database Management': {
    priority: 'medium', frequency: 76,
    pyqs: [
      { question: 'Explain normalization forms: 1NF, 2NF, 3NF with examples.', year: 2023, frequency: 4, isHighlighted: true },
      { question: 'Write SQL queries for JOIN operations with examples.', year: 2022, frequency: 5, isHighlighted: true },
      { question: 'Explain ACID properties of database transactions.', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
  // Biology
  'Cell Biology': {
    priority: 'high', frequency: 91,
    pyqs: [
      { question: 'Describe the structure and function of mitochondria.', year: 2023, frequency: 4, isHighlighted: true },
      { question: 'Explain the stages of cell division: mitosis vs meiosis.', year: 2022, frequency: 5, isHighlighted: true },
      { question: 'What is the role of the endoplasmic reticulum?', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
  'Genetics': {
    priority: 'high', frequency: 89,
    pyqs: [
      { question: 'Explain Mendel\'s laws of heredity with examples.', year: 2023, frequency: 5, isHighlighted: true },
      { question: 'Describe DNA replication with relevant enzymes.', year: 2022, frequency: 4, isHighlighted: true },
      { question: 'What are mutations? Classify them with examples.', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
  // Economics
  'Microeconomics': {
    priority: 'high', frequency: 88,
    pyqs: [
      { question: 'Explain the law of demand and demand elasticity with examples.', year: 2023, frequency: 4, isHighlighted: true },
      { question: 'Describe different market structures: perfect competition, monopoly.', year: 2022, frequency: 5, isHighlighted: true },
      { question: 'What is consumer surplus? Explain graphically.', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
  'Macroeconomics': {
    priority: 'high', frequency: 85,
    pyqs: [
      { question: 'Explain Keynesian theory of income determination.', year: 2023, frequency: 4, isHighlighted: true },
      { question: 'What is GDP? Distinguish between nominal and real GDP.', year: 2022, frequency: 4, isHighlighted: true },
      { question: 'Explain the role of monetary policy in controlling inflation.', year: 2021, frequency: 3, isHighlighted: false },
    ],
  },
};

// Generic topics for unrecognized subjects
const GENERIC_TOPICS = {
  'Introduction & Fundamentals': { priority: 'high', frequency: 90, pyqs: [
    { question: 'Define the core concepts and principles of this subject.', year: 2023, frequency: 4, isHighlighted: true },
    { question: 'Explain the historical development and key milestones.', year: 2022, frequency: 3, isHighlighted: false },
  ]},
  'Core Theory': { priority: 'high', frequency: 88, pyqs: [
    { question: 'Explain the most important theoretical framework with examples.', year: 2023, frequency: 5, isHighlighted: true },
    { question: 'Describe the main principles and their practical applications.', year: 2022, frequency: 4, isHighlighted: true },
  ]},
  'Problem Solving & Applications': { priority: 'medium', frequency: 80, pyqs: [
    { question: 'Solve a standard problem demonstrating key analytical skills.', year: 2023, frequency: 4, isHighlighted: true },
    { question: 'Apply the learned concepts to a real-world scenario.', year: 2022, frequency: 3, isHighlighted: false },
  ]},
  'Advanced Topics': { priority: 'medium', frequency: 72, pyqs: [
    { question: 'Discuss an advanced concept and its implications.', year: 2023, frequency: 3, isHighlighted: false },
    { question: 'Compare and contrast two advanced approaches.', year: 2022, frequency: 2, isHighlighted: false },
  ]},
  'Revision & Practice': { priority: 'low', frequency: 60, pyqs: [
    { question: 'Short answer questions from all major chapters.', year: 2023, frequency: 2, isHighlighted: false },
  ]},
};

// Subject → relevant topics mapping
const SUBJECT_TOPICS = {
  'mathematics': ['Calculus', 'Linear Algebra', 'Probability'],
  'math': ['Calculus', 'Linear Algebra', 'Probability'],
  'physics': ['Mechanics', 'Thermodynamics', 'Electromagnetism'],
  'chemistry': ['Organic Chemistry', 'Physical Chemistry', 'Inorganic Chemistry'],
  'computer science': ['Data Structures', 'Algorithms', 'Operating Systems', 'Database Management'],
  'cs': ['Data Structures', 'Algorithms', 'Operating Systems'],
  'biology': ['Cell Biology', 'Genetics'],
  'economics': ['Microeconomics', 'Macroeconomics'],
};

// ── Plan Generation ──────────────────────────────────────────────────────────

const getTopicsForSubject = (subject) => {
  const key = subject.toLowerCase();
  const matchedKey = Object.keys(SUBJECT_TOPICS).find(k => key.includes(k));
  if (matchedKey) {
    return SUBJECT_TOPICS[matchedKey].map(topicName => ({
      name: topicName,
      ...PYQ_DATABASE[topicName],
    }));
  }
  // Generic fallback
  return Object.entries(GENERIC_TOPICS).map(([name, data]) => ({ name, ...data }));
};

const getLocalDateString = (d) => {
  return d.toISOString().slice(0, 10);
};

const generateDailyPlan = (subjects, startDate, totalDays, dailyStudyHours) => {
  const revisionDays = Math.max(1, Math.floor(totalDays * 0.15)); // 15% for revision
  const studyDays = totalDays - revisionDays;

  const tasks = [];
  let dayOffset = 0;

  if (studyDays <= 0) {
    // Very tight schedule — just revision
    for (let d = 1; d <= totalDays; d++) {
      const date = new Date(startDate);
      date.setUTCDate(date.getUTCDate() + (d - 1));
      subjects.forEach(subj => {
        tasks.push({
          day: d,
          date: getLocalDateString(date),
          subject: subj,
          topic: 'Full Revision',
          durationMinutes: Math.floor((dailyStudyHours * 60) / subjects.length),
          isRevision: true,
          isCompleted: false,
          completedAt: null,
        });
      });
    }
    return tasks;
  }

  // Distribute study days across subjects, weighted by topic count
  const subjectTopics = subjects.map(subj => ({
    subject: subj,
    topics: getTopicsForSubject(subj).sort((a, b) => b.frequency - a.frequency),
  }));

  const totalTopics = subjectTopics.reduce((sum, s) => sum + s.topics.length, 0);
  const minutesPerDay = dailyStudyHours * 60;

  // Assign days per subject proportionally
  let topicQueue = [];
  subjectTopics.forEach(({ subject, topics }) => {
    const daysForSubject = Math.max(1, Math.round((topics.length / totalTopics) * studyDays));
    const minutesPerTopic = Math.floor((daysForSubject * minutesPerDay) / topics.length);
    topics.forEach(topic => {
      topicQueue.push({
        subject,
        topic: topic.name,
        durationMinutes: Math.max(30, minutesPerTopic),
      });
    });
  });

  // Spread topics across study days
  const tasksPerDay = Math.ceil(topicQueue.length / studyDays);
  let topicIdx = 0;

  for (let d = 1; d <= studyDays && topicIdx < topicQueue.length; d++) {
    const date = new Date(startDate);
    date.setUTCDate(date.getUTCDate() + (d - 1));

    for (let t = 0; t < tasksPerDay && topicIdx < topicQueue.length; t++, topicIdx++) {
      const item = topicQueue[topicIdx];
      const adjustedDuration = Math.min(item.durationMinutes, Math.floor(minutesPerDay / tasksPerDay));
      tasks.push({
        day: d,
        date: getLocalDateString(date),
        subject: item.subject,
        topic: item.topic,
        durationMinutes: adjustedDuration,
        isRevision: false,
        isCompleted: false,
        completedAt: null,
      });
    }

    dayOffset = d;
  }

  // Add revision days at the end
  for (let r = 1; r <= revisionDays; r++) {
    const d = dayOffset + r;
    const date = new Date(startDate);
    date.setUTCDate(date.getUTCDate() + (d - 1));

    subjects.forEach(subj => {
      tasks.push({
        day: d,
        date: getLocalDateString(date),
        subject: subj,
        topic: `${subj} - Full Revision`,
        durationMinutes: Math.floor(minutesPerDay / subjects.length),
        isRevision: true,
        isCompleted: false,
        completedAt: null,
      });
    });
  }

  return tasks;
};

const buildImportantTopics = (subjects) => {
  const allTopics = [];
  subjects.forEach(subj => {
    const topics = getTopicsForSubject(subj);
    topics.forEach(t => {
      allTopics.push({
        name: t.name,
        priority: t.priority,
        frequencyScore: t.frequency,
        pyqs: t.pyqs,
      });
    });
  });
  // Sort by frequency descending
  return allTopics.sort((a, b) => b.frequencyScore - a.frequencyScore);
};

// ── Service Methods ──────────────────────────────────────────────────────────

const createExamPlan = async (userId, { subjects, examDate, dailyStudyHours = 4 }) => {
  if (!subjects || subjects.length === 0) throw new AppError('At least one subject is required.', 400);
  if (!examDate) throw new AppError('Exam date is required.', 400);

  const exam = new Date(examDate);
  const today = getTodayDate(); // IST-aligned midnight
  exam.setUTCHours(0, 0, 0, 0);

  const totalDays = Math.ceil((exam - today) / (1000 * 60 * 60 * 24));
  if (totalDays < 1) throw new AppError('Exam date must be in the future.', 400);

  // Deactivate previous plans
  await ExamPlan.updateMany({ userId, isActive: true }, { isActive: false });

  const generatedPlan = generateDailyPlan(subjects, today, totalDays, dailyStudyHours);
  const importantTopics = buildImportantTopics(subjects);

  const plan = await ExamPlan.create({
    userId,
    subjects,
    examDate: exam,
    totalDays,
    dailyStudyHours,
    generatedPlan,
    importantTopics,
    isActive: true,
  });

  return plan;
};

const getExamPlan = async (userId) => {
  const plan = await ExamPlan.findOne({ userId, isActive: true }).sort({ createdAt: -1 });
  return plan;
};

const markTaskCompleted = async (userId, planId, taskIndex, completed) => {
  const plan = await ExamPlan.findOne({ _id: planId, userId });
  if (!plan) throw new AppError('Exam plan not found.', 404);
  if (taskIndex < 0 || taskIndex >= plan.generatedPlan.length) throw new AppError('Invalid task index.', 400);

  plan.generatedPlan[taskIndex].isCompleted = completed;
  plan.generatedPlan[taskIndex].completedAt = completed ? new Date() : null;
  await plan.save();
  return plan;
};

const getPlanProgress = async (userId) => {
  const plan = await ExamPlan.findOne({ userId, isActive: true });
  if (!plan) return null;

  const total = plan.generatedPlan.length;
  const completed = plan.generatedPlan.filter(t => t.isCompleted).length;
  const todayStr = getLocalDateString(getTodayDate());
  const todayTasks = plan.generatedPlan.filter(t => t.date === todayStr);
  const todayCompleted = todayTasks.filter(t => t.isCompleted).length;

  const daysLeft = Math.max(0, Math.ceil((new Date(plan.examDate) - new Date()) / (1000 * 60 * 60 * 24)));

  return {
    totalTasks: total,
    completedTasks: completed,
    progressPercent: total > 0 ? Math.round((completed / total) * 100) : 0,
    todayTasks: todayTasks.length,
    todayCompleted,
    daysLeft,
    dailyStudyHours: plan.dailyStudyHours,
    subjects: plan.subjects,
    examDate: plan.examDate,
  };
};

module.exports = { createExamPlan, getExamPlan, markTaskCompleted, getPlanProgress };
