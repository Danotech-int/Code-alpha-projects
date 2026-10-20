import 'package:flutter/material.dart';

import '../controllers/flashcard_controller.dart';
import '../models/flashcard.dart';
import '../screens/flashcard_form_screen.dart';

Future<void> openCardForm(
  BuildContext context,
  FlashcardController controller, {
  Flashcard? card,
}) async {
  final saved = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => FlashcardFormScreen(controller: controller, card: card),
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          card == null ? 'Card added to your library.' : 'Card updated.',
        ),
      ),
    );
  }
}

Future<void> confirmDelete(
  BuildContext context,
  FlashcardController controller,
  Flashcard card,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this flashcard?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await controller.delete(card.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Card deleted.')));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not delete this card. Please retry.'),
      ),
    );
  }
}

class CardMenu extends StatelessWidget {
  const CardMenu({super.key, required this.controller, required this.card});
  final FlashcardController controller;
  final Flashcard card;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Card options',
    enabled: !controller.saving,
    onSelected: (value) {
      if (value == 'edit') {
        openCardForm(context, controller, card: card);
      } else {
        confirmDelete(context, controller, card);
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'edit', child: Text('Edit card')),
      PopupMenuItem(value: 'delete', child: Text('Delete card')),
    ],
  );
}
