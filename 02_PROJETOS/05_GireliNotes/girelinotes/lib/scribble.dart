import 'dart:ui';

import 'geometry.dart';
import 'models.dart';

/// Detecta o gesto de "apagar riscando": zigue-zague rápido e comprido
/// dentro de uma área pequena.
bool looksLikeScribble(List<Offset> pts) {
  if (pts.length < 12) return false;
  final diag = diagonalOf(boundsOf(pts));
  if (diag < 30) return false;
  if (pathLength(pts) < diag * 3.0) return false;

  final s = resampleBySpacing(pts, 10);
  var reversals = 0;
  for (var i = 2; i < s.length; i++) {
    final a = s[i - 1] - s[i - 2];
    final b = s[i] - s[i - 1];
    final la = a.distance, lb = b.distance;
    if (la == 0 || lb == 0) continue;
    final cos = (a.dx * b.dx + a.dy * b.dy) / (la * lb);
    if (cos < -0.2) reversals++;
  }
  return reversals >= 4;
}

/// Traços que o risco [scribble] encosta ou cruza.
List<Stroke> strokesTouchedBy(
  List<Stroke> strokes,
  List<Offset> scribble, {
  double tol = 6,
}) {
  final poly = resampleBySpacing(scribble, 6);
  if (poly.length < 2) return [];
  final pb = boundsOf(poly).inflate(tol);
  final hits = <Stroke>[];
  for (final s in strokes) {
    if (!s.bounds.overlaps(pb)) continue;
    if (_touches(s, poly, tol)) hits.add(s);
  }
  return hits;
}

bool _touches(Stroke s, List<Offset> poly, double tol) {
  final pts = s.points;
  final reach = tol + s.effectiveWidth / 2;
  for (var i = 0; i < pts.length; i++) {
    for (var j = 0; j < poly.length - 1; j++) {
      if (distToSegment(pts[i], poly[j], poly[j + 1]) <= reach) return true;
      if (i > 0 && segmentsIntersect(pts[i - 1], pts[i], poly[j], poly[j + 1])) {
        return true;
      }
    }
  }
  return false;
}
