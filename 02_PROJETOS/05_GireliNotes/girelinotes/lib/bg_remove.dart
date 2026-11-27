import 'dart:math' as math;
import 'dart:typed_data';

/// Um toque da varinha mágica (posição em pixels da imagem).
class WandTap {
  const WandTap(this.x, this.y);
  final int x, y;
}

/// Distância máxima de cor (0..442) para uma tolerância [t] de 0 a 100.
double toleranceDistance(double t) => t.clamp(0, 100) * 4.42;

/// Marca em [mask] (1 = remover) os pixels parecidos com a cor tocada em (sx, sy).
/// [contiguous]: só a região ligada ao toque; senão, toda a imagem com aquela cor.
/// Pixels já transparentes contam como fundo.
void floodMask(
  Uint8List rgba,
  int w,
  int h,
  int sx,
  int sy,
  double dist, {
  required bool contiguous,
  required Uint8List mask,
}) {
  sx = sx.clamp(0, w - 1);
  sy = sy.clamp(0, h - 1);
  // cor de referência: média 3x3 em volta do toque (menos sensível a ruído)
  var r = 0, g = 0, b = 0, n = 0;
  for (var y = math.max(0, sy - 1); y <= math.min(h - 1, sy + 1); y++) {
    for (var x = math.max(0, sx - 1); x <= math.min(w - 1, sx + 1); x++) {
      final i = (y * w + x) * 4;
      if (rgba[i + 3] < 16) continue;
      r += rgba[i];
      g += rgba[i + 1];
      b += rgba[i + 2];
      n++;
    }
  }
  final seedClear = n == 0;
  if (!seedClear) {
    r ~/= n;
    g ~/= n;
    b ~/= n;
  }
  final lim = dist * dist;

  bool match(int p) {
    final i = p * 4;
    if (rgba[i + 3] < 16) return true;
    if (seedClear) return false;
    final dr = rgba[i] - r, dg = rgba[i + 1] - g, db = rgba[i + 2] - b;
    return dr * dr + dg * dg + db * db <= lim;
  }

  if (!contiguous) {
    for (var p = 0; p < w * h; p++) {
      if (match(p)) mask[p] = 1;
    }
    return;
  }
  final start = sy * w + sx;
  if (mask[start] == 1 || !match(start)) {
    if (!match(start)) return;
  }
  final stack = <int>[start];
  mask[start] = 1;
  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    final x = p % w, y = p ~/ w;
    void visit(int q) {
      if (mask[q] == 0 && match(q)) {
        mask[q] = 1;
        stack.add(q);
      }
    }

    if (x > 0) visit(p - 1);
    if (x < w - 1) visit(p + 1);
    if (y > 0) visit(p - w);
    if (y < h - 1) visit(p + w);
  }
}

/// União das regiões de todos os [taps].
Uint8List wandMask(Uint8List rgba, int w, int h, List<WandTap> taps, double tolerance,
    {required bool contiguous}) {
  final mask = Uint8List(w * h);
  final d = toleranceDistance(tolerance);
  for (final t in taps) {
    floodMask(rgba, w, h, t.x, t.y, d, contiguous: contiguous, mask: mask);
  }
  return mask;
}

/// Cópia de [rgba] com o fundo marcado em [mask] transparente. [feather] (px)
/// suaviza a borda do recorte; 0 = corte seco.
Uint8List applyMask(Uint8List rgba, int w, int h, Uint8List mask, {int feather = 0}) {
  final out = Uint8List.fromList(rgba);
  if (feather <= 0) {
    for (var p = 0; p < w * h; p++) {
      if (mask[p] == 1) out[p * 4 + 3] = 0;
    }
    return out;
  }
  final r = feather;
  final win = 2 * r + 1;
  // média da máscara numa janela (duas passadas); fora da imagem vale o pixel da borda
  final tmp = Int32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var s = 0;
      for (var k = -r; k <= r; k++) {
        s += mask[y * w + (x + k).clamp(0, w - 1)];
      }
      tmp[y * w + x] = s;
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = y * w + x;
      if (mask[p] == 1) {
        out[p * 4 + 3] = 0;
        continue;
      }
      var s = 0;
      for (var k = -r; k <= r; k++) {
        s += tmp[(y + k).clamp(0, h - 1) * w + x];
      }
      if (s == 0) continue;
      final keep = 1 - s / (win * win);
      out[p * 4 + 3] = (out[p * 4 + 3] * keep).round().clamp(0, 255);
    }
  }
  return out;
}
