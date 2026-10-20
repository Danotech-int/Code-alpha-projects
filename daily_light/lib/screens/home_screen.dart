import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/quotes_data.dart';
import '../models/quote.dart';
import '../services/favorites_service.dart';
import '../services/quote_picker.dart';
import '../widgets/category_selector.dart';
import '../widgets/quote_card.dart';
import '../widgets/share_quote_preview.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.favorites,
    required this.onToggleTheme,
  });

  final FavoritesService favorites;
  final ValueChanged<Brightness> onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = QuotePicker();
  QuoteCategory? _category;
  Quote? _currentQuote;
  bool _storageError = false;
  bool _loadingFavorites = false;
  bool _sharing = false;

  List<Quote> get _filteredQuotes => _category == null
      ? quotes
      : quotes.where((quote) => quote.category == _category).toList();

  @override
  void initState() {
    super.initState();
    _currentQuote = _picker.pick(quotes);
    if (!widget.favorites.isLoaded) _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loadingFavorites = true;
      _storageError = false;
    });
    try {
      await widget.favorites.load();
    } on Exception {
      if (mounted) setState(() => _storageError = true);
    } finally {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  void _newQuote() {
    setState(() {
      _currentQuote = _picker.pick(
        _filteredQuotes,
        currentId: _currentQuote?.id,
      );
    });
  }

  void _selectCategory(QuoteCategory? category) {
    setState(() {
      _category = category;
      _currentQuote = _picker.pick(
        _filteredQuotes,
        currentId: _currentQuote?.id,
      );
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleFavorite(Quote quote) async {
    try {
      await widget.favorites.toggle(quote.id);
    } on Exception {
      _showMessage('Could not save this change. Please try again.');
    }
  }

  Future<void> _copyQuote(Quote quote) async {
    try {
      await Clipboard.setData(ClipboardData(text: quote.shareText));
      _showMessage('Quote and source copied');
    } on Exception {
      _showMessage('Could not copy this quote. Please try again.');
    }
  }

  Future<void> _shareQuote(Quote quote) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final shared = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ShareQuotePreview(quote: quote),
      );
      if (shared == false) {
        _showMessage('Could not share the image. Please try again.');
      }
    } catch (_) {
      _showMessage('Could not open the share preview. Please try again.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final quote = _currentQuote;
    final pool = _filteredQuotes;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return ListenableBuilder(
      listenable: widget.favorites,
      builder: (context, child) {
        final saved = quote != null && widget.favorites.contains(quote.id);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                systemNavigationBarColor: colors.surface,
                systemNavigationBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
              ),
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width < 360
                          ? 18
                          : 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: colors.tertiary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.wb_sunny_outlined,
                                color: colors.tertiary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Daily Light',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: dark
                                  ? 'Switch to light theme'
                                  : 'Switch to dark theme',
                              onPressed: () =>
                                  widget.onToggleTheme(theme.brightness),
                              icon: Icon(
                                dark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 22,
                              ),
                            ),
                            IconButton(
                              tooltip: 'View favorites',
                              onPressed: widget.favorites.isLoaded
                                  ? () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => FavoritesScreen(
                                          favorites: widget.favorites,
                                        ),
                                      ),
                                    )
                                  : null,
                              icon: const Icon(
                                Icons.bookmarks_outlined,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'A WORD FOR YOUR DAY',
                          style: TextStyle(
                            color: colors.tertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Take a breath. Find a word to carry with you.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 26),
                        CategorySelector(
                          selected: _category,
                          onSelected: _selectCategory,
                        ),
                        const SizedBox(height: 20),
                        if (_storageError)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Saved quotes could not be loaded.',
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loadingFavorites
                                      ? null
                                      : _loadFavorites,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        AnimatedSwitcher(
                          duration: reducedMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.025),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: quote == null
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'No quotes in this collection yet. Try another category.',
                                  ),
                                )
                              : QuoteCard(
                                  key: ValueKey(quote.id),
                                  quote: quote,
                                  position:
                                      pool.indexWhere(
                                        (item) => item.id == quote.id,
                                      ) +
                                      1,
                                  total: pool.length,
                                ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: quote == null ? null : _newQuote,
                            icon: const Icon(Icons.shuffle_rounded, size: 21),
                            label: const Text('New Quote'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _QuoteAction(
                                label: saved ? 'Saved' : 'Favorite',
                                tooltip: saved
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                icon: saved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                selected: saved,
                                onPressed:
                                    quote != null &&
                                        widget.favorites.isLoaded &&
                                        !widget.favorites.isSaving
                                    ? () => _toggleFavorite(quote)
                                    : null,
                              ),
                            ),
                            Expanded(
                              child: _QuoteAction(
                                label: 'Copy',
                                tooltip: 'Copy quote and source',
                                icon: Icons.copy_outlined,
                                onPressed: quote == null
                                    ? null
                                    : () => _copyQuote(quote),
                              ),
                            ),
                            Expanded(
                              child: _QuoteAction(
                                label: 'Share',
                                tooltip: 'Share quote as image',
                                icon: Icons.ios_share_rounded,
                                onPressed: quote == null || _sharing
                                    ? null
                                    : () => _shareQuote(quote),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Center(
                          child: Text(
                            'PAUSE. BREATHE. BEGIN AGAIN.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                              letterSpacing: 1.8,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuoteAction extends StatelessWidget {
  const _QuoteAction({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        toggled: label == 'Favorite' || label == 'Saved' ? selected : null,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 66),
            foregroundColor: selected
                ? colors.tertiary
                : colors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 21),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
