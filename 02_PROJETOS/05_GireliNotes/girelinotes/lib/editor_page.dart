import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canvas_controller.dart';
import 'canvas_view.dart';
import 'dialogs.dart';
import 'models.dart';
import 'settings.dart';
import 'settings_page.dart';
import 'storage.dart';
import 'toolbar.dart';

/// Tela de um caderno: barra + página + indicador de páginas.
class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.notebook,
    required this.storage,
    required this.settings,
  });

  final Notebook notebook;
  final NotebookStorage storage;
  final AppSettings settings;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with WidgetsBindingObserver {
  late final CanvasController c;
  Timer? _saveTimer;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c = CanvasController(widget.notebook, widget.settings)
      ..onDocumentChanged = _scheduleSave;
  }

  void _scheduleSave() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _flush);
  }

  Future<void> _flush() async {
    if (!_dirty) return;
    _dirty = false;
    await widget.storage.save(widget.notebook);
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
    c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    _saveTimer?.cancel();
    await _flush();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _rename() async {
    final name = await promptText(
      context,
      title: 'Nome do caderno',
      initial: c.notebook.name,
      confirm: 'Salvar',
    );
    if (name != null) c.renameNotebook(name);
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SettingsPage(settings: widget.settings),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: CallbackShortcuts(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NotasToolbar(
                    controller: c,
                    onBack: _close,
                    onRename: _rename,
                    onSettings: _openSettings,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: CanvasView(controller: c)),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 16,
                          child: Center(child: _PagePill(controller: c)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador flutuante de páginas: anterior, "2 / 5", próxima e nova página.
class _PagePill extends StatelessWidget {
  const _PagePill({required this.controller});
  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final n = c.notebook.pages.length;
        return Material(
          elevation: 3,
          color: scheme.surfaceContainerHigh,
          shape: const StadiumBorder(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Página anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: c.pageIndex > 0 ? () => c.goToPage(c.pageIndex - 1) : null,
              ),
              Text('${c.pageIndex + 1} / $n', style: Theme.of(context).textTheme.labelLarge),
              IconButton(
                tooltip: 'Próxima página',
                icon: const Icon(Icons.chevron_right),
                onPressed: c.pageIndex < n - 1 ? () => c.goToPage(c.pageIndex + 1) : null,
              ),
              IconButton(
                tooltip: 'Nova página',
                icon: const Icon(Icons.add),
                onPressed: c.addPage,
              ),
            ],
          ),
        );
      },
    );
  }
}
