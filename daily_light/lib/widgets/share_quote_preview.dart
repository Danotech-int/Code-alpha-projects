import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../services/share_service.dart';
import 'share_quote_card.dart';

/// Returns false on failure so the home screen can show an unobscured SnackBar.
class ShareQuotePreview extends StatefulWidget {
  const ShareQuotePreview({super.key, required this.quote});

  final Quote quote;

  @override
  State<ShareQuotePreview> createState() => _ShareQuotePreviewState();
}

class _ShareQuotePreviewState extends State<ShareQuotePreview> {
  final _cardKey = GlobalKey();
  final _shareService = ShareService();
  bool _busy = false;

  Future<void> _shareImage(BuildContext buttonContext) async {
    if (_busy) return;
    final box = buttonContext.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _busy = true);
    try {
      await _shareService.shareCard(_cardKey, origin: origin);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // Includes rendering failures as well as plugin/cache-storage failures.
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Share a little light',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = math.min(
                      constraints.maxWidth,
                      ShareQuoteCard.size.width,
                    );
                    return SizedBox(
                      height: width * 5 / 4,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: ShareQuoteCard(quote: widget.quote),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Builder(
                  builder: (buttonContext) => FilledButton.icon(
                    onPressed: _busy ? null : () => _shareImage(buttonContext),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share_rounded),
                    label: Text(_busy ? 'Preparing image…' : 'Share Image'),
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
