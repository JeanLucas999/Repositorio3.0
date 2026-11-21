import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notas/canvas_controller.dart';
import 'package:notas/canvas_view.dart';
import 'package:notas/geometry.dart';
import 'package:notas/models.dart';
import 'package:notas/pen_tune.dart';
import 'package:notas/page_image.dart';
import 'package:notas/palm_guard.dart';
import 'package:notas/scribble.dart';
import 'package:notas/settings.dart';
import 'package:notas/shape_recognizer.dart';
import 'package:notas/shapes.dart';
import 'package:notas/color_utils.dart';
import 'package:notas/export_service.dart';

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
      c.selectTool(Tool.eraser); // trocar de ferramenta mantém a linha fechada
      expect(c.showOptions, isFalse);
      c.selectTool(Tool.eraser);
      expect(c.showOptions, isTrue); // a borracha também tem opções (modo e tamanho)
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
        ..fingerDraws = true
        ..eraserPixel = true
        ..eraserSize = 22;
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
      expect(copy.eraserPixel, isTrue);
      expect(copy.eraserSize, 22);
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

  group('caneta tinteiro', () {
    CanvasController make() => CanvasController(Notebook.empty('t', 't'));

    test('largura varia com a pressão; começa e termina fina', () {
      final c = make();
      c.setTool(Tool.fountain);
      c.beginStroke(const Offset(10, 10), 0.2, timeMs: 0);
      for (var i = 1; i <= 30; i++) {
        c.extendStroke(Offset(10 + i * 6.0, 10), 0.2 + 0.7 * i / 30, timeMs: i * 8);
      }
      c.endStroke();
      final s = c.page.strokes.single;
      expect(s.fountain, isTrue);
      expect(s.variable, isTrue);
      expect(s.widths!.length, s.points.length);
      final body = s.widths!.sublist(4, s.widths!.length - 3);
      expect(body.reduce(math.max), greaterThan(body.reduce(math.min) * 1.3));
      expect(s.widths!.last, lessThan(body.last)); // ponta final afinou
      expect(s.widths!.first, lessThan(body.first)); // entrada começou fina
    });

    test('mais rápido fica mais fino (mouse, sem pressão)', () {
      double midWidth(int msPerStep) {
        final c = make();
        c.setTool(Tool.fountain);
        c.beginStroke(const Offset(10, 10), 0.5, timeMs: 0);
        for (var i = 1; i <= 30; i++) {
          c.extendStroke(Offset(10 + i * 6.0, 10), 0.5, timeMs: i * msPerStep);
        }
        c.endStroke();
        final w = c.page.strokes.single.widths!;
        return w[w.length ~/ 2];
      }

      expect(midWidth(2), lessThan(midWidth(30)));
    });

    test('larguras vão e voltam no JSON', () {
      final c = make();
      c.setTool(Tool.fountain);
      c.beginStroke(const Offset(10, 10), 0.5);
      for (var i = 1; i <= 20; i++) {
        c.extendStroke(Offset(10 + i * 8.0, 10 + i * 2.0), 0.5);
      }
      c.endStroke();
      final copy = Notebook.fromJson(c.notebook.toJson());
      final a = c.page.strokes.single, b = copy.pages.first.strokes.single;
      expect(b.fountain, isTrue);
      expect(b.variable, isTrue);
      expect(b.widths!.length, a.widths!.length);
    });

    test('encaixar numa forma vira largura uniforme', () {
      final c = make();
      c.setTool(Tool.fountain);
      final pts = _circle(200, 200, 100, 100);
      c.beginStroke(pts.first, 0.5);
      for (final p in pts.skip(1)) {
        c.extendStroke(p, 0.5);
      }
      expect(c.holdDetected(), isTrue);
      expect(c.current!.widths, isNull);
      c.endStroke();
      expect(c.page.strokes.single.variable, isFalse);
    });

    test('tem cor e espessura próprias', () {
      final c = make();
      c.setTool(Tool.fountain);
      expect(c.color, 0xFF1A237E);
      c.setColor(0xFFC62828);
      c.setWidth(5);
      c.setTool(Tool.pen);
      expect(c.color, 0xFF1A1A1A);
      expect(c.width, 2.5);
      c.setTool(Tool.fountain);
      expect(c.color, 0xFFC62828);
      expect(c.width, 5);
    });
  });

  group('borracha', () {
    CanvasController make() => CanvasController(Notebook.empty('t', 't'));

    void draw(CanvasController c, List<Offset> pts) {
      c.beginStroke(pts.first, 0.5);
      for (final p in pts.skip(1)) {
        c.extendStroke(p, 0.5);
      }
      c.endStroke();
    }

    CanvasController withLine() {
      final c = make();
      draw(c, [for (var x = 0.0; x <= 300; x += 4) Offset(x, 50)]);
      return c;
    }

    test('modo Traço (padrão) apaga o traço inteiro e desfaz', () {
      final c = withLine();
      final original = c.page.strokes.single;
      expect(c.eraserPixel, isFalse);
      c.setTool(Tool.eraser);
      c.beginStroke(const Offset(150, 52), 0.5);
      c.endStroke();
      expect(c.page.strokes, isEmpty);
      c.undo();
      expect(c.page.strokes.single, same(original));
    });

    test('modo Normal apaga só o pedaço tocado, e desfaz/refaz', () {
      final c = withLine();
      final original = c.page.strokes.single;
      c.setEraserPixel(true);
      c.setTool(Tool.eraser);
      c.beginStroke(const Offset(150, 52), 0.5);
      c.endStroke();
      expect(c.page.strokes.length, 2);
      expect(c.page.strokes[0].bounds.right, lessThan(150));
      expect(c.page.strokes[1].bounds.left, greaterThan(150));
      c.undo();
      expect(c.page.strokes.single, same(original));
      c.redo();
      expect(c.page.strokes.length, 2);
    });

    test('modo Normal não deixa buraco quando a caneta anda rápido', () {
      final c = withLine();
      c.setEraserPixel(true);
      c.setTool(Tool.eraser);
      c.beginStroke(const Offset(100, 50), 0.5);
      c.extendStroke(const Offset(200, 50), 0.5); // salto de 100 numa amostra só
      c.endStroke();
      expect(c.page.strokes.length, 2);
      expect(c.page.strokes[0].bounds.right, lessThan(100));
      expect(c.page.strokes[1].bounds.left, greaterThan(200));
    });

    test('a varrida inteira é UM passo de desfazer', () {
      final c = withLine();
      c.setEraserPixel(true);
      c.setTool(Tool.eraser);
      c.beginStroke(const Offset(60, 50), 0.5);
      for (var x = 70.0; x <= 240; x += 10) {
        c.extendStroke(Offset(x, 50), 0.5);
      }
      c.endStroke();
      expect(c.page.strokes.length, 2);
      c.undo();
      expect(c.page.strokes.length, 1);
      expect(c.canUndo, isTrue); // ainda há o traço original para desfazer
    });

    test('pedaços da tinteiro mantêm a largura de cada ponto', () {
      final c = make();
      c.setTool(Tool.fountain);
      draw(c, [for (var x = 0.0; x <= 300; x += 4) Offset(x, 50)]);
      c.setEraserPixel(true);
      c.setTool(Tool.eraser);
      c.beginStroke(const Offset(150, 50), 0.5);
      c.endStroke();
      expect(c.page.strokes.length, 2);
      for (final s in c.page.strokes) {
        expect(s.fountain, isTrue);
        expect(s.variable, isTrue);
        expect(s.widths!.length, s.points.length);
      }
    });

    test('círculo-guia aparece enquanto apaga e some no fim', () {
      final c = withLine();
      c.setTool(Tool.eraser);
      c.beginStroke(const Offset(5, 5), 0.5);
      expect(c.eraserPos, const Offset(5, 5));
      c.endStroke();
      expect(c.eraserPos, isNull);
    });

    test('apagar onde não há nada não cria passo de desfazer', () {
      final c = make();
      c.setTool(Tool.eraser);
      c.beginStroke(const Offset(50, 50), 0.5);
      c.endStroke();
      expect(c.canUndo, isFalse);
    });

    test('tamanho da borracha é uma configuração salva', () {
      final c = make();
      c.setEraserSize(25);
      expect(c.eraserRadius, 25);
      expect(c.settings.eraserSize, 25);
    });
  });

  group('botão único de caneta', () {
    CanvasController make() => CanvasController(Notebook.empty('t', 't'));

    test('escolher o tipo troca a ferramenta e lembra a última caneta', () {
      final c = make();
      expect(c.isPenTool, isTrue);
      expect(c.lastPen, Tool.pen);
      c.setPenType(Tool.fountain);
      expect(c.tool, Tool.fountain);
      expect(c.lastPen, Tool.fountain);
      c.setPenType(Tool.pen);
      expect(c.tool, Tool.pen);
      expect(c.lastPen, Tool.pen);
    });

    test('marca-texto, linha e borracha não são canetas nem viram a última caneta', () {
      final c = make();
      c.setPenType(Tool.fountain);
      c.setPenType(Tool.highlighter); // ignorado: o marca-texto fica fora da escolha
      expect(c.tool, Tool.fountain);
      c.selectTool(Tool.highlighter);
      expect(c.isPenTool, isFalse);
      expect(c.lastPen, Tool.fountain);
      c.selectTool(Tool.eraser);
      expect(c.isPenTool, isFalse);
      expect(c.lastPen, Tool.fountain);
    });

    test('primeiro toque só volta para a última caneta; a subaba abre no segundo', () {
      final c = make();
      c.setPenType(Tool.fountain);
      c.selectTool(Tool.highlighter);
      c.showOptions = true; // subaba do marca-texto aberta
      c.selectPen(); // 1º toque: volta para a tinteiro e fecha a subaba
      expect(c.tool, Tool.fountain);
      expect(c.showOptions, isFalse);
      c.selectPen(); // 2º toque: abre a subaba
      expect(c.showOptions, isTrue);
      c.selectPen(); // 3º toque: fecha
      expect(c.showOptions, isFalse);
    });

    test('com a caneta já ativa, um toque abre a subaba', () {
      final c = make();
      expect(c.isPenTool, isTrue);
      expect(c.showOptions, isFalse);
      c.selectPen();
      expect(c.showOptions, isTrue);
    });

    test('atalhos P e F também atualizam a última caneta', () {
      final c = make();
      c.setTool(Tool.fountain); // atalho F
      c.setTool(Tool.shape);
      expect(c.lastPen, Tool.fountain);
      c.setTool(Tool.pen); // atalho P
      expect(c.lastPen, Tool.pen);
    });
  });

  group('cores, formas e mãozinha', () {
    CanvasController make() => CanvasController(Notebook.empty('t', 't'));

    test('HSV ida e volta preserva a cor', () {
      for (final argb in [0xFFFF0000, 0xFF2979FF, 0xFF00897B, 0xFF808080]) {
        final hsv = argbToHsv(argb);
        final back = hsvToArgb(hsv[0], hsv[1], hsv[2]);
        expect(back, argb);
      }
    });

    test('pickColor guarda nas recentes sem repetir', () {
      final c = make();
      c.pickColor(0xFF112233);
      c.pickColor(0xFF445566);
      c.pickColor(0xFF112233);
      expect(c.settings.recentColors.first, 0xFF112233);
      expect(c.settings.recentColors.length, 2);
    });

    test('forma retângulo é fechada e elipse tem muitos pontos', () {
      final r = shapePoints(ShapeKind.rectangle, const Offset(0, 0), const Offset(100, 50));
      expect(r.length, 5);
      expect(r.first, r.last);
      final e = shapePoints(ShapeKind.ellipse, const Offset(0, 0), const Offset(100, 50));
      expect(e.length, greaterThan(40));
    });

    test('desenhar com a ferramenta de formas cria um traço de retângulo', () {
      final c = make();
      c.setShape(ShapeKind.rectangle);
      expect(c.tool, Tool.shape);
      c.beginStroke(const Offset(100, 100), 0.5);
      c.extendStroke(const Offset(300, 220), 0.5);
      c.endStroke();
      expect(c.page.strokes.length, 1);
      expect(c.page.strokes.first.points.length, 5);
    });

    test('mãozinha liga/desliga e volta para a ferramenta anterior', () {
      final c = make();
      c.setTool(Tool.fountain);
      c.selectTool(Tool.pan);
      expect(c.tool, Tool.pan);
      expect(c.panActive, isTrue);
      c.selectTool(Tool.pan);
      expect(c.tool, Tool.fountain);
    });

    test('segurar a tecla ativa a mãozinha temporariamente', () {
      final c = make();
      expect(c.panActive, isFalse);
      c.setPanHeld(true);
      expect(c.panActive, isTrue);
      c.setPanHeld(false);
      expect(c.panActive, isFalse);
    });

    test('tecla da mãozinha é configurável e persiste', () {
      final s = AppSettings()..panKeyId = 0x61;
      final back = AppSettings.fromJson(s.toJson());
      expect(back.panKeyId, 0x61);
      expect(AppSettings().panKeyId, AppSettings.defaultPanKey);
    });
  });

  group('fundo padrão', () {
    test('trocar o fundo vale para as próximas páginas do caderno', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.cycleBackground();
      c.addPage();
      expect(c.page.background, c.notebook.pages.first.background);
      expect(c.page.background, isNot(PageBackground.blank));
      final back = Notebook.fromJson(c.notebook.toJson());
      expect(back.nextBackground, c.notebook.nextBackground);
    });

    test('fundo dos cadernos novos é uma configuração separada', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.cycleBackground();
      expect(c.settings.newNotebookBackground, 0);
      final s = AppSettings()..newNotebookBackground = 2;
      expect(AppSettings.fromJson(s.toJson()).newNotebookBackground, 2);
    });
  });

  group('páginas em coluna', () {
    test('goToPage pede rolagem mesmo para a mesma página', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      final t0 = c.scrollTick;
      c.goToPage(0);
      expect(c.scrollTick, greaterThan(t0));
      expect(c.scrollForce, isTrue);
    });

    test('activatePage troca a página ativa sem pedir rolagem', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.addPage();
      c.addPage();
      final t0 = c.scrollTick;
      c.activatePage(0);
      expect(c.pageIndex, 0);
      expect(c.scrollTick, t0);
    });

    testWidgets('depois de ir à página 2, a caneta desenha nela', (tester) async {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.addPage();
      c.goToPage(0);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CanvasView(controller: c)),
      ));
      c.goToPage(1);
      await tester.pump();

      final g = await tester.startGesture(const Offset(300, 200),
          kind: PointerDeviceKind.stylus);
      for (var i = 1; i <= 10; i++) {
        await g.moveBy(const Offset(20, 5));
      }
      await g.up();
      await tester.pump();

      expect(c.pageIndex, 1);
      expect(c.notebook.pages[1].strokes.length, 1);
      expect(c.notebook.pages[0].strokes, isEmpty);
    });
  });

  group('tinta e cores compartilhadas', () {
    test('caneta e tinteiro dividem a cor e a paleta', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.setColor(0xFFC62828);
      c.setTool(Tool.fountain);
      expect(c.color, 0xFFC62828);
      expect(c.palette, CanvasController.penColors);
      c.beginStroke(const Offset(10, 10), 0.5, timeMs: 0);
      c.extendStroke(const Offset(40, 10), 0.5, timeMs: 10);
      c.endStroke();
      expect(c.page.strokes.single.color, 0xFFC62828);
    });

    test('estabilização persiste nas configurações', () {
      final s = AppSettings()
        ..stabBrush = 0.8
        ..pressFountain = 0.7
        ..sharpFountain = 0.2;
      final b = AppSettings.fromJson(s.toJson());
      expect(b.stabBrush, closeTo(0.8, 1e-9));
      expect(b.pressFountain, closeTo(0.7, 1e-9));
      expect(b.sharpFountain, closeTo(0.2, 1e-9));
      // arquivo antigo: uma estabilização valia para todas
      final old = AppSettings.fromJson({'stabilization': 0.9});
      expect(old.stabPen, closeTo(0.9, 1e-9));
      expect(old.stabFountain, closeTo(0.9, 1e-9));
    });

    test('canto fechado não é arredondado demais', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.beginStroke(const Offset(100, 100), 0.5);
      for (var x = 104.0; x <= 200; x += 4) {
        c.extendStroke(Offset(x, 100), 0.5);
      }
      for (var y = 104.0; y <= 200; y += 4) {
        c.extendStroke(Offset(200, y), 0.5);
      }
      c.endStroke();
      final pts = c.page.strokes.isEmpty ? <Offset>[] : c.page.strokes.single.points;
      expect(pts, isNotEmpty);
    });
  });

  group('formatos de caderno', () {
    test('formato persiste e define o tamanho da página', () {
      for (final f in NotebookFormat.values) {
        final nb = Notebook.empty('i', 'n', f);
        final back = Notebook.fromJson(nb.toJson());
        expect(back.format, f);
      }
      final h = Notebook.empty('i', 'n', NotebookFormat.landscape);
      expect(h.pageSize.width, greaterThan(h.pageSize.height));
      expect(Notebook.empty('i', 'n').pageSize.height, greaterThan(1000));
    });

    test('cadernos antigos (sem formato) abrem como vertical', () {
      final j = Notebook.empty('i', 'n').toJson()..remove('fmt');
      expect(Notebook.fromJson(j).format, NotebookFormat.portrait);
    });

    testWidgets('quadro infinito aceita traço fora da área de uma página', (tester) async {
      final c = CanvasController(Notebook.empty('t', 't', NotebookFormat.board));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CanvasView(controller: c)),
      ));
      final g = await tester.startGesture(const Offset(700, 500),
          kind: PointerDeviceKind.stylus);
      for (var i = 1; i <= 10; i++) {
        await g.moveBy(const Offset(20, 5));
      }
      await g.up();
      await tester.pump();
      expect(c.notebook.pages.length, 1);
      expect(c.page.strokes.length, 1);
    });
  });

  group('papel e fundos', () {
    test('espaçamento e preenchimento persistem', () {
      final s = AppSettings()
        ..lineSpacing = 56
        ..shapeFill = true;
      final back = AppSettings.fromJson(s.toJson());
      expect(back.lineSpacing, 56);
      expect(back.shapeFill, isTrue);
    });

    test('forma fechada sai com fundo claro; reta não', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.settings.shapeFill = true;
      c.setShape(ShapeKind.rectangle);
      c.beginStroke(const Offset(100, 100), 0.5);
      c.extendStroke(const Offset(300, 220), 0.5);
      c.endStroke();
      final f = c.page.strokes.single.fill;
      expect(f, isNotNull);
      expect((f! >> 24) & 0xFF, lessThan(80)); // baixa opacidade
      c.setShape(ShapeKind.line);
      c.beginStroke(const Offset(100, 400), 0.5);
      c.extendStroke(const Offset(300, 400), 0.5);
      c.endStroke();
      expect(c.page.strokes.last.fill, isNull);
      final back = Stroke.fromJson(c.page.strokes.first.toJson());
      expect(back.fill, f);
    });
  });

  group('formas inteligentes', () {
    CanvasController make() => CanvasController(Notebook.empty('t', 't'));

    void drawPoly(CanvasController c, List<Offset> pts) {
      c.beginStroke(pts.first, 0.5);
      for (final p in pts.skip(1)) {
        c.extendStroke(p, 0.5);
      }
      c.endStroke();
    }

    test('é uma caneta da subaba e não vem ligada', () {
      final c = make();
      expect(c.tool, Tool.pen);
      expect(c.smartActive, isFalse);
      c.setPenType(Tool.smart);
      expect(c.smartActive, isTrue);
      expect(c.isPenTool, isTrue);
      expect(c.lastPen, Tool.smart);
      c.setShape(ShapeKind.line);
      expect(c.smartActive, isFalse);
    });

    test('ao soltar, um quadrado desenhado à mão vira retângulo limpo', () {
      final c = make();
      c.setPenType(Tool.smart);
      drawPoly(c, _polyPath(const [
        Offset(100, 100), Offset(300, 100), Offset(300, 300), Offset(100, 300), Offset(100, 100),
      ]));
      final s = c.page.strokes.single;
      expect(s.points.length, 5);
      expect(s.smooth, isFalse);
      expect(c.editing, same(s));
    });

    test('desenho que não é forma continua traço livre', () {
      final c = make();
      c.setPenType(Tool.smart);
      drawPoly(c, [for (var i = 0; i < 60; i++) Offset(100 + i * 4.0, 100 + 30 * math.sin(i / 4))]);
      final s = c.page.strokes.single;
      expect(s.points.length, greaterThan(10));
      expect(c.editing, isNull);
    });

    test('alça de canto redimensiona a forma', () {
      final c = make();
      c.setShape(ShapeKind.rectangle);
      c.beginStroke(const Offset(100, 100), 0.5);
      c.extendStroke(const Offset(200, 200), 0.5);
      c.endStroke();
      final s = c.page.strokes.single;
      expect(c.editing, same(s));
      final h = c.hitHandle(const Offset(200, 200), 10);
      expect(h, 4); // canto inferior direito
      c.beginResize(h!);
      c.resizeTo(const Offset(300, 250));
      c.endResize();
      final b = boundsOf(s.points);
      expect(b.right, closeTo(300, 1e-6));
      expect(b.bottom, closeTo(250, 1e-6));
      expect(b.left, closeTo(100, 1e-6));
    });

    test('reta: arrastar a ponta muda o comprimento', () {
      final c = make();
      c.setShape(ShapeKind.line);
      c.beginStroke(const Offset(100, 100), 0.5);
      c.extendStroke(const Offset(200, 100), 0.5);
      c.endStroke();
      c.beginResize(1);
      c.resizeTo(const Offset(400, 100));
      c.endResize();
      expect(c.page.strokes.single.points.last.dx, closeTo(400, 1e-6));
    });

    test('começar outro traço tira as alças', () {
      final c = make();
      c.setShape(ShapeKind.rectangle);
      c.beginStroke(const Offset(100, 100), 0.5);
      c.extendStroke(const Offset(200, 200), 0.5);
      c.endStroke();
      expect(c.editing, isNotNull);
      c.beginStroke(const Offset(500, 500), 0.5);
      expect(c.editing, isNull);
    });
  });

  group('cores arrastadas e dica do Shift', () {
    test('substituir uma cor da barra principal e persistir', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.replacePaletteColor(2, 0xFF123456);
      expect(c.palette[2], 0xFF123456);
      expect(c.color, 0xFF123456);
      final back = AppSettings.fromJson(c.settings.toJson());
      expect(back.penPalette[2], 0xFF123456);
      expect(back.penPalette.length, AppSettings.defaultPenPalette.length);
    });

    test('marca-texto tem paleta própria', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.setTool(Tool.highlighter);
      c.replacePaletteColor(0, 0xFF00FF00);
      expect(c.settings.hlPalette[0], 0xFF00FF00);
      expect(c.settings.penPalette[0], AppSettings.defaultPenPalette[0]);
    });

    test('índice inválido é ignorado', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.replacePaletteColor(99, 0xFF123456);
      expect(c.palette, AppSettings.defaultPenPalette);
    });

    test('dica do Shift some depois de usar', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      expect(c.settings.shiftHintSeen, isFalse);
      c.markShiftUsed();
      expect(AppSettings.fromJson(c.settings.toJson()).shiftHintSeen, isTrue);
    });
  });

  group('barra reposicionável', () {
    test('posição da barra persiste', () {
      final s = AppSettings();
      expect(s.toolbarPos, ToolbarPos.top);
      for (final p in ToolbarPos.values) {
        s.toolbarPos = p;
        expect(AppSettings.fromJson(s.toJson()).toolbarPos, p);
      }
    });
  });

  group('forma presa à caneta', () {
    test('depois de encaixar, mover a caneta redimensiona a forma', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.beginStroke(const Offset(100, 100), 0.5);
      final pts = _polyPath(const [
        Offset(100, 100), Offset(300, 100), Offset(300, 300), Offset(100, 300), Offset(100, 100),
      ]);
      for (final q in pts.skip(1)) {
        c.extendStroke(q, 0.5);
      }
      expect(c.holdDetected(), isTrue);
      final before = boundsOf(c.current!.points);
      c.extendStroke(Offset(before.right + 100, before.bottom + 100), 0.5);
      final after = boundsOf(c.current!.points);
      expect(after.width, greaterThan(before.width * 1.3));
      expect(after.height, greaterThan(before.height * 1.3));
      c.endStroke();
      expect(c.page.strokes.length, 1);
    });

    test('tremor pequeno depois de encaixar não mexe na forma', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.beginStroke(const Offset(100, 100), 0.5);
      for (final q in _polyPath(const [
        Offset(100, 100), Offset(300, 100), Offset(300, 300), Offset(100, 300), Offset(100, 100),
      ]).skip(1)) {
        c.extendStroke(q, 0.5);
      }
      expect(c.holdDetected(), isTrue);
      final before = boundsOf(c.current!.points);
      c.extendStroke(const Offset(103, 101), 0.5);
      expect(boundsOf(c.current!.points), before);
    });
  });

  group('estilos de traço', () {
    test('estilo vai para o traço, persiste e o tinteiro vira largura uniforme', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.setStrokeStyle(StrokeStyle.dashed);
      c.setTool(Tool.fountain);
      c.beginStroke(const Offset(10, 10), 0.5, timeMs: 0);
      for (var i = 1; i <= 20; i++) {
        c.extendStroke(Offset(10.0 + i * 6, 10), 0.5, timeMs: i * 8);
      }
      c.endStroke();
      final s = c.page.strokes.single;
      expect(s.style, StrokeStyle.dashed);
      expect(s.variable, isFalse);
      final back = Stroke.fromJson(s.toJson());
      expect(back.style, StrokeStyle.dashed);
      expect(AppSettings.fromJson(c.settings.toJson()).strokeStyle, StrokeStyle.dashed);
    });

    test('tracejado e pontilhado geram menos traço que o contínuo', () {
      Stroke mk(StrokeStyle st) => Stroke(
            id: 'x',
            points: [for (var i = 0; i <= 100; i++) Offset(i * 3.0, 0)],
            color: 0xFF000000,
            width: 3,
            highlighter: false,
            smooth: false,
            pressure: 0.5,
            fountain: false,
            style: st,
          );
      double len(Path p) =>
          p.computeMetrics().fold(0.0, (a, m) => a + m.length);
      final solid = len(mk(StrokeStyle.solid).path);
      final dash = len(mk(StrokeStyle.dashed).dashedPath);
      final dot = len(mk(StrokeStyle.dotted).dashedPath);
      expect(dash, lessThan(solid * 0.8));
      expect(dot, lessThan(dash));
    });

    test('caneta comum e marca-texto: só a caneta recebe o estilo', () {
      final c = CanvasController(Notebook.empty('t', 't'));
      c.setStrokeStyle(StrokeStyle.dotted);
      c.setTool(Tool.highlighter);
      c.beginStroke(const Offset(10, 10), 0.5);
      c.extendStroke(const Offset(100, 10), 0.5);
      c.endStroke();
      expect(c.page.strokes.single.style, StrokeStyle.solid);
    });
  });

  group('exportação', () {
    Notebook sample(NotebookFormat f) {
      final c = CanvasController(Notebook.empty('t', 'Aula', f));
      c.settings.shapeFill = true;
      c.setStrokeStyle(StrokeStyle.dotted);
      c.beginStroke(const Offset(100, 100), 0.5);
      for (var i = 1; i <= 30; i++) {
        c.extendStroke(Offset(100 + i * 5.0, 100 + i * 2.0), 0.5);
      }
      c.endStroke();
      c.setStrokeStyle(StrokeStyle.solid);
      c.setTool(Tool.fountain);
      c.beginStroke(const Offset(100, 300), 0.5, timeMs: 0);
      for (var i = 1; i <= 30; i++) {
        c.extendStroke(Offset(100 + i * 5.0, 300 + 20 * math.sin(i / 3)), 0.6, timeMs: i * 8);
      }
      c.endStroke();
      c.setShape(ShapeKind.rectangle);
      c.beginStroke(const Offset(300, 400), 0.5);
      c.extendStroke(const Offset(500, 560), 0.5);
      c.endStroke();
      c.setTool(Tool.highlighter);
      c.beginStroke(const Offset(100, 600), 0.5);
      c.extendStroke(const Offset(400, 600), 0.5);
      c.endStroke();
      if (f != NotebookFormat.board) c.addPage();
      return c.notebook;
    }

    test('.notas: ida e volta preserva traços, estilos, preenchimento e formato', () {
      final nb = sample(NotebookFormat.landscape);
      final bytes = encodeNotas(nb);
      expect(bytes[0], 0x1f); // gzip
      final back = decodeNotas(bytes, 'novo-id');
      expect(back.id, 'novo-id');
      expect(back.format, NotebookFormat.landscape);
      expect(back.pages.length, nb.pages.length);
      expect(back.pages.first.strokes.length, nb.pages.first.strokes.length);
      final a = nb.pages.first.strokes, b = back.pages.first.strokes;
      for (var i = 0; i < a.length; i++) {
        expect(b[i].points.length, a[i].points.length);
        expect(b[i].style, a[i].style);
        expect(b[i].fill, a[i].fill);
        expect(b[i].fountain, a[i].fountain);
        expect(b[i].highlighter, a[i].highlighter);
      }
    });

    test('.notas rejeita arquivo que não é do app', () {
      expect(() => decodeNotas(Uint8List.fromList(utf8.encode('{"a":1}')), 'x'),
          throwsFormatException);
      expect(() => decodeNotas(Uint8List.fromList(utf8.encode('lixo')), 'x'),
          throwsFormatException);
    });

    test('.notas é bem menor que o JSON puro', () {
      final nb = sample(NotebookFormat.portrait);
      expect(encodeNotas(nb).length, lessThan(jsonEncode(nb.toJson()).length));
    });

    test('PDF: uma página por página do caderno', () async {
      final nb = sample(NotebookFormat.portrait);
      final pdf = await buildPdf(nb);
      expect(utf8.decode(pdf.sublist(0, 5)), '%PDF-');
      expect(pdf.length, greaterThan(500));
    });

    test('PDF do quadro infinito também é gerado', () async {
      final pdf = await buildPdf(sample(NotebookFormat.board));
      expect(utf8.decode(pdf.sublist(0, 5)), '%PDF-');
      final empty = await buildPdf(Notebook.empty('e', 'vazio', NotebookFormat.board));
      expect(utf8.decode(empty.sublist(0, 5)), '%PDF-');
    });
  });

  group('limites da mãozinha', () {
    const page = Size(1000, 1414);
    final views = [
      const Size(800, 600),
      const Size(1600, 900),
      const Size(360, 780),
      const Size(1280, 400),
    ];

    test('página que cabe na largura fica centralizada e não anda na horizontal', () {
      for (final v in views) {
        const scale = 0.3; // 300 px de largura
        if (v.width < 332) continue;
        final r = clampPanOffset(
            offset: const Offset(999, 0), scale: scale, view: v, page: page, pages: 3);
        expect(r.dx, closeTo((v.width - page.width * scale) / 2, 1e-9));
        final l = clampPanOffset(
            offset: const Offset(-999, 0), scale: scale, view: v, page: page, pages: 3);
        expect(l.dx, r.dx);
      }
    });

    test('com zoom maior que a janela, anda só até as bordas encostarem na margem', () {
      for (final v in views) {
        final scale = (v.width * 1.6) / page.width;
        final pw = page.width * scale;
        final right = clampPanOffset(
            offset: const Offset(5000, 0), scale: scale, view: v, page: page, pages: 2);
        final left = clampPanOffset(
            offset: const Offset(-5000, 0), scale: scale, view: v, page: page, pages: 2);
        expect(right.dx, kPanMargin);
        expect(left.dx, closeTo(v.width - pw - kPanMargin, 1e-9));
      }
    });

    test('vertical: para no topo da primeira e no fim da última página', () {
      for (final v in views) {
        final scale = (v.width * 0.9) / page.width;
        final docH = (3 * (page.height + kPageGap) - kPageGap) * scale;
        if (docH + 2 * kPanMargin <= v.height) continue;
        final top = clampPanOffset(
            offset: const Offset(0, 9999), scale: scale, view: v, page: page, pages: 3);
        final bottom = clampPanOffset(
            offset: const Offset(0, -99999), scale: scale, view: v, page: page, pages: 3);
        expect(top.dy, kPanMargin);
        expect(bottom.dy, closeTo(v.height - docH - kPanMargin, 1e-9));
      }
    });

    test('coluna menor que a janela fica fixa no topo (sem balançar)', () {
      final r1 = clampPanOffset(
          offset: const Offset(0, 300), scale: 0.2, view: const Size(800, 900), page: page, pages: 1);
      final r2 = clampPanOffset(
          offset: const Offset(0, -300), scale: 0.2, view: const Size(800, 900), page: page, pages: 1);
      expect(r1.dy, kPanMargin);
      expect(r2.dy, kPanMargin);
    });

    test('é idempotente: aplicar de novo não muda nada', () {
      for (final v in views) {
        for (final scale in [0.2, 0.6, 1.0, 2.5]) {
          final a = clampPanOffset(
              offset: const Offset(123, -456), scale: scale, view: v, page: page, pages: 4);
          final b = clampPanOffset(offset: a, scale: scale, view: v, page: page, pages: 4);
          expect(b, a);
        }
      }
    });
  });

  group('imagens', () {
    PageImage mk() => PageImage(
          id: 'i1',
          bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]),
          rect: const Rect.fromLTWH(100, 200, 300, 150),
        );

    test('salva e reabre com a imagem', () {
      final nb = Notebook.empty('a', 'A');
      nb.pages.first.images.add(mk());
      final back = Notebook.fromJson(jsonDecode(jsonEncode(nb.toJson())) as Map<String, dynamic>);
      final im = back.pages.first.images.single;
      expect(im.rect, const Rect.fromLTWH(100, 200, 300, 150));
      expect(im.bytes.length, 7);
    });

    test('seleciona, move com desfazer e apaga', () {
      final c = CanvasController(Notebook.empty('a', 'A'));
      final im = mk();
      c.page.images.add(im);
      c.tool = Tool.select;
      expect(c.selectImageAt(const Offset(150, 250)), isTrue);
      c.beginImageMove(const Offset(150, 250));
      c.imageDragTo(const Offset(170, 260));
      c.endImageDrag();
      expect(im.rect.topLeft, const Offset(120, 210));
      c.undo();
      expect(im.rect.topLeft, const Offset(100, 200));
      c.redo();
      expect(im.rect.topLeft, const Offset(120, 210));
      c.selectImageAt(const Offset(150, 250));
      c.deleteSelectedImage();
      expect(c.page.images, isEmpty);
      c.undo();
      expect(c.page.images.length, 1);
    });

    test('redimensiona pelo canto mantendo a proporção', () {
      final c = CanvasController(Notebook.empty('a', 'A'));
      final im = mk();
      c.page.images.add(im);
      c.tool = Tool.select;
      c.selectImageAt(const Offset(150, 250));
      c.beginImageResize(2); // canto inferior direito
      c.imageDragTo(const Offset(700, 400));
      c.endImageDrag();
      expect(im.rect.topLeft, const Offset(100, 200));
      expect(im.rect.width / im.rect.height, closeTo(2.0, 1e-6));
      expect(im.rect.width, closeTo(600, 1e-6));
    });
  });

  group('ajustes por caneta', () {
    test('pressão: 0 = constante, 0.5 = padrão, 1 = mais sensível', () {
      expect(pressureFactor(Tool.fountain, 0.0, 0), closeTo(1, 1e-9));
      expect(pressureFactor(Tool.fountain, 1.0, 0), closeTo(1, 1e-9));
      expect(pressureFactor(Tool.fountain, 1.0, 0.5), closeTo(0.28 + 1.55, 1e-9));
      expect(pressureFactor(Tool.brush, 0.5, 0.5), closeTo(0.12 + 1.0, 1e-9));
      final lo = pressureFactor(Tool.fountain, 0.1, 1);
      final hi = pressureFactor(Tool.fountain, 0.9, 1);
      expect(hi, greaterThan(lo));
      expect(hi, lessThanOrEqualTo(2.3));
    });

    test('ponta mais aguda afina mais', () {
      expect(tipMin(1.0), lessThan(tipMin(0.5)));
      expect(tipMin(0.5), closeTo(0.45, 1e-9));
    });
  });
}
