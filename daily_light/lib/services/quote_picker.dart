import 'dart:math';

import '../models/quote.dart';

class QuotePicker {
  QuotePicker({Random? random}) : _random = random ?? Random();

  final Random _random;

  Quote? pick(List<Quote> pool, {String? currentId}) {
    if (pool.isEmpty) return null;
    // Removing the current quote avoids retries and also handles a one-item pool.
    final alternatives = pool.where((quote) => quote.id != currentId).toList();
    final candidates = alternatives.isEmpty ? pool : alternatives;
    return candidates[_random.nextInt(candidates.length)];
  }
}
