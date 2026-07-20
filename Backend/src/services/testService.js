const { getOpenAIClient } = require('../config/openai');
const Test = require('../models/Test');
const { AppError } = require('../middlewares/errorMiddleware');

// ── Grade helper ───────────────────────────────────────────────────────────────
const gradeFromPct = (pct) => {
  if (pct >= 90) return 'A+';
  if (pct >= 80) return 'A';
  if (pct >= 70) return 'B';
  if (pct >= 60) return 'C';
  if (pct >= 50) return 'D';
  return 'F';
};

// ── Normalise question type ────────────────────────────────────────────────────
const normaliseType = (raw) => {
  if (!raw) return 'mcq';
  const t = raw.toString().toLowerCase().trim()
    .replace(/[^a-z_]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
  if (['mcq','multiple_choice','multiple_choice_question'].includes(t)) return 'mcq';
  if (['true_false','true_or_false','truefalse','boolean'].includes(t)) return 'true_false';
  if (['fill_blank','fill_in_the_blank','fill_in_blank','fill_the_blank','fillblank'].includes(t)) return 'fill_blank';
  if (['short_answer','short_ans','shortanswer','short'].includes(t)) return 'short_answer';
  if (['code_output','code','output','code_based'].includes(t)) return 'code_output';
  if (['scenario','scenario_based','case_based'].includes(t)) return 'scenario';
  if (['conceptual','concept'].includes(t)) return 'conceptual';
  return 'mcq';
};

// ── Robust JSON parser ─────────────────────────────────────────────────────────
// Handles: plain JSON, ```json blocks, JSON buried after prose text
const safeParseJson = (raw) => {
  if (!raw) throw new Error('Empty AI response');
  let text = raw.trim();

  // 1. Try to extract from a code fence first
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]+?)\s*```/);
  if (fenceMatch) {
    try { return JSON.parse(fenceMatch[1].trim()); } catch (_) {}
  }

  // 2. Try parsing the whole thing as-is
  try { return JSON.parse(text); } catch (_) {}

  // 3. Find the first '{' and last '}' and try that substring
  const first = text.indexOf('{');
  const last  = text.lastIndexOf('}');
  if (first !== -1 && last > first) {
    try { return JSON.parse(text.slice(first, last + 1)); } catch (_) {}
  }

  // 4. Find first '[' and last ']'
  const arrFirst = text.indexOf('[');
  const arrLast  = text.lastIndexOf(']');
  if (arrFirst !== -1 && arrLast > arrFirst) {
    try {
      const arr = JSON.parse(text.slice(arrFirst, arrLast + 1));
      return { questions: arr };
    } catch (_) {}
  }

  throw new Error(`Could not parse AI response as JSON. Raw (first 200): ${text.slice(0, 200)}`);
};

// ── Groq caller with retry + fallback ─────────────────────────────────────────
const callGroq = async (messages, opts = {}) => {
  const openai = getOpenAIClient();
  const primaryModel  = 'llama-3.3-70b-versatile';
  const fallbackModel = 'llama-3.1-8b-instant';

  // Try primary model up to 2 times
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const res = await openai.chat.completions.create({
        model: primaryModel,
        messages,
        max_tokens: opts.maxTokens || 4000,
        temperature: opts.temperature ?? 0.7,
        ...(opts.jsonMode ? { response_format: { type: 'json_object' } } : {}),
      });
      const content = res.choices[0].message.content;
      if (content && content.trim().length > 0) return content;
      throw new Error('Empty response from primary model');
    } catch (err) {
      console.error(`[testService] Primary attempt ${attempt + 1} failed:`, err.message);
      if (attempt === 0) {
        // Short wait before retry
        await new Promise(r => setTimeout(r, 2000));
      }
    }
  }

  // Fallback to smaller model
  try {
    console.log('[testService] Falling back to', fallbackModel);
    const res = await openai.chat.completions.create({
      model: fallbackModel,
      messages,
      max_tokens: opts.maxTokens || 4000,
      temperature: opts.temperature ?? 0.7,
      ...(opts.jsonMode ? { response_format: { type: 'json_object' } } : {}),
    });
    const content = res.choices[0].message.content;
    if (content && content.trim().length > 0) return content;
    throw new Error('Empty response from fallback model');
  } catch (err) {
    console.error('[testService] Fallback also failed:', err.message);
    throw new AppError(
      'AI service is temporarily unavailable. Please try again in a moment.',
      503,
      'AI_UNAVAILABLE'
    );
  }
};

// ── Generate Questions ─────────────────────────────────────────────────────────
const generateQuestions = async (userId, config) => {
  const { subject, topics, difficulty, questionCount } = config;

  const topicStr = topics && topics.length > 0
    ? `Focus topics: ${topics.join(', ')}`
    : `Cover the entire subject broadly.`;

  const difficultyInstr = difficulty === 'mixed'
    ? 'Mix easy (33%), medium (34%), and hard (33%) questions.'
    : `ALL questions must be ${difficulty} difficulty. Do not deviate.`;

  // Use a system message to enforce JSON-only output
  const systemMsg = {
    role: 'system',
    content: `You are an expert exam question generator. You ALWAYS respond with ONLY valid JSON. No preamble, no explanation, no markdown outside the JSON. Your entire response must be parseable by JSON.parse().`
  };

  const userMsg = {
    role: 'user',
    content: `Generate exactly ${questionCount} exam questions for:
Subject: ${subject}
${topicStr}
Difficulty: ${difficultyInstr}

Rules:
- 60% MCQ (4 options each, correctAnswer = exact option text)
- 20% True/False (options: ["True","False"])
- 15% Fill in the blank (use ___ in question text)
- 5% Short answer (answer ≤ 10 words)
- Each question must be unique and factually correct
- Include explanation for each answer

Respond with ONLY this JSON structure, nothing else:
{
  "questions": [
    {
      "index": 0,
      "type": "mcq",
      "question": "Question text here",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "Option A",
      "explanation": "Brief explanation",
      "topic": "Specific topic",
      "difficulty": "${difficulty === 'mixed' ? 'easy' : difficulty}"
    }
  ]
}`
  };

  const raw = await callGroq(
    [systemMsg, userMsg],
    { maxTokens: 4000, temperature: 0.75, jsonMode: true }
  );

  let parsed;
  try {
    parsed = safeParseJson(raw);
  } catch (parseErr) {
    console.error('[testService] JSON parse failed:', parseErr.message, '\nRaw:', raw.slice(0, 300));
    throw new AppError(
      'AI returned an invalid response. Please try again — this is usually temporary.',
      500,
      'AI_PARSE_ERROR'
    );
  }

  const rawQuestions = Array.isArray(parsed) ? parsed
    : Array.isArray(parsed.questions) ? parsed.questions
    : [];

  if (rawQuestions.length === 0) {
    throw new AppError(
      'AI generated no questions. Please try again with a different subject or fewer questions.',
      500,
      'NO_QUESTIONS'
    );
  }

  const questions = rawQuestions.slice(0, questionCount).map((q, i) => ({
    index: i,
    type: normaliseType(q.type),
    question: (q.question || '').trim(),
    options: Array.isArray(q.options) ? q.options.map(String) : [],
    correctAnswer: (q.correctAnswer || '').trim(),
    explanation: (q.explanation || '').trim(),
    topic: (q.topic || subject).trim(),
    difficulty: ['easy', 'medium', 'hard'].includes(q.difficulty) ? q.difficulty : 'medium',
  }));

  return questions;
};

// ── Create Test ────────────────────────────────────────────────────────────────
const createTest = async (userId, config) => {
  const { subject, topics, testType, difficulty, questionCount, timerMinutes } = config;

  // Input validation
  if (!subject || subject.trim() === '') {
    throw new AppError('Subject is required', 422, 'VALIDATION_ERROR');
  }

  const validDifficulties = ['easy', 'medium', 'hard', 'mixed'];
  const safeDifficulty = validDifficulties.includes(difficulty) ? difficulty : 'mixed';

  const validTypes = ['full_subject', 'topic_wise', 'mock_exam', 'chapter_test', 'revision', 'practice'];
  const safeType = validTypes.includes(testType) ? testType : 'full_subject';

  const safeCount = Math.min(Math.max(parseInt(questionCount) || 10, 5), 40);

  const questions = await generateQuestions(userId, {
    subject: subject.trim(),
    topics: topics || [],
    difficulty: safeDifficulty,
    questionCount: safeCount,
  });

  const test = await Test.create({
    userId,
    subject: subject.trim(),
    topics: topics || [],
    testType: safeType,
    difficulty: safeDifficulty,
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

// ── Save Bulk Answers ──────────────────────────────────────────────────────────
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

  // Merge submitted answers
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
    const isCorrect = userAnswer.trim().toLowerCase() === q.correctAnswer.trim().toLowerCase();
    if (isCorrect) correct++; else wrong++;
    return { questionIndex: q.index, userAnswer, isCorrect };
  });

  const total      = test.questions.length;
  const attempted  = correct + wrong;
  const marks      = correct;
  const percentage = total > 0 ? Math.round((correct / total) * 100) : 0;

  test.answers          = scoredAnswers;
  test.status           = 'submitted';
  test.submittedAt      = new Date();
  test.timeSpentSecs    = timeSpentSecs || 0;
  test.totalQuestions   = total;
  test.attempted        = attempted;
  test.correct          = correct;
  test.wrong            = wrong;
  test.skipped          = skipped;
  test.marks            = marks;
  test.percentage       = percentage;
  test.grade            = gradeFromPct(percentage);
  test.passed           = percentage >= 50;
  test.accuracy         = attempted > 0 ? Math.round((correct / attempted) * 100) : 0;
  test.avgTimePerQuestion = total > 0 ? Math.round((timeSpentSecs || 0) / total) : 0;
  await test.save();
  return test;
};

// ── AI Analysis ────────────────────────────────────────────────────────────────
const analyseTest = async (userId, testId) => {
  const test = await Test.findOne({ _id: testId, userId });
  if (!test) throw new AppError('Test not found', 404, 'TEST_NOT_FOUND');
  if (test.status === 'draft' || test.status === 'active') {
    throw new AppError('Test must be submitted first', 400, 'NOT_SUBMITTED');
  }
  if (test.aiAnalysis) return test;

  const wrongQuestions = test.questions
    .filter((q) => {
      const ans = test.answers.find((a) => a.questionIndex === q.index);
      return ans && !ans.isCorrect && ans.userAnswer !== null;
    })
    .map((q) => {
      const ans = test.answers.find((a) => a.questionIndex === q.index);
      return `Q: ${q.question}\nUser: ${ans?.userAnswer}\nCorrect: ${q.correctAnswer}\nTopic: ${q.topic}`;
    })
    .slice(0, 12)
    .join('\n---\n');

  const summary = `Subject: ${test.subject} | Difficulty: ${test.difficulty}
Score: ${test.correct}/${test.totalQuestions} (${test.percentage}%) | Grade: ${test.grade}
Accuracy: ${test.accuracy}% | Time: ${Math.round(test.timeSpentSecs / 60)} min

Wrong answers:\n${wrongQuestions || 'None — all correct!'}`.trim();

  const systemMsg = {
    role: 'system',
    content: 'You are an academic performance analyst. Respond ONLY with valid JSON. No markdown, no preamble.'
  };

  const [analysisRaw, revisionRaw] = await Promise.all([
    callGroq([systemMsg, {
      role: 'user',
      content: `Analyse this test result and return JSON:\n\n${summary}\n\nReturn:\n{"overallPerformance":"","strongTopics":[],"weakTopics":[],"mistakes":"","knowledgeGaps":"","conceptsToRevise":[],"difficultyAnalysis":"","learningPattern":"","personalizedFeedback":"","studySuggestions":[],"estimatedLevel":"","motivationMessage":""}`
    }], { maxTokens: 1200, temperature: 0.5, jsonMode: true }),
    callGroq([systemMsg, {
      role: 'user',
      content: `Create a revision plan for this test result and return JSON:\n\n${summary}\n\nReturn:\n{"highPriority":[],"mediumPriority":[],"lowPriority":[],"studyOrder":[],"estimatedHours":0,"suggestedNextTest":""}`
    }], { maxTokens: 600, temperature: 0.4, jsonMode: true }),
  ]);

  let analysisData = {}, revisionData = {};
  try { analysisData = safeParseJson(analysisRaw); } catch (e) { console.error('Analysis parse error', e.message); }
  try { revisionData = safeParseJson(revisionRaw); } catch (e) { console.error('Revision parse error', e.message); }

  test.aiAnalysis = {
    overallPerformance:   analysisData.overallPerformance   || '',
    strongTopics:         analysisData.strongTopics          || [],
    weakTopics:           analysisData.weakTopics            || [],
    mistakes:             analysisData.mistakes              || '',
    knowledgeGaps:        analysisData.knowledgeGaps         || '',
    conceptsToRevise:     analysisData.conceptsToRevise      || [],
    difficultyAnalysis:   analysisData.difficultyAnalysis    || '',
    learningPattern:      analysisData.learningPattern       || '',
    personalizedFeedback: analysisData.personalizedFeedback  || '',
    studySuggestions:     analysisData.studySuggestions      || [],
    estimatedLevel:       analysisData.estimatedLevel        || '',
    motivationMessage:    analysisData.motivationMessage     || '',
  };
  test.revisionPlan = {
    highPriority:      revisionData.highPriority      || [],
    mediumPriority:    revisionData.mediumPriority     || [],
    lowPriority:       revisionData.lowPriority        || [],
    studyOrder:        revisionData.studyOrder         || [],
    estimatedHours:    revisionData.estimatedHours     || 0,
    suggestedNextTest: revisionData.suggestedNextTest  || '',
  };
  test.status = 'analysed';
  await test.save();
  return test;
};

// ── History ────────────────────────────────────────────────────────────────────
const getHistory = async (userId, filters = {}) => {
  const query = { userId, status: { $in: ['submitted', 'analysed'] } };
  if (filters.subject)   query.subject    = new RegExp(filters.subject, 'i');
  if (filters.difficulty) query.difficulty = filters.difficulty;
  if (filters.grade)     query.grade      = filters.grade;
  if (filters.passed !== undefined) query.passed = filters.passed === 'true';
  if (filters.dateFrom || filters.dateTo) {
    query.submittedAt = {};
    if (filters.dateFrom) query.submittedAt.$gte = new Date(filters.dateFrom);
    if (filters.dateTo)   query.submittedAt.$lte = new Date(filters.dateTo);
  }
  return Test.find(query)
    .sort({ submittedAt: -1 })
    .limit(50)
    .select('-questions -answers')
    .lean();
};

// ── Get Single Test ────────────────────────────────────────────────────────────
const getTest = async (userId, testId) => {
  const test = await Test.findOne({ _id: testId, userId });
  if (!test) throw new AppError('Test not found', 404, 'TEST_NOT_FOUND');
  return test;
};

// ── Stats ──────────────────────────────────────────────────────────────────────
const getStats = async (userId) => {
  const tests = await Test.find({ userId, status: { $in: ['submitted', 'analysed'] } }).lean();
  if (tests.length === 0) {
    return { totalTests: 0, avgScore: 0, highestScore: 0, lowestScore: 100,
      overallAccuracy: 0, subjectStats: [], weakTopics: [], strongTopics: [], weeklyProgress: [] };
  }
  const scores = tests.map((t) => t.percentage);
  const avgScore = Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);
  const totalCorrect  = tests.reduce((s, t) => s + (t.correct  || 0), 0);
  const totalAttempted = tests.reduce((s, t) => s + (t.attempted || 0), 0);
  const subjectMap = {};
  for (const t of tests) {
    if (!subjectMap[t.subject]) subjectMap[t.subject] = { count: 0, total: 0, best: 0 };
    subjectMap[t.subject].count++;
    subjectMap[t.subject].total += t.percentage;
    subjectMap[t.subject].best = Math.max(subjectMap[t.subject].best, t.percentage);
  }
  const weakSet = new Set(), strongSet = new Set();
  for (const t of tests) {
    if (t.aiAnalysis) {
      (t.aiAnalysis.weakTopics   || []).forEach((w) => weakSet.add(w));
      (t.aiAnalysis.strongTopics || []).forEach((s) => strongSet.add(s));
    }
  }
  const now = new Date();
  const weeklyProgress = [];
  for (let w = 11; w >= 0; w--) {
    const wStart = new Date(now); wStart.setDate(wStart.getDate() - w * 7);
    const wEnd   = new Date(wStart); wEnd.setDate(wEnd.getDate() + 7);
    const wTests = tests.filter((t) => t.submittedAt >= wStart && t.submittedAt < wEnd);
    weeklyProgress.push({
      week: `W${12 - w}`,
      avgScore: wTests.length ? Math.round(wTests.reduce((s, t) => s + t.percentage, 0) / wTests.length) : 0,
      count: wTests.length,
    });
  }
  return {
    totalTests: tests.length, avgScore,
    highestScore: Math.max(...scores), lowestScore: Math.min(...scores),
    overallAccuracy: totalAttempted > 0 ? Math.round((totalCorrect / totalAttempted) * 100) : 0,
    subjectStats: Object.entries(subjectMap).map(([subject, d]) => ({
      subject, count: d.count, avgScore: Math.round(d.total / d.count), bestScore: d.best,
    })),
    weakTopics:   [...weakSet].slice(0, 10),
    strongTopics: [...strongSet].slice(0, 10),
    weeklyProgress,
  };
};

// ── Delete ─────────────────────────────────────────────────────────────────────
const deleteTest = async (userId, testId) => {
  const test = await Test.findOneAndDelete({ _id: testId, userId });
  if (!test) throw new AppError('Test not found', 404, 'TEST_NOT_FOUND');
  return { deleted: true };
};

// ── Active Draft ───────────────────────────────────────────────────────────────
const getActiveDraft = async (userId) => {
  return Test.findOne({ userId, status: { $in: ['draft', 'active'] } })
    .sort({ createdAt: -1 })
    .lean();
};

module.exports = {
  createTest, startTest, saveAnswer, saveBulkAnswers,
  submitTest, analyseTest, getHistory, getTest,
  getStats, deleteTest, getActiveDraft,
};
