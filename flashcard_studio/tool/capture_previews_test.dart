import 'dart:io';
import 'dart:ui' as ui;

import 'package:flashcard_studio/controllers/flashcard_controller.dart';
import 'package:flashcard_studio/data/sample_flashcards.dart';
import 'package:flashcard_studio/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support.dart';

// Optional documentation capture; not part of the normal test/ suite.
// Run with FLUTTER_ROOT set to the SDK directory and a host clang on PATH.
void main() {
  testWidgets('capture mobile library and study previews', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT'];
      if (sdk == null) throw StateError('Set FLUTTER_ROOT to your Flutter SDK.');
      final loader = FontLoader('Roboto');
      for (final name in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
        final bytes = await File('$sdk/bin/cache/artifacts/material_fonts/$name').readAsBytes();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    });
    final controller = FlashcardController(MemoryStorage(sampleFlashcards()));
    await controller.initialize();
    addTearDown(controller.dispose);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: FlashcardStudioApp(controller: controller)));
    await tester.pumpAndSettle();

    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/screenshots/$name.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('library');
    await tester.ensureVisible(find.text('Start studying'));
    await tester.tap(find.text('Start studying'));
    await tester.pumpAndSettle();
    await capture('study');
    await tester.tap(find.text('Show Answer'));
    await tester.pumpAndSettle();
    await capture('answer');
    expect(tester.takeException(), isNull);
  });
}
