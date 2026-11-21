import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'canvas_view.dart' show paintStroke;
import 'models.dart';

/// Multiplicador da largura base pela pressão [p] (0..1). Com [sens] = 0.5 é a
/// curva padrão de cada caneta; 0 = largura constante; 1 = bem mais sensível.
double pressureFactor(Tool t, double p, double sens) {
  final cur = t == Tool.brush ? 0.12 + 2.0 * p : 0.28 + 1.55 * p;
  return (1 + (cur - 1) * sens * 2).clamp(0.1, 2.3).toDouble();
}

/// Fração da largura na ponta do traço (entrada e saída) do tinteiro:
/// ponta mais aguda = começa e termina mais fino. 0.5 = padrão.
double tipMin(double sharp) => (0.75 - 0.6 * sharp).clamp(0.1, 0.9).toDouble();

String penTuneName(Tool t) => switch (t) {
      Tool.fountain => 'Tinteiro',
      Tool.brush => 'Pincel',
      Tool.smart => 'Caneta de formas',
      _ => 'Caneta',
    };

/// Ajustes da caneta em uso: prévia do traço + controles simples.
/// Cada caneta só mostra o que faz sentido nela.
class PenTunePanel extends StatelessWidget {
  const PenTunePanel({super.key, required this.controller});
  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final s = c.settings;
        final t = c.tool;
        final fountain = t == Tool.fountain;
        final brush = t == Tool.brush;
        return Material(
          elevation: 8,
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(penTuneName(t), style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(
                    height: 64,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _PreviewPainter(
                        tool: t,
                        color: c.penColor,
                        width: c.width,
                        sens: fountain ? s.pressFountain : s.pressBrush,
                        sharp: s.sharpFountain,
                        revision: Object.hash(c.penColor, c.width, s.pressFountain,
                            s.pressBrush, s.sharpFountain, t),
                      ),
                    ),
                  ),
                  if (fountain)
                    _Tune(
                      label: 'Ponta fina',
                      value: s.sharpFountain,
                      onChanged: (v) => s.update(() => s.sharpFountain = v),
                    ),
                  if (fountain || brush)
                    _Tune(
                      label: 'Sensibilidade à pressão',
                      value: fountain ? s.pressFountain : s.pressBrush,
                      onChanged: (v) => s.update(() {
                        if (fountain) {
                          s.pressFountain = v;
                        } else {
                          s.pressBrush = v;
                        }
                      }),
                    ),
                  _Tune(
                    label: 'Estabilização do traço',
                    value: c.stabOf(t),
                    onChanged: (v) => s.update(() {
                      switch (t) {
                        case Tool.fountain:
                          s.stabFountain = v;
                        case Tool.brush:
                          s.stabBrush = v;
                        default:
                          s.stabPen = v;
                      }
                    }),
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

class _Tune extends StatelessWidget {
  const _Tune({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text('${(value * 100).round()}%', style: style),
          ],
        ),
        SizedBox(
          height: 32,
          child: Slider(value: value.clamp(0.0, 1.0).toDouble(), divisions: 20, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({
    required this.tool,
    required this.color,
    required this.width,
    required this.sens,
    required this.sharp,
    required this.revision,
  });

  final Tool tool;
  final int color;
  final double width, sens, sharp;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 48;
    final base = width.clamp(1.0, 7.0).toDouble();
    final pts = <Offset>[];
    final ws = <double>[];
    final variable = tool == Tool.fountain || tool == Tool.brush;
    final tip = tipMin(sharp);
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      pts.add(Offset(
        size.width * (0.08 + 0.84 * t),
        size.height * (0.5 - 0.3 * math.sin(t * 2 * math.pi)),
      ));
      // pressão simulada: leve no começo e no fim, firme no meio
      final p = 0.1 + 0.9 * math.sin(t * math.pi);
      var w = base * pressureFactor(tool, p, sens);
      if (tool == Tool.fountain) {
        final e = (i < 4 ? i / 4.0 : (n - 1 - i) < 3 ? (n - 1 - i) / 3.0 : 1.0);
        w *= tip + (1 - tip) * e.clamp(0.0, 1.0);
      } else if (tool == Tool.brush) {
        final e = i < 8 ? i / 8.0 : (n - 1 - i) < 8 ? (n - 1 - i) / 8.0 : 1.0;
        w *= 0.15 + 0.85 * e.clamp(0.0, 1.0);
      }
      ws.add(w);
    }
    final st = Stroke(
      id: 'preview',
      points: pts,
      color: color,
      width: base,
      fountain: variable,
      widths: variable ? ws : null,
    );
    paintStroke(canvas, st);
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.revision != revision;
}
