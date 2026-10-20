import 'package:flutter/material.dart';

import '../controllers/flashcard_controller.dart';
import '../models/flashcard.dart';
import '../utils/app_theme.dart';

class FlashcardFormScreen extends StatefulWidget {
  const FlashcardFormScreen({
    super.key,
    required this.controller,
    this.card,
    this.initialAnswer = '',
    this.initialExplanation = '',
  });

  final FlashcardController controller;
  final Flashcard? card;
  final String initialAnswer;
  final String initialExplanation;

  @override
  State<FlashcardFormScreen> createState() => _FlashcardFormScreenState();
}

class _FlashcardFormScreenState extends State<FlashcardFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _question = TextEditingController(text: widget.card?.question);
  late final _answer = TextEditingController(
    text: widget.card?.answer ?? widget.initialAnswer,
  );
  late final _hint = TextEditingController(text: widget.card?.hint);
  late final _explanation = TextEditingController(
    text: widget.card?.explanation ?? widget.initialExplanation,
  );
  bool _saving = false;

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    _hint.dispose();
    _explanation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final existing = widget.card;
      final card = existing == null
          ? Flashcard.create(
              question: _question.text,
              answer: _answer.text,
              hint: _hint.text,
              explanation: _explanation.text,
            )
          : existing.copyWith(
              question: _question.text,
              answer: _answer.text,
              hint: _hint.text,
              explanation: _explanation.text,
            );
      if (existing == null) {
        await widget.controller.add(card);
      } else {
        await widget.controller.update(card);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your card. Please retry.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'Create a card' : 'Edit card'),
      ),
      body: SafeArea(
        child: ReadingWidth(
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.card == null
                        ? 'One idea.\nMake it memorable.'
                        : 'Refine your notes.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Keep the question focused and the answer clear. * Required',
                  ),
                  const SizedBox(height: 28),
                  _field(
                    _question,
                    'Question *',
                    'What do you want to remember?',
                    required: true,
                  ),
                  _field(
                    _answer,
                    'Answer *',
                    'Write the answer in your own words.',
                    required: true,
                  ),
                  _field(_hint, 'Hint', 'A clue, without giving it away.'),
                  _field(
                    _explanation,
                    'Explanation',
                    'Why is this the answer?',
                    lines: 4,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('save-card'),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Saving…' : 'Save card'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    bool required = false,
    int lines = 3,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      minLines: 2,
      maxLines: lines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Please enter ${label.startsWith('Question') ? 'a question' : 'an answer'}.'
                : null
          : null,
    ),
  );
}
