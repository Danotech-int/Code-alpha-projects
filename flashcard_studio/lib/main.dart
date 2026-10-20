import 'package:flutter/material.dart';

import 'controllers/flashcard_controller.dart';
import 'screens/home_screen.dart';
import 'services/flashcard_storage_service.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudioBootstrap());
}

class StudioBootstrap extends StatefulWidget {
  const StudioBootstrap({super.key});

  @override
  State<StudioBootstrap> createState() => _StudioBootstrapState();
}

class _StudioBootstrapState extends State<StudioBootstrap> {
  late Future<FlashcardController> _loading = _open();
  FlashcardController? _controller;

  Future<FlashcardController> _open() async {
    final storage = await HiveFlashcardStorageService.open();
    final controller = FlashcardController(storage);
    try {
      await controller.initialize();
      _controller = controller;
      return controller;
    } catch (_) {
      controller.dispose();
      rethrow;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FlashcardController>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return FlashcardStudioApp(controller: snapshot.data!);
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: studioTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_off_outlined, size: 48),
                          const SizedBox(height: 20),
                          const Text(
                            'Your library could not be opened. Your saved data has not been replaced. Please try again.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => setState(() => _loading = _open()),
                            child: const Text('Try again'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(
                        semanticsLabel: 'Opening your library',
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class FlashcardStudioApp extends StatelessWidget {
  const FlashcardStudioApp({super.key, required this.controller});

  final FlashcardController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flashcard Studio',
    debugShowCheckedModeBanner: false,
    theme: studioTheme(),
    home: HomeScreen(controller: controller),
  );
}
