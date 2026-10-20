import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_studio/main.dart';
import 'package:flashcard_studio/screens/flashcard_form_screen.dart';
import 'package:flashcard_studio/screens/study_screen.dart';
import 'package:flashcard_studio/utils/app_theme.dart';

import 'support.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200);
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app renders the library and starts a study session', (
    tester,
  ) async {
    final controller = await testController([testCard(), testCard('2')]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(FlashcardStudioApp(controller: controller));
    expect(find.text('Flashcard\nStudio'), findsOneWidget);
    expect(find.text('2 cards'), findsOneWidget);
    await tapVisible(tester, find.text('Start studying'));
    expect(find.text('Question 1?'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Answer 1.'), findsNothing);
  });

  testWidgets('empty library shows an empty state and disables study', (
    tester,
  ) async {
    final controller = await testController([]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(FlashcardStudioApp(controller: controller));
    expect(find.text('0 cards'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start studying'),
          )
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(find.text('A fresh page.'), 250);
    expect(find.text('Create your first card'), findsOneWidget);
  });

  testWidgets('hint, reveal, next and previous reset per-card state', (
    tester,
  ) async {
    final controller = await testController([testCard(), testCard('2')]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: StudyScreen(controller: controller),
      ),
    );
    expect(find.text('Clue 1.'), findsNothing);
    await tapVisible(tester, find.text('Hint'));
    expect(find.text('Clue 1.'), findsOneWidget);
    expect(find.text('Answer 1.'), findsNothing);
    await tapVisible(tester, find.text('Show Answer'));
    expect(find.text('Answer 1.'), findsOneWidget);
    expect(find.text('Explanation 1.'), findsOneWidget);
    await tapVisible(tester, find.text('Hide Answer'));
    expect(find.text('Answer 1.'), findsNothing);
    await tapVisible(tester, find.text('Next  →'));
    expect(find.text('Question 2?'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Answer 2.'), findsNothing);
    expect(find.text('Clue 2.'), findsNothing);
    await tapVisible(tester, find.text('Previous'));
    expect(find.text('Question 1?'), findsOneWidget);
    expect(find.text('Answer 1.'), findsNothing);
    expect(find.text('Clue 1.'), findsNothing);
  });

  testWidgets('one-card navigation is disabled; deleting final card is safe', (
    tester,
  ) async {
    final controller = await testController([testCard()]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: StudyScreen(controller: controller),
      ),
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Previous'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next  →'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Card options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.cards, hasLength(1));
    await tester.tap(find.byTooltip('Card options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(controller.cards, isEmpty);
    expect(find.text('A fresh page.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form rejects whitespace and saves valid input', (tester) async {
    final controller = await testController([]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: FlashcardFormScreen(controller: controller),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), '  ');
    await tapVisible(tester, find.byKey(const Key('save-card')));
    expect(controller.cards, isEmpty);
    await tester.ensureVisible(find.byType(TextFormField).first);
    expect(find.text('Please enter a question.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'What is a widget?',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'A UI description.',
    );
    await tapVisible(tester, find.byKey(const Key('save-card')));
    expect(controller.cards.single.question, 'What is a widget?');
  });

  testWidgets('editing pre-fills fields and preserves identity', (
    tester,
  ) async {
    final original = testCard();
    final controller = await testController([original]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: FlashcardFormScreen(controller: controller, card: original),
      ),
    );
    expect(find.text('Question 1?'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Revised question?',
    );
    await tapVisible(tester, find.byKey(const Key('save-card')));
    expect(controller.cards.single.question, 'Revised question?');
    expect(controller.cards.single.id, original.id);
  });

  testWidgets('small screen and larger text stay scrollable without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = await testController([testCard()]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: StudyScreen(controller: controller),
      ),
    );
    await tapVisible(tester, find.text('Show Answer'));
    await tester.ensureVisible(find.text('Previous'));
    expect(tester.takeException(), isNull);
  });
}
