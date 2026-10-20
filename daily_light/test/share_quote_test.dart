import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:daily_light/data/quotes_data.dart';
import 'package:daily_light/main.dart';
import 'package:daily_light/models/quote.dart';
import 'package:daily_light/services/share_service.dart';
import 'package:daily_light/theme/app_theme.dart';
import 'package:daily_light/widgets/quote_card.dart';
import 'package:daily_light/widgets/share_quote_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const cacheChannel = MethodChannel('plugins.flutter.io/path_provider');

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const DailyLightApp());
    await tester.pumpAndSettle();
  }

  Future<void> openPreview(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Share'));
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Share Image'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  for (final dark in [false, true]) {
    testWidgets('all quote cards fit with correct attribution, dark=$dark', (
      tester,
    ) async {
      for (final quote in quotes) {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: Scaffold(
              body: Center(child: ShareQuoteCard(quote: quote)),
            ),
          ),
        );
        expect(find.text(quote.text), findsOneWidget);
        expect(find.text('— ${quote.source}'), findsOneWidget);
        expect(find.text(quote.category.label.toUpperCase()), findsOneWidget);
        expect(
          tester.getSize(find.byType(ShareQuoteCard)),
          ShareQuoteCard.size,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('long quote and long source fit without truncation', (
    tester,
  ) async {
    final quote = Quote(
      id: 'long_test',
      text: List.filled(15, 'Take one small step forward today.').join(' '),
      source: List.filled(5, 'An original encouragement').join(' '),
      category: QuoteCategory.motivation,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Center(child: ShareQuoteCard(quote: quote)),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text(quote.text));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(find.text('— ${quote.source}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures a real 1080 by 1350 PNG', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: ShareQuoteCard(quote: quotes.first),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final capture = ShareService().capturePng(key);
      await tester.pump();
      final bytes = await capture;
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 1080);
        expect(frame.image.height, 1350);
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    });
  });

  testWidgets('a missing render boundary gives a recoverable error', (
    tester,
  ) async {
    final capture = ShareService().capturePng(GlobalKey());
    final expectation = expectLater(capture, throwsStateError);
    await tester.pump();
    await expectation;
  });

  testWidgets('preview keeps current quote and can close without sharing', (
    tester,
  ) async {
    await launch(tester);
    final quote = tester.widget<QuoteCard>(find.byType(QuoteCard)).quote;
    expect(find.byType(ShareQuoteCard), findsNothing);
    await openPreview(tester);
    expect(
      tester.widget<ShareQuoteCard>(find.byType(ShareQuoteCard)).quote,
      quote,
    );
    expect(find.text('Share Image'), findsOneWidget);
    await tester.tap(find.byTooltip('Close preview'));
    await tester.pumpAndSettle();
    expect(find.byType(ShareQuoteCard), findsNothing);
    await openPreview(tester);
    expect(find.text('Share Image'), findsOneWidget);
  });

  testWidgets('shares PNG files repeatedly after cancellation and success', (
    tester,
  ) async {
    final cache = Directory.systemTemp.createTempSync(
      'daily-light-share-test-',
    );
    addTearDown(() => cache.deleteSync(recursive: true));
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(cacheChannel, (_) async => cache.path);
    addTearDown(() => messenger.setMockMethodCallHandler(cacheChannel, null));
    final calls = <MethodCall>[];
    var invoked = Completer<void>();
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      calls.add(call);
      invoked.complete();
      return calls.length == 1 ? '' : 'test.target';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(shareChannel, null));
    await launch(tester);

    for (var i = 0; i < 3; i++) {
      if (i == 1) {
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
      }
      await openPreview(tester);
      await tester.runAsync(() async {
        await tester.tap(find.text('Share Image'));
        await tester.pump();
        for (var tick = 0; tick < 1000 && !invoked.isCompleted; tick++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(invoked.isCompleted, isTrue);
      });
      await tester.pumpAndSettle();
      final args = calls.last.arguments as Map;
      expect(calls.last.method, 'share');
      expect(args['text'], isNull);
      expect(args['mimeTypes'], ['image/png']);
      final path = (args['paths'] as List).single as String;
      expect(path.endsWith('/daily_light_quote.png'), isTrue);
      final bytes = File(path).readAsBytesSync();
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(16), 1080);
      expect(header.getUint32(20), 1350);
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(find.byType(ShareQuoteCard), findsNothing);
      expect(tester.takeException(), isNull);
      invoked = Completer<void>();
      await tester.ensureVisible(find.text('New Quote'));
      await tester.tap(find.text('New Quote'));
      await tester.pumpAndSettle();
    }
    expect(calls, hasLength(3));
  });

  for (final storageFailure in [true, false]) {
    testWidgets('failure allows retry, storageFailure=$storageFailure', (
      tester,
    ) async {
      final cache = Directory.systemTemp.createTempSync('daily-light-failure-');
      addTearDown(() => cache.deleteSync(recursive: true));
      final invoked = Completer<void>();
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(cacheChannel, (_) async {
        if (storageFailure) {
          invoked.complete();
          throw PlatformException(code: 'cache_unavailable');
        }
        return cache.path;
      });
      messenger.setMockMethodCallHandler(shareChannel, (_) async {
        invoked.complete();
        throw PlatformException(code: 'sharing_unavailable');
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(cacheChannel, null);
        messenger.setMockMethodCallHandler(shareChannel, null);
      });
      await launch(tester);
      await openPreview(tester);
      await tester.runAsync(() async {
        await tester.tap(find.text('Share Image'));
        await tester.pump();
        for (var tick = 0; tick < 1000 && !invoked.isCompleted; tick++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(invoked.isCompleted, isTrue);
      });
      await tester.pumpAndSettle();
      expect(
        find.text('Could not share the image. Please try again.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await openPreview(tester);
      expect(find.text('Share Image'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sharing disables repeat taps and closing until completion', (
    tester,
  ) async {
    final cache = Directory.systemTemp.createTempSync('daily-light-busy-');
    addTearDown(() => cache.deleteSync(recursive: true));
    final messenger = tester.binding.defaultBinaryMessenger;
    final invoked = Completer<void>();
    final result = Completer<String>();
    var calls = 0;
    messenger.setMockMethodCallHandler(cacheChannel, (_) async => cache.path);
    messenger.setMockMethodCallHandler(shareChannel, (_) async {
      calls++;
      invoked.complete();
      return result.future;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(cacheChannel, null);
      messenger.setMockMethodCallHandler(shareChannel, null);
    });
    await launch(tester);
    await openPreview(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('Share Image'));
      await tester.pump();
      for (var tick = 0; tick < 1000 && !invoked.isCompleted; tick++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(invoked.isCompleted, isTrue);
    });
    final button = find.widgetWithText(FilledButton, 'Preparing image…');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Close preview',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Preparing image…'));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ShareQuoteCard), findsOneWidget);
    expect(calls, 1);
    await tester.runAsync(() async {
      result.complete('');
      await tester.pump();
    });
    await tester.pumpAndSettle();
    expect(find.byType(ShareQuoteCard), findsNothing);
    await openPreview(tester);
    expect(find.text('Share Image'), findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(800, 360)]) {
    testWidgets('preview scrolls at $size with large text', (tester) async {
      await launch(tester);
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await openPreview(tester);
      await tester.ensureVisible(find.text('Share Image'));
      expect(tester.takeException(), isNull);
    });
  }
}
