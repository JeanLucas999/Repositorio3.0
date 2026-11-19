import 'dart:math' as math;
import 'dart:ui';

import 'geometry.dart';

class RecognizedShape {
  const RecognizedShape(this.kind, this.points);

  /// 'line', 'circle', 'ellipse', 'rectangle', 'triangle' ou 'polygon'.
  final String kind;
  final List<Offset> points;
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
  final closed = chord < 0.22 * length;

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

  // ---- Círculo / elipse (alinhada aos eixos) ----
  final cx = bb.center.dx, cy = bb.center.dy;
  final a = bb.width / 2, b = bb.height / 2;
  if (a > 8 && b > 8) {
    var err = 0.0;
    for (final p in pts) {
      final nx = (p.dx - cx) / a, ny = (p.dy - cy) / b;
      err += (math.sqrt(nx * nx + ny * ny) - 1).abs();
    }
    err /= pts.length;
    if (err < 0.10) {
      final circle = (a - b).abs() / math.max(a, b) < 0.12;
      final ra = circle ? (a + b) / 2 : a;
      final rb = circle ? (a + b) / 2 : b;
      return RecognizedShape(circle ? 'circle' : 'ellipse', [
        for (var i = 0; i <= 72; i++)
          Offset(cx + ra * math.cos(2 * math.pi * i / 72),
              cy + rb * math.sin(2 * math.pi * i / 72)),
      ]);
    }
  }

  // ---- Polígonos (triângulo, retângulo, quadrilátero) ----
  var v = simplifyRdp(pts, math.max(0.05 * diag, 4.0));
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

  if (v.length == 3) {
    return RecognizedShape('triangle', [...v, v.first]);
  }

  if (v.length == 4) {
    var rightAngles = true;
    for (var i = 0; i < 4; i++) {
      final ang = angleAt(v[(i + 3) % 4], v[i], v[(i + 1) % 4]);
      if (ang < 65 || ang > 115) rightAngles = false;
    }
    if (rightAngles && _edgesAxisAligned(v)) {
      return RecognizedShape('rectangle', [
        bb.topLeft,
        bb.topRight,
        bb.bottomRight,
        bb.bottomLeft,
        bb.topLeft,
      ]);
    }
    return RecognizedShape(rightAngles ? 'rectangle' : 'polygon', [...v, v.first]);
  }

  return null;
}

bool _edgesAxisAligned(List<Offset> v) {
  for (var i = 0; i < v.length; i++) {
    final d = v[(i + 1) % v.length] - v[i];
    final ang = (math.atan2(d.dy, d.dx) * 180 / math.pi).abs() % 90;
    if (math.min(ang, 90 - ang) > 15) return false;
  }
  return true;
}
