import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app_style.dart';
import 'library_page.dart';
import 'settings.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isWindows) {
    // abre a janela maximizada
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(title: 'Gireli Notes'),
      () async {
        await windowManager.show();
        await windowManager.maximize();
        await windowManager.focus();
      },
    );
  }
  final settings = await SettingsStorage().load();
  runApp(NotasApp(settings: settings, storage: NotebookStorage()));
  if (!kIsWeb && Platform.isWindows) _maximizeAfterFirstFrame();
}

/// O executável do Windows chama "mostrar janela (tamanho normal)" quando o
/// primeiro quadro fica pronto, e isso desfaz o maximizar feito antes. Por isso
/// maximiza DEPOIS do primeiro quadro, e confere de novo mais um pouco depois.
Future<void> _maximizeAfterFirstFrame() async {
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  for (final ms in const [150, 500, 1200]) {
    await Future<void>.delayed(Duration(milliseconds: ms));
    if (!await windowManager.isMaximized()) await windowManager.maximize();
  }
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
  late AppStyle _style = widget.settings.style;

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
    if (s.theme != _theme || s.accent != _accent || s.style != _style) {
      setState(() {
        _theme = s.theme;
        _accent = s.accent;
        _style = s.style;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _style.forceDark
        ? ThemeMode.dark
        : switch (_theme) {
      ThemePref.system => ThemeMode.system,
      ThemePref.light => ThemeMode.light,
      ThemePref.dark => ThemeMode.dark,
    };
    return MaterialApp(
      title: 'Gireli Notes',
      debugShowCheckedModeBanner: false,
      theme: buildStyledTheme(Brightness.light, _accent, _style),
      darkTheme: buildStyledTheme(Brightness.dark, _accent, _style),
      themeMode: mode,
      home: LibraryPage(storage: widget.storage, settings: widget.settings),
    );
  }
}
