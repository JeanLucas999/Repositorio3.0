import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notas/canvas_controller.dart';
import 'package:notas/models.dart';
import 'package:notas/scribble.dart';
import 'package:notas/shape_recognizer.dart';

final _rng = math.Random(7);

Offset _jit(Offset p, double n) => Offset(
      p.dx + (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() - 1.5) * n,
      p.dy + (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() - 1.5) * n,
    );

List<Offset> _polyPath(List<Offset> vs, {double step = 4, double noise = 3}) {
  final pts = <Offset>[];
  for (var i = 0; i < vs.length - 1; i++) {
    final a = vs[i], b = vs[i + 1];
    final n = math.max(2, ((b - a).distance / step).floor());
    for (var k = 0; k < n; k++) {
      pts.add(_jit(Offset.lerp(a, b, k / n)!, noise));
    }
  }
  pts.add(_jit(vs.last, noise));
  return pts;
}

List<Offset> _circle(double cx, double cy, double rx, double ry) => [
      for (var i = 0; i < 114; i++)
        _jit(
          Offset(
            cx + rx * (1 + 0.04 * math.sin(3 * 2 * math.pi * i / 120 + 1)) *
                math.cos(2 * math.pi * i / 120),
            cy + ry * (1 + 0.04 * math.sin(3 * 2 * math.pi * i / 120 + 1)) *
                math.sin(2 * math.pi * i / 120),
          ),
          3,
        ),
    ];

double _rate(List<Offset> Function() gen, String kind, {int n = 60}) {
  var ok = 0;
  for (var i = 0; i < n; i++) {
    if (recognizeShape(gen())?.kind == kind) ok++;
  }
  return ok / n;
}

void main() {
  group('reconhecimento de formas', () {
    test('reta', () {
      expect(_rate(() => _polyPath([const Offset(0, 0), const Offset(300, 8)]), 'line'),
          greaterThan(0.9));
    });
    test('círculo', () {
      expect(_rate(() => _circle(200, 200, 100, 100), 'circle'), greaterThan(0.9));
    });
    test('elipse', () {
      expect(_rate(() => _circle(200, 200, 160, 80), 'ellipse'), greaterThan(0.9));
    });
    test('retângulo', () {
      const v = [Offset(0, 0), Offset(320, 0), Offset(320, 160), Offset(0, 160), Offset(0, 0)];
      expect(_rate(() => _polyPath(v), 'rectangle'), greaterThan(0.9));
    });
    test('triângulo', () {
      const v = [Offset(100, 0), Offset(200, 170), Offset(0, 170), Offset(100, 0)];
      expect(_rate(() => _polyPath(v), 'triangle'), greaterThan(0.9));
    });
    test('arco aberto não vira nada', () {
      final arc = [
        for (var i = 0; i < 50; i++)
          Offset(150 + 150 * math.cos(i * math.pi / 60), 150 + 150 * math.sin(i * math.pi / 60)),
      ];
      expect(recognizeShape(arc), isNull);
    });
  });

  group('apagar riscando', () {
    List<Offset> zig({int n = 8}) {
      final pts = <Offset>[];
      for (var i = 0; i < n; i++) {
        final y0 = 14.0 * i / n;
        final a = Offset(i.isEven ? 0 : 120, y0);
        final b = Offset(i.isEven ? 120 : 0, y0 + 14.0 / n);
        for (var k = 0; k < 15; k++) {
          pts.add(_jit(Offset.lerp(a, b, k / 15)!, 1.5));
        }
      }
      return pts;
    }

    test('zigue-zague é detectado', () => expect(looksLikeScribble(zig()), isTrue));
    test('reta longa não é', () {
      expect(looksLikeScribble(_polyPath([const Offset(0, 0), const Offset(300, 0)])), isFalse);
    });
    test('círculo não é', () {
      expect(looksLikeScribble(_circle(200, 200, 100, 100)), isFalse);
    });
  });

  group('controlador', () {
    CanvasController make() => CanvasController(Notebook.empty('t', 't'));

    void draw(CanvasController c, List<Offset> pts) {
      c.beginStroke(pts.first, 0.5);
      for (final p in pts.skip(1)) {
        c.extendStroke(p, 0.5);
      }
      c.endStroke();
    }

    test('desfazer e refazer um traço', () {
      final c = make();
      draw(c, _polyPath([const Offset(10, 10), const Offset(200, 40)]));
      expect(c.page.strokes.length, 1);
      c.undo();
      expect(c.page.strokes.length, 0);
      c.redo();
      expect(c.page.strokes.length, 1);
    });

    test('riscar por cima apaga o traço e dá para desfazer', () {
      final c = make();
      draw(c, _polyPath([const Offset(0, 5), const Offset(200, 5)]));
      expect(c.page.strokes.length, 1);
      final scribble = <Offset>[];
      for (var i = 0; i < 8; i++) {
        final a = Offset(i.isEven ? 20 : 180, i * 2.0);
        final b = Offset(i.isEven ? 180 : 20, i * 2.0 + 2);
        for (var k = 0; k < 15; k++) {
          scribble.add(Offset.lerp(a, b, k / 15)!);
        }
      }
      draw(c, scribble);
      expect(c.page.strokes.length, 0);
      c.undo();
      expect(c.page.strokes.length, 1);
    });

    test('borracha remove e desfaz', () {
      final c = make();
      draw(c, _polyPath([const Offset(0, 50), const Offset(200, 50)]));
      c.setTool(Tool.eraser);
      c.beginStroke(const Offset(100, 52), 0.5);
      c.endStroke();
      expect(c.page.strokes, isEmpty);
      c.undo();
      expect(c.page.strokes.length, 1);
    });

    test('salvar e carregar JSON preserva os traços', () {
      final c = make();
      draw(c, _polyPath([const Offset(10, 10), const Offset(200, 40)]));
      final copy = Notebook.fromJson(c.notebook.toJson());
      expect(copy.pages.first.strokes.length, 1);
      expect(copy.pages.first.strokes.first.points.length,
          c.page.strokes.first.points.length);
    });
  });
}
