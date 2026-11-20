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

class NotasApp extends StatelessWidget {
  const NotasApp({super.key, required this.settings, required this.storage});

  final AppSettings settings;
  final NotebookStorage storage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final mode = switch (settings.theme) {
          ThemePref.system => ThemeMode.system,
          ThemePref.light => ThemeMode.light,
          ThemePref.dark => ThemeMode.dark,
        };
        return MaterialApp(
          title: 'Notas',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light, settings.accent),
          darkTheme: buildTheme(Brightness.dark, settings.accent),
          themeMode: mode,
          home: LibraryPage(storage: storage, settings: settings),
        );
      },
    );
  }
}
