const { getOpenAIClient } = require('../config/openai');
const AiConversation = require('../models/AiConversation');
const StudySession = require('../models/StudySession');
const PerformanceData = require('../models/PerformanceData');
const { getRedisClient } = require('../config/redis');
const { AppError } = require('../middlewares/errorMiddleware');
const crypto = require('crypto');
const pdfParse = require('pdf-parse');

const SYSTEM_PROMPT = `You are a super friendly, enthusiastic, and highly capable AI Study Coach! Your goal is to make learning fun, engaging, and stress-free for students. 
You help them understand concepts, answer doubts, generate practice questions, and provide study guidance across ANY educational or academic subject (e.g., Math, Science, Literature, Programming, History, etc.).

KEY GUIDELINES:
1. Always maintain a warm, encouraging, and highly positive tone.
2. Frequently use emojis 🚀✨🎓💡 to make your messages visually engaging and friendly!
3. Even if the user is currently studying a specific subject, you MUST gladly answer their questions about any other academic subject they ask about.
4. Keep explanations simple, clear, and easy to understand using analogies where possible.
5. Refuse harmful or completely non-educational requests politely, but pivot back to learning in a fun way!`;

const MAX_HISTORY_MESSAGES = 20;

const buildUserContext = async (userId) => {
  const [recentSessions, weakTopics] = await Promise.all([
    StudySession.find({ userId, status: 'completed' }).sort({ startTime: -1 }).limit(5).select('subject focusScore actualDurationMinutes'),
    PerformanceData.find({ userId, isWeakTopic: true }).select('subject topic'),
  ]);

  const subjects = [...new Set(recentSessions.map((s) => s.subject))];
  const avgFocus = recentSessions.length
    ? Math.round(recentSessions.reduce((s, r) => s + r.focusScore, 0) / recentSessions.length)
    : null;

  return `User context: Recently studying ${subjects.join(', ') || 'various subjects'}. Average focus score: ${avgFocus || 'N/A'}. Weak topics: ${weakTopics.map((t) => `${t.subject} - ${t.topic}`).join(', ') || 'none identified'}.`;
};

const chat = async (userId, { message, conversationId, subject }) => {
  const openai = getOpenAIClient();
  let conversation;

  if (conversationId) {
    conversation = await AiConversation.findOne({ _id: conversationId, userId });
    if (!conversation) throw new AppError('Conversation not found', 404, 'CONV_NOT_FOUND');
  } else {
    conversation = await AiConversation.create({ userId, subject, messages: [], type: 'chat' });
  }

  // Build messages for API call
  const userContext = await buildUserContext(userId);
  const history = conversation.messages.slice(-MAX_HISTORY_MESSAGES);

  let finalSystemPrompt = `${SYSTEM_PROMPT}\n\n${userContext}`;
  if (conversation.documentContext) {
    finalSystemPrompt += `\n\n--- DOCUMENT CONTEXT ---\nThe user has uploaded a document. You must answer their questions based PRIMARILY on this document context. If the answer is not in the document, you may use your general knowledge but mention that it's not in the document.\n\n${conversation.documentContext}`;
  }

  const apiMessages = [
    { role: 'system', content: finalSystemPrompt },
    ...history.map((m) => ({ role: m.role, content: m.content })),
    { role: 'user', content: message },
  ];

  let response;
  try {
    response = await openai.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: apiMessages,
      max_tokens: 1024,
      temperature: 0.7,
    });
  } catch (err) {
    console.error('Groq Primary Model Error:', err.message);
    // Fallback to a smaller/faster model if rate-limited or decommissioned
    response = await openai.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      messages: apiMessages,
      max_tokens: 1024,
      temperature: 0.7,
    });
  }

  const assistantMessage = response.choices[0].message.content;
  const tokensUsed = response.usage?.total_tokens || 0;

  // Persist messages
  conversation.messages.push({ role: 'user', content: message });
  conversation.messages.push({ role: 'assistant', content: assistantMessage });
  conversation.tokensUsed += tokensUsed;
  await conversation.save();

  return { conversationId: conversation._id, reply: assistantMessage, tokensUsed };
};

const uploadNotes = async (userId, fileBuffer, subject) => {
  const openai = getOpenAIClient();
  let pdfText = '';
  
  try {
    const data = await pdfParse(fileBuffer.buffer);
    pdfText = data.text;
  } catch (err) {
    throw new AppError('Failed to parse PDF document', 400);
  }

  // Limit text to roughly 20k characters to avoid token explosion
  const limitedText = pdfText.length > 20000 ? pdfText.substring(0, 20000) + '...[Document Truncated]' : pdfText;

  const conversation = await AiConversation.create({
    userId,
    subject: subject || 'Uploaded Notes',
    documentContext: limitedText,
    type: 'chat',
    messages: []
  });

  const apiMessages = [
    { role: 'system', content: `${SYSTEM_PROMPT}\n\n--- DOCUMENT CONTEXT ---\n${limitedText}` },
    { role: 'user', content: 'I have uploaded my notes. Please give me a brief 3-sentence summary of what these notes are about, and ask me if I want to be quizzed on them or if I want you to explain a specific part.' }
  ];

  let response;
  try {
    response = await openai.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: apiMessages,
      max_tokens: 500,
    });
  } catch (err) {
    response = await openai.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      messages: apiMessages,
      max_tokens: 500,
    });
  }

  const assistantMessage = response.choices[0].message.content;
  
  conversation.messages.push({ role: 'assistant', content: assistantMessage });
  await conversation.save();

  return { conversationId: conversation._id, reply: assistantMessage };
};

const explain = async (userId, { concept, subject }) => {
  const openai = getOpenAIClient();
  const prompt = `Explain the concept of "${concept}" in the context of ${subject}. 
Use simple language, examples, and analogies a student would understand.`;

  const cacheKey = `ai:explain:${crypto.createHash('md5').update(prompt).digest('hex')}`;
  const redis = getRedisClient();
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  let response;
  try {
    response = await openai.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: prompt },
      ],
      max_tokens: 800,
    });
  } catch (err) {
    console.error('Groq Explain Model Error:', err.message);
    response = await openai.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: prompt },
      ],
      max_tokens: 800,
    });
  }

  const explanation = response.choices[0].message.content;
  await redis.setex(cacheKey, 3600, JSON.stringify({ explanation }));

  return { explanation };
};

const generateQuiz = async (userId, { subject, chapter, topic, difficulty = 'intermediate', count = 5 }) => {
  const openai = getOpenAIClient();

  const prompt = `Generate ${count} multiple-choice questions on "${topic || chapter || subject}" 
for difficulty level: ${difficulty}. 
Return as JSON array: [{ "question": "...", "options": ["A","B","C","D"], "answer": "A", "explanation": "..." }]`;

  const response = await openai.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: prompt },
    ],
    max_tokens: 2000,
    response_format: { type: 'json_object' },
  });

  const parsed = JSON.parse(response.choices[0].message.content);
  const questions = parsed.questions || parsed;

  const conversation = await AiConversation.create({
    userId,
    subject,
    type: 'quiz',
    messages: [
      { role: 'user', content: prompt },
      { role: 'assistant', content: JSON.stringify(questions) },
    ],
    tokensUsed: response.usage?.total_tokens || 0,
  });

  return { quizId: conversation._id, questions, difficulty, subject };
};

const submitQuiz = async (userId, quizId, answers) => {
  const conversation = await AiConversation.findOne({ _id: quizId, userId, type: 'quiz' });
  if (!conversation) throw new AppError('Quiz not found', 404, 'QUIZ_NOT_FOUND');

  const questions = JSON.parse(conversation.messages[1].content);
  let correct = 0;
  const results = questions.map((q, i) => {
    const isCorrect = answers[i] === q.answer;
    if (isCorrect) correct++;
    return { question: q.question, selected: answers[i], correct: q.answer, isCorrect, explanation: q.explanation };
  });

  const score = Math.round((correct / questions.length) * 100);
  return { score, correct, total: questions.length, results };
};

const getRecommendations = async (userId) => {
  const openai = getOpenAIClient();
  const userContext = await buildUserContext(userId);

  const response = await openai.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: `Based on this student's profile, give 3 specific, actionable study recommendations for this week:\n${userContext}` },
    ],
    max_tokens: 500,
  });

  return { recommendations: response.choices[0].message.content };
};

const getWeakTopics = async (userId) => {
  return PerformanceData.find({ userId, isWeakTopic: true }).select('subject chapter topic averageAccuracy lastUpdated');
};

const getConversations = async (userId) => {
  return AiConversation.find({ userId }).sort({ createdAt: -1 }).limit(20).select('-messages');
};

const getConversation = async (userId, conversationId) => {
  const conv = await AiConversation.findOne({ _id: conversationId, userId });
  if (!conv) throw new AppError('Conversation not found', 404, 'CONV_NOT_FOUND');
  return conv;
};

const getSubjectInfo = async (subject) => {
  const openai = getOpenAIClient();
  const redis = getRedisClient();

  const cacheKey = `ai:subjectinfo:${crypto.createHash('md5').update(subject.toLowerCase()).digest('hex')}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const prompt = `You are an expert academic curriculum designer.
For the subject: "${subject}"

Return a JSON object with EXACTLY this structure:
{
  "topics": [
    { "name": "Topic Name", "weightage": "High/Medium/Low", "description": "1 sentence" }
  ],
  "pyqs": [
    { "year": 2023, "question": "Full question text", "marks": 5, "difficulty": "Easy/Medium/Hard" }
  ]
}

Rules:
- topics: list 8-12 most important topics for this subject
- pyqs: list 6-8 realistic previous year exam questions (mix of years 2019-2024)
- weightage should reflect actual exam importance
- questions should be realistic, exam-style questions
- Return ONLY valid JSON, no explanation text`;

  let response;
  try {
    response = await openai.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 2000,
      temperature: 0.3,
      response_format: { type: 'json_object' },
    });
  } catch (err) {
    console.error('Groq subject info error, falling back:', err.message);
    response = await openai.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 2000,
      temperature: 0.3,
      response_format: { type: 'json_object' },
    });
  }

  const parsed = JSON.parse(response.choices[0].message.content);
  const result = {
    subject,
    topics: parsed.topics || [],
    pyqs: parsed.pyqs || [],
  };

  // Cache for 24 hours — subject info rarely changes
  await redis.setex(cacheKey, 86400, JSON.stringify(result));
  return result;
};

module.exports = { chat, explain, generateQuiz, submitQuiz, getRecommendations, getWeakTopics, getConversations, getConversation, getSubjectInfo, uploadNotes };
