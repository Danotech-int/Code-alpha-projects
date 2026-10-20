import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/favorites_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DailyLightApp());
}

class DailyLightApp extends StatefulWidget {
  const DailyLightApp({super.key, this.favoritesService});

  final FavoritesService? favoritesService;

  @override
  State<DailyLightApp> createState() => _DailyLightAppState();
}

class _DailyLightAppState extends State<DailyLightApp> {
  late final FavoritesService _favorites;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _favorites = widget.favoritesService ?? FavoritesService();
  }

  @override
  void dispose() {
    if (widget.favoritesService == null) _favorites.dispose();
    super.dispose();
  }

  void _toggleTheme(Brightness currentBrightness) {
    setState(() {
      _themeMode = currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Light',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: HomeScreen(favorites: _favorites, onToggleTheme: _toggleTheme),
    );
  }
}
