import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'shapes.dart';

/// Mini barra flutuante com as formas mais básicas. Aparece enquanto a
/// ferramenta de formas está ativa; arraste na página para desenhar a forma.
class ShapeBar extends StatelessWidget {
  const ShapeBar({super.key, required this.controller});

  final CanvasController controller;

  static IconData iconFor(ShapeKind k) => switch (k) {
        ShapeKind.line => Icons.horizontal_rule,
        ShapeKind.arrow => Icons.arrow_right_alt,
        ShapeKind.rectangle => Icons.crop_square,
        ShapeKind.ellipse => Icons.circle_outlined,
        ShapeKind.triangle => Icons.change_history,
      };

  static String nameFor(ShapeKind k) => switch (k) {
        ShapeKind.line => 'Reta',
        ShapeKind.arrow => 'Seta',
        ShapeKind.rectangle => 'Retângulo',
        ShapeKind.ellipse => 'Elipse',
        ShapeKind.triangle => 'Triângulo',
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
                for (final k in ShapeKind.values)
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
