import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'canvas_view.dart';
import 'models.dart';
import 'review.dart';

/// Tela de revisão: todos os trechos marcados com marca-texto, em sequência.
/// Tocar num trecho volta ao caderno naquela página.
Future<void> showReview(BuildContext context, CanvasController c) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReviewPage(controller: c),
    ));

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.controller});
  final CanvasController controller;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final List<ReviewClip> _all;
  final Set<int> _off = {}; // cores desligadas
  int _repaint = 0;

  Notebook get nb => widget.controller.notebook;

  @override
  void initState() {
    super.initState();
    _all = reviewClips(nb);
  }

  List<int> get _colors => {for (final c in _all) c.color}.toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clips = [for (final c in _all) if (!_off.contains(c.color)) c];
    final colors = _colors;
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisão · ${clips.length} ${clips.length == 1 ? 'trecho' : 'trechos'}'),
      ),
      body: _all.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nenhum trecho marcado ainda.\nUse o marca-texto no caderno e eles aparecem aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.outline),
                ),
              ),
            )
          : Column(
              children: [
                if (colors.length > 1)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        for (final col in colors)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: CircleAvatar(backgroundColor: Color(col), radius: 8),
                              label: Text('${_all.where((c) => c.color == col).length}'),
                              selected: !_off.contains(col),
                              onSelected: (v) => setState(() {
                                v ? _off.remove(col) : _off.add(col);
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: clips.length,
                    itemBuilder: (context, i) {
                      final clip = clips[i];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: _ClipCard(
                            clip: clip,
                            page: nb.pages[clip.pageIndex],
                            rev: _repaint,
                            step: widget.controller.settings.lineSpacing,
                            onReady: () {
                              if (mounted) setState(() => _repaint++);
                            },
                            onOpen: () {
                              widget.controller.goToPage(clip.pageIndex);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ClipCard extends StatelessWidget {
  const _ClipCard({
    required this.clip,
    required this.page,
    required this.rev,
    required this.onReady,
    required this.onOpen,
    required this.step,
  });

  final double step;
  final ReviewClip clip;
  final NotePage page;
  final int rev;
  final VoidCallback onReady;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(builder: (context, box) {
              final size = clipDisplaySize(clip.rect, box.maxWidth);
              return SizedBox(
                width: size.width,
                height: size.height.clamp(40, 900).toDouble(),
                child: CustomPaint(painter: _ClipPainter(clip, page, rev, onReady, step)),
              );
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Color(clip.color), radius: 6),
                  const SizedBox(width: 8),
                  Text(
                    'Página ${clip.pageIndex + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Icon(Icons.open_in_new, size: 16, color: scheme.outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipPainter extends CustomPainter {
  _ClipPainter(this.clip, this.page, this.rev, this.onReady, this.step);
  final double step;
  final ReviewClip clip;
  final NotePage page;
  final int rev;
  final VoidCallback onReady;

  @override
  void paint(Canvas canvas, Size size) {
    final r = clip.rect;
    final k = size.width / r.width;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(k);
    canvas.translate(-r.left, -r.top);
    paintPageLines(canvas, page.background, Size(r.right, r.bottom),
        strokeWidth: 2.5, step: step);
    paintPageContent(canvas, page, r, onReady);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClipPainter old) => old.clip != clip || old.rev != rev;
}
