import 'package:flutter/material.dart';

import '../models/quote.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.position,
    required this.total,
  });

  final Quote quote;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scripture = quote.category == QuoteCategory.scripture;
    return Container(
      key: ValueKey(quote.id),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 350),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -62,
            bottom: -90,
            child: ExcludeSemantics(
              child: Icon(
                Icons.wb_sunny_outlined,
                size: 230,
                color: colors.primary.withValues(alpha: 0.055),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      scripture
                          ? Icons.auto_stories_outlined
                          : Icons.wb_sunny_outlined,
                      size: 17,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scripture ? 'SCRIPTURE · KJV' : 'MOTIVATION',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ExcludeSemantics(
                  child: Icon(
                    Icons.format_quote_rounded,
                    size: 36,
                    color: colors.tertiary,
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    quote.text,
                    key: const ValueKey('quote_text'),
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 25,
                      height: 1.5,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Container(width: 32, height: 2, color: colors.tertiary),
                const SizedBox(height: 14),
                Text(
                  '— ${quote.source}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'A moment to reflect',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$position of $total',
                      key: const ValueKey('quote_position'),
                      semanticsLabel:
                          'Quote $position of $total in this collection',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
