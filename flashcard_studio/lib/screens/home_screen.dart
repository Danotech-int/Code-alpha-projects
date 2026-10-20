import 'package:flutter/material.dart';

import '../controllers/flashcard_controller.dart';
import '../utils/app_theme.dart';
import '../utils/card_actions.dart';
import '../widgets/empty_deck.dart';
import 'study_screen.dart';
import 'pdf_import_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final FlashcardController controller;

  void _study(BuildContext context, [int index = 0]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudyScreen(controller: controller, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final cards = controller.cards;
      return Scaffold(
        body: SafeArea(
          child: ReadingWidth(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ink,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.style_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'YOUR LEARNING SPACE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.7,
                                  color: muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Flashcard\nStudio',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Turn what you learn into\nsomething you remember.',
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: controller.saving
                                  ? null
                                  : () => openCardForm(context, controller),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create Card'),
                            ),
                            OutlinedButton.icon(
                              onPressed: controller.saving
                                  ? null
                                  : () async {
                                      final saved = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PdfImportScreen(
                                            controller: controller,
                                          ),
                                        ),
                                      );
                                      if (saved == true && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Cards from your notes added to the library.',
                                                ),
                                              ),
                                            );
                                      }
                                    },
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('Import PDF'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7EDDC),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SMALL SESSIONS. LASTING KNOWLEDGE.',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Make a little progress.',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cards.isEmpty
                                    ? 'Your study session starts with one card.'
                                    : '${cards.length} cards ready for a fresh perspective.',
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: cards.isEmpty
                                      ? null
                                      : () => _study(context),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Start studying'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'YOUR DECK',
                                style: TextStyle(
                                  letterSpacing: 1.8,
                                  fontSize: 12,
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${cards.length} ${cards.length == 1 ? 'card' : 'cards'}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('A collection of things worth knowing.'),
                        if (cards.isEmpty)
                          EmptyDeck(
                            onCreate: () => openCardForm(context, controller),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverList.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFE1E4DA)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _study(context, index),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 4, 18),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: paper,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${index + 1}'.padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cards[index].question,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          color: ink,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Tap to study',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CardMenu(
                                  controller: controller,
                                  card: cards[index],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
