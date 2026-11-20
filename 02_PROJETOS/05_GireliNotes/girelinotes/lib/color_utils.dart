/// Conversões entre ARGB (0xAARRGGBB) e HSV, sem depender da API de Color
/// (que mudou entre versões do Flutter). h em graus 0..360, s e v em 0..1.

int hsvToArgb(double h, double s, double v) {
  final hh = (h % 360 + 360) % 360;
  final ss = s.clamp(0.0, 1.0).toDouble();
  final vv = v.clamp(0.0, 1.0).toDouble();
  final c = vv * ss;
  final hp = hh / 60;
  final x = c * (1 - ((hp % 2) - 1).abs());
  double r = 0, g = 0, b = 0;
  if (hp < 1) {
    r = c;
    g = x;
  } else if (hp < 2) {
    r = x;
    g = c;
  } else if (hp < 3) {
    g = c;
    b = x;
  } else if (hp < 4) {
    g = x;
    b = c;
  } else if (hp < 5) {
    r = x;
    b = c;
  } else {
    r = c;
    b = x;
  }
  final m = vv - c;
  int ch(double t) => ((t + m) * 255).round().clamp(0, 255).toInt();
  return 0xFF000000 | (ch(r) << 16) | (ch(g) << 8) | ch(b);
}

/// Retorna [h, s, v].
List<double> argbToHsv(int argb) {
  final r = ((argb >> 16) & 0xFF) / 255;
  final g = ((argb >> 8) & 0xFF) / 255;
  final b = (argb & 0xFF) / 255;
  final mx = [r, g, b].reduce((a, c) => a > c ? a : c);
  final mn = [r, g, b].reduce((a, c) => a < c ? a : c);
  final d = mx - mn;
  double h = 0;
  if (d != 0) {
    if (mx == r) {
      h = 60 * (((g - b) / d) % 6);
    } else if (mx == g) {
      h = 60 * (((b - r) / d) + 2);
    } else {
      h = 60 * (((r - g) / d) + 4);
    }
  }
  if (h < 0) h += 360;
  final s = mx == 0 ? 0.0 : d / mx;
  return [h, s, mx];
}
