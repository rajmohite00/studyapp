class Flashcard {
  final String id;
  final String subject;
  final String term;
  final String definition;
  final DateTime nextReviewDate;

  Flashcard({
    required this.id,
    required this.subject,
    required this.term,
    required this.definition,
    required this.nextReviewDate,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['_id'] ?? '',
      subject: json['subject'] ?? '',
      term: json['term'] ?? '',
      definition: json['definition'] ?? '',
      nextReviewDate: json['nextReviewDate'] != null 
          ? DateTime.parse(json['nextReviewDate'])
          : DateTime.now(),
    );
  }
}
