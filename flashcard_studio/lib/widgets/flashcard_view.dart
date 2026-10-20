import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../utils/app_theme.dart';

class FlashcardView extends StatefulWidget {
  const FlashcardView({super.key, required this.card});
  final Flashcard card;

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  bool _answerVisible = false;
  bool _hintVisible = false;

  @override
  void didUpdateWidget(covariant FlashcardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card != widget.card) {
      _answerVisible = false;
      _hintVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFE0E4D9)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08263D34),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.style_outlined, color: accent, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'THINK IT THROUGH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          widget.card.question,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 30),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          child: _answerVisible
              ? Column(
                  key: const ValueKey('answer'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 18),
                    const Text(
                      'ANSWER',
                      style: TextStyle(
                        color: ink,
                        letterSpacing: 1.5,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.card.answer,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WHY?',
                            style: TextStyle(
                              color: ink,
                              letterSpacing: 1.5,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.card.explanation.isEmpty
                                ? 'No explanation added. You can add one by editing this card.'
                                : widget.card.explanation,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                )
              : const SizedBox(
                  key: ValueKey('question'),
                  width: double.infinity,
                ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _answerVisible = !_answerVisible),
            icon: Icon(
              _answerVisible
                  ? Icons.visibility_off_outlined
                  : Icons.flip_rounded,
            ),
            label: Text(_answerVisible ? 'Hide Answer' : 'Show Answer'),
          ),
        ),
        if (!_answerVisible) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: widget.card.hint.isEmpty
                  ? null
                  : () => setState(() => _hintVisible = !_hintVisible),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
              label: Text(
                widget.card.hint.isEmpty
                    ? 'No hint added'
                    : _hintVisible
                    ? 'Hide hint'
                    : 'Hint',
              ),
            ),
          ),
          if (_hintVisible)
            Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4DE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.card.hint,
                  style: const TextStyle(color: Color(0xFF79542F)),
                ),
              ),
            ),
        ],
      ],
    ),
  );
}
