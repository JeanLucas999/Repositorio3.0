import 'dart:async';

import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'canvas_view.dart';
import 'dialogs.dart';
import 'models.dart';

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
  int _rev = 0; // muda quando o desenho muda (com atraso), para repintar miniaturas
  int _lastIndex = -1;

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
    super.dispose();
  }

  void _onCommit() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _rev++);
    });
  }

  void _onController() {
    if (!mounted) return;
    setState(() {});
    if (c.pageIndex != _lastIndex) {
      _lastIndex = c.pageIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
    }
  }

  void _ensureVisible({bool animate = true}) {
    if (!mounted || !_scroll.hasClients) return;
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = c.notebook.pages;
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '${pages.length} ${pages.length == 1 ? 'página' : 'páginas'}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemExtent: _itemExtent,
                itemCount: pages.length,
                itemBuilder: (context, i) => _Thumb(
                  page: pages[i],
                  pageSize: c.notebook.pageSize,
                  spacing: c.settings.lineSpacing,
                  index: i,
                  selected: i == c.pageIndex,
                  rev: _rev,
                  onTap: () => c.goToPage(i),
                  onDelete: () async {
                    final ok = await confirmDialog(
                      context,
                      title: pages.length > 1 ? 'Excluir página ${i + 1}?' : 'Esvaziar página?',
                      message: 'Essa ação não pode ser desfeita.',
                      confirm: pages.length > 1 ? 'Excluir' : 'Esvaziar',
                    );
                    if (ok) c.deletePageAt(i);
                  },
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: IconButton(
                tooltip: 'Nova página',
                icon: const Icon(Icons.add),
                onPressed: c.addPage,
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
  });

  final double spacing;
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
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _ThumbPainter(page, rev, pageSize, spacing),
                        size: Size.infinite,
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
            Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
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
    paintPageLines(canvas, page.background, pageSize, strokeWidth: 2.5, step: spacing);
    paintPageContent(canvas, page, Offset.zero & pageSize, () {});
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.page != page || old.rev != rev || old.pageSize != pageSize || old.spacing != spacing;
}
