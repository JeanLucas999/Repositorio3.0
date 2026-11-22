import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'shapes.dart';

/// Mini barra flutuante com as formas mais básicas. Aparece enquanto a
/// ferramenta de formas está ativa; arraste na página para desenhar a forma.
class ShapeBar extends StatelessWidget {
  const ShapeBar({super.key, required this.controller});

  final CanvasController controller;

  /// Ícone das formas básicas; as demais são desenhadas por [ShapePreview].
  static IconData iconFor(ShapeKind k) => switch (k) {
        ShapeKind.line => Icons.horizontal_rule,
        ShapeKind.arrow => Icons.arrow_right_alt,
        ShapeKind.rectangle => Icons.crop_square,
        ShapeKind.ellipse => Icons.circle_outlined,
        ShapeKind.triangle => Icons.change_history,
        _ => Icons.category_outlined,
      };

  static String nameFor(ShapeKind k) => switch (k) {
        ShapeKind.line => 'Reta',
        ShapeKind.arrow => 'Seta',
        ShapeKind.rectangle => 'Retângulo',
        ShapeKind.ellipse => 'Elipse',
        ShapeKind.triangle => 'Triângulo',
        ShapeKind.diamond => 'Losango',
        ShapeKind.pentagon => 'Pentágono',
        ShapeKind.hexagon => 'Hexágono',
        ShapeKind.star => 'Estrela',
        ShapeKind.doubleArrow => 'Seta dupla',
        ShapeKind.curvedArrow => 'Seta curva',
        ShapeKind.blockArrow => 'Seta larga',
        ShapeKind.speech => 'Balão de fala',
        ShapeKind.brace => 'Chave',
        ShapeKind.cube => 'Cubo',
        ShapeKind.cylinder => 'Cilindro',
        ShapeKind.axes => 'Plano cartesiano',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        return Material(
          elevation: 4,
          color: scheme.surfaceContainerHigh,
          shape: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final k in kBasicShapes)
                  Tooltip(
                    message: nameFor(k),
                    child: Material(
                      color: c.shapeKind == k
                          ? scheme.primary.withAlpha(36)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => c.setShape(k),
                        child: SizedBox(
                          width: 42,
                          height: 40,
                          child: Icon(
                            iconFor(k),
                            size: 22,
                            color: c.shapeKind == k
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                Tooltip(
                  message: 'Mais formas (L)',
                  child: Material(
                    color: (c.showShapeLib || !kBasicShapes.contains(c.shapeKind))
                        ? scheme.primary.withAlpha(36)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: c.toggleShapeLib,
                      child: SizedBox(
                        width: 42,
                        height: 40,
                        child: Icon(
                          Icons.apps,
                          size: 22,
                          color: (c.showShapeLib || !kBasicShapes.contains(c.shapeKind))
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: VerticalDivider(
                      width: 8, thickness: 1, color: scheme.outlineVariant),
                ),
                Tooltip(
                  message: 'Preenchimento claro',
                  child: Material(
                    color: c.settings.shapeFill
                        ? scheme.primary.withAlpha(36)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => c.settings
                          .update(() => c.settings.shapeFill = !c.settings.shapeFill),
                      child: SizedBox(
                        width: 42,
                        height: 40,
                        child: Icon(
                          Icons.format_color_fill,
                          size: 20,
                          color: c.settings.shapeFill
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Biblioteca com todas as formas além das básicas (grade de miniaturas).
class ShapeLibrary extends StatelessWidget {
  const ShapeLibrary({super.key, required this.controller});
  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        return Material(
          elevation: 8,
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (final k in kLibraryShapes)
                    Tooltip(
                      message: ShapeBar.nameFor(k),
                      child: Material(
                        color: c.shapeKind == k ? scheme.primary.withAlpha(36) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => c.setShape(k),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: ShapePreview(
                                kind: k,
                                size: 30,
                                color: c.shapeKind == k ? scheme.primary : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Miniatura de uma forma, desenhada com o mesmo contorno usado na página.
class ShapePreview extends StatelessWidget {
  const ShapePreview({super.key, required this.kind, this.size = 24, this.color});
  final ShapeKind kind;
  final double size;
  final Color? color; // padrão: cor do IconTheme

  @override
  Widget build(BuildContext context) {
    final col = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return CustomPaint(size: Size.square(size), painter: _ShapeIconPainter(kind, col));
  }
}

class _ShapeIconPainter extends CustomPainter {
  _ShapeIconPainter(this.kind, this.color);
  final ShapeKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.width * 0.1;
    final pts = shapePoints(
      kind,
      Offset(m, m),
      Offset(size.width - m, size.height - m),
      headLen: size.width * 0.28,
    );
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ShapeIconPainter old) => old.kind != kind || old.color != color;
}
