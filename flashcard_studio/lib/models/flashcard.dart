import 'dart:math';

/// Immutable so edits cannot accidentally change a card before it is saved.
class Flashcard {
  Flashcard({
    required this.id,
    required String question,
    required String answer,
    String hint = '',
    String explanation = '',
    required this.createdAt,
  }) : question = question.trim(),
       answer = answer.trim(),
       hint = hint.trim(),
       explanation = explanation.trim() {
    if (id.isEmpty || this.question.isEmpty || this.answer.isEmpty) {
      throw ArgumentError('A card needs an id, question and answer.');
    }
  }

  factory Flashcard.create({
    required String question,
    required String answer,
    String hint = '',
    String explanation = '',
  }) {
    final now = DateTime.now().toUtc();
    return Flashcard(
      id: '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
      question: question,
      answer: answer,
      hint: hint,
      explanation: explanation,
      createdAt: now,
    );
  }

  final String id;
  final String question;
  final String answer;
  final String hint;
  final String explanation;
  final DateTime createdAt;

  Flashcard copyWith({
    String? question,
    String? answer,
    String? hint,
    String? explanation,
  }) => Flashcard(
    id: id,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    hint: hint ?? this.hint,
    explanation: explanation ?? this.explanation,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
    'hint': hint,
    'explanation': explanation,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'] as String,
    question: json['question'] as String,
    answer: json['answer'] as String,
    hint: json['hint'] as String? ?? '',
    explanation: json['explanation'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
