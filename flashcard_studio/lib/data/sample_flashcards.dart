import '../models/flashcard.dart';

/// Added only on the first launch; deleting the deck keeps it empty on restart.
List<Flashcard> sampleFlashcards() {
  final created = DateTime.utc(2026, 1, 1);
  final content = [
    (
      'What is method overloading in Java?',
      'Defining multiple methods with the same name but different parameter lists.',
      'Think about one name accepting different inputs.',
      'The compiler chooses a matching method from the number and types of arguments. Changing only the return type is not sufficient.',
    ),
    (
      'What is the difference between a stack and a queue?',
      'A stack is last in, first out (LIFO). A queue is first in, first out (FIFO).',
      'Compare a pile of plates with a line of people.',
      'Stacks remove the most recently added item. Queues remove the earliest added item, preserving arrival order.',
    ),
    (
      'What does a primary key do in a database?',
      'It uniquely identifies each row in a table.',
      'How would you tell two otherwise similar records apart?',
      'A primary key must be unique and non-null. It may consist of one column or several columns together.',
    ),
    (
      'What is active recall?',
      'Retrieving information from memory instead of simply rereading it.',
      'Try answering before you turn the card over.',
      'Attempting to retrieve an answer gives you feedback about what you know and what needs more practice.',
    ),
    (
      'What is a Flutter widget?',
      'An immutable description of part of a Flutter user interface.',
      'Think of the building blocks of a screen.',
      'Widgets compose into a tree. When state changes, Flutter rebuilds the relevant descriptions and updates the rendered interface.',
    ),
  ];
  return [
    for (var i = 0; i < content.length; i++)
      Flashcard(
        id: 'starter-$i',
        question: content[i].$1,
        answer: content[i].$2,
        hint: content[i].$3,
        explanation: content[i].$4,
        createdAt: created,
      ),
  ];
}
