import 'package:flutter/material.dart';

import 'canvas_view.dart';
import 'dialogs.dart';
import 'editor_page.dart';
import 'models.dart';
import 'settings.dart';
import 'settings_page.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var list = <Notebook>[];
    try {
      list = await widget.storage.listNotebooks();
    } catch (_) {}
    if (list.isEmpty) {
      // Primeira vez: já cria um caderno para começar a escrever.
      final nb = Notebook.empty(widget.storage.newId(), 'Meu caderno');
      list = [nb];
      try {
        await widget.storage.save(nb);
      } catch (_) {}
    }
    if (mounted) setState(() => _books = list);
  }

  void _sort() => _books?.sort((a, b) => b.modified.compareTo(a.modified));

  Future<void> _open(Notebook nb) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EditorPage(
        notebook: nb,
        storage: widget.storage,
        settings: widget.settings,
      ),
    ));
    if (!mounted) return;
    setState(_sort); // o caderno é o mesmo objeto: já traz o que foi escrito
  }

  Future<void> _create() async {
    final name = await promptText(
      context,
      title: 'Novo caderno',
      initial: 'Novo caderno',
      confirm: 'Criar',
    );
    if (name == null || !mounted) return;
    final nb = Notebook.empty(
      widget.storage.newId(),
      name.trim().isEmpty ? 'Novo caderno' : name.trim(),
    );
    await widget.storage.save(nb);
    if (!mounted) return;
    setState(() => _books = [nb, ...?_books]);
    await _open(nb);
  }

  Future<void> _rename(Notebook nb) async {
    final name = await promptText(
      context,
      title: 'Renomear caderno',
      initial: nb.name,
      confirm: 'Salvar',
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    nb.name = name.trim();
    nb.modified = DateTime.now();
    await widget.storage.save(nb);
    if (mounted) setState(_sort);
  }

  Future<void> _delete(Notebook nb) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir "${nb.name}"?',
      message: 'O caderno e todas as páginas serão apagados. Não dá para desfazer.',
    );
    if (!ok || !mounted) return;
    await widget.storage.delete(nb.id);
    if (mounted) setState(() => _books?.remove(nb));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SettingsPage(settings: widget.settings),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final books = _books;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: books == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Novo caderno'),
            ),
      body: books == null
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
              ? const Center(child: Text('Nenhum caderno ainda. Toque em "Novo caderno".'))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, i) => _NotebookCard(
                    notebook: books[i],
                    onOpen: () => _open(books[i]),
                    onRename: () => _rename(books[i]),
                    onDelete: () => _delete(books[i]),
                  ),
                ),
    );
  }
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
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final Notebook notebook;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = notebook.pages.length;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: kPageSize.width / kPageSize.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _ThumbPainter(notebook.pages.first),
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
                    onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Renomear')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniatura da primeira página (marca-texto atrás da tinta, como no editor).
class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.page);

  final NotePage page;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.save();
    canvas.scale(size.width / kPageSize.width);
    canvas.clipRect(Offset.zero & kPageSize);
    for (final s in page.strokes) {
      if (s.highlighter) paintStroke(canvas, s);
    }
    for (final s in page.strokes) {
      if (!s.highlighter) paintStroke(canvas, s);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => true;
}
