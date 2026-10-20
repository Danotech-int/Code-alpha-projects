import 'package:flutter/material.dart';

import '../models/quote.dart';

/// A fixed-size graphic, independent of the phone's screen dimensions.
class ShareQuoteCard extends StatelessWidget {
  const ShareQuoteCard({super.key, required this.quote});

  static const size = Size(360, 450);
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // The preview scales this whole canvas; system text scaling must not crop
    // the exported graphic. The surrounding dialog keeps normal text scaling.
    return MediaQuery.withNoTextScaling(
      child: SizedBox.fromSize(
        size: size,
        child: Material(
          color: colors.surface,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.surface, colors.surfaceContainerLow],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: -65,
                  bottom: -65,
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      size: 240,
                      color: colors.primary.withValues(alpha: 0.045),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 32, 34, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 27,
                        color: colors.tertiary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'DAILY LIGHT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'A word for your day',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ExcludeSemantics(
                        child: Icon(
                          Icons.format_quote_rounded,
                          size: 32,
                          color: colors.tertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        // Keep the full quote and source. Longer content scales
                        // down together instead of being truncated or overflowing.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: size.width - 68,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  quote.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lora',
                                    color: colors.onSurface,
                                    fontSize: 24,
                                    height: 1.45,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '— ${quote.source}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Container(
                          width: 28,
                          height: 2,
                          color: colors.tertiary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        quote.category.label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
