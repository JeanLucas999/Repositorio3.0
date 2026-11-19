import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canvas_controller.dart';
import 'models.dart';
import 'palm_guard.dart';

/// Tamanho lógico da página (proporção A4).
const Size kPageSize = Size(1000, 1414);

void paintStroke(Canvas canvas, Stroke s) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = s.highlighter ? StrokeCap.square : StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = s.effectiveWidth
    ..isAntiAlias = true
    ..color = s.highlighter ? Color(s.color).withAlpha(105) : Color(s.color);
  canvas.drawPath(s.path, paint);
}

bool _isPen(PointerDeviceKind k) =>
    k == PointerDeviceKind.stylus || k == PointerDeviceKind.invertedStylus;

class CanvasView extends StatefulWidget {
  const CanvasView({super.key, required this.controller});
  final CanvasController controller;

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _viewSize = Size.zero;
  bool _fitted = false;
  int _lastFitTick = 0;

  final Map<int, Offset> _touches = {};
  int? _drawPointer;
  bool _drawIsTouch = false;
  Timer? _holdTimer;
  Offset _holdAnchor = Offset.zero;

  late final PalmGuard _guard = PalmGuard(c.settings);

  CanvasController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _lastFitTick = c.fitTick;
    c.addListener(_onController);
  }

  @override
  void dispose() {
    c.removeListener(_onController);
    _holdTimer?.cancel();
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    setState(() {
      if (c.fitTick != _lastFitTick) {
        _lastFitTick = c.fitTick;
        _fit();
      }
    });
  }

  void _fit() {
    final w = _viewSize.width;
    if (w <= 0) return;
    _scale = ((w - 32) / kPageSize.width).clamp(0.2, 4.0).toDouble();
    _offset = Offset((w - kPageSize.width * _scale) / 2, 16);
  }

  Offset _toPage(Offset screen) => (screen - _offset) / _scale;

  double _norm(PointerEvent e) {
    if (e.pressureMax > e.pressureMin) {
      return ((e.pressure - e.pressureMin) / (e.pressureMax - e.pressureMin))
          .clamp(0.0, 1.0)
          .toDouble();
    }
    return 0.5; // mouse: sem pressão
  }

  void _cancelTouchDrawing() {
    if (_drawPointer != null && _drawIsTouch) {
      c.cancelStroke();
      _drawPointer = null;
      _holdTimer?.cancel();
    }
  }

  // ---------------- ponteiros ----------------
  void _onHover(PointerHoverEvent e) {
    if (_isPen(e.kind)) _guard.onPenHover(e.timeStamp.inMilliseconds);
  }

  void _onDown(PointerDownEvent e) {
    final now = e.timeStamp.inMilliseconds;

    if (_isPen(e.kind)) {
      _guard.onPenDown(now);
      if (c.settings.palmRejection) {
        // A palma pode ter pousado antes da caneta: esses toques viram lixo.
        for (final id in _touches.keys) {
          _guard.ignore(id);
        }
        _touches.clear();
      }
      _cancelTouchDrawing(); // caneta tem prioridade sobre o dedo
    }

    if (e.kind == PointerDeviceKind.touch) {
      if (_guard.rejectTouchDown(e.pointer, now, e.radiusMajor)) return;
      _touches[e.pointer] = e.localPosition;
      if (_touches.length >= 2) {
        _cancelTouchDrawing();
        return;
      }
      if (!c.fingerDraws) return;
      _startDraw(e, touch: true);
      return;
    }
    if (_drawPointer != null) return;
    _startDraw(e, touch: false);
  }

  void _startDraw(PointerDownEvent e, {required bool touch}) {
    _drawPointer = e.pointer;
    _drawIsTouch = touch;
    c.beginStroke(
      _toPage(e.localPosition),
      _norm(e),
      asEraser: e.kind == PointerDeviceKind.invertedStylus,
    );
    _holdAnchor = e.localPosition;
    _restartHold();
  }

  void _restartHold() {
    _holdTimer?.cancel();
    _holdTimer = Timer(Duration(milliseconds: c.settings.holdMs), () {
      if (_drawPointer == null) return;
      if (c.holdDetected()) HapticFeedback.selectionClick();
    });
  }

  void _onMove(PointerMoveEvent e) {
    if (_isPen(e.kind)) _guard.onPenMove(e.timeStamp.inMilliseconds);

    if (e.kind == PointerDeviceKind.touch &&
        _guard.rejectTouchMove(e.pointer, e.radiusMajor)) {
      // O toque virou palma (ou já era): sai da conta e, se desenhava, cancela.
      _touches.remove(e.pointer);
      if (e.pointer == _drawPointer) _cancelTouchDrawing();
      return;
    }

    if (e.pointer == _drawPointer) {
      c.extendStroke(_toPage(e.localPosition), _norm(e));
      if ((e.localPosition - _holdAnchor).distance > 4) {
        _holdAnchor = e.localPosition;
        _restartHold();
      }
      if (e.kind == PointerDeviceKind.touch) _touches[e.pointer] = e.localPosition;
      return;
    }
    if (e.kind != PointerDeviceKind.touch) return;

    final old = _touches[e.pointer];
    if (old == null) return;
    if (_touches.length == 1) {
      setState(() => _offset += e.localPosition - old);
      _touches[e.pointer] = e.localPosition;
      return;
    }
    final ids = _touches.keys.take(2).toList();
    if (!ids.contains(e.pointer)) {
      _touches[e.pointer] = e.localPosition;
      return;
    }
    final oa = _touches[ids[0]]!, ob = _touches[ids[1]]!;
    _touches[e.pointer] = e.localPosition;
    _applyPinch(oa, ob, _touches[ids[0]]!, _touches[ids[1]]!);
  }

  void _applyPinch(Offset oa, Offset ob, Offset na, Offset nb) {
    final oldDist = (oa - ob).distance;
    final newDist = (na - nb).distance;
    if (oldDist < 1) return;
    final oldC = (oa + ob) / 2, newC = (na + nb) / 2;
    final pagePt = (oldC - _offset) / _scale;
    final ns = (_scale * newDist / oldDist).clamp(0.2, 8.0).toDouble();
    setState(() {
      _scale = ns;
      _offset = newC - pagePt * ns;
    });
  }

  void _onUp(PointerEvent e, {bool cancel = false}) {
    if (_isPen(e.kind)) _guard.onPenUp(e.timeStamp.inMilliseconds);
    _guard.touchEnded(e.pointer);
    _touches.remove(e.pointer);
    if (e.pointer == _drawPointer) {
      _holdTimer?.cancel();
      if (cancel) {
        c.cancelStroke();
      } else {
        c.endStroke();
      }
      _drawPointer = null;
    }
  }

  void _onSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final kb = HardwareKeyboard.instance;
    if (kb.isControlPressed) {
      final f = math.exp(-e.scrollDelta.dy / 300);
      final pagePt = (e.localPosition - _offset) / _scale;
      final ns = (_scale * f).clamp(0.2, 8.0).toDouble();
      setState(() {
        _scale = ns;
        _offset = e.localPosition - pagePt * ns;
      });
    } else {
      final shift = kb.isShiftPressed;
      setState(() {
        _offset -= Offset(shift ? e.scrollDelta.dy : e.scrollDelta.dx,
            shift ? 0 : e.scrollDelta.dy);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      _viewSize = constraints.biggest;
      if (!_fitted) {
        _fitted = true;
        _fit();
      }
      c.pixelSize = 1 / _scale;
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: (e) => _onUp(e, cancel: true),
        onPointerHover: _onHover,
        onPointerSignal: _onSignal,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: scheme.surfaceContainerHighest),
              // Camadas, de baixo para cima: papel -> marca-texto -> tinta -> traço ao vivo.
              // O marca-texto fica ATRÁS da tinta, então o texto continua 100% da cor dele.
              RepaintBoundary(
                child: CustomPaint(
                  painter: _BackgroundPainter(c, _scale, _offset),
                  size: Size.infinite,
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: _HighlightPainter(c, _scale, _offset),
                  size: Size.infinite,
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: _InkPainter(c, _scale, _offset),
                  size: Size.infinite,
                ),
              ),
              CustomPaint(
                painter: _LiveInkPainter(c, _scale, _offset),
                size: Size.infinite,
              ),
            ],
          ),
        ),
      );
    });
  }
}

Rect _visibleRect(Size size, Offset offset, double scale) => Rect.fromLTWH(
    -offset.dx / scale, -offset.dy / scale, size.width / scale, size.height / scale);

void _beginPage(Canvas canvas, Offset offset, double scale) {
  canvas.save();
  canvas.translate(offset.dx, offset.dy);
  canvas.scale(scale);
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.c, this.scale, this.offset) : super(repaint: c.committed);

  final CanvasController c;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    _beginPage(canvas, offset, scale);
    final pageRect = Offset.zero & kPageSize;
    canvas.drawShadow(Path()..addRect(pageRect), Colors.black, 3, false);
    canvas.drawRect(pageRect, Paint()..color = Colors.white);
    _paintLines(canvas, c.page.background);
    canvas.restore();
  }

  void _paintLines(Canvas canvas, PageBackground bg) {
    if (bg == PageBackground.blank) return;
    final p = Paint()
      ..color = const Color(0xFFD5DCE8)
      ..strokeWidth = 1;
    const step = 40.0;
    if (bg == PageBackground.ruled) {
      for (var y = 100.0; y < kPageSize.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(kPageSize.width, y), p);
      }
    } else {
      for (var y = step; y < kPageSize.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(kPageSize.width, y), p);
      }
      for (var x = step; x < kPageSize.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, kPageSize.height), p);
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.scale != scale || old.offset != offset;
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.c, this.scale, this.offset)
      : super(repaint: Listenable.merge([c.committed, c.liveHighlight]));

  final CanvasController c;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    _beginPage(canvas, offset, scale);
    canvas.clipRect(Offset.zero & kPageSize);
    final visible = _visibleRect(size, offset, scale);
    for (final s in c.page.strokes) {
      if (s.highlighter && s.bounds.overlaps(visible)) paintStroke(canvas, s);
    }
    final live = c.current;
    if (live != null && live.highlighter) paintStroke(canvas, live);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.scale != scale || old.offset != offset;
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.c, this.scale, this.offset) : super(repaint: c.committed);

  final CanvasController c;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    _beginPage(canvas, offset, scale);
    canvas.clipRect(Offset.zero & kPageSize);
    final visible = _visibleRect(size, offset, scale);
    for (final s in c.page.strokes) {
      if (!s.highlighter && s.bounds.overlaps(visible)) paintStroke(canvas, s);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InkPainter old) => old.scale != scale || old.offset != offset;
}

class _LiveInkPainter extends CustomPainter {
  _LiveInkPainter(this.c, this.scale, this.offset) : super(repaint: c.live);

  final CanvasController c;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final s = c.current;
    if (s == null || s.highlighter) return; // marca-texto ao vivo é pintado atrás
    _beginPage(canvas, offset, scale);
    canvas.clipRect(Offset.zero & kPageSize);
    paintStroke(canvas, s);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LiveInkPainter old) => old.scale != scale || old.offset != offset;
}
