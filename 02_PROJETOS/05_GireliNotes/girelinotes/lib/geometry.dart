import 'dart:math' as math;
import 'dart:ui';

double dist(Offset a, Offset b) => (a - b).distance;

double pathLength(List<Offset> p) {
  var s = 0.0;
  for (var i = 1; i < p.length; i++) {
    s += dist(p[i - 1], p[i]);
  }
  return s;
}

Rect boundsOf(List<Offset> pts) {
  if (pts.isEmpty) return Rect.zero;
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final p in pts) {
    if (p.dx < minX) minX = p.dx;
    if (p.dy < minY) minY = p.dy;
    if (p.dx > maxX) maxX = p.dx;
    if (p.dy > maxY) maxY = p.dy;
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

double diagonalOf(Rect r) => Offset(r.width, r.height).distance;

/// Distância do ponto [p] ao segmento [a]-[b].
double distToSegment(Offset p, Offset a, Offset b) {
  final abx = b.dx - a.dx, aby = b.dy - a.dy;
  final len2 = abx * abx + aby * aby;
  if (len2 == 0) return dist(p, a);
  var t = ((p.dx - a.dx) * abx + (p.dy - a.dy) * aby) / len2;
  t = t.clamp(0.0, 1.0).toDouble();
  return dist(p, Offset(a.dx + abx * t, a.dy + aby * t));
}

bool segmentsIntersect(Offset a, Offset b, Offset c, Offset d) {
  double cross(Offset o, Offset p, Offset q) =>
      (p.dx - o.dx) * (q.dy - o.dy) - (p.dy - o.dy) * (q.dx - o.dx);
  final d1 = cross(c, d, a), d2 = cross(c, d, b);
  final d3 = cross(a, b, c), d4 = cross(a, b, d);
  return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
}

/// Ramer–Douglas–Peucker.
List<Offset> simplifyRdp(List<Offset> pts, double eps) {
  if (pts.length < 3) return List.of(pts);
  final keep = List<bool>.filled(pts.length, false);
  keep[0] = true;
  keep[pts.length - 1] = true;
  void rec(int s, int e) {
    var maxD = 0.0;
    var idx = -1;
    for (var i = s + 1; i < e; i++) {
      final d = distToSegment(pts[i], pts[s], pts[e]);
      if (d > maxD) {
        maxD = d;
        idx = i;
      }
    }
    if (idx != -1 && maxD > eps) {
      keep[idx] = true;
      rec(s, idx);
      rec(idx, e);
    }
  }

  rec(0, pts.length - 1);
  return [
    for (var i = 0; i < pts.length; i++)
      if (keep[i]) pts[i],
  ];
}

/// Ângulo interno (graus) em [b] formado por a-b-c.
double angleAt(Offset a, Offset b, Offset c) {
  final v1 = a - b, v2 = c - b;
  final l = v1.distance * v2.distance;
  if (l == 0) return 180;
  final cosv = ((v1.dx * v2.dx + v1.dy * v2.dy) / l).clamp(-1.0, 1.0).toDouble();
  return math.acos(cosv) * 180 / math.pi;
}

/// Mantém só pontos separados por pelo menos [spacing]; sempre guarda o último.
List<Offset> resampleBySpacing(List<Offset> pts, double spacing) {
  if (pts.isEmpty) return [];
  final out = <Offset>[pts.first];
  for (final p in pts) {
    if (dist(p, out.last) >= spacing) out.add(p);
  }
  if (dist(out.last, pts.last) > 0.01) out.add(pts.last);
  return out;
}
