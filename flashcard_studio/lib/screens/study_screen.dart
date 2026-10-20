import 'package:flutter/material.dart';

import '../controllers/flashcard_controller.dart';
import '../utils/app_theme.dart';
import '../utils/card_actions.dart';
import '../widgets/empty_deck.dart';
import '../widgets/flashcard_view.dart';
import '../widgets/progress_header.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.controller,
    this.initialIndex = 0,
  });
  final FlashcardController controller;
  final int initialIndex;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late int _index = widget.initialIndex;
  final _scroll = ScrollController();

  void _move(int delta) {
    setState(() => _index += delta);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final cards = widget.controller.cards;
      _index = cards.isEmpty ? 0 : _index.clamp(0, cards.length - 1);
      final card = cards.isEmpty ? null : cards[_index];
      return Scaffold(
        appBar: AppBar(
          title: const Text('Flashcard Studio'),
          actions: [
            if (card != null)
              CardMenu(controller: widget.controller, card: card),
          ],
        ),
        body: SafeArea(
          child: ReadingWidth(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              children: [
                if (card == null)
                  EmptyDeck(
                    onCreate: () => openCardForm(context, widget.controller),
                  )
                else ...[
                  ProgressHeader(index: _index, total: cards.length),
                  const SizedBox(height: 24),
                  const Text('A little focus goes a long way.'),
                  const SizedBox(height: 18),
                  FlashcardView(key: ValueKey(card.id), card: card),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _index == 0 ? null : () => _move(-1),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _index >= cards.length - 1
                              ? null
                              : () => _move(1),
                          child: const Text('Next  →'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      _index == cards.length - 1
                          ? 'Last card. Revisit any card, or finish for now.'
                          : 'Try recalling the answer before revealing it.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_index == cards.length - 1)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Finish session'),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
