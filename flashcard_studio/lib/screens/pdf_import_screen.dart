import 'package:flutter/material.dart';

import '../controllers/flashcard_controller.dart';
import '../services/flashcard_generator_service.dart';
import '../services/pdf_import_service.dart';
import '../utils/app_theme.dart';
import 'flashcard_form_screen.dart';

class PdfImportScreen extends StatefulWidget {
  const PdfImportScreen({
    super.key,
    required this.controller,
    this.importService,
    this.generator,
  });
  final FlashcardController controller;
  final PdfImportService? importService;
  final FlashcardGeneratorService? generator;

  @override
  State<PdfImportScreen> createState() => _PdfImportScreenState();
}

class _PdfImportScreenState extends State<PdfImportScreen> {
  late final _service = widget.importService ?? PdfImportService();
  late final _generator = widget.generator ?? LocalFlashcardGenerator();
  final _cancellation = ImportCancellation();
  PdfSource? _source;
  ExtractedPdf? _document;
  List<FlashcardDraft> _drafts = [];
  final Set<int> _selected = {};
  bool _busy = false;
  bool _saving = false;
  bool _showText = false;
  String _stage = '';
  double? _progress;
  String? _message;
  int _pageIndex = 0;
  String _selection = '';

  @override
  void dispose() {
    _cancellation.cancelled = true;
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _stage = 'Selecting file…';
      _progress = null;
      _message = null;
    });
    try {
      final source = await _service.pick();
      if (!mounted || source == null) return;
      setState(() {
        _source = source;
        _document = null;
        _drafts = [];
        _selected.clear();
        _selection = '';
        _pageIndex = 0;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'The file picker could not open. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _process() async {
    if (_source == null || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
      _stage = 'Reading PDF…';
      _progress = null;
    });
    try {
      final document = await _service.extract(
        _source!,
        cancellation: _cancellation,
        onProgress: (stage, progress) {
          if (mounted) {
            setState(() {
              _stage = stage;
              _progress = progress;
            });
          }
        },
      );
      if (!mounted) return;
      setState(() => _document = document);
      if (!document.hasText) {
        setState(
          () => _message = "We couldn't find readable text in this PDF. Scanned documents may require OCR.",
        );
        return;
      }
      setState(() {
        _stage = 'Creating cards…';
        _progress = null;
      });
      // Give the reading state a frame before running the local generator.
      await Future<void>.delayed(Duration.zero);
      final drafts = await _generator.generate(document);
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _selected.addAll(List.generate(drafts.length, (index) => index));
        _showText = drafts.isEmpty;
        if (drafts.isEmpty) _message = 'No clear English definitions found. Select a useful passage in Source text and write your own question.';
      });
    } on PdfImportException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = _document?.hasText == true
              ? 'Card suggestions could not be created. You can still select source text to make a card.'
              : 'This PDF could not be processed. Please try another file.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDrafts() async {
    if (_selected.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await widget.controller.addAll([
        for (final index in _selected.toList()..sort())
          _drafts[index].toFlashcard(),
      ]);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Could not save these cards. Please retry.';
        });
      }
    }
  }

  Future<void> _createFromSelection() async {
    final page = _document!.pages[_pageIndex];
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardFormScreen(
          controller: widget.controller,
          initialAnswer: _selection.trim(),
          initialExplanation:
              'Source: ${_document!.name}, page ${page.number}.',
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card from your notes added to the library.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Study from your notes')),
      body: SafeArea(
        child: ReadingWidth(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 46,
                  color: accent,
                ),
                const SizedBox(height: 20),
                Text(
                  'From pages\nto practice.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose your notes, find the key ideas, and make them yours. Your PDF is processed on this device.',
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _busy || _saving ? null : _pick,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    _source == null ? 'Choose PDF' : 'Choose another PDF',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'PDF only · Up to 20 MB and 150 pages',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                if (_source != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE0E4D9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELECTED',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _source!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_document == null)
                    FilledButton.icon(
                      onPressed: _busy ? null : _process,
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: const Text('Generate Flashcards'),
                    ),
                ],
                if (_busy || _saving) ...[
                  const SizedBox(height: 24),
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 12),
                  Text(
                    _saving ? 'Saving cards…' : _stage,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 20),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0DD),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _message!,
                        style: const TextStyle(color: Color(0xFF79542F)),
                      ),
                    ),
                  ),
                ],
                if (_document?.hasText == true && !_busy) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'YOUR STUDY MATERIAL',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        label: Text('Cards (${_drafts.length})'),
                        selected: !_showText,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _showText = false),
                      ),
                      ChoiceChip(
                        label: const Text('Source text'),
                        selected: _showText,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _showText = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_showText)
                    ..._sourceText(context)
                  else
                    ..._reviewCards(context),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _reviewCards(BuildContext context) => [
    const Text(
      'Local suggestions, not AI. Only clear English definitions are used. Review the answer and source before adding a card; edit it later from your library.',
    ),
    const SizedBox(height: 16),
    for (var index = 0; index < _drafts.length; index++)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            value: _selected.contains(index),
            onChanged: _saving
                ? null
                : (selected) => setState(() {
                    selected == true
                        ? _selected.add(index)
                        : _selected.remove(index);
                  }),
            title: Text(
              _drafts[index].question,
              style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${_drafts[index].answer}\n\n${_drafts[index].explanation}',
              ),
            ),
          ),
        ),
      ),
    if (_drafts.isNotEmpty)
      FilledButton.icon(
        onPressed: _saving || _selected.isEmpty ? null : _saveDrafts,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add ${_selected.length} ${_selected.length == 1 ? 'card' : 'cards'} to library',
        ),
      ),
  ];

  List<Widget> _sourceText(BuildContext context) {
    final pages = _document!.pages;
    final page = pages[_pageIndex];
    return [
      const Text(
        'Long-press and select a passage. Then create a card and write a focused question for it.',
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        key: ValueKey(_document),
        initialValue: _pageIndex,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Source page'),
        items: [
          for (var index = 0; index < pages.length; index++)
            DropdownMenuItem(
              value: index,
              child: Text('Page ${pages[index].number}'),
            ),
        ],
        onChanged: (index) {
          if (index != null) {
            setState(() {
              _pageIndex = index;
              _selection = '';
            });
          }
        },
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SelectableText(
          key: ValueKey(_pageIndex),
          page.text.isEmpty ? 'No readable text on this page.' : page.text,
          style: Theme.of(context).textTheme.bodyLarge,
          onSelectionChanged: (selection, cause) {
            final selected =
                selection.isValid &&
                    !selection.isCollapsed &&
                    selection.end <= page.text.length
                ? page.text.substring(selection.start, selection.end)
                : '';
            if (_selection != selected) setState(() => _selection = selected);
          },
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _selection.trim().isEmpty || _saving
            ? null
            : _createFromSelection,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Create card from selection'),
      ),
    ];
  }
}
