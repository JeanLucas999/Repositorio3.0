import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'canvas_view.dart';
import 'dialogs.dart';
import 'models.dart';
import 'pdf_text.dart';
import 'review_page.dart';

/// Aba lateral com miniaturas de todas as páginas. Tocar numa miniatura leva
/// até a página; a página ativa fica com borda azul.
class PagesSidebar extends StatefulWidget {
  const PagesSidebar({super.key, required this.controller, required this.onClose});

  final CanvasController controller;
  final VoidCallback onClose;

  static const double width = 148;

  @override
  State<PagesSidebar> createState() => _PagesSidebarState();
}

class _PagesSidebarState extends State<PagesSidebar> {
  static const double _itemExtent = 196;

  final ScrollController _scroll = ScrollController();
  Timer? _debounce;
  final Map<NotePage, int> _revs = {}; // por página: só a que mudou repinta a miniatura
  int _revAll = 0;
  final _ThumbCache _thumbs = _ThumbCache();
  int _lastIndex = -1;
  int _tab = 0; // 0 páginas, 1 favoritas, 2 buscar
  final TextEditingController _q = TextEditingController();
  Timer? _searchDebounce;
  List<SearchHit> _hits = const [];
  final ScrollController _favScroll = ScrollController();

  CanvasController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onController);
    c.committed.addListener(_onCommit);
    _lastIndex = c.pageIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible(animate: false));
  }

  @override
  void dispose() {
    c.removeListener(_onController);
    c.committed.removeListener(_onCommit);
    _debounce?.cancel();
    _scroll.dispose();
    _favScroll.dispose();
    _q.dispose();
    _searchDebounce?.cancel();
    _thumbs.clear();
    c.searchRects = {};
    WidgetsBinding.instance.addPostFrameCallback((_) => c.setSearchRects({}));
    super.dispose();
  }

  void _onCommit() {
    _debounce?.cancel();
    _dirty.add(c.page);
    _flushThumbs();
  }

  final Set<NotePage> _dirty = {};

  void _flushThumbs() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        for (final p in _dirty) {
          _revs[p] = (_revs[p] ?? 0) + 1;
        }
        _dirty.clear();
      });
    });
  }

  void _onController() {
    if (!mounted) return;
    setState(() {});
    if (c.pageIndex != _lastIndex) {
      // a página que ficou para trás pode ter mudado (ex.: item levado a outra)
      if (_lastIndex >= 0 && _lastIndex < c.notebook.pages.length) {
        final left = c.notebook.pages[_lastIndex];
        if (_thumbs.changed(left)) {
          _dirty.add(left);
          _flushThumbs();
        }
      }
      _lastIndex = c.pageIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
    }
  }

  void _ensureVisible({bool animate = true}) {
    if (!mounted || _tab != 0 || !_scroll.hasClients) return;
    final pos = _scroll.position;
    final top = c.pageIndex * _itemExtent;
    final bottom = top + _itemExtent;
    double? target;
    if (top < pos.pixels) {
      target = top;
    } else if (bottom > pos.pixels + pos.viewportDimension) {
      target = bottom - pos.viewportDimension;
    }
    if (target == null) return;
    target = target.clamp(0.0, pos.maxScrollExtent).toDouble();
    if (animate) {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(target);
    }
  }

  Future<void> _editTitle(int i) async {
    final t = await promptText(
      context,
      title: 'Título da página favorita',
      initial: c.notebook.pages[i].mark ?? '',
      confirm: 'Salvar',
    );
    if (t != null && mounted) c.setMarkTitle(i, t);
  }

  Future<void> _deletePage(int i) async {
    final pages = c.notebook.pages;
    final ok = await confirmDialog(
      context,
      title: pages.length > 1 ? 'Excluir página ${i + 1}?' : 'Esvaziar página?',
      message: 'Essa ação não pode ser desfeita.',
      confirm: pages.length > 1 ? 'Excluir' : 'Esvaziar',
    );
    if (ok) c.deletePageAt(i);
  }

  Widget _tabButton(int tab, IconData icon, IconData selectedIcon, String tip) => IconButton(
        tooltip: tip,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(34, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        isSelected: _tab == tab,
        icon: Icon(icon, size: 21),
        selectedIcon: Icon(selectedIcon, size: 21),
        onPressed: () {
          setState(() => _tab = tab);
          if (tab == 2) {
            _runSearch();
          } else {
            c.setSearchRects({}); // tira os destaques da página
          }
        },
      );

  void _onQuery(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  void _runSearch() {
    if (!mounted) return;
    final hits = searchNotebook(c.notebook, _q.text);
    final byPage = <int, List<Rect>>{};
    for (final h in hits) {
      byPage.putIfAbsent(h.pageIndex, () => []).addAll(h.rects);
    }
    setState(() => _hits = hits);
    c.setSearchRects(byPage);
  }

  Widget _searchBody(ColorScheme scheme) {
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline);
    String? note;
    if (!isPdfNotebook(c.notebook)) {
      note = 'A busca funciona em PDFs importados.';
    } else if (!hasSearchableText(c.notebook)) {
      note = 'Este PDF não tem texto pesquisável. Se ele foi importado antes desta versão, importe de novo.';
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: TextField(
            controller: _q,
            enabled: note == null,
            onChanged: _onQuery,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar no PDF',
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 18),
              prefixIconConstraints: const BoxConstraints(minWidth: 32),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
        Expanded(
          child: note != null || _hits.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    note ?? (_q.text.trim().isEmpty ? 'Digite uma palavra.' : 'Nada encontrado.'),
                    textAlign: TextAlign.center,
                    style: small,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  itemCount: _hits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final h = _hits[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => c.goToPage(h.pageIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Página ${h.pageIndex + 1}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 12, height: 1.25),
                                children: [
                                  TextSpan(text: h.before.isEmpty ? '' : '${h.before} '),
                                  TextSpan(
                                    text: h.match,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      backgroundColor: Color(0x66FF9800),
                                    ),
                                  ),
                                  TextSpan(text: h.after.isEmpty ? '' : ' ${h.after}'),
                                ],
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = c.notebook.pages;
    final marked = c.markedPages;
    final showing = _tab == 0 ? [for (var i = 0; i < pages.length; i++) i] : marked;
    return Material(
      color: scheme.surfaceContainer,
      child: SizedBox(
        width: PagesSidebar.width,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  _tabButton(0, Icons.grid_view_outlined, Icons.grid_view, 'Páginas'),
                  _tabButton(1, Icons.star_outline_rounded, Icons.star_rounded, 'Favoritas'),
                  _tabButton(2, Icons.search, Icons.search, 'Buscar no PDF'),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                _tab == 0
                    ? '${pages.length} ${pages.length == 1 ? 'página' : 'páginas'}'
                    : _tab == 1
                        ? '${marked.length} ${marked.length == 1 ? 'favorita' : 'favoritas'}'
                        : '${_hits.length} ${_hits.length == 1 ? 'resultado' : 'resultados'}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: _tab == 2
                  ? _searchBody(scheme)
                  : (_tab == 1 && marked.isEmpty)
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Toque na estrela de uma página para marcá-la como favorita.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.outline),
                      ),
                    )
                  : ListView.builder(
                      key: ValueKey(_tab),
                      controller: _tab == 0 ? _scroll : _favScroll,
                      itemExtent: _itemExtent,
                      itemCount: showing.length,
                      itemBuilder: (context, n) {
                        final i = showing[n];
                        final mk = pages[i].mark;
                        return _Thumb(
                          page: pages[i],
                          pageSize: c.notebook.pageSize,
                          spacing: c.settings.lineSpacing,
                          cache: _thumbs,
                          index: i,
                          label: (mk != null && mk.isNotEmpty) ? '${i + 1} · $mk' : '${i + 1}',
                          selected: i == c.pageIndex,
                          marked: mk != null,
                          rev: _revAll + (_revs[pages[i]] ?? 0),
                          onTap: () => c.goToPage(i),
                          onStar: () => c.toggleMark(i),
                          onEdit: _tab == 1 ? () => _editTitle(i) : null,
                          onDelete: () => _deletePage(i),
                        );
                      },
                    ),
            ),
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Nova página',
                    icon: const Icon(Icons.add),
                    onPressed: c.addPage,
                  ),
                  IconButton(
                    tooltip: 'Revisão: trechos marcados com marca-texto',
                    icon: const Icon(Icons.auto_stories_outlined),
                    onPressed: () => showReview(context, c),
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

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.page,
    required this.index,
    required this.selected,
    required this.rev,
    required this.onTap,
    required this.onDelete,
    required this.pageSize,
    required this.spacing,
    required this.cache,
    required this.label,
    required this.marked,
    required this.onStar,
    this.onEdit,
  });

  final String label;
  final bool marked;
  final VoidCallback onStar;
  final VoidCallback? onEdit;

  final double spacing;
  final _ThumbCache cache;
  final Size pageSize;
  final VoidCallback onDelete;
  final NotePage page;
  final int index;
  final bool selected;
  final int rev;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: pageSize.width / pageSize.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ThumbBitmap(
                      cache: cache,
                      page: page,
                      rev: rev,
                      pageSize: pageSize,
                      spacing: spacing,
                    ),
                    if (marked || selected)
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Material(
                          color: scheme.surfaceContainerHigh.withAlpha(230),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onStar,
                            child: Tooltip(
                              message: marked ? 'Tirar dos favoritos' : 'Favoritar página',
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  marked ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 16,
                                  color: marked ? const Color(0xFFFFB300) : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (selected)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Material(
                          color: scheme.surfaceContainerHigh.withAlpha(230),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onDelete,
                            child: Tooltip(
                              message: 'Excluir página',
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline,
                                    size: 16, color: scheme.error),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected ? scheme.primary : scheme.onSurfaceVariant,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                  ),
                ),
                if (onEdit != null)
                  InkWell(
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(Icons.edit_outlined, size: 14, color: scheme.outline),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.page, this.rev, this.pageSize, this.spacing);

  final double spacing;

  final NotePage page;
  final Size pageSize;
  final int rev;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / pageSize.width;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.save();
    canvas.scale(k);
    canvas.clipRect(Offset.zero & pageSize);
    paintPageLines(canvas, page.background, pageSize,
        strokeWidth: 2.5, step: spacing, fitWidth: true);
    paintPageContent(canvas, page, Offset.zero & pageSize, () {});
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.page != page || old.rev != rev || old.pageSize != pageSize || old.spacing != spacing;
}


/// Assinatura barata do conteúdo de uma página (sem varrer os pontos).
int _pageSig(NotePage p) => Object.hash(p.strokes.length, p.images.length,
    p.strokes.isEmpty ? 0 : p.strokes.last.points.length, p.background);

class _ThumbEntry {
  _ThumbEntry(this.image, this.rev, this.spacing, this.sig, this.w);
  final ui.Image image;
  final int rev;
  final double spacing;
  final int sig;
  final int w;
}

/// Guarda as miniaturas já prontas como bitmap. Desenhar um bitmap é quase
/// de graça; antes, cada miniatura redesenhava todos os traços vetoriais a
/// cada quadro em que a barra estava visível.
class _ThumbCache {
  final Map<NotePage, _ThumbEntry> _m = {};
  static const int _max = 80;

  _ThumbEntry? get(NotePage p) => _m[p];

  bool changed(NotePage p) {
    final e = _m[p];
    return e == null || e.sig != _pageSig(p);
  }

  void put(NotePage p, _ThumbEntry e) {
    _m.remove(p);
    _m[p] = e;
    while (_m.length > _max) {
      final k = _m.keys.first;
      _m.remove(k);
    }
  }

  void clear() {
    _m.clear(); // sem dispose manual: um widget ainda pode estar pintando a imagem
  }
}

class _ThumbBitmap extends StatefulWidget {
  const _ThumbBitmap({
    required this.cache,
    required this.page,
    required this.rev,
    required this.pageSize,
    required this.spacing,
  });

  final _ThumbCache cache;
  final NotePage page;
  final int rev;
  final Size pageSize;
  final double spacing;

  @override
  State<_ThumbBitmap> createState() => _ThumbBitmapState();
}

class _ThumbBitmapState extends State<_ThumbBitmap> {
  bool _queued = false;

  /// Largura em pixels da miniatura; muda só se a janela mudar de escala.
  int _pxWidth(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ((PagesSidebar.width - 42) * dpr).round().clamp(64, 400);
  }

  bool _stale(int w) {
    final e = widget.cache.get(widget.page);
    return e == null ||
        e.rev != widget.rev ||
        e.spacing != widget.spacing ||
        e.w != w;
  }

  void _maybeRender(int w) {
    if (_queued || !_stale(w)) return;
    _queued = true;
    // fora do build, e uma miniatura por quadro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted || !_stale(w)) return;
      final pg = widget.page;
      final ps = widget.pageSize;
      final h = (w * ps.height / ps.width).round();
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      _ThumbPainter(pg, widget.rev, ps, widget.spacing)
          .paint(canvas, Size(w.toDouble(), h.toDouble()));
      final pic = rec.endRecording();
      final img = pic.toImageSync(w, h);
      pic.dispose();
      widget.cache.put(pg, _ThumbEntry(img, widget.rev, widget.spacing, _pageSig(pg), w));
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = _pxWidth(context);
    _maybeRender(w);
    final e = widget.cache.get(widget.page);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BitmapPainter(e?.image, e?.rev ?? -1),
        size: Size.infinite,
      ),
    );
  }
}

class _BitmapPainter extends CustomPainter {
  _BitmapPainter(this.image, this.rev);
  final ui.Image? image;
  final int rev;

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      return;
    }
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_BitmapPainter old) => old.image != image || old.rev != rev;
}
