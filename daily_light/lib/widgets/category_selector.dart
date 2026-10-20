import 'package:flutter/material.dart';

import '../models/quote.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  // null represents All, keeping the QuoteCategory enum specific to quote data.
  final QuoteCategory? selected;
  final ValueChanged<QuoteCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final category in [null, ...QuoteCategory.values])
            Expanded(
              child: Semantics(
                selected: selected == category,
                child: TextButton(
                  key: ValueKey('category_${category?.name ?? 'all'}'),
                  onPressed: () => onSelected(category),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    backgroundColor: selected == category
                        ? colors.surface
                        : Colors.transparent,
                    foregroundColor: selected == category
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    category?.label ?? 'All',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
