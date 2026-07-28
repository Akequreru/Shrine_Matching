class Question {
  final String id;
  final String question;
  final String answer1;
  final String answer2;
  final int value;

  Question({
    required this.id,
    required this.question,
    required this.answer1,
    required this.answer2,
    required this.value,
  });

  factory Question.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Question(
      id: documentId,
      question: data['question'] ?? '',
      answer1: data['answer1'] ?? '',
      answer2: data['answer2'] ?? '',
      value: data['value'] ?? 0,
    );
  }
}
