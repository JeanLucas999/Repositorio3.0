import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import 'canvas_view.dart';
import 'backup_service.dart';
import 'backup_ui.dart';
import 'dialogs.dart';
import 'drive_auth.dart';
import 'drive_sync.dart';
import 'editor_page.dart';
import 'folders.dart';
import 'models.dart';
import 'pdf_import.dart';
import 'settings.dart';
import 'settings_page.dart';
import 'export_ui.dart';
import 'storage.dart';

/// Tela inicial: seus cadernos.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.storage, required this.settings});

  final NotebookStorage storage;
  final AppSettings settings;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<Notebook>? _books;
  List<Folder> _folders = [];
  String? _cwd; // pasta aberta (null = raiz)

  // seleção: Notebook ou Folder
  final Set<Object> _sel = {};
  bool _selecting = false; // modo seleção: um toque marca/desmarca
  Object? _anchor; // âncora do Shift

  // laço de seleção (mouse), como no Explorer
  final GlobalKey _areaKey = GlobalKey();
  final Map<Object, GlobalKey> _keys = {};
  int? _mPointer;
  Offset? _mStart, _mEnd;
  Set<Object> _mBase = {};

  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load().then((_) => _sync());
  }

  /// Sincroniza com o Drive (se já tiver entrado na conta). Automático: sem
  /// avisos de erro; manual: mostra o resultado.
  Future<void> _sync({bool manual = false}) async {
    if (_syncing || _books == null || !mounted) return;
    await driveAuth.load();
    if (!mounted) return;
    if (!driveAuth.signedIn) {
      setState(() {});
      if (manual) _say('Entre na conta em Configurações > Google Drive.');
      return;
    }
    setState(() => _syncing = true);
    String? msg;
    try {
      final r = await DriveSync(driveAuth, widget.storage).run(_books!, _folders);
      msg = r.summary;
    } catch (e) {
      msg = 'Não consegui sincronizar: ${e.toString().replaceFirst('Exception: ', '')}';
      if (!manual) msg = null;
    }
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _sort();
    });
    if (msg != null && (manual || !msg.startsWith('Tudo'))) _say(msg);
  }

  void _say(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _load() async {
    var list = <Notebook>[];
    var folders = <Folder>[];
    try {
      list = await widget.storage.listNotebooks();
      folders = await widget.storage.loadFolders();
    } catch (_) {}
    // caderno numa pasta que não existe mais volta para a raiz
    final ids = {for (final f in folders) f.id};
    for (final b in list) {
      if (b.folderId != null && !ids.contains(b.folderId)) b.folderId = null;
    }
    if (list.isEmpty && folders.isEmpty) {
      // Primeira vez: já cria um caderno para começar a escrever.
      final nb = Notebook.empty(widget.storage.newId(), 'Meu caderno');
      list = [nb];
      try {
        await widget.storage.save(nb);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _books = list;
        _folders = folders;
      });
    }
  }

  void _sort() => _books?.sort((a, b) => b.modified.compareTo(a.modified));

  /// Itens da pasta aberta: pastas (por nome) e depois cadernos (mais recentes primeiro).
  List<Object> get _items {
    final fs = _folders.where((f) => f.parentId == _cwd).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final bs = (_books ?? const <Notebook>[]).where((b) => b.folderId == _cwd).toList();
    // pastas; depois os favoritos; depois os demais cadernos
    return [
      ...fs,
      ...bs.where((b) => b.favorite),
      ...bs.where((b) => !b.favorite),
    ];
  }

  GlobalKey _keyOf(Object o) => _keys.putIfAbsent(o, GlobalKey.new);

  bool get _inSelectMode => _selecting || _sel.isNotEmpty;

  void _clearSel() {
    _sel.clear();
    _selecting = false;
    _anchor = null;
  }

  // ---------------- abrir / criar ----------------

  Future<void> _open(Notebook nb) async {
    while (_syncing && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EditorPage(
        notebook: nb,
        storage: widget.storage,
        settings: widget.settings,
      ),
    ));
    if (!mounted) return;
    setState(_sort); // o caderno é o mesmo objeto: já traz o que foi escrito
    _sync();
  }

  Future<void> _create() async {
    final res = await newNotebookDialog(context);
    if (res == null || !mounted) return;
    final name = res.name;
    final nb = Notebook.empty(
      widget.storage.newId(),
      name.trim().isEmpty ? 'Novo caderno' : name.trim(),
      res.format,
    )..folderId = _cwd;
    nb.pages.first.background =
        PageBackground.values[widget.settings.newNotebookBackground];
    await widget.storage.save(nb);
    if (!mounted) return;
    setState(() => _books = [nb, ...?_books]);
    await _open(nb);
  }

  Future<void> _newFolder() async {
    final name = await promptText(context, title: 'Nova pasta', confirm: 'Criar');
    if (name == null || name.trim().isEmpty || !mounted) return;
    final f = Folder(
      id: 'fd-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      parentId: _cwd,
    );
    setState(() => _folders.add(f));
    await widget.storage.saveFolders(_folders);
  }

  Future<void> _toggleFavorite(Notebook nb) async {
    nb.favorite = !nb.favorite;
    nb.modified = DateTime.now();
    await widget.storage.save(nb);
    if (mounted) setState(_sort);
  }

  Future<void> _rename(Object it) async {
    final current = it is Notebook ? it.name : (it as Folder).name;
    final name = await promptText(
      context,
      title: it is Notebook ? 'Renomear caderno' : 'Renomear pasta',
      initial: current,
      confirm: 'Salvar',
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    if (it is Notebook) {
      it.name = name.trim();
      it.modified = DateTime.now();
      await widget.storage.save(it);
      if (mounted) setState(_sort);
    } else if (it is Folder) {
      setState(() => it.name = name.trim());
      await widget.storage.saveFolders(_folders);
    }
  }

  Future<void> _import() async {
    final nb = await pickNotasFile(context, widget.storage.newId());
    if (nb == null || !mounted) return;
    nb.folderId = _cwd;
    await widget.storage.save(nb);
    setState(() {
      _books?.add(nb);
      _sort();
    });
  }

  /// Importa um PDF: cada página vira o fundo de uma página do caderno.
  Future<void> _importPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    final f = res?.files.firstOrNull;
    final data = f?.bytes;
    if (f == null || data == null || !mounted) return;
    final progress = ValueNotifier<String>('Preparando…');
    messenger.showSnackBar(SnackBar(
      duration: const Duration(minutes: 5),
      content: ValueListenableBuilder<String>(
        valueListenable: progress,
        builder: (_, v, __) => Text(v),
      ),
    ));
    final name = f.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final nb = await importPdf(
      data,
      id: widget.storage.newId(),
      name: name.isEmpty ? 'PDF' : name,
      onProgress: (d, t) => progress.value = 'Importando página $d de $t…',
    );
    messenger.hideCurrentSnackBar();
    if (nb == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Não consegui abrir esse PDF.')));
      return;
    }
    nb.folderId = _cwd;
    await widget.storage.save(nb);
    if (!mounted) return;
    setState(() => _books = [nb, ...?_books]);
    await _open(nb);
  }

  Future<void> _backup() => showBackupDialog(
        context,
        books: List<Notebook>.of(_books ?? const []),
        folders: List<Folder>.of(_folders),
        spacing: widget.settings.lineSpacing,
      );

  Future<void> _restore() async {
    final books = _books;
    if (books == null) return;
    final r = await pickAndRestore(context, books, _folders, widget.storage);
    if (r == null || !mounted) return;
    setState(_sort);
    _say(r.summary);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SettingsPage(
        settings: widget.settings,
        onBackup: _backup,
        onRestore: _restore,
      ),
    ));
    if (!mounted) return;
    setState(() {});
    _sync();
  }

  // ---------------- apagar / mover ----------------

  Future<void> _deleteItems(List<Object> items) async {
    final nbs = items.whereType<Notebook>().toList();
    final fds = items.whereType<Folder>().toList();
    if (items.isEmpty) return;
    final parts = <String>[
      if (nbs.isNotEmpty) '${nbs.length} ${nbs.length == 1 ? 'caderno' : 'cadernos'}',
      if (fds.isNotEmpty) '${fds.length} ${fds.length == 1 ? 'pasta' : 'pastas'}',
    ];
    final title = items.length == 1
        ? 'Excluir "${items.first is Notebook ? (items.first as Notebook).name : (items.first as Folder).name}"?'
        : 'Excluir ${parts.join(' e ')}?';
    final msg = [
      if (nbs.isNotEmpty) 'Os cadernos e todas as páginas serão apagados. Não dá para desfazer.',
      if (fds.isNotEmpty) 'O que estiver dentro de uma pasta excluída vai para a pasta acima.',
    ].join(' ');
    final ok = await confirmDialog(context, title: title, message: msg);
    if (!ok || !mounted) return;

    for (final nb in nbs) {
      await widget.storage.delete(nb.id);
      _books?.remove(nb);
    }
    if (nbs.isNotEmpty && driveAuth.signedIn) {
      DriveSync(driveAuth, widget.storage).trash(nbs.map((b) => b.id)); // sem esperar
    }
    for (final f in fds) {
      // o conteúdo sobe para a pasta de cima
      for (final b in _books ?? const <Notebook>[]) {
        if (b.folderId == f.id) {
          b.folderId = f.parentId;
          await widget.storage.save(b);
        }
      }
      for (final o in _folders) {
        if (o.parentId == f.id) o.parentId = f.parentId;
      }
      _folders.remove(f);
    }
    if (fds.isNotEmpty) await widget.storage.saveFolders(_folders);
    if (mounted) setState(_clearSel);
  }

  /// Pode mover [items] para a pasta [target]? (uma pasta não entra nela mesma
  /// nem dentro de uma filha.)
  bool _canMove(List<Object> items, String? target) {
    for (final f in items.whereType<Folder>()) {
      if (target == f.id || descendantIds(_folders, f.id).contains(target)) return false;
    }
    return true;
  }

  Future<void> _moveItems(List<Object> items, String? target) async {
    if (!_canMove(items, target)) return;
    var foldersChanged = false;
    for (final it in items) {
      if (it is Notebook) {
        if (it.folderId == target) continue;
        it.folderId = target;
        await widget.storage.save(it);
      } else if (it is Folder) {
        if (it.parentId == target) continue;
        it.parentId = target;
        foldersChanged = true;
      }
    }
    if (foldersChanged) await widget.storage.saveFolders(_folders);
    if (mounted) setState(_clearSel);
  }

  Future<void> _moveDialog(List<Object> items) async {
    final blocked = <String>{
      for (final f in items.whereType<Folder>()) ...{f.id, ...descendantIds(_folders, f.id)},
    };
    // pastas em ordem de árvore, com o nível de cada uma
    final rows = <(Folder, int)>[];
    void walk(String? parent, int depth) {
      final kids = _folders.where((f) => f.parentId == parent).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      for (final f in kids) {
        rows.add((f, depth));
        walk(f.id, depth + 1);
      }
    }

    walk(null, 0);
    final res = await showDialog<({String? id})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mover para'),
        content: SizedBox(
          width: 340,
          height: 360,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Notas (início)'),
                onTap: () => Navigator.pop(ctx, (id: null)),
              ),
              for (final r in rows)
                ListTile(
                  enabled: !blocked.contains(r.$1.id),
                  contentPadding: EdgeInsets.only(left: 16 + 20.0 * r.$2, right: 16),
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(r.$1.name),
                  onTap: () => Navigator.pop(ctx, (id: r.$1.id)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ],
      ),
    );
    if (res != null && mounted) await _moveItems(items, res.id);
  }

  // ---------------- seleção ----------------

  void _tapItem(Object it) {
    final kb = HardwareKeyboard.instance;
    final ctrl = kb.isControlPressed || kb.isMetaPressed;
    final shift = kb.isShiftPressed;
    final items = _items;
    setState(() {
      if (shift && _anchor != null && items.contains(_anchor)) {
        final r = rangeBetween(items, _anchor!, it);
        if (!ctrl) _sel.clear();
        _sel.addAll(r);
      } else if (ctrl || _inSelectMode) {
        if (!_sel.add(it)) _sel.remove(it);
        _anchor = it;
      } else {
        _anchor = it;
        if (it is Folder) {
          _cwd = it.id;
          _clearSel();
        } else if (it is Notebook) {
          // abre fora do setState
          WidgetsBinding.instance.addPostFrameCallback((_) => _open(it));
        }
      }
    });
  }

  void _toggleSelect(Object it) {
    setState(() {
      if (!_sel.add(it)) _sel.remove(it);
      _anchor = it;
      _selecting = true;
    });
  }

  Map<Object, Rect> _itemRects() {
    final area = _areaKey.currentContext?.findRenderObject();
    if (area is! RenderBox || !area.attached) return const {};
    final out = <Object, Rect>{};
    for (final it in _items) {
      final rb = _keys[it]?.currentContext?.findRenderObject();
      if (rb is RenderBox && rb.attached) {
        out[it] = rb.localToGlobal(Offset.zero, ancestor: area) & rb.size;
      }
    }
    return out;
  }

  void _pointerDown(PointerDownEvent e) {
    if (e.kind != PointerDeviceKind.mouse || e.buttons != kPrimaryMouseButton) return;
    final rects = _itemRects();
    if (rects.values.any((r) => r.contains(e.localPosition))) return; // começou num cartão
    final kb = HardwareKeyboard.instance;
    final add = kb.isControlPressed || kb.isShiftPressed || kb.isMetaPressed;
    _mPointer = e.pointer;
    _mStart = e.localPosition;
    _mEnd = e.localPosition;
    _mBase = add ? {..._sel} : {};
    if (!add && _sel.isNotEmpty) setState(_clearSel);
  }

  void _pointerMove(PointerMoveEvent e) {
    if (e.pointer != _mPointer || _mStart == null) return;
    final box = Rect.fromPoints(_mStart!, e.localPosition);
    final hit = box.longestSide < 4
        ? <Object>{}
        : {
            for (final en in _itemRects().entries)
              if (en.value.overlaps(box)) en.key,
          };
    setState(() {
      _mEnd = e.localPosition;
      _sel
        ..clear()
        ..addAll(_mBase)
        ..addAll(hit);
      if (hit.isNotEmpty) _anchor = hit.first;
    });
  }

  void _pointerUp(PointerEvent e) {
    if (e.pointer != _mPointer) return;
    setState(() {
      _mPointer = null;
      _mStart = null;
      _mEnd = null;
    });
  }

  // ---------------- arrastar para uma pasta ----------------

  Widget _draggable(Object it, Widget child) {
    final data = <Object>[
      if (_sel.contains(it)) ..._sel else it,
    ];
    final label = data.length == 1
        ? (it is Notebook ? it.name : (it as Folder).name)
        : '${data.length} itens';
    final feedback = Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
    final desktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final dim = Opacity(opacity: 0.4, child: child);
    return desktop
        ? Draggable<List<Object>>(
            data: data,
            feedback: feedback,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            childWhenDragging: dim,
            child: child,
          )
        : LongPressDraggable<List<Object>>(
            data: data,
            feedback: feedback,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            childWhenDragging: dim,
            child: child,
          );
  }

  // ---------------- tela ----------------

  PreferredSizeWidget _appBar(BuildContext context) {
    final path = folderPath(_folders, _cwd);
    // a trilha fica nos dois modos: a altura da barra não muda no meio de um laço
    final PreferredSizeWidget? bottom = path.isEmpty
        ? null
        : PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: SizedBox(height: 40, child: _breadcrumb(path)),
          );
    if (_inSelectMode) {
      final items = _items;
      return AppBar(
        bottom: bottom,
        leading: IconButton(
          tooltip: 'Cancelar seleção',
          icon: const Icon(Icons.close),
          onPressed: () => setState(_clearSel),
        ),
        title: Text(_sel.isEmpty
            ? 'Selecione itens'
            : '${_sel.length} ${_sel.length == 1 ? 'selecionado' : 'selecionados'}'),
        actions: [
          IconButton(
            tooltip: 'Selecionar tudo',
            icon: const Icon(Icons.select_all),
            onPressed: () => setState(() => _sel.addAll(items)),
          ),
          IconButton(
            tooltip: 'Mover para…',
            icon: const Icon(Icons.drive_file_move_outline),
            onPressed: _sel.isEmpty ? null : () => _moveDialog(_sel.toList()),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: _sel.isEmpty ? null : () => _deleteItems(_sel.toList()),
          ),
        ],
      );
    }
    return AppBar(
      title: Text(path.isEmpty ? 'Gireli Notes' : path.last.name),
      leading: path.isEmpty
          ? null
          : IconButton(
              tooltip: 'Voltar',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _cwd = path.last.parentId),
            ),
      bottom: bottom,
      actions: [
        IconButton(
          tooltip: 'Selecionar (Ctrl/Shift + clique, ou arraste um laço)',
          icon: const Icon(Icons.checklist),
          onPressed: () => setState(() => _selecting = true),
        ),
        IconButton(
          tooltip: 'Nova pasta',
          icon: const Icon(Icons.create_new_folder_outlined),
          onPressed: _newFolder,
        ),
        IconButton(
          tooltip: 'Importar caderno (.notas)',
          icon: const Icon(Icons.file_open_outlined),
          onPressed: _import,
        ),
        IconButton(
          tooltip: 'Importar PDF',
          icon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: _importPdf,
        ),
        if (driveAuth.signedIn)
          IconButton(
            tooltip: 'Sincronizar com o Drive',
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync_outlined),
            onPressed: _syncing ? null : () => _sync(manual: true),
          ),
        IconButton(
          tooltip: 'Configurações',
          icon: const Icon(Icons.settings_outlined),
          onPressed: _openSettings,
        ),
      ],
    );
  }

  /// Trilha "Notas › Pasta › Subpasta"; soltar itens numa etapa move para ela.
  Widget _breadcrumb(List<Folder> path) {
    Widget crumb(String label, String? id) => DragTarget<List<Object>>(
          onWillAcceptWithDetails: (d) => _canMove(d.data, id),
          onAcceptWithDetails: (d) => _moveItems(d.data, id),
          builder: (context, cand, _) => TextButton(
            style: cand.isNotEmpty
                ? TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(40))
                : null,
            onPressed: () => setState(() {
              _cwd = id;
              _clearSel();
            }),
            child: Text(label),
          ),
        );
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        crumb('Notas', null),
        for (final f in path) ...[
          const Icon(Icons.chevron_right, size: 18),
          crumb(f.name, f.id),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = _books;
    final items = _items;
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _cwd == null && !_inSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (_inSelectMode) {
            _clearSel();
          } else {
            _cwd = folderPath(_folders, _cwd).lastOrNull?.parentId;
          }
        });
      },
      child: Scaffold(
        appBar: _appBar(context),
        floatingActionButton: books == null || _inSelectMode
            ? null
            : FloatingActionButton.extended(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Novo caderno'),
              ),
        body: books == null
            ? const Center(child: CircularProgressIndicator())
            : Listener(
                key: _areaKey,
                behavior: HitTestBehavior.translucent,
                onPointerDown: _pointerDown,
                onPointerMove: _pointerMove,
                onPointerUp: _pointerUp,
                onPointerCancel: _pointerUp,
                child: Stack(
                  children: [
                    items.isEmpty
                        ? Center(
                            child: Text(_cwd == null
                                ? 'Nenhum caderno ainda. Toque em "Novo caderno".'
                                : 'Pasta vazia.'),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final it = items[i];
                              final selected = _sel.contains(it);
                              final Widget card;
                              if (it is Folder) {
                                card = _FolderCard(
                                  folder: it,
                                  count: _folders.where((f) => f.parentId == it.id).length +
                                      books.where((b) => b.folderId == it.id).length,
                                  selected: selected,
                                  onTap: () => _tapItem(it),
                                  onRename: () => _rename(it),
                                  onDelete: () => _deleteItems([it]),
                                  onSelect: () => _toggleSelect(it),
                                  canAccept: (d) => _canMove(d, it.id),
                                  onAccept: (d) => _moveItems(d, it.id),
                                );
                              } else {
                                final nb = it as Notebook;
                                card = _NotebookCard(
                                  notebook: nb,
                                  selected: selected,
                                  onOpen: () => _tapItem(nb),
                                  onRename: () => _rename(nb),
                                  onFavorite: () => _toggleFavorite(nb),
                                  onDelete: () => _deleteItems([nb]),
                                  onSelect: () => _toggleSelect(nb),
                                  onMove: () => _moveDialog([nb]),
                                  onExport: () => showExportDialog(context, nb,
                                      spacing: widget.settings.lineSpacing),
                                );
                              }
                              return KeyedSubtree(
                                key: _keyOf(it),
                                child: _draggable(it, card),
                              );
                            },
                          ),
                    if (_mStart != null && _mEnd != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _MarqueePainter(
                              Rect.fromPoints(_mStart!, _mEnd!),
                              scheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Retângulo do laço de seleção.
class _MarqueePainter extends CustomPainter {
  _MarqueePainter(this.rect, this.color);
  final Rect rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(rect, Paint()..color = color.withAlpha(40));
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_MarqueePainter old) => old.rect != rect || old.color != color;
}

String _when(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'hoje ${two(d.hour)}:${two(d.minute)}';
  if (diff == 1) return 'ontem';
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({
    required this.notebook,
    required this.selected,
    required this.onOpen,
    required this.onRename,
    required this.onFavorite,
    required this.onDelete,
    required this.onSelect,
    required this.onMove,
    required this.onExport,
  });

  final Notebook notebook;
  final VoidCallback onFavorite;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onSelect;
  final VoidCallback onMove;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = notebook.pages.length;
    return Card(
      elevation: 0,
      color: selected ? scheme.primary.withAlpha(30) : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Stack(children: [
          Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: notebook.pageSize.width / notebook.pageSize.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _ThumbPainter(notebook.pages.first, notebook.pageSize),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 2, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notebook.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '$pages ${pages == 1 ? 'página' : 'páginas'} · ${_when(notebook.modified)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opções',
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) {
                      if (v == 'rename') {
                        onRename();
                      } else if (v == 'fav') {
                        onFavorite();
                      } else if (v == 'export') {
                        onExport();
                      } else if (v == 'select') {
                        onSelect();
                      } else if (v == 'move') {
                        onMove();
                      } else {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'fav',
                        child: Text(notebook.favorite ? 'Tirar dos favoritos' : 'Favoritar'),
                      ),
                      const PopupMenuItem(value: 'rename', child: Text('Renomear')),
                      const PopupMenuItem(value: 'select', child: Text('Selecionar')),
                      const PopupMenuItem(value: 'move', child: Text('Mover para…')),
                      const PopupMenuItem(value: 'export', child: Text('Exportar…')),
                      const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
          if (selected)
            Positioned(
              top: 8,
              left: 8,
              child: Icon(Icons.check_circle, color: scheme.primary, size: 22),
            ),
          if (notebook.favorite)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: 'Tirar dos favoritos',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 22),
                onPressed: onFavorite,
              ),
            ),
        ]),
      ),
    );
  }
}

/// Cartão de pasta: abre ao tocar e recebe cadernos/pastas arrastados.
class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onSelect,
    required this.canAccept,
    required this.onAccept,
  });

  final Folder folder;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onSelect;
  final bool Function(List<Object>) canAccept;
  final void Function(List<Object>) onAccept;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<List<Object>>(
      onWillAcceptWithDetails: (d) => canAccept(d.data),
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, cand, _) {
        final hot = cand.isNotEmpty;
        return Card(
          elevation: 0,
          color: hot || selected ? scheme.primary.withAlpha(30) : scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: hot || selected ? scheme.primary : scheme.outlineVariant,
              width: hot || selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: Icon(Icons.folder_rounded, size: 84, color: scheme.primary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 2, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  folder.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  count == 0
                                      ? 'vazia'
                                      : '$count ${count == 1 ? 'item' : 'itens'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opções',
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (v) {
                              if (v == 'rename') {
                                onRename();
                              } else if (v == 'select') {
                                onSelect();
                              } else {
                                onDelete();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'rename', child: Text('Renomear')),
                              PopupMenuItem(value: 'select', child: Text('Selecionar')),
                              PopupMenuItem(value: 'delete', child: Text('Excluir')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (selected)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(Icons.check_circle, color: scheme.primary, size: 22),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Miniatura da primeira página (marca-texto atrás da tinta, como no editor).
class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.page, this.pageSize);

  final NotePage page;
  final Size pageSize;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.save();
    canvas.scale(size.width / pageSize.width);
    canvas.clipRect(Offset.zero & pageSize);
    paintPageContent(canvas, page, Offset.zero & pageSize, () {});
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => true;
}
