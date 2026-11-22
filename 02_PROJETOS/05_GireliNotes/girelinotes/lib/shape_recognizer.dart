import 'dart:math' as math;
import 'dart:ui';

import 'geometry.dart';

class RecognizedShape {
  const RecognizedShape(this.kind, this.points);

  /// 'line', 'circle', 'ellipse', 'rectangle', 'triangle' ou 'polygon'.
  final String kind;
  final List<Offset> points;
}

class _Fit {
  const _Fit(this.err, this.deg, this.cx, this.cy, this.a, this.b);

  /// Distância média (em unidades da página) entre o traço e o modelo.
  final double err;

  /// Inclinação testada, em graus (0..85).
  final int deg;

  /// Centro e meias-medidas no referencial já girado.
  final double cx, cy, a, b;
}

class _Fits {
  const _Fits(this.ellipse, this.rect);
  final _Fit? ellipse;
  final _Fit? rect;
}

/// Compara o traço com uma elipse e com um retângulo de cantos levemente
/// arredondados, em várias inclinações. Quem ajusta melhor ganha.
/// É isso que impede um quadrado "meio redondo" de virar círculo.
_Fits _fitFrames(List<Offset> pts) {
  _Fit? bestE, bestR;
  for (var deg = 0; deg < 90; deg += 5) {
    final th = deg * math.pi / 180;
    final q = rotatePoints(pts, -th);
    final bb = boundsOf(q);
    final cx = bb.center.dx, cy = bb.center.dy;
    final a = bb.width / 2, b = bb.height / 2;
    if (a < 8 || b < 8) continue;

    var e = 0.0;
    for (final p in q) {
      final nx = (p.dx - cx) / a, ny = (p.dy - cy) / b;
      e += (math.sqrt(nx * nx + ny * ny) - 1).abs();
    }
    e = e / q.length * (a + b) / 2;
    if (bestE == null || e < bestE.err - 1e-9) {
      bestE = _Fit(e, deg, cx, cy, a, b);
    }

    for (final k in const [0.0, 0.1, 0.2, 0.3, 0.4, 0.5]) {
      final rad = k * math.min(a, b);
      var r = 0.0;
      for (final p in q) {
        r += distToRoundedRect(p, cx, cy, a, b, rad);
      }
      r /= q.length;
      if (bestR == null || r < bestR.err - 1e-9) {
        bestR = _Fit(r, deg, cx, cy, a, b);
      }
    }
  }
  return _Fits(bestE, bestR);
}

/// Perto dos eixos (±8°) trava em 0° e usa a caixa do próprio traço.
_Fit _axisSnapped(_Fit f, List<Offset> pts) {
  if (f.deg > 8 && f.deg < 82) return f;
  final bb = boundsOf(pts);
  return _Fit(f.err, 0, bb.center.dx, bb.center.dy, bb.width / 2, bb.height / 2);
}

/// Tenta reconhecer o traço como uma forma geométrica limpa.
/// Retorna null se não parecer nenhuma. Sem IA: só geometria, é instantâneo.
RecognizedShape? recognizeShape(List<Offset> pts) {
  if (pts.length < 6) return null;

  final length = pathLength(pts);
  final bb = boundsOf(pts);
  final diag = diagonalOf(bb);
  if (length < 40 || diag < 25) return null;

  final chord = dist(pts.first, pts.last);
  final closed = chord < 0.25 * length;

  // ---- Linha reta (traço aberto e quase reto) ----
  if (!closed) {
    var maxDev = 0.0;
    for (final p in pts) {
      final d = distToSegment(p, pts.first, pts.last);
      if (d > maxDev) maxDev = d;
    }
    if (maxDev <= math.max(0.06 * chord, 4.0)) {
      return RecognizedShape('line', [pts.first, pts.last]);
    }
    return null;
  }

  // ---- Ajuste de elipse e retângulo ----
  final fits = _fitFrames(pts);
  final ell = fits.ellipse?.err ?? double.infinity;
  final rr = fits.rect?.err ?? double.infinity;

  // ---- Vértices (triângulo / quadrilátero) ----
  var v = simplifyRdp(movingAverage(pts, 2), math.max(0.05 * diag, 4.0));
  if (v.length > 3) v = v.sublist(0, v.length - 1); // último ≈ primeiro

  // remove vértices "falsos": quase retos ou colados no vizinho
  var changed = true;
  while (changed && v.length > 3) {
    changed = false;
    for (var i = 0; i < v.length; i++) {
      final prev = v[(i - 1 + v.length) % v.length];
      final next = v[(i + 1) % v.length];
      if (angleAt(prev, v[i], next) > 160 || dist(prev, v[i]) < 0.08 * diag) {
        v.removeAt(i);
        changed = true;
        break;
      }
    }
  }
  final pd = (v.length == 3 || v.length == 4)
      ? meanDistToPolygon(pts, v)
      : double.infinity;

  // Triângulo: tolerante (mão livre), mas ainda precisa ajustar melhor que elipse/retângulo.
  if (v.length == 3 && pd < 1.25 * math.min(ell, rr) && pd < 0.075 * diag) {
    return RecognizedShape('triangle', [...v, v.first]);
  }

  // Retângulo (inclui quadrado com cantos meio arredondados): sai com cantos vivos.
  final rf = fits.rect;
  if (rf != null && rr < 0.04 * diag && rr < 0.75 * ell) {
    final f = _axisSnapped(rf, pts);
    final th = f.deg * math.pi / 180;
    final corners = [
      Offset(f.cx - f.a, f.cy - f.b),
      Offset(f.cx + f.a, f.cy - f.b),
      Offset(f.cx + f.a, f.cy + f.b),
      Offset(f.cx - f.a, f.cy + f.b),
      Offset(f.cx - f.a, f.cy - f.b),
    ];
    return RecognizedShape('rectangle', rotatePoints(corners, th));
  }

  // Círculo / elipse (inclusive inclinada)
  final ef = fits.ellipse;
  final fe = ef == null ? null : _axisSnapped(ef, pts);
  // Elipse (achatada) é mais exigente que círculo: só sai se o ajuste for bem bom.
  final roundish =
      fe != null && (fe.a - fe.b).abs() / math.max(fe.a, fe.b) < 0.15;
  if (fe != null && ell < 0.045 * diag && (roundish || ell < 0.032 * diag)) {
    final f = fe;
    final th = f.deg * math.pi / 180;
    final circle = roundish;
    final ra = circle ? (f.a + f.b) / 2 : f.a;
    final rb = circle ? (f.a + f.b) / 2 : f.b;
    const n = 240; // bastante pontos para não aparecer facetas no zoom
    final base = [
      for (var i = 0; i <= n; i++)
        Offset(f.cx + ra * math.cos(2 * math.pi * i / n),
            f.cy + rb * math.sin(2 * math.pi * i / n)),
    ];
    return RecognizedShape(circle ? 'circle' : 'ellipse', rotatePoints(base, th));
  }

  // Quadriláteros irregulares não são reconhecidos: só retângulo/quadrado.
  return null;
}
