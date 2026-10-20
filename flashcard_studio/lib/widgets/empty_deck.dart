import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class EmptyDeck extends StatelessWidget {
  const EmptyDeck({super.key, required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFE8ECDD),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.style_outlined, size: 40, color: ink),
        ),
        const SizedBox(height: 24),
        Text(
          'A fresh page.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your next discovery belongs here.\nCreate a card to start studying.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Create your first card'),
        ),
      ],
    ),
  );
}
