import 'package:daily_light/data/quotes_data.dart';
import 'package:daily_light/main.dart';
import 'package:daily_light/models/quote.dart';
import 'package:daily_light/widgets/quote_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const DailyLightApp());
    await tester.pumpAndSettle();
  }

  Quote currentQuote(WidgetTester tester) =>
      tester.widget<QuoteCard>(find.byType(QuoteCard)).quote;

  testWidgets('renders an initial quote, its source, and assignment controls', (
    tester,
  ) async {
    await launch(tester);
    final quote = currentQuote(tester);
    expect(find.text('Daily Light'), findsOneWidget);
    expect(quotes, contains(quote));
    expect(find.text(quote.text), findsOneWidget);
    expect(find.text('— ${quote.source}'), findsOneWidget);
    expect(find.text('New Quote'), findsOneWidget);
    for (final label in ['All', 'Scripture', 'Motivation']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('of 40'), findsOneWidget);
  });

  testWidgets('New Quote displays a different quote', (tester) async {
    await launch(tester);
    final previous = currentQuote(tester);
    await tester.ensureVisible(find.text('New Quote'));
    await tester.tap(find.text('New Quote'));
    await tester.pumpAndSettle();
    expect(currentQuote(tester).id, isNot(previous.id));
  });

  testWidgets(
    'category selection immediately filters quotes and updates position',
    (tester) async {
      await launch(tester);
      for (final category in QuoteCategory.values) {
        await tester.tap(find.byKey(ValueKey('category_${category.name}')));
        await tester.pumpAndSettle();
        expect(currentQuote(tester).category, category);
        expect(find.textContaining('of 20'), findsOneWidget);
        await tester.ensureVisible(find.text('New Quote'));
        await tester.tap(find.text('New Quote'));
        await tester.pumpAndSettle();
        expect(currentQuote(tester).category, category);
        await tester.ensureVisible(find.byKey(const ValueKey('category_all')));
      }
      await tester.tap(find.byKey(const ValueKey('category_all')));
      await tester.pumpAndSettle();
      expect(find.textContaining('of 40'), findsOneWidget);
    },
  );

  testWidgets('favorite appears in saved view and can be removed', (
    tester,
  ) async {
    await launch(tester);
    final quote = currentQuote(tester);
    await tester.ensureVisible(find.text('Favorite'));
    await tester.tap(find.text('Favorite'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('View favorites'));
    await tester.tap(find.byTooltip('View favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text(quote.text), findsOneWidget);
    await tester.tap(find.byTooltip('Remove ${quote.source} from favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Keep a little light'), findsOneWidget);
    await tester.tap(find.text('Find your next quote'));
    await tester.pumpAndSettle();
    expect(find.text('Favorite'), findsOneWidget);
  });

  testWidgets('empty Favorites view explains how to save quotes', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byTooltip('View favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Keep a little light'), findsOneWidget);
    expect(find.textContaining('Tap Favorite'), findsOneWidget);
  });

  testWidgets('Copy passes quote and source to clipboard and confirms', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await launch(tester);
    final quote = currentQuote(tester);
    await tester.ensureVisible(find.text('Copy'));
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copiedText, quote.shareText);
    expect(find.text('Quote and source copied'), findsOneWidget);
  });

  testWidgets('theme toggle switches between light and dark', (tester) async {
    await launch(tester);
    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(QuoteCard));
    expect(Theme.of(context).brightness, Brightness.dark);
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(Theme.of(context).brightness, Brightness.light);
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 800),
    const Size(800, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('no layout errors at $size with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(const DailyLightApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('New Quote'));
        await tester.tap(find.text('New Quote'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byTooltip('View favorites'));
        await tester.tap(find.byTooltip('View favorites'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
