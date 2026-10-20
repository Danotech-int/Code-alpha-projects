enum QuoteCategory {
  scripture('Scripture'),
  motivation('Motivation');

  const QuoteCategory(this.label);

  final String label;
}

class Quote {
  const Quote({
    required this.id,
    required this.text,
    required this.source,
    required this.category,
  });

  final String id;
  final String text;
  final String source;
  final QuoteCategory category;

  String get shareText => '“$text”\n— $source';
}
