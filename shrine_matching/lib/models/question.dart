class Question {
  final String id;
  final String content;
  final int value;

  Question({required this.id, required this.content, required this.value});

  factory Question.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Question(
      id: documentId,
      content: data['content'] ?? '', 
      value: data['value'] ?? 0,
    );
  }
}
