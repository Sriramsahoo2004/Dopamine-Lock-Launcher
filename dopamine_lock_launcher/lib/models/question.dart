import 'dart:convert';

class Question {
  const Question({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.category,
  });

  final int id;
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final String category;

  factory Question.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final decodedOptions = rawOptions is String
        ? jsonDecode(rawOptions) as List<dynamic>
        : rawOptions as List<dynamic>;

    return Question(
      id: map['id'] as int,
      questionText: map['question_text'] as String,
      correctAnswer: map['correct_answer'] as String,
      options: decodedOptions.map((option) => option.toString()).toList(),
      category: map['category'] as String,
    );
  }
}
