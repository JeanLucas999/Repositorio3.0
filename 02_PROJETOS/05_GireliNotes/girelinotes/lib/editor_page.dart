import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

import 'canvas_controller.dart';
import 'canvas_view.dart';
import 'color_panel.dart';
import 'dialogs.dart';
import 'models.dart';
import 'export_ui.dart';
import 'bg_remove_dialog.dart';
import 'graph.dart';
import 'graph_dialog.dart';
import 'image_search_dialog.dart';
import 'pages_sidebar.dart';
import 'note_dialog.dart';
import 'pen_tune.dart';
import 'selection_bar.dart';
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
  final SaveStatus _saveStatus = SaveStatus();
  bool _pagesOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c = CanvasController(widget.notebook, widget.settings)
      ..onDocumentChanged = _scheduleSave;
    HardwareKeyboard.instance.addHandler(_onKey);
    widget.settings.addListener(_onSettings);
  }

  late ToolbarPos _pos = widget.settings.toolbarPos;

  void _onSettings() {
    if (mounted && _pos != widget.settings.toolbarPos) {
      setState(() => _pos = widget.settings.toolbarPos);
    }
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
    _saveStatus.set(pending: true);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _flush);
  }

  Future<void> _flush() async {
    if (!_dirty) return;
    _dirty = false;
    _saveStatus.set(saving: true);
    try {
      await widget.storage.save(widget.notebook);
      _saveStatus.set(last: DateTime.now(), pending: _dirty);
    } catch (_) {
      _saveStatus.set(failed: true, pending: true);
      rethrow;
    }
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
    widget.settings.removeListener(_onSettings);
    _saveTimer?.cancel();
    _flush();
    c.dispose();
    _saveStatus.dispose();
    super.dispose();
  }

  /// Botão Post-it: pede o texto e cria a nota no centro da área visível.
  Future<void> _newNote() async {
    final r = await showNoteDialog(context);
    if (r == null) return;
    c.insertNote(r.text, r.color, r.size);
  }

  /// Edita o post-it selecionado (texto, cor, tamanho).
  Future<void> _editNote() async {
    if (c.selImages.length != 1 || !c.selImages.first.isNote) return;
    final n = c.selImages.first;
    final r = await showNoteDialog(
      context,
      text: n.text ?? '',
      color: n.noteColor,
      size: n.fontSize,
      isNew: false,
    );
    if (r == null) return;
    c.updateNote(n, text: r.text, color: r.color, fontSize: r.size);
  }

  /// Botão: escolhe uma ou mais imagens do computador.
  /// Cria um gráfico de função no caderno.
  Future<void> _newGraph() async {
    final spec = await showGraphDialog(context);
    if (spec == null || !mounted) return;
    final png = await renderGraphPng(spec);
    await c.insertImageBytes(png, graph: spec.encode());
  }

  /// Edita o gráfico selecionado.
  Future<void> _editGraph() async {
    if (c.selStrokes.isNotEmpty || c.selImages.length != 1 || !c.selImages.first.isGraph) return;
    final im = c.selImages.first;
    final spec = await showGraphDialog(context, initial: GraphSpec.decode(im.graph));
    if (spec == null || !mounted) return;
    final png = await renderGraphPng(spec);
    await c.replaceImageBytes(im, png, graph: spec.encode());
  }

  /// Remove o fundo da imagem selecionada (varinha mágica).
  Future<void> _removeBg() async {
    if (c.selStrokes.isNotEmpty || c.selImages.length != 1 || c.selImages.first.isNote) return;
    final im = c.selImages.first;
    final out = await showBgRemover(context, im.bytes);
    if (out == null || !mounted) return;
    if (!await c.replaceImageBytes(im, out) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Não consegui aplicar.')));
    }
  }

  /// Busca imagens na internet e coloca a escolhida no caderno.
  Future<void> _searchImage() async {
    final pick = await showImageSearch(context);
    if (pick == null || !mounted) return;
    final ok = await c.insertImageBytes(pick.bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(ok ? 'Fonte: ${pick.credit}' : 'Não consegui usar essa imagem.'),
      ));
  }

  Future<void> _pickImage() async {
    try {
      final r = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: true, withData: true);
      if (r == null) return;
      for (final f in r.files) {
        final b = f.bytes;
        if (b != null) await c.insertImageBytes(b);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Não consegui abrir a imagem.')));
      }
    }
  }

  // Copiar/recortar: troca o conteúdo da área de transferência do sistema, para o
  // Ctrl+V colar o que foi copiado aqui e não uma imagem antiga de outro app.
  void _copy() {
    if (!c.hasSel) return;
    c.copySelection();
    Clipboard.setData(const ClipboardData(text: 'notas'));
  }

  void _cut() {
    if (!c.hasSel) return;
    c.cutSelection();
    Clipboard.setData(const ClipboardData(text: 'notas'));
  }

  /// Ctrl+V: cola a imagem que está na área de transferência.
  Future<void> _paste() async {
    try {
      final b = await Pasteboard.image;
      if (b != null && b.isNotEmpty) {
        await c.insertImageBytes(b);
      } else {
        c.pasteSelection(); // o que foi copiado com o laço
      }
    } catch (_) {}
  }

  void _openShapes() => c.openShapes();

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
    final pos = _pos;
    final bottom = pos == ToolbarPos.bottom;
    final bar = ExcludeFocus(
      child: NotasToolbar(
        controller: c,
        onBack: _close,
        onRename: _rename,
        saveStatus: _saveStatus,
        onSettings: _openSettings,
        pagesOpen: _pagesOpen,
        onPages: () => setState(() => _pagesOpen = !_pagesOpen),
        onExport: () => showExportDialog(context, c.notebook, spacing: widget.settings.lineSpacing),
        pos: pos,
        onImage: _pickImage,
        onSearchImage: _searchImage,
      ),
    );
    final body = Expanded(
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
                              top: bottom ? null : 8,
                              bottom: bottom ? 8 : null,
                              child: ListenableBuilder(
                                listenable: c,
                                builder: (context, _) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (c.tool == Tool.select)
                                      Center(child: ExcludeFocus(child: SelectionBar(controller: c, onEditNote: _editNote, onRemoveBg: _removeBg, onEditGraph: _editGraph))),
                                    if (c.tool == Tool.select &&
                                        c.showSelColors &&
                                        c.hasSel &&
                                        c.selStrokes.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Center(
                                        child: ExcludeFocus(
                                          child: ColorPanel(controller: c, forSelection: true),
                                        ),
                                      ),
                                    ],
                                    if (c.showOptions && c.showTune && c.isPenTool)
                                      Center(
                                        child: ExcludeFocus(child: PenTunePanel(controller: c)),
                                      ),
                                    if (c.showOptions && c.showColors && c.usesColor)
                                      Center(
                                        child: ExcludeFocus(child: ColorPanel(controller: c)),
                                      ),
                                    if (c.tool == Tool.shape) ...[
                                      if (c.showColors) const SizedBox(height: 8),
                                      Center(
                                        child: ExcludeFocus(child: ShapeBar(controller: c, onNote: _newNote)),
                                      ),
                                      if (c.showShapeLib) ...[
                                        const SizedBox(height: 8),
                                        Center(
                                          child: ExcludeFocus(child: ShapeLibrary(controller: c, onGraph: _newGraph)),
                                        ),
                                      ],
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
                  );
    final Widget layout;
    switch (pos) {
      case ToolbarPos.top:
        layout = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [bar, body]);
      case ToolbarPos.bottom:
        layout = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [body, bar]);
      case ToolbarPos.left:
        layout = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [bar, Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [NotasOptions(controller: c), body]))]);
      case ToolbarPos.right:
        layout = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [NotasOptions(controller: c), body])), bar]);
    }
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
          // 1, 2, 3: caneta, tinteiro e pincel
          const SingleActivator(LogicalKeyboardKey.digit1): () => c.setTool(Tool.pen),
          const SingleActivator(LogicalKeyboardKey.numpad1): () => c.setTool(Tool.pen),
          const SingleActivator(LogicalKeyboardKey.digit2): () => c.setTool(Tool.fountain),
          const SingleActivator(LogicalKeyboardKey.numpad2): () => c.setTool(Tool.fountain),
          const SingleActivator(LogicalKeyboardKey.digit3): () => c.setTool(Tool.brush),
          const SingleActivator(LogicalKeyboardKey.numpad3): () => c.setTool(Tool.brush),
          // F: a última caneta usada, como se tocasse no botão de caneta da barra
          const SingleActivator(LogicalKeyboardKey.keyF): c.selectPen,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
              showExportDialog(context, c.notebook, spacing: widget.settings.lineSpacing),
          const SingleActivator(LogicalKeyboardKey.keyV, control: true): _paste,
          const SingleActivator(LogicalKeyboardKey.keyV): () => c.selectTool(Tool.select),
          const SingleActivator(LogicalKeyboardKey.delete): c.deleteSelection,
          const SingleActivator(LogicalKeyboardKey.backspace): c.deleteSelection,
          const SingleActivator(LogicalKeyboardKey.escape): c.clearSelection,
          const SingleActivator(LogicalKeyboardKey.keyC, control: true): _copy,
          const SingleActivator(LogicalKeyboardKey.keyX, control: true): _cut,
          const SingleActivator(LogicalKeyboardKey.keyD, control: true): c.duplicateSelection,
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
              child: layout,
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
