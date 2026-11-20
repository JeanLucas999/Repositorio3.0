import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canvas_controller.dart';
import 'canvas_view.dart';
import 'color_panel.dart';
import 'dialogs.dart';
import 'models.dart';
import 'pages_sidebar.dart';
import 'settings.dart';
import 'settings_page.dart';
import 'shape_bar.dart';
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
  bool _pagesOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c = CanvasController(widget.notebook, widget.settings)
      ..onDocumentChanged = _scheduleSave;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  /// Segurar a tecla da mãozinha (Espaço por padrão) move a página com a caneta.
  bool _onKey(KeyEvent e) {
    if (e.logicalKey.keyId != widget.settings.panKeyId) return false;
    if (e is KeyDownEvent) {
      if (ModalRoute.of(context)?.isCurrent ?? false) c.setPanHeld(true);
    } else if (e is KeyUpEvent) {
      c.setPanHeld(false);
    }
    return false; // não consome: atalhos normais continuam
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
    if (state != AppLifecycleState.resumed) {
      c.setPanHeld(false);
      _flush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _saveTimer?.cancel();
    _flush();
    c.dispose();
    super.dispose();
  }

  void _openShapes() => c.setShape(c.shapeKind);

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
          const SingleActivator(LogicalKeyboardKey.keyF): () => c.setTool(Tool.fountain),
          const SingleActivator(LogicalKeyboardKey.keyH): () =>
              c.setTool(Tool.highlighter),
          const SingleActivator(LogicalKeyboardKey.keyL): () => _openShapes(),
          const SingleActivator(LogicalKeyboardKey.equal, control: true): () => c.zoomBy(1.2),
          const SingleActivator(LogicalKeyboardKey.equal, control: true, shift: true):
              () => c.zoomBy(1.2),
          const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): () =>
              c.zoomBy(1.2),
          const SingleActivator(LogicalKeyboardKey.minus, control: true): () => c.zoomBy(1 / 1.2),
          const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): () =>
              c.zoomBy(1 / 1.2),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => c.scrollByPx(-120),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => c.scrollByPx(120),
          const SingleActivator(LogicalKeyboardKey.keyE): () => c.setTool(Tool.eraser),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeFocus(
                    child: NotasToolbar(
                      controller: c,
                      onBack: _close,
                      onRename: _rename,
                      onSettings: _openSettings,
                      pagesOpen: _pagesOpen,
                      onPages: () => setState(() => _pagesOpen = !_pagesOpen),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_pagesOpen && !c.notebook.infinite)
                          ExcludeFocus(
                            child: PagesSidebar(
                              controller: c,
                              onClose: () => setState(() => _pagesOpen = false),
                            ),
                          ),
                        Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(child: CanvasView(controller: c)),
                            if (!c.notebook.infinite)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 16,
                                child: Center(child: ExcludeFocus(child: _PagePill(controller: c))),
                              ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 72,
                              child: IgnorePointer(
                                child: ListenableBuilder(
                                  listenable: c,
                                  builder: (context, _) => AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: (c.panActive && !c.settings.shiftHintSeen)
                                        ? Center(
                                            key: const ValueKey('shift-hint'),
                                            child: _Hint('Dica: segure Shift para mover só na horizontal ou vertical'),
                                          )
                                        : const SizedBox.shrink(key: ValueKey('none')),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 8,
                              child: ListenableBuilder(
                                listenable: c,
                                builder: (context, _) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (c.showOptions && c.showColors && c.usesColor)
                                      Center(
                                        child: ExcludeFocus(child: ColorPanel(controller: c)),
                                      ),
                                    if (c.tool == Tool.shape) ...[
                                      if (c.showColors) const SizedBox(height: 8),
                                      Center(
                                        child: ExcludeFocus(child: ShapeBar(controller: c)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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


/// Dica discreta e passageira.
class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.inverseSurface.withAlpha(215),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: scheme.onInverseSurface),
        ),
      ),
    );
  }
}
