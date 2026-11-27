import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'function_parser.dart';

/// Tamanho (px) da imagem do gráfico: proporção 4:3.
const ui.Size kGraphSize = ui.Size(1200, 900);

/// Cores das curvas, na ordem de uso.
const List<int> kGraphColors = [0xFF1E88E5, 0xFFE53935, 0xFF43A047, 0xFFFB8C00];

class GraphFn {
  GraphFn(this.expr, this.color);
  String expr;
  int color;
}

/// O que o gráfico mostra: funções, janela (x e y) e grade.
class GraphSpec {
  GraphSpec({
    required this.fns,
    this.xMin = -10,
    this.xMax = 10,
    this.yMin = -10,
    this.yMax = 10,
    this.autoY = true,
    this.grid = true,
  });

  List<GraphFn> fns;
  double xMin, xMax, yMin, yMax;
  bool autoY, grid;

  String encode() => jsonEncode({
        'f': [
          for (final f in fns) {'e': f.expr, 'c': f.color},
        ],
        'x': [xMin, xMax],
        'y': [yMin, yMax],
        'a': autoY,
        'g': grid,
      });

  static GraphSpec? decode(String? s) {
    if (s == null) return null;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      final x = (j['x'] as List).cast<num>(), y = (j['y'] as List).cast<num>();
      return GraphSpec(
        fns: [
          for (final f in (j['f'] as List))
            GraphFn(f['e'] as String, (f['c'] as num).toInt()),
        ],
        xMin: x[0].toDouble(),
        xMax: x[1].toDouble(),
        yMin: y[0].toDouble(),
        yMax: y[1].toDouble(),
        autoY: j['a'] != false,
        grid: j['g'] != false,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Passo "redondo" (1, 2, 5 × 10^k) que dá cerca de [target] marcas em [range].
double niceStep(double range, {int target = 8}) {
  if (!(range > 0) || range.isInfinite) return 1;
  final raw = range / target;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final f = raw / mag;
  final m = f < 1.5 ? 1 : (f < 3.5 ? 2 : (f < 7.5 ? 5 : 10));
  return m * mag;
}

/// Faixa de y que mostra bem as curvas: ignora os extremos (assíntotas).
(double, double) autoYRange(List<MathFn> fns, double x0, double x1, {int samples = 800}) {
  final ys = <double>[];
  for (final f in fns) {
    for (var i = 0; i <= samples; i++) {
      final y = f(x0 + (x1 - x0) * i / samples);
      if (y.isFinite) ys.add(y);
    }
  }
  if (ys.isEmpty) return (-10, 10);
  ys.sort();
  final lo = ys[(ys.length * 0.02).floor()];
  final hi = ys[math.min(ys.length - 1, (ys.length * 0.98).ceil())];
  final span = hi - lo;
  if (span < 1e-6) return (lo - 1, hi + 1); // função constante
  final pad = span * 0.12;
  return (lo - pad, hi + pad);
}

String _fmt(double v, double step) {
  if (v.abs() < step * 1e-6) return '0';
  final decimals = step >= 1 ? 0 : (-(math.log(step) / math.ln10).floor()).clamp(0, 6);
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}

void _label(ui.Canvas c, String text, ui.Offset at, {
  double size = 22,
  int color = 0xFF555555,
  bool italic = false,
  double dx = 0, // 0 = centraliza em x; 1 = termina em x; -1 = começa em x
  double dy = 0, // 0 = centraliza em y; 1 = termina em y; -1 = começa em y
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: ui.Color(color),
        fontSize: size,
        fontStyle: italic ? ui.FontStyle.italic : ui.FontStyle.normal,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();
  final x = at.dx - tp.width * (dx == 0 ? 0.5 : (dx > 0 ? 1 : 0));
  final y = at.dy - tp.height * (dy == 0 ? 0.5 : (dy > 0 ? 1 : 0));
  tp.paint(c, ui.Offset(x, y));
}

/// Desenha o gráfico (fundo transparente) e devolve o PNG.
/// Funções inválidas são ignoradas; a janela vem de [spec].
Future<Uint8List> renderGraphPng(GraphSpec spec) async {
  const w = 1200.0, h = 900.0, pad = 64.0;
  final plot = ui.Rect.fromLTRB(pad, pad * 0.6, w - pad * 0.7, h - pad);

  final parsed = <(MathFn, GraphFn)>[];
  for (final f in spec.fns) {
    try {
      if (f.expr.trim().isNotEmpty) parsed.add((parseFunction(f.expr), f));
    } on FormatException {
      // ignora
    }
  }
  final xMin = spec.xMin, xMax = spec.xMax;
  var yMin = spec.yMin, yMax = spec.yMax;
  if (spec.autoY && parsed.isNotEmpty) {
    (yMin, yMax) = autoYRange([for (final p in parsed) p.$1], xMin, xMax);
  }

  double sx(double x) => plot.left + (x - xMin) / (xMax - xMin) * plot.width;
  double sy(double y) => plot.bottom - (y - yMin) / (yMax - yMin) * plot.height;

  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec, const ui.Rect.fromLTWH(0, 0, w, h));

  final xStep = niceStep(xMax - xMin), yStep = niceStep(yMax - yMin);
  final axisX = 0.0.clamp(yMin, yMax).toDouble(); // y onde o eixo x passa
  final axisY = 0.0.clamp(xMin, xMax).toDouble(); // x onde o eixo y passa
  final ox = sx(axisY), oy = sy(axisX);

  // grade
  if (spec.grid) {
    final gp = ui.Paint()
      ..color = const ui.Color(0x33607D8B)
      ..strokeWidth = 1.6;
    for (var v = (xMin / xStep).ceil() * xStep; v <= xMax + 1e-9; v += xStep) {
      c.drawLine(ui.Offset(sx(v), plot.top), ui.Offset(sx(v), plot.bottom), gp);
    }
    for (var v = (yMin / yStep).ceil() * yStep; v <= yMax + 1e-9; v += yStep) {
      c.drawLine(ui.Offset(plot.left, sy(v)), ui.Offset(plot.right, sy(v)), gp);
    }
  }

  // eixos com setinha
  final ap = ui.Paint()
    ..color = const ui.Color(0xFF37474F)
    ..strokeWidth = 3
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke;
  c.drawLine(ui.Offset(plot.left, oy), ui.Offset(plot.right, oy), ap);
  c.drawLine(ui.Offset(ox, plot.bottom), ui.Offset(ox, plot.top), ap);
  final fill = ui.Paint()..color = const ui.Color(0xFF37474F);
  c.drawPath(
    ui.Path()
      ..moveTo(plot.right + 8, oy)
      ..lineTo(plot.right - 10, oy - 7)
      ..lineTo(plot.right - 10, oy + 7)
      ..close(),
    fill,
  );
  c.drawPath(
    ui.Path()
      ..moveTo(ox, plot.top - 8)
      ..lineTo(ox - 7, plot.top + 10)
      ..lineTo(ox + 7, plot.top + 10)
      ..close(),
    fill,
  );
  _label(c, 'x', ui.Offset(plot.right + 6, oy + 18), italic: true, color: 0xFF37474F, size: 26, dx: 1);
  _label(c, 'y', ui.Offset(ox + 16, plot.top - 6), italic: true, color: 0xFF37474F, size: 26, dx: -1);

  // marcas e números
  final tp = ui.Paint()
    ..color = const ui.Color(0xFF37474F)
    ..strokeWidth = 2.5;
  for (var v = (xMin / xStep).ceil() * xStep; v <= xMax + 1e-9; v += xStep) {
    if (v.abs() < xStep * 1e-6) continue;
    c.drawLine(ui.Offset(sx(v), oy - 6), ui.Offset(sx(v), oy + 6), tp);
    _label(c, _fmt(v, xStep), ui.Offset(sx(v), oy + 24));
  }
  for (var v = (yMin / yStep).ceil() * yStep; v <= yMax + 1e-9; v += yStep) {
    if (v.abs() < yStep * 1e-6) continue;
    c.drawLine(ui.Offset(ox - 6, sy(v)), ui.Offset(ox + 6, sy(v)), tp);
    _label(c, _fmt(v, yStep), ui.Offset(ox - 12, sy(v)), dx: 1);
  }
  if (xMin <= 0 && xMax >= 0 && yMin <= 0 && yMax >= 0) {
    _label(c, '0', ui.Offset(ox - 10, oy + 18), dx: 1);
  }

  // curvas (cortadas na janela; quebra nas assíntotas)
  c.save();
  c.clipRect(plot.inflate(2));
  for (final (f, g) in parsed) {
    final path = ui.Path();
    var pen = false;
    double? prev;
    const n = 2400;
    for (var i = 0; i <= n; i++) {
      final x = xMin + (xMax - xMin) * i / n;
      final y = f(x);
      if (!y.isFinite) {
        pen = false;
        prev = null;
        continue;
      }
      final py = sy(y);
      final jump = prev != null && (py - prev).abs() > plot.height * 1.2;
      if (!pen || jump) {
        path.moveTo(sx(x), py);
        pen = true;
      } else {
        path.lineTo(sx(x), py);
      }
      prev = py;
    }
    c.drawPath(
      path,
      ui.Paint()
        ..color = ui.Color(g.color)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..isAntiAlias = true,
    );
  }
  c.restore();

  // legenda
  if (parsed.isNotEmpty) {
    var y = plot.top + 10;
    for (final (_, g) in parsed) {
      final label = 'y = ${g.expr.trim().replaceFirst(RegExp(r'^\s*(y|f\(x\))\s*=\s*'), '')}';
      final t = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: ui.Color(g.color), fontSize: 26, fontWeight: ui.FontWeight.w600)),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: plot.width * 0.5);
      final box = ui.Rect.fromLTWH(plot.left + 12, y, t.width + 20, t.height + 8);
      c.drawRRect(
        ui.RRect.fromRectAndRadius(box, const ui.Radius.circular(10)),
        ui.Paint()..color = const ui.Color(0xCCFFFFFF),
      );
      t.paint(c, ui.Offset(box.left + 10, box.top + 4));
      y += t.height + 14;
    }
  }

  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}
