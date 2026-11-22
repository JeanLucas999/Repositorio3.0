import 'dart:math' as math;
import 'dart:ui';

/// Formas: as 5 primeiras ficam na mini barra; as demais, na biblioteca.
enum ShapeKind {
  line,
  arrow,
  rectangle,
  ellipse,
  triangle,
  diamond,
  pentagon,
  hexagon,
  star,
  doubleArrow,
  curvedArrow,
  blockArrow,
  speech,
  brace,
  cube,
  cylinder,
  axes,
}

const List<ShapeKind> kBasicShapes = [
  ShapeKind.line,
  ShapeKind.arrow,
  ShapeKind.rectangle,
  ShapeKind.ellipse,
  ShapeKind.triangle,
];

final List<ShapeKind> kLibraryShapes = [
  for (final k in ShapeKind.values)
    if (!kBasicShapes.contains(k)) k,
];

/// Formas que seguem a reta da caneta (duas pontas, ângulo "imantado").
bool isArrowLike(ShapeKind k) =>
    k == ShapeKind.arrow || k == ShapeKind.doubleArrow || k == ShapeKind.curvedArrow;

/// Formas fechadas: aceitam preenchimento claro.
bool isClosedShape(ShapeKind k) => const {
      ShapeKind.rectangle,
      ShapeKind.ellipse,
      ShapeKind.triangle,
      ShapeKind.diamond,
      ShapeKind.pentagon,
      ShapeKind.hexagon,
      ShapeKind.star,
      ShapeKind.blockArrow,
      ShapeKind.speech,
      ShapeKind.cube,
      ShapeKind.cylinder,
    }.contains(k);

/// Silhueta externa para o preenchimento de formas cujo traço repassa arestas
/// (cubo, cilindro). Null para as demais (preenchem o próprio contorno).
List<Offset>? shapeFillOutline(ShapeKind kind, Offset a, Offset b) {
  switch (kind) {
    case ShapeKind.cube:
      {
        final r = _box(a, b);
        final d = math.min(r.width, r.height) * 0.3;
        final f1 = Offset(r.left, r.top + d), f3 = Offset(r.right - d, r.bottom);
        final f4 = Offset(r.left, r.bottom), b1 = Offset(r.left + d, r.top);
        final b2 = Offset(r.right, r.top), b3 = Offset(r.right, r.bottom - d);
        return [f1, b1, b2, b3, f3, f4, f1];
      }
    case ShapeKind.cylinder:
      {
        final r = _box(a, b);
        final e = math.min(r.height * 0.3, r.width * 0.5);
        final cx = r.center.dx, rx = r.width / 2, ry = e / 2;
        final ty = r.top + ry, by = r.bottom - ry;
        return [
          for (var i = 0; i <= 24; i++)
            Offset(cx - rx * math.cos(math.pi * i / 24), ty - ry * math.sin(math.pi * i / 24)),
          for (var i = 0; i <= 24; i++)
            Offset(cx + rx * math.cos(math.pi * i / 24), by + ry * math.sin(math.pi * i / 24)),
        ];
      }
    default:
      return null;
  }
}

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
    case ShapeKind.diamond:
      {
        final r = _box(a, b);
        return [r.topCenter, r.centerRight, r.bottomCenter, r.centerLeft, r.topCenter];
      }
    case ShapeKind.pentagon:
      return _polygonIn(_box(a, b), 5, -math.pi / 2);
    case ShapeKind.hexagon:
      return _polygonIn(_box(a, b), 6, 0);
    case ShapeKind.star:
      {
        final u = <Offset>[];
        for (var i = 0; i <= 10; i++) {
          final rad = i.isEven ? 1.0 : 0.4;
          final ang = -math.pi / 2 + i * math.pi / 5;
          u.add(Offset(rad * math.cos(ang), rad * math.sin(ang)));
        }
        return _fit(u, _box(a, b));
      }
    case ShapeKind.doubleArrow:
      {
        final d = b - a;
        final len = d.distance;
        if (len < 1) return [a, b];
        final h = math.min(headLen, len * 0.35);
        final ang = math.atan2(d.dy, d.dx);
        Offset head(Offset tip, double dir, double side) =>
            tip - Offset(math.cos(ang + side) * dir, math.sin(ang + side) * dir) * h;
        return [
          head(a, -1, 0.5), a, head(a, -1, -0.5), a,
          b,
          head(b, 1, -0.5), b, head(b, 1, 0.5),
        ];
      }
    case ShapeKind.curvedArrow:
      {
        final d = b - a;
        final len = d.distance;
        if (len < 1) return [a, b];
        final mid = (a + b) / 2;
        final ctrl = mid + Offset(-d.dy, d.dx) / len * (len * 0.35);
        final pts = <Offset>[
          for (var i = 0; i <= 28; i++) _quad(a, ctrl, b, i / 28),
        ];
        final t = b - ctrl; // tangente no fim da curva
        final tl = t.distance;
        final ang = math.atan2(t.dy, t.dx);
        final h = math.min(headLen, math.max(4.0, tl * 0.5));
        final h1 = b - Offset(math.cos(ang - 0.5), math.sin(ang - 0.5)) * h;
        final h2 = b - Offset(math.cos(ang + 0.5), math.sin(ang + 0.5)) * h;
        return [...pts, h1, b, h2];
      }
    case ShapeKind.blockArrow:
      {
        // seta cheia apontando para onde a caneta andou
        final r = Rect.fromPoints(a, b);
        const u = [
          Offset(0, .3), Offset(.6, .3), Offset(.6, 0), Offset(1, .5),
          Offset(.6, 1), Offset(.6, .7), Offset(0, .7), Offset(0, .3),
        ];
        final d = b - a;
        final horiz = d.dx.abs() >= d.dy.abs();
        final pos = horiz ? d.dx >= 0 : d.dy >= 0;
        return [
          for (final q in u)
            horiz
                ? Offset(pos ? r.left + q.dx * r.width : r.right - q.dx * r.width,
                    r.top + q.dy * r.height)
                : Offset(r.left + q.dy * r.width,
                    pos ? r.top + q.dx * r.height : r.bottom - q.dx * r.height),
        ];
      }
    case ShapeKind.speech:
      {
        final r = _box(a, b);
        final w = r.width, h = r.height;
        final by = r.top + h * 0.78; // base do balão; abaixo dela fica a ponta
        final rad = math.min(w, h) * 0.14;
        final pts = <Offset>[];
        void arc(double cx, double cy, double a0, double a1) {
          for (var i = 0; i <= 6; i++) {
            final t = a0 + (a1 - a0) * i / 6;
            pts.add(Offset(cx + rad * math.cos(t), cy + rad * math.sin(t)));
          }
        }

        arc(r.right - rad, r.top + rad, -math.pi / 2, 0);
        arc(r.right - rad, by - rad, 0, math.pi / 2);
        pts.add(Offset(r.left + w * 0.5, by));
        pts.add(Offset(r.left + w * 0.18, r.bottom));
        pts.add(Offset(r.left + w * 0.3, by));
        arc(r.left + rad, by - rad, math.pi / 2, math.pi);
        arc(r.left + rad, r.top + rad, math.pi, math.pi * 1.5);
        pts.add(pts.first);
        return pts;
      }
    case ShapeKind.brace:
      {
        // unidade: x 0 (ponta do meio) a 1 (extremidades), y 0 a 1
        final u = <Offset>[
          ..._cubic(const Offset(1, 0), const Offset(0.5, 0), const Offset(0.5, 0.05),
              const Offset(0.5, 0.2)),
          ..._cubic(const Offset(0.5, 0.2), const Offset(0.5, 0.4), const Offset(0.5, 0.45),
              const Offset(0, 0.5)),
          ..._cubic(const Offset(0, 0.5), const Offset(0.5, 0.55), const Offset(0.5, 0.6),
              const Offset(0.5, 0.8)),
          ..._cubic(const Offset(0.5, 0.8), const Offset(0.5, 0.95), const Offset(0.5, 1),
              const Offset(1, 1)),
        ];
        final r = Rect.fromPoints(a, b);
        if (r.width > r.height * 1.5) {
          // horizontal: a ponta do meio aponta para cima
          return [for (final q in u) Offset(r.left + q.dy * r.width, r.top + q.dx * r.height)];
        }
        return [for (final q in u) Offset(r.left + q.dx * r.width, r.top + q.dy * r.height)];
      }
    case ShapeKind.cube:
      {
        final r = _box(a, b);
        final d = math.min(r.width, r.height) * 0.3;
        final f1 = Offset(r.left, r.top + d), f2 = Offset(r.right - d, r.top + d);
        final f3 = Offset(r.right - d, r.bottom), f4 = Offset(r.left, r.bottom);
        final b1 = Offset(r.left + d, r.top), b2 = Offset(r.right, r.top);
        final b3 = Offset(r.right, r.bottom - d);
        return [f1, f2, f3, f4, f1, b1, b2, f2, b2, b3, f3];
      }
    case ShapeKind.cylinder:
      {
        final r = _box(a, b);
        final e = math.min(r.height * 0.3, r.width * 0.5); // altura da elipse
        final cx = r.center.dx, rx = r.width / 2, ry = e / 2;
        final ty = r.top + ry, by = r.bottom - ry;
        final pts = <Offset>[
          for (var i = 0; i <= 48; i++)
            Offset(cx - rx * math.cos(2 * math.pi * i / 48), ty - ry * math.sin(2 * math.pi * i / 48)),
          Offset(r.left, by),
          for (var i = 0; i <= 24; i++)
            Offset(cx - rx * math.cos(math.pi * i / 24), by + ry * math.sin(math.pi * i / 24)),
          Offset(r.right, ty),
        ];
        return pts;
      }
    case ShapeKind.axes:
      {
        final r = _box(a, b);
        final c = r.center;
        final h = math.min(headLen, math.min(r.width, r.height) * 0.2);
        final tk = math.max(3.0, h * 0.35);
        final unit = math.max(14.0, math.min(r.width, r.height) / 8);
        final pts = <Offset>[Offset(c.dx, r.bottom), Offset(c.dx, r.top)];
        pts.addAll([
          Offset(c.dx - h * 0.5, r.top + h), Offset(c.dx, r.top), Offset(c.dx + h * 0.5, r.top + h),
          Offset(c.dx, r.top),
        ]);
        // marcas no eixo y (descendo até a origem) e depois no eixo x
        for (var y = r.top + unit; y < c.dy - unit * 0.5; y += unit) {
          pts.addAll([Offset(c.dx, y), Offset(c.dx - tk, y), Offset(c.dx + tk, y), Offset(c.dx, y)]);
        }
        pts.add(Offset(c.dx, c.dy));
        for (var y = c.dy + unit; y < r.bottom - unit * 0.5; y += unit) {
          pts.addAll([Offset(c.dx, y), Offset(c.dx - tk, y), Offset(c.dx + tk, y), Offset(c.dx, y)]);
        }
        pts.add(Offset(c.dx, c.dy));
        pts.add(Offset(r.left, c.dy));
        for (var x = r.left + unit; x < c.dx - unit * 0.5; x += unit) {
          pts.addAll([Offset(x, c.dy), Offset(x, c.dy - tk), Offset(x, c.dy + tk), Offset(x, c.dy)]);
        }
        pts.add(Offset(c.dx, c.dy));
        for (var x = c.dx + unit; x < r.right - unit * 0.5; x += unit) {
          pts.addAll([Offset(x, c.dy), Offset(x, c.dy - tk), Offset(x, c.dy + tk), Offset(x, c.dy)]);
        }
        pts.add(Offset(r.right, c.dy));
        pts.addAll([
          Offset(r.right - h, c.dy - h * 0.5), Offset(r.right, c.dy), Offset(r.right - h, c.dy + h * 0.5),
        ]);
        return pts;
      }
  }
}

Offset _quad(Offset p0, Offset p1, Offset p2, double t) {
  final u = 1 - t;
  return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
}

List<Offset> _cubic(Offset p0, Offset p1, Offset p2, Offset p3, {int n = 12}) {
  return [
    for (var i = 0; i <= n; i++)
      () {
        final t = i / n, u = 1 - t;
        return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t);
      }(),
  ];
}

/// Polígono regular de [n] lados dentro de [r] (esticado para preencher a caixa).
List<Offset> _polygonIn(Rect r, int n, double startAngle) {
  final u = [
    for (var i = 0; i <= n; i++)
      Offset(math.cos(startAngle + 2 * math.pi * i / n), math.sin(startAngle + 2 * math.pi * i / n)),
  ];
  return _fit(u, r);
}

/// Escala os pontos [u] para que a caixa deles preencha exatamente [r].
List<Offset> _fit(List<Offset> u, Rect r) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final q in u) {
    minX = math.min(minX, q.dx);
    minY = math.min(minY, q.dy);
    maxX = math.max(maxX, q.dx);
    maxY = math.max(maxY, q.dy);
  }
  final w = math.max(maxX - minX, 1e-9), h = math.max(maxY - minY, 1e-9);
  return [
    for (final q in u)
      Offset(r.left + (q.dx - minX) / w * r.width, r.top + (q.dy - minY) / h * r.height),
  ];
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
