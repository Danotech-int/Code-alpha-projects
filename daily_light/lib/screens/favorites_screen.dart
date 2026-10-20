import 'package:flutter/material.dart';

import '../data/quotes_data.dart';
import '../models/quote.dart';
import '../services/favorites_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.favorites});

  final FavoritesService favorites;

  Future<void> _remove(BuildContext context, Quote quote) async {
    try {
      await favorites.toggle(quote.id);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not remove this quote. Please try again.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: favorites,
          builder: (context, child) {
            final savedQuotes = quotes
                .where((quote) => favorites.contains(quote.id))
                .toList();
            if (savedQuotes.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          color: colors.primary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Keep a little light',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Lora', fontSize: 26),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your saved words will live here.\nTap Favorite on a quote to keep it close.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Find your next quote'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: savedQuotes.length + 1,
                  separatorBuilder: (_, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${savedQuotes.length} saved ${savedQuotes.length == 1 ? 'quote' : 'quotes'} · Words to return to',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      );
                    }
                    final quote = savedQuotes[index - 1];
                    return Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 12, 22),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  quote.category == QuoteCategory.scripture
                                      ? 'Scripture · KJV'
                                      : 'Motivation',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    'Remove ${quote.source} from favorites',
                                onPressed: favorites.isSaving
                                    ? null
                                    : () => _remove(context, quote),
                                icon: Icon(
                                  Icons.favorite_rounded,
                                  color: colors.tertiary,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              quote.text,
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 20,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '— ${quote.source}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
