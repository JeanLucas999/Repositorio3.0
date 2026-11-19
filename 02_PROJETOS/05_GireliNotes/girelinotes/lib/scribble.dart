import 'dart:math' as math;
import 'dart:ui';

import 'geometry.dart';
import 'models.dart';

/// Detecta o gesto de "apagar riscando": zigue-zague comprido, com viradas
/// bem fechadas, dentro de uma área pequena. Exige pelo menos 6 passadas.
bool looksLikeScribble(List<Offset> pts) {
  if (pts.length < 12) return false;
  final diag = diagonalOf(boundsOf(pts));
  if (diag < 30) return false;
  if (pathLength(pts) < diag * 3.5) return false;

  final s = resampleBySpacing(pts, 10);
  var reversals = 0;
  for (var i = 2; i < s.length; i++) {
    final a = s[i - 1] - s[i - 2];
    final b = s[i] - s[i - 1];
    final la = a.distance, lb = b.distance;
    if (la == 0 || lb == 0) continue;
    final cos = (a.dx * b.dx + a.dy * b.dy) / (la * lb);
    if (cos < -0.35) reversals++;
  }
  return reversals >= 5;
}

/// Traços que o risco [scribble] realmente cobre: ele precisa encostar no
/// traço E a maior parte do traço ([minCoverage] do comprimento) precisa
/// estar dentro da área do risco. Assim, uma linha comprida que só atravessa
/// o objeto riscado não é apagada junto.
List<Stroke> strokesCoveredBy(
  List<Stroke> strokes,
  List<Offset> scribble, {
  double tol = 6,
  double minCoverage = 0.6,
}) {
  final poly = resampleBySpacing(scribble, 6);
  if (poly.length < 2) return [];
  final area = boundsOf(poly).inflate(10);
  final hits = <Stroke>[];
  for (final s in strokes) {
    if (!s.bounds.overlaps(area)) continue;
    if (!_touches(s, poly, tol)) continue;
    if (_coverage(s, area) >= minCoverage) hits.add(s);
  }
  return hits;
}

/// Fração do comprimento do traço que está dentro de [area].
double _coverage(Stroke s, Rect area) {
  final pts = s.points;
  if (pts.length == 1) return area.contains(pts.first) ? 1.0 : 0.0;
  var total = 0, inside = 0;
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1], b = pts[i];
    final n = math.max(1, ((b - a).distance / 4).ceil());
    for (var k = 0; k < n; k++) {
      total++;
      if (area.contains(Offset.lerp(a, b, k / n)!)) inside++;
    }
  }
  return total == 0 ? 0.0 : inside / total;
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
