class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        answer: json['answer'] ?? '',
        explanation: json['explanation'] ?? '',
      );
}

class QuizModel {
  final String quizId;
  final String subject;
  final String difficulty;
  final List<QuizQuestion> questions;

  const QuizModel({
    required this.quizId,
    required this.subject,
    required this.difficulty,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) => QuizModel(
        quizId: json['quizId'] ?? '',
        subject: json['subject'] ?? '',
        difficulty: json['difficulty'] ?? 'intermediate',
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
      );
}

class QuizResult {
  final int score;
  final int correct;
  final int total;
  final List<QuizResultItem> results;

  const QuizResult({
    required this.score,
    required this.correct,
    required this.total,
    required this.results,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        score: json['score'] ?? 0,
        correct: json['correct'] ?? 0,
        total: json['total'] ?? 0,
        results: (json['results'] as List<dynamic>? ?? [])
            .map((r) => QuizResultItem.fromJson(r))
            .toList(),
      );
}

class QuizResultItem {
  final String question;
  final String selected;
  final String correct;
  final bool isCorrect;
  final String explanation;

  const QuizResultItem({
    required this.question,
    required this.selected,
    required this.correct,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuizResultItem.fromJson(Map<String, dynamic> json) => QuizResultItem(
        question: json['question'] ?? '',
        selected: json['selected'] ?? '',
        correct: json['correct'] ?? '',
        isCorrect: json['isCorrect'] ?? false,
        explanation: json['explanation'] ?? '',
      );
}
