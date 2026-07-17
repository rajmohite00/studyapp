// ── Question ──────────────────────────────────────────────────────────────────
class TestQuestion {
  final int index;
  final String type; // mcq, true_false, fill_blank, short_answer
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String topic;
  final String difficulty;

  const TestQuestion({
    required this.index,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.topic,
    required this.difficulty,
  });

  factory TestQuestion.fromJson(Map<String, dynamic> j) => TestQuestion(
        index: j['index'] ?? 0,
        type: j['type'] ?? 'mcq',
        question: j['question'] ?? '',
        options: List<String>.from(j['options'] ?? []),
        correctAnswer: j['correctAnswer'] ?? '',
        explanation: j['explanation'] ?? '',
        topic: j['topic'] ?? '',
        difficulty: j['difficulty'] ?? 'medium',
      );
}

// ── Answer ────────────────────────────────────────────────────────────────────
class TestAnswer {
  final int questionIndex;
  final String? userAnswer;
  final bool isCorrect;

  const TestAnswer({
    required this.questionIndex,
    this.userAnswer,
    required this.isCorrect,
  });

  factory TestAnswer.fromJson(Map<String, dynamic> j) => TestAnswer(
        questionIndex: j['questionIndex'] ?? 0,
        userAnswer: j['userAnswer'],
        isCorrect: j['isCorrect'] ?? false,
      );
}

// ── AI Analysis ───────────────────────────────────────────────────────────────
class AiTestAnalysis {
  final String overallPerformance;
  final List<String> strongTopics;
  final List<String> weakTopics;
  final String mistakes;
  final String knowledgeGaps;
  final List<String> conceptsToRevise;
  final String difficultyAnalysis;
  final String learningPattern;
  final String personalizedFeedback;
  final List<String> studySuggestions;
  final String estimatedLevel;
  final String motivationMessage;

  const AiTestAnalysis({
    required this.overallPerformance,
    required this.strongTopics,
    required this.weakTopics,
    required this.mistakes,
    required this.knowledgeGaps,
    required this.conceptsToRevise,
    required this.difficultyAnalysis,
    required this.learningPattern,
    required this.personalizedFeedback,
    required this.studySuggestions,
    required this.estimatedLevel,
    required this.motivationMessage,
  });

  factory AiTestAnalysis.fromJson(Map<String, dynamic> j) => AiTestAnalysis(
        overallPerformance: j['overallPerformance'] ?? '',
        strongTopics: List<String>.from(j['strongTopics'] ?? []),
        weakTopics: List<String>.from(j['weakTopics'] ?? []),
        mistakes: j['mistakes'] ?? '',
        knowledgeGaps: j['knowledgeGaps'] ?? '',
        conceptsToRevise: List<String>.from(j['conceptsToRevise'] ?? []),
        difficultyAnalysis: j['difficultyAnalysis'] ?? '',
        learningPattern: j['learningPattern'] ?? '',
        personalizedFeedback: j['personalizedFeedback'] ?? '',
        studySuggestions: List<String>.from(j['studySuggestions'] ?? []),
        estimatedLevel: j['estimatedLevel'] ?? '',
        motivationMessage: j['motivationMessage'] ?? '',
      );
}

// ── Revision Plan ─────────────────────────────────────────────────────────────
class RevisionPlan {
  final List<String> highPriority;
  final List<String> mediumPriority;
  final List<String> lowPriority;
  final List<String> studyOrder;
  final int estimatedHours;
  final String suggestedNextTest;

  const RevisionPlan({
    required this.highPriority,
    required this.mediumPriority,
    required this.lowPriority,
    required this.studyOrder,
    required this.estimatedHours,
    required this.suggestedNextTest,
  });

  factory RevisionPlan.fromJson(Map<String, dynamic> j) => RevisionPlan(
        highPriority: List<String>.from(j['highPriority'] ?? []),
        mediumPriority: List<String>.from(j['mediumPriority'] ?? []),
        lowPriority: List<String>.from(j['lowPriority'] ?? []),
        studyOrder: List<String>.from(j['studyOrder'] ?? []),
        estimatedHours: j['estimatedHours'] ?? 0,
        suggestedNextTest: j['suggestedNextTest'] ?? '',
      );
}

// ── TestModel ─────────────────────────────────────────────────────────────────
class TestModel {
  final String id;
  final String subject;
  final List<String> topics;
  final String testType; // full_subject | topic_wise
  final String difficulty;
  final int questionCount;
  final int timerMinutes;
  final String status; // draft | active | submitted | analysed
  final List<TestQuestion> questions;
  final List<TestAnswer> answers;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final int timeSpentSecs;

  // Score
  final int totalQuestions;
  final int attempted;
  final int correct;
  final int wrong;
  final int skipped;
  final int marks;
  final int percentage;
  final String grade;
  final bool passed;
  final int accuracy;
  final int avgTimePerQuestion;

  final AiTestAnalysis? aiAnalysis;
  final RevisionPlan? revisionPlan;
  final DateTime? createdAt;

  const TestModel({
    required this.id,
    required this.subject,
    required this.topics,
    required this.testType,
    required this.difficulty,
    required this.questionCount,
    required this.timerMinutes,
    required this.status,
    required this.questions,
    required this.answers,
    this.startedAt,
    this.submittedAt,
    this.timeSpentSecs = 0,
    this.totalQuestions = 0,
    this.attempted = 0,
    this.correct = 0,
    this.wrong = 0,
    this.skipped = 0,
    this.marks = 0,
    this.percentage = 0,
    this.grade = '',
    this.passed = false,
    this.accuracy = 0,
    this.avgTimePerQuestion = 0,
    this.aiAnalysis,
    this.revisionPlan,
    this.createdAt,
  });

  factory TestModel.fromJson(Map<String, dynamic> j) => TestModel(
        id: j['_id'] ?? j['id'] ?? '',
        subject: j['subject'] ?? '',
        topics: List<String>.from(j['topics'] ?? []),
        testType: j['testType'] ?? 'full_subject',
        difficulty: j['difficulty'] ?? 'mixed',
        questionCount: j['questionCount'] ?? 0,
        timerMinutes: j['timerMinutes'] ?? 0,
        status: j['status'] ?? 'draft',
        questions: (j['questions'] as List<dynamic>? ?? [])
            .map((q) => TestQuestion.fromJson(q))
            .toList(),
        answers: (j['answers'] as List<dynamic>? ?? [])
            .map((a) => TestAnswer.fromJson(a))
            .toList(),
        startedAt: j['startedAt'] != null ? DateTime.tryParse(j['startedAt']) : null,
        submittedAt: j['submittedAt'] != null ? DateTime.tryParse(j['submittedAt']) : null,
        timeSpentSecs: j['timeSpentSecs'] ?? 0,
        totalQuestions: j['totalQuestions'] ?? 0,
        attempted: j['attempted'] ?? 0,
        correct: j['correct'] ?? 0,
        wrong: j['wrong'] ?? 0,
        skipped: j['skipped'] ?? 0,
        marks: j['marks'] ?? 0,
        percentage: j['percentage'] ?? 0,
        grade: j['grade'] ?? '',
        passed: j['passed'] ?? false,
        accuracy: j['accuracy'] ?? 0,
        avgTimePerQuestion: j['avgTimePerQuestion'] ?? 0,
        aiAnalysis: j['aiAnalysis'] != null
            ? AiTestAnalysis.fromJson(j['aiAnalysis'])
            : null,
        revisionPlan: j['revisionPlan'] != null
            ? RevisionPlan.fromJson(j['revisionPlan'])
            : null,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
      );
}

// ── Stats ─────────────────────────────────────────────────────────────────────
class TestStats {
  final int totalTests;
  final int avgScore;
  final int highestScore;
  final int lowestScore;
  final int overallAccuracy;
  final List<SubjectStat> subjectStats;
  final List<String> weakTopics;
  final List<String> strongTopics;
  final List<WeeklyProgress> weeklyProgress;

  const TestStats({
    required this.totalTests,
    required this.avgScore,
    required this.highestScore,
    required this.lowestScore,
    required this.overallAccuracy,
    required this.subjectStats,
    required this.weakTopics,
    required this.strongTopics,
    required this.weeklyProgress,
  });

  factory TestStats.fromJson(Map<String, dynamic> j) => TestStats(
        totalTests: j['totalTests'] ?? 0,
        avgScore: j['avgScore'] ?? 0,
        highestScore: j['highestScore'] ?? 0,
        lowestScore: j['lowestScore'] ?? 0,
        overallAccuracy: j['overallAccuracy'] ?? 0,
        subjectStats: (j['subjectStats'] as List<dynamic>? ?? [])
            .map((s) => SubjectStat.fromJson(s))
            .toList(),
        weakTopics: List<String>.from(j['weakTopics'] ?? []),
        strongTopics: List<String>.from(j['strongTopics'] ?? []),
        weeklyProgress: (j['weeklyProgress'] as List<dynamic>? ?? [])
            .map((w) => WeeklyProgress.fromJson(w))
            .toList(),
      );
}

class SubjectStat {
  final String subject;
  final int count;
  final int avgScore;
  final int bestScore;

  const SubjectStat({
    required this.subject,
    required this.count,
    required this.avgScore,
    required this.bestScore,
  });

  factory SubjectStat.fromJson(Map<String, dynamic> j) => SubjectStat(
        subject: j['subject'] ?? '',
        count: j['count'] ?? 0,
        avgScore: j['avgScore'] ?? 0,
        bestScore: j['bestScore'] ?? 0,
      );
}

class WeeklyProgress {
  final String week;
  final int avgScore;
  final int count;

  const WeeklyProgress({
    required this.week,
    required this.avgScore,
    required this.count,
  });

  factory WeeklyProgress.fromJson(Map<String, dynamic> j) => WeeklyProgress(
        week: j['week'] ?? '',
        avgScore: j['avgScore'] ?? 0,
        count: j['count'] ?? 0,
      );
}
