import 'dart:math' as math;
import 'dart:ui';

/// Formas básicas da mini barra (a biblioteca maior de formas vem separada).
enum ShapeKind { line, arrow, rectangle, ellipse, triangle }

/// Contorno da forma ao arrastar de [a] (onde a caneta encostou) até [b].
/// Perto de um quadrado/círculo (diferença de até 8%) já sai perfeito.
List<Offset> shapePoints(ShapeKind kind, Offset a, Offset b, {double headLen = 16}) {
  switch (kind) {
    case ShapeKind.line:
      {
        return [a, b];
      }
    case ShapeKind.arrow:
      {
        final d = b - a;
        final len = d.distance;
        if (len < 1) return [a, b];
        final h = math.min(headLen, len * 0.5);
        final ang = math.atan2(d.dy, d.dx);
        const spread = 0.5; // ~28° para cada lado
        final h1 = b - Offset(math.cos(ang - spread), math.sin(ang - spread)) * h;
        final h2 = b - Offset(math.cos(ang + spread), math.sin(ang + spread)) * h;
        return [a, b, h1, b, h2];
      }
    case ShapeKind.rectangle:
      {
        final r = _box(a, b);
        return [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft, r.topLeft];
      }
    case ShapeKind.ellipse:
      {
        final r = _box(a, b);
        const n = 96;
        final c = r.center;
        final rx = r.width / 2, ry = r.height / 2;
        return [
          for (var i = 0; i <= n; i++)
            Offset(c.dx + rx * math.cos(2 * math.pi * i / n),
                c.dy + ry * math.sin(2 * math.pi * i / n)),
        ];
      }
    case ShapeKind.triangle:
      {
        final r = _box(a, b);
        final apex = Offset(r.center.dx, r.top);
        return [apex, r.bottomRight, r.bottomLeft, apex];
      }
  }
}

Rect _box(Offset a, Offset b) {
  var dx = b.dx - a.dx, dy = b.dy - a.dy;
  final adx = dx.abs(), ady = dy.abs();
  final m = math.max(adx, ady);
  if (m > 0 && (adx - ady).abs() < 0.08 * m) {
    dx = dx.isNegative ? -m : m;
    dy = dy.isNegative ? -m : m;
  }
  return Rect.fromPoints(a, Offset(a.dx + dx, a.dy + dy));
}
