const { getOpenAIClient } = require('../config/openai');
const Test = require('../models/Test');
const { AppError } = require('../middlewares/errorMiddleware');

// ── Helpers ────────────────────────────────────────────────────────────────────

const gradeFromPct = (pct) => {
  if (pct >= 90) return 'A+';
  if (pct >= 80) return 'A';
  if (pct >= 70) return 'B';
  if (pct >= 60) return 'C';
  if (pct >= 50) return 'D';
  return 'F';
};

/**
 * Normalise any question type string the AI might return into the
 * Mongoose enum values: mcq | true_false | fill_blank | short_answer | conceptual | scenario | code_output
 */
const normaliseType = (raw) => {
  if (!raw) return 'mcq';
  const t = raw.toString().toLowerCase().trim()
    .replace(/[^a-z_]/g, '_')   // replace spaces, slashes, dashes with _
    .replace(/_+/g, '_')         // collapse multiple underscores
    .replace(/^_|_$/g, '');      // trim leading/trailing _

  if (t === 'mcq' || t === 'multiple_choice' || t === 'multiple_choice_question') return 'mcq';
  if (t === 'true_false' || t === 'true_or_false' || t === 'truefalse' || t === 'boolean') return 'true_false';
  if (t === 'fill_blank' || t === 'fill_in_the_blank' || t === 'fill_in_blank' || t === 'fill_the_blank' || t === 'fillblank') return 'fill_blank';
  if (t === 'short_answer' || t === 'short_ans' || t === 'shortanswer' || t === 'short') return 'short_answer';
  if (t === 'code_output' || t === 'code' || t === 'output' || t === 'code_based') return 'code_output';
  if (t === 'scenario' || t === 'scenario_based' || t === 'case_based') return 'scenario';
  if (t === 'conceptual' || t === 'concept') return 'conceptual';
  // Default unknown types to mcq — it's always safe
  return 'mcq';
};

/**
 * Safely parse JSON from Groq response.
 * Groq sometimes wraps JSON in a markdown code block.
 */
const safeParseJson = (raw) => {
  let text = raw.trim();
  // Strip ```json ... ``` or ``` ... ```
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]+?)\s*```/);
  if (fenceMatch) text = fenceMatch[1];
  return JSON.parse(text);
};

const callGroq = async (messages, opts = {}) => {
  const openai = getOpenAIClient();
  try {
    const res = await openai.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages,
      max_tokens: opts.maxTokens || 3000,
      temperature: opts.temperature ?? 0.7,
      ...(opts.jsonMode ? { response_format: { type: 'json_object' } } : {}),
    });
    return res.choices[0].message.content;
  } catch (err) {
    console.error('[testService] Primary model error, falling back:', err.message);
    const res = await openai.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      messages,
      max_tokens: opts.maxTokens || 3000,
      temperature: opts.temperature ?? 0.7,
      ...(opts.jsonMode ? { response_format: { type: 'json_object' } } : {}),
    });
    return res.choices[0].message.content;
  }
};

// ── Phase 4: Generate Questions ────────────────────────────────────────────────

const generateQuestions = async (userId, config) => {
  const { subject, topics, testType, difficulty, questionCount } = config;

  const topicStr = topics && topics.length > 0
    ? `Topics: ${topics.join(', ')}`
    : `Entire subject: ${subject}`;

  const difficultyInstr = difficulty === 'mixed'
    ? 'Mix easy, medium, and hard questions roughly equally.'
    : `All questions must be ${difficulty} difficulty.`;

  const typeInstr = `Use a variety of question types. Use EXACTLY these type values:
- "mcq" — multiple choice with exactly 4 options (A/B/C/D)
- "true_false" — options must be exactly ["True","False"]
- "fill_blank" — use ___ in the question; correctAnswer is the missing word
- "short_answer" — brief answer, correctAnswer ≤10 words
Aim for ~60% mcq, ~15% true_false, ~15% fill_blank, ~10% short_answer.`;

  const prompt = `You are an expert academic question paper setter.
Generate exactly ${questionCount} unique, high-quality exam questions.

Subject: ${subject}
${topicStr}
${difficultyInstr}

${typeInstr}

CRITICAL RULES — READ CAREFULLY:
- No repeated or similar questions.
- Questions must be factually accurate and unambiguous.
- For MCQ, provide exactly 4 options. The answer must be one of the option strings exactly.
- For True/False, options must be exactly ["True","False"].
- For Fill in the Blank, use ___ in the question. The correctAnswer is the missing word/phrase.
- For Short Answer, correctAnswer must be a brief phrase (≤10 words).
- Include a clear explanation for each answer.
- Cover diverse topics within the subject.
- IMPORTANT FOR CODE QUESTIONS: If a question references code or asks "what is the output", you MUST embed the COMPLETE code snippet directly inside the "question" field itself. Use this exact format:
  "What is the output of the following code?\\n\\n\`\`\`\\n<full code here>\\n\`\`\`"
  Never omit the code. The question field must be self-contained and fully readable on its own.

Return ONLY a JSON object:
{
  "questions": [
    {
      "index": 0,
      "type": "mcq",
      "question": "...",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
      "correctAnswer": "A. ...",
      "explanation": "...",
      "topic": "topic name",
      "difficulty": "easy"
    },
    {
      "index": 1,
      "type": "true_false",
      "question": "...",
      "options": ["True","False"],
      "correctAnswer": "True",
      "explanation": "...",
      "topic": "topic name",
      "difficulty": "medium"
    }
  ]
}`;

  const raw = await callGroq(
    [{ role: 'user', content: prompt }],
    { maxTokens: 4000, temperature: 0.8, jsonMode: true }
  );

  const parsed = safeParseJson(raw);
  const questions = (parsed.questions || []).slice(0, questionCount).map((q, i) => ({
    index: i,
    type: normaliseType(q.type),
    question: q.question || '',
    options: Array.isArray(q.options) ? q.options : [],
    correctAnswer: q.correctAnswer || '',
    explanation: q.explanation || '',
    topic: q.topic || subject,
    difficulty: ['easy','medium','hard'].includes(q.difficulty) ? q.difficulty : 'medium',
  }));

  return questions;
};

// ── Create (Draft) Test ────────────────────────────────────────────────────────

const createTest = async (userId, config) => {
  const { subject, topics, testType, difficulty, questionCount, timerMinutes } = config;

  const questions = await generateQuestions(userId, config);

  const test = await Test.create({
    userId,
    subject,
    topics: topics || [],
    testType: testType || 'full_subject',
    difficulty,
    questionCount: questions.length,
    timerMinutes: timerMinutes || 0,
    status: 'draft',
    questions,
    answers: [],
    startedAt: new Date(),
  });

  return test;
};

// ── Start / Resume Test ────────────────────────────────────────────────────────

const startTest = async (userId, testId) => {
  const test = await Test.findOne({ _id: testId, userId });
  if (!test) throw new AppError('Test not found', 404, 'TEST_NOT_FOUND');
  if (test.status === 'submitted' || test.status === 'analysed') {
    throw new AppError('Test already submitted', 400, 'ALREADY_SUBMITTED');
  }
  if (test.status === 'draft') {
    test.status = 'active';
    test.startedAt = test.startedAt || new Date();
    await test.save();
  }
  return test;
};

// ── Save Answer (auto-save) ────────────────────────────────────────────────────

const saveAnswer = async (userId, testId, { questionIndex, userAnswer }) => {
  const test = await Test.findOne({ _id: testId, userId, status: 'active' });
  if (!test) throw new AppError('Active test not found', 404, 'TEST_NOT_FOUND');

  const existing = test.answers.find((a) => a.questionIndex === questionIndex);
  if (existing) {
    existing.userAnswer = userAnswer;
  } else {
    test.answers.push({ questionIndex, userAnswer });
  }
  await test.save();
  return { saved: true };
};

// ── Save Bulk Answers (sync) ───────────────────────────────────────────────────

const saveBulkAnswers = async (userId, testId, answers) => {
  const test = await Test.findOne({ _id: testId, userId, status: 'active' });
  if (!test) throw new AppError('Active test not found', 404, 'TEST_NOT_FOUND');

  for (const { questionIndex, userAnswer } of answers) {
    const existing = test.answers.find((a) => a.questionIndex === questionIndex);
    if (existing) {
      existing.userAnswer = userAnswer;
    } else {
      test.answers.push({ questionIndex, userAnswer });
    }
  }
  await test.save();
  return { saved: true };
};

// ── Submit Test ────────────────────────────────────────────────────────────────

const submitTest = async (userId, testId, { answers, timeSpentSecs }) => {
  const test = await Test.findOne({ _id: testId, userId });
  if (!test) throw new AppError('Test not found', 404, 'TEST_NOT_FOUND');
  if (test.status === 'submitted' || test.status === 'analysed') {
    throw new AppError('Test already submitted', 400, 'ALREADY_SUBMITTED');
  }

  // Merge submitted answers (override auto-saved ones)
  if (answers && answers.length > 0) {
    for (const { questionIndex, userAnswer } of answers) {
      const existing = test.answers.find((a) => a.questionIndex === questionIndex);
      if (existing) {
        existing.userAnswer = userAnswer;
      } else {
        test.answers.push({ questionIndex, userAnswer });
      }
    }
  }

  // Score
  let correct = 0, wrong = 0, skipped = 0;
  const scoredAnswers = test.questions.map((q) => {
    const ans = test.answers.find((a) => a.questionIndex === q.index);
    const userAnswer = ans?.userAnswer ?? null;

    if (!userAnswer || userAnswer.trim() === '') {
      skipped++;
      return { questionIndex: q.index, userAnswer: null, isCorrect: false };
    }

    // Normalize comparison (case-insensitive, trimmed)
    const isCorrect =
      userAnswer.trim().toLowerCase() === q.correctAnswer.trim().toLowerCase();

    if (isCorrect) correct++;
    else wrong++;

    return { questionIndex: q.index, userAnswer, isCorrect };
  });

  const total = test.questions.length;
  const attempted = correct + wrong;
  const marks = correct; // 1 mark per correct
  const percentage = total > 0 ? Math.round((correct / total) * 100) : 0;
  const grade = gradeFromPct(percentage);
  const passed = percentage >= 50;
  const accuracy = attempted > 0 ? Math.round((correct / attempted) * 100) : 0;
  const avgTimePerQuestion = total > 0 ? Math.round((timeSpentSecs || 0) / total) : 0;

  test.answers = scoredAnswers;
  test.status = 'submitted';
  test.submittedAt = new Date();
  test.timeSpentSecs = timeSpentSecs || 0;
  test.totalQuestions = total;
  test.attempted = attempted;
  test.correct = correct;
  test.wrong = wrong;
  test.skipped = skipped;
  test.marks = marks;
  test.percentage = percentage;
  test.grade = grade;
  test.passed = passed;
  test.accuracy = accuracy;
  test.avgTimePerQuestion = avgTimePerQuestion;

  await test.save();

  return test;
};

// ── Phase 7 & 8: AI Analysis + Revision Plan ─────────────────────────────────

const analyseTest = async (userId, testId) => {
  const test = await Test.findOne({ _id: testId, userId });
  if (!test) throw new AppError('Test not found', 404, 'TEST_NOT_FOUND');
  if (test.status === 'draft' || test.status === 'active') {
    throw new AppError('Test must be submitted first', 400, 'NOT_SUBMITTED');
  }
  if (test.aiAnalysis) return test; // already analysed

  // Build a compact summary for Groq
  const wrongQuestions = test.questions
    .filter((q) => {
      const ans = test.answers.find((a) => a.questionIndex === q.index);
      return ans && !ans.isCorrect && ans.userAnswer !== null;
    })
    .map((q) => {
      const ans = test.answers.find((a) => a.questionIndex === q.index);
      return `Q: ${q.question}\nUser answered: ${ans?.userAnswer}\nCorrect: ${q.correctAnswer}\nTopic: ${q.topic}`;
    })
    .slice(0, 15) // limit to 15 wrong to stay within tokens
    .join('\n---\n');

  const summary = `
Subject: ${test.subject}
Topics: ${test.topics.length > 0 ? test.topics.join(', ') : 'Full subject'}
Difficulty: ${test.difficulty}
Score: ${test.correct}/${test.totalQuestions} (${test.percentage}%)
Grade: ${test.grade} | ${test.passed ? 'PASSED' : 'FAILED'}
Accuracy: ${test.accuracy}%
Time taken: ${Math.round(test.timeSpentSecs / 60)} minutes
Avg time/question: ${test.avgTimePerQuestion}s

Wrong answers (max 15):
${wrongQuestions || 'All answers correct!'}
`.trim();

  const analysisPrompt = `You are an expert academic performance analyst and learning coach.
A student just completed a test. Analyse their performance and give actionable, encouraging feedback.

${summary}

Return a JSON object with EXACTLY these fields:
{
  "overallPerformance": "1-2 sentence summary",
  "strongTopics": ["topic1", "topic2"],
  "weakTopics": ["topic1", "topic2"],
  "mistakes": "Common mistake patterns observed",
  "knowledgeGaps": "Key concepts the student seems to be missing",
  "conceptsToRevise": ["concept1", "concept2", "concept3"],
  "difficultyAnalysis": "How the student performed across difficulty levels",
  "learningPattern": "Observation about how this student learns/makes mistakes",
  "personalizedFeedback": "2-3 sentences of personalized, encouraging feedback",
  "studySuggestions": ["suggestion1", "suggestion2", "suggestion3"],
  "estimatedLevel": "Beginner / Intermediate / Advanced / Expert",
  "motivationMessage": "Short, genuine motivational message"
}`;

  const revisionPrompt = `Based on this test result, create a targeted revision plan.

${summary}

Return a JSON object:
{
  "highPriority": ["topic1", "topic2"],
  "mediumPriority": ["topic1", "topic2"],
  "lowPriority": ["topic1"],
  "studyOrder": ["topic1", "topic2", "topic3"],
  "estimatedHours": 4,
  "suggestedNextTest": "What kind of test to take next"
}`;

  // Run both in parallel
  const [analysisRaw, revisionRaw] = await Promise.all([
    callGroq([{ role: 'user', content: analysisPrompt }], { maxTokens: 1500, temperature: 0.5, jsonMode: true }),
    callGroq([{ role: 'user', content: revisionPrompt }], { maxTokens: 800, temperature: 0.4, jsonMode: true }),
  ]);

  const analysisData = safeParseJson(analysisRaw);
  const revisionData = safeParseJson(revisionRaw);

  test.aiAnalysis = {
    overallPerformance: analysisData.overallPerformance || '',
    strongTopics: analysisData.strongTopics || [],
    weakTopics: analysisData.weakTopics || [],
    mistakes: analysisData.mistakes || '',
    knowledgeGaps: analysisData.knowledgeGaps || '',
    conceptsToRevise: analysisData.conceptsToRevise || [],
    difficultyAnalysis: analysisData.difficultyAnalysis || '',
    learningPattern: analysisData.learningPattern || '',
    personalizedFeedback: analysisData.personalizedFeedback || '',
    studySuggestions: analysisData.studySuggestions || [],
    estimatedLevel: analysisData.estimatedLevel || '',
    motivationMessage: analysisData.motivationMessage || '',
  };

  test.revisionPlan = {
    highPriority: revisionData.highPriority || [],
    mediumPriority: revisionData.mediumPriority || [],
    lowPriority: revisionData.lowPriority || [],
    studyOrder: revisionData.studyOrder || [],
    estimatedHours: revisionData.estimatedHours || 0,
    suggestedNextTest: revisionData.suggestedNextTest || '',
  };

  test.status = 'analysed';
  await test.save();

  return test;
};

// ── Test History ───────────────────────────────────────────────────────────────

const getHistory = async (userId, filters = {}) => {
  const query = { userId, status: { $in: ['submitted', 'analysed'] } };

  if (filters.subject) query.subject = new RegExp(filters.subject, 'i');
  if (filters.difficulty) query.difficulty = filters.difficulty;
  if (filters.grade) query.grade = filters.grade;
  if (filters.passed !== undefined) query.passed = filters.passed === 'true';
  if (filters.dateFrom || filters.dateTo) {
    query.submittedAt = {};
    if (filters.dateFrom) query.submittedAt.$gte = new Date(filters.dateFrom);
    if (filters.dateTo) query.submittedAt.$lte = new Date(filters.dateTo);
  }

  const tests = await Test.find(query)
    .sort({ submittedAt: -1 })
    .limit(50)
    .select('-questions -answers') // exclude heavy arrays from list view
    .lean();

  return tests;
};

// ── Get Single Test (full detail) ──────────────────────────────────────────────

const getTest = async (userId, testId) => {
  const test = await Test.findOne({ _id: testId, userId });
  if (!test) throw new AppError('Test not found', 404, 'TEST_NOT_FOUND');
  return test;
};

// ── Analytics Dashboard ───────────────────────────────────────────────────────

const getStats = async (userId) => {
  const tests = await Test.find({
    userId,
    status: { $in: ['submitted', 'analysed'] },
  }).lean();

  if (tests.length === 0) {
    return {
      totalTests: 0,
      avgScore: 0,
      highestScore: 0,
      lowestScore: 100,
      overallAccuracy: 0,
      subjectStats: [],
      weakTopics: [],
      strongTopics: [],
    };
  }

  const scores = tests.map((t) => t.percentage);
  const avgScore = Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);
  const highestScore = Math.max(...scores);
  const lowestScore = Math.min(...scores);
  const totalCorrect = tests.reduce((s, t) => s + (t.correct || 0), 0);
  const totalAttempted = tests.reduce((s, t) => s + (t.attempted || 0), 0);
  const overallAccuracy = totalAttempted > 0 ? Math.round((totalCorrect / totalAttempted) * 100) : 0;

  // Per-subject stats
  const subjectMap = {};
  for (const t of tests) {
    if (!subjectMap[t.subject]) subjectMap[t.subject] = { count: 0, totalPct: 0, best: 0 };
    subjectMap[t.subject].count++;
    subjectMap[t.subject].totalPct += t.percentage;
    subjectMap[t.subject].best = Math.max(subjectMap[t.subject].best, t.percentage);
  }
  const subjectStats = Object.entries(subjectMap).map(([subject, d]) => ({
    subject,
    count: d.count,
    avgScore: Math.round(d.totalPct / d.count),
    bestScore: d.best,
  }));

  // Collect weak/strong topics from AI analysis
  const weakSet = new Set();
  const strongSet = new Set();
  for (const t of tests) {
    if (t.aiAnalysis) {
      (t.aiAnalysis.weakTopics || []).forEach((w) => weakSet.add(w));
      (t.aiAnalysis.strongTopics || []).forEach((s) => strongSet.add(s));
    }
  }

  // Weekly & monthly progress (last 12 weeks)
  const now = new Date();
  const weeklyProgress = [];
  for (let w = 11; w >= 0; w--) {
    const weekStart = new Date(now);
    weekStart.setDate(weekStart.getDate() - w * 7);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 7);
    const weekTests = tests.filter(
      (t) => t.submittedAt >= weekStart && t.submittedAt < weekEnd
    );
    const avg = weekTests.length
      ? Math.round(weekTests.reduce((s, t) => s + t.percentage, 0) / weekTests.length)
      : 0;
    weeklyProgress.push({ week: `W${12 - w}`, avgScore: avg, count: weekTests.length });
  }

  return {
    totalTests: tests.length,
    avgScore,
    highestScore,
    lowestScore,
    overallAccuracy,
    subjectStats,
    weakTopics: [...weakSet].slice(0, 10),
    strongTopics: [...strongSet].slice(0, 10),
    weeklyProgress,
  };
};

// ── Delete Test ────────────────────────────────────────────────────────────────

const deleteTest = async (userId, testId) => {
  const test = await Test.findOneAndDelete({ _id: testId, userId });
  if (!test) throw new AppError('Test not found', 404, 'TEST_NOT_FOUND');
  return { deleted: true };
};

// ── Get Active Draft ───────────────────────────────────────────────────────────

const getActiveDraft = async (userId) => {
  return Test.findOne({ userId, status: { $in: ['draft', 'active'] } })
    .sort({ createdAt: -1 })
    .lean();
};

module.exports = {
  createTest,
  startTest,
  saveAnswer,
  saveBulkAnswers,
  submitTest,
  analyseTest,
  getHistory,
  getTest,
  getStats,
  deleteTest,
  getActiveDraft,
};
