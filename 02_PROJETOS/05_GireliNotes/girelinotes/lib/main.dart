import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canvas_controller.dart';
import 'canvas_view.dart';
import 'storage.dart';
import 'toolbar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotasApp());
}

class NotasApp extends StatelessWidget {
  const NotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _storage = NotebookStorage();
  CanvasController? _c;
  Timer? _saveTimer;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final nb = await _storage.loadOrCreate();
    final c = CanvasController(nb)..onDocumentChanged = _scheduleSave;
    if (mounted) setState(() => _c = c);
  }

  void _scheduleSave() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _flush);
  }

  Future<void> _flush() async {
    final c = _c;
    if (c == null || !_dirty) return;
    _dirty = false;
    await _storage.save(c.notebook);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _flush();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _flush();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): c.undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): c.redo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            c.redo,
        const SingleActivator(LogicalKeyboardKey.keyP): () => c.setTool(Tool.pen),
        const SingleActivator(LogicalKeyboardKey.keyH): () =>
            c.setTool(Tool.highlighter),
        const SingleActivator(LogicalKeyboardKey.keyL): () => c.setTool(Tool.line),
        const SingleActivator(LogicalKeyboardKey.keyE): () => c.setTool(Tool.eraser),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                NotasToolbar(controller: c),
                Expanded(child: CanvasView(controller: c)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
