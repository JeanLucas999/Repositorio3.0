import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'library_page.dart';
import 'settings.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isWindows) {
    // abre a janela maximizada
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(title: 'Notas'),
      () async {
        await windowManager.maximize();
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
  final settings = await SettingsStorage().load();
  runApp(NotasApp(settings: settings, storage: NotebookStorage()));
}

ThemeData buildTheme(Brightness brightness, int accent) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Color(accent),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

class NotasApp extends StatefulWidget {
  const NotasApp({super.key, required this.settings, required this.storage});

  final AppSettings settings;
  final NotebookStorage storage;

  @override
  State<NotasApp> createState() => _NotasAppState();
}

class _NotasAppState extends State<NotasApp> {
  late ThemePref _theme = widget.settings.theme;
  late int _accent = widget.settings.accent;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettings);
    super.dispose();
  }

  /// Só reconstrói o app inteiro se o tema ou a cor de destaque mudaram;
  /// as outras configurações (paleta, borracha, etc.) não precisam disso.
  void _onSettings() {
    final s = widget.settings;
    if (s.theme != _theme || s.accent != _accent) {
      setState(() {
        _theme = s.theme;
        _accent = s.accent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = switch (_theme) {
      ThemePref.system => ThemeMode.system,
      ThemePref.light => ThemeMode.light,
      ThemePref.dark => ThemeMode.dark,
    };
    return MaterialApp(
      title: 'Notas',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, _accent),
      darkTheme: buildTheme(Brightness.dark, _accent),
      themeMode: mode,
      home: LibraryPage(storage: widget.storage, settings: widget.settings),
    );
  }
}
