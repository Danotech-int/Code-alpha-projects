import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// The 360 × 450 logical canvas becomes a sharp 1080 × 1350 PNG.
  Future<Uint8List> capturePng(GlobalKey cardKey) async {
    // A boundary must have finished painting before toImage can capture it.
    await WidgetsBinding.instance.endOfFrame;
    final boundary = cardKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || !boundary.hasSize) {
      throw StateError('The share card is not ready.');
    }

    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode the share card.');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  Future<void> shareCard(GlobalKey cardKey, {required ui.Rect origin}) async {
    final png = await capturePng(cardKey);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: ['daily_light_quote.png'],
        title: 'Daily Light',
        sharePositionOrigin: origin,
      ),
    );
  }
}
