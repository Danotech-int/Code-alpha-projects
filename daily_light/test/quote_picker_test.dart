import 'dart:math';

import 'package:daily_light/data/quotes_data.dart';
import 'package:daily_light/models/quote.dart';
import 'package:daily_light/services/quote_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dataset has 20 unique entries per category and complete sources', () {
    expect(quotes.length, 40);
    expect(quotes.map((quote) => quote.id).toSet().length, quotes.length);
    expect(quotes.map((quote) => quote.text).toSet().length, quotes.length);
    for (final category in QuoteCategory.values) {
      expect(quotes.where((quote) => quote.category == category).length, 20);
    }
    for (final quote in quotes) {
      expect(quote.text.trim(), isNotEmpty);
      expect(quote.source.trim(), isNotEmpty);
    }
  });

  test('random picker never repeats consecutively over 1000 selections', () {
    final picker = QuotePicker(random: Random(42));
    Quote? previous;
    final seen = <String>{};
    for (var index = 0; index < 1000; index++) {
      final next = picker.pick(quotes, currentId: previous?.id)!;
      expect(next.id, isNot(previous?.id));
      expect(quotes, contains(next));
      seen.add(next.id);
      previous = next;
    }
    expect(seen.length, greaterThan(1));
  });

  test('picker stays within a filtered category', () {
    final picker = QuotePicker(random: Random(7));
    for (final category in QuoteCategory.values) {
      final pool = quotes.where((quote) => quote.category == category).toList();
      for (var index = 0; index < 100; index++) {
        expect(picker.pick(pool)?.category, category);
      }
    }
  });

  test('empty and single-item pools are safe', () {
    final picker = QuotePicker(random: Random(1));
    expect(picker.pick([]), isNull);
    expect(picker.pick([quotes.first]), quotes.first);
    expect(
      picker.pick([quotes.first], currentId: quotes.first.id),
      quotes.first,
    );
  });

  test('copied and shared text contains both quote and attribution', () {
    expect(
      quotes.first.shareText,
      '“${quotes.first.text}”\n— ${quotes.first.source}',
    );
  });
}
