import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notas/canvas_controller.dart';
import 'package:notas/canvas_view.dart';
import 'package:notas/geometry.dart';
import 'package:notas/models.dart';
import 'package:notas/palm_guard.dart';
import 'package:notas/scribble.dart';
import 'package:notas/settings.dart';
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

List<Offset> _circle(double cx, double cy, double rx, double ry, {double tilt = 0}) {
  final phase = _rng.nextDouble() * 6;
  var pts = [
    for (var i = 0; i < 114; i++)
      Offset(
        cx + rx * (1 + 0.04 * math.sin(3 * 2 * math.pi * i / 120 + phase)) *
            math.cos(2 * math.pi * i / 120),
        cy + ry * (1 + 0.04 * math.sin(3 * 2 * math.pi * i / 120 + phase)) *
            math.sin(2 * math.pi * i / 120),
      ),
  ];
  if (tilt != 0) pts = rotatePoints(pts, tilt * math.pi / 180, Offset(cx, cy));
  return [for (final p in pts) _jit(p, 3)];
}

/// Retângulo de cantos arredondados, como uma pessoa desenha "quadrado" à mão.
List<Offset> _roundedRect(double w, double h, double rad,
    {double tilt = 0, double start = 0}) {
  List<Offset> arc(double cx, double cy, double a0) => [
        for (var k = 0; k <= 10; k++)
          Offset(cx + rad * math.cos(a0 + math.pi / 2 * k / 10),
              cy + rad * math.sin(a0 + math.pi / 2 * k / 10)),
      ];
  var path = <Offset>[
    Offset(rad, 0),
    Offset(w - rad, 0),
    ...arc(w - rad, rad, -math.pi / 2),
    Offset(w, rad),
    Offset(w, h - rad),
    ...arc(w - rad, h - rad, 0),
    Offset(w - rad, h),
    Offset(rad, h),
    ...arc(rad, h - rad, math.pi / 2),
    Offset(0, h - rad),
    Offset(0, rad),
    ...arc(rad, rad, math.pi),
  ];
  final k = (start * path.length).floor();
  path = [...path.sublist(k), ...path.sublist(0, k)];
  path.add(path.first);
  if (tilt != 0) path = rotatePoints(path, tilt * math.pi / 180, Offset(w / 2, h / 2));
  return _polyPath(path, noise: 2.5);
}

double _rate(List<Offset> Function() gen, String kind, {int n = 60}) {
  var ok = 0;
  for (var i = 0; i < n; i++) {
    if (recognizeShape(gen())?.kind == kind) ok++;
  }
  return ok / n;
}

List<Offset> _zig({int passes = 8, double w = 120, double h = 14}) {
  final pts = <Offset>[];
  for (var i = 0; i < passes; i++) {
    final y0 = h * i / passes;
    final a = Offset(i.isEven ? 0 : w, y0);
    final b = Offset(i.isEven ? w : 0, y0 + h / passes);
    for (var k = 0; k < 15; k++) {
      pts.add(_jit(Offset.lerp(a, b, k / 15)!, 1.5));
    }
  }
  return pts;
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
    test('elipse inclinada', () {
      expect(_rate(() => _circle(200, 200, 160, 80, tilt: 30), 'ellipse'),
          greaterThan(0.9));
    });
    test('retângulo', () {
      const v = [Offset(0, 0), Offset(320, 0), Offset(320, 160), Offset(0, 160), Offset(0, 0)];
      expect(_rate(() => _polyPath(v), 'rectangle'), greaterThan(0.9));
    });
    test('quadrado com cantos arredondados NÃO vira círculo', () {
      for (final rad in [10.0, 20.0, 30.0, 40.0]) {
        expect(
          _rate(() => _roundedRect(200, 200, rad, start: _rng.nextDouble()), 'rectangle'),
          greaterThan(0.9),
          reason: 'cantos de raio $rad',
        );
      }
    });
    test('quadrado arredondado e girado', () {
      expect(
        _rate(() => _roundedRect(200, 200, 25, tilt: 20, start: _rng.nextDouble()),
            'rectangle'),
        greaterThan(0.9),
      );
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
    test('zigue-zague de 8 passadas é detectado', () {
      expect(looksLikeScribble(_zig()), isTrue);
    });
    test('hachura de 4 e 5 passadas (sombreado) NÃO é', () {
      expect(looksLikeScribble(_zig(passes: 4)), isFalse);
      expect(looksLikeScribble(_zig(passes: 5)), isFalse);
    });
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

    List<Offset> scribbleOver(double w, double h, {int passes = 8}) {
      final pts = <Offset>[];
      for (var i = 0; i < passes; i++) {
        final y = h * i / passes;
        final a = Offset(i.isEven ? 0 : w, y);
        final b = Offset(i.isEven ? w : 0, y + h / passes);
        for (var k = 0; k < 15; k++) {
          pts.add(Offset.lerp(a, b, k / 15)!);
        }
      }
      return pts;
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
      draw(c, scribbleOver(200, 16));
      expect(c.page.strokes.length, 0);
      c.undo();
      expect(c.page.strokes.length, 1);
    });

    test('riscar o retângulo NÃO apaga a linha que passa por ele', () {
      final c = make();
      // retângulo de 200x160
      draw(c, _polyPath(const [
        Offset(0, 0), Offset(200, 0), Offset(200, 160), Offset(0, 160), Offset(0, 0),
      ], noise: 0.5));
      // linha comprida que atravessa o lado direito do retângulo
      draw(c, _polyPath(const [Offset(150, 80), Offset(600, 80)], noise: 0.5));
      expect(c.page.strokes.length, 2);

      draw(c, scribbleOver(200, 160)); // rabisco só sobre o retângulo
      expect(c.page.strokes.length, 1, reason: 'só o retângulo some');
      final remaining = c.page.strokes.single;
      expect(remaining.bounds.right, greaterThan(500)); // sobrou a linha comprida
    });

    test('hachura curta sobre um traço fica como tinta, não apaga', () {
      final c = make();
      draw(c, _polyPath([const Offset(0, 5), const Offset(200, 5)]));
      draw(c, scribbleOver(200, 16, passes: 5));
      expect(c.page.strokes.length, 2);
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

    test('filtro de entrada: traço termina onde a caneta terminou', () {
      final c = make();
      c.beginStroke(const Offset(0, 0), 0.5);
      c.extendStroke(const Offset(3, 1), 0.5);
      c.extendStroke(const Offset(6, 1), 0.5);
      c.extendStroke(const Offset(9, 2), 0.5);
      c.endStroke();
      final last = c.page.strokes.single.points.last;
      expect((last - const Offset(9, 2)).distance, lessThan(0.6));
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

  group('marca-texto', () {
    CanvasController make() => CanvasController(Notebook.empty('t', 't'));

    void draw(CanvasController c, List<Offset> pts) {
      c.beginStroke(pts.first, 0.5);
      for (final p in pts.skip(1)) {
        c.extendStroke(p, 0.5);
      }
      c.endStroke();
    }

    test('tem cor e espessura próprias (não herda o preto da caneta)', () {
      final c = make();
      c.setTool(Tool.highlighter);
      expect(c.color, 0xFFFFEB3B);
      draw(c, _polyPath([const Offset(0, 0), const Offset(200, 0)], noise: 0.5));
      final s = c.page.strokes.single;
      expect(s.highlighter, isTrue);
      expect(s.color, 0xFFFFEB3B);

      c.setTool(Tool.pen);
      expect(c.color, 0xFF1A1A1A); // a caneta continua preta
      c.setColor(0xFFC62828);
      c.setTool(Tool.highlighter);
      expect(c.color, 0xFFFFEB3B); // e o marca-texto continua amarelo
    });

    test('tocar na ferramenta ativa abre/fecha as opções', () {
      final c = make();
      expect(c.showOptions, isFalse);
      c.selectTool(Tool.pen);
      expect(c.showOptions, isTrue);
      c.selectTool(Tool.pen);
      expect(c.showOptions, isFalse);
      c.selectTool(Tool.eraser);
      c.selectTool(Tool.eraser);
      expect(c.showOptions, isFalse); // borracha não tem opções
    });
  });

  group('palm rejection', () {
    AppSettings settings() => AppSettings(); // padrão: ligado, 600 ms, raio 30

    test('sem caneta por perto, o dedo funciona normalmente', () {
      final g = PalmGuard(settings());
      expect(g.rejectTouchDown(1, 1000, 10), isFalse);
    });

    test('toque durante a caneta encostada é ignorado', () {
      final g = PalmGuard(settings());
      g.onPenDown(1000);
      expect(g.rejectTouchDown(2, 1100, 10), isTrue);
      expect(g.rejectTouchMove(2, 10), isTrue); // continua ignorado enquanto durar
      g.touchEnded(2);
      expect(g.isIgnored(2), isFalse);
    });

    test('depois que a caneta sai, a proteção dura palmGuardMs', () {
      final g = PalmGuard(settings());
      g.onPenDown(1000);
      g.onPenUp(1500);
      expect(g.rejectTouchDown(3, 1900, 10), isTrue); // 400 ms depois
      expect(g.rejectTouchDown(4, 2200, 10), isFalse); // 700 ms depois
    });

    test('caneta pairando também protege', () {
      final g = PalmGuard(settings());
      g.onPenHover(5000);
      expect(g.rejectTouchDown(5, 5300, 10), isTrue);
      expect(g.rejectTouchDown(6, 6000, 10), isFalse);
    });

    test('contato grande (palma) é ignorado mesmo sem caneta', () {
      final g = PalmGuard(settings());
      expect(g.rejectTouchDown(7, 0, 45), isTrue);
    });

    test('toque que cresce no meio do caminho vira palma', () {
      final g = PalmGuard(settings());
      expect(g.rejectTouchDown(8, 0, 12), isFalse);
      expect(g.rejectTouchMove(8, 12), isFalse);
      expect(g.rejectTouchMove(8, 50), isTrue);
      expect(g.rejectTouchMove(8, 12), isTrue); // e não volta atrás
    });

    test('desligada, nada é ignorado', () {
      final s = settings()..palmRejection = false;
      final g = PalmGuard(s);
      g.onPenDown(0);
      expect(g.rejectTouchDown(9, 10, 80), isFalse);
    });
  });

  group('configurações', () {
    test('ida e volta em JSON', () {
      final s = AppSettings()
        ..theme = ThemePref.dark
        ..accent = 0xFFE91E63
        ..palmRejection = false
        ..palmGuardMs = 900
        ..palmRadius = 40
        ..holdMs = 700
        ..autoShape = false
        ..scribbleErase = false
        ..fingerDraws = true;
      final copy = AppSettings.fromJson(s.toJson());
      expect(copy.theme, ThemePref.dark);
      expect(copy.accent, 0xFFE91E63);
      expect(copy.palmRejection, isFalse);
      expect(copy.palmGuardMs, 900);
      expect(copy.palmRadius, 40);
      expect(copy.holdMs, 700);
      expect(copy.autoShape, isFalse);
      expect(copy.scribbleErase, isFalse);
      expect(copy.fingerDraws, isTrue);
    });

    test('valores absurdos no arquivo são limitados', () {
      final s = AppSettings.fromJson({'palmGuardMs': 999999, 'holdMs': 1, 'theme': 99});
      expect(s.palmGuardMs, 3000);
      expect(s.holdMs, 200);
      expect(s.theme, ThemePref.system);
    });

    test('update avisa os ouvintes e o salvamento', () {
      final s = AppSettings();
      var heard = 0, saved = 0;
      s.addListener(() => heard++);
      s.onChanged = () => saved++;
      s.update(() => s.accent = 0xFF7C4DFF);
      expect(s.accent, 0xFF7C4DFF);
      expect(heard, 1);
      expect(saved, 1);
    });
  });

  group('tela de desenho', () {
    testWidgets('caneta (stylus) desenha um traço', (tester) async {
      final c = CanvasController(Notebook.empty('t', 't'));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CanvasView(controller: c)),
      ));

      final g = await tester.startGesture(const Offset(300, 300),
          kind: PointerDeviceKind.stylus);
      for (var i = 1; i <= 10; i++) {
        await g.moveBy(const Offset(20, 5));
      }
      await g.up();
      await tester.pump();

      expect(c.page.strokes.length, 1);
      expect(c.page.strokes.single.points.length, greaterThan(3));
    });

    testWidgets('o dedo não desenha por padrão', (tester) async {
      final c = CanvasController(Notebook.empty('t', 't'));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CanvasView(controller: c)),
      ));

      final g = await tester.startGesture(const Offset(300, 300));
      for (var i = 1; i <= 10; i++) {
        await g.moveBy(const Offset(20, 5));
      }
      await g.up();
      await tester.pump();

      expect(c.page.strokes, isEmpty);
    });
  });
}
