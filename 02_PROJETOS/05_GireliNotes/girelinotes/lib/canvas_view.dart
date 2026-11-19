import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canvas_controller.dart';
import 'models.dart';

/// Tamanho lógico da página (proporção A4).
const Size kPageSize = Size(1000, 1414);

void paintStroke(Canvas canvas, Stroke s) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = s.highlighter ? StrokeCap.square : StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = s.effectiveWidth
    ..isAntiAlias = true
    ..color = s.highlighter ? Color(s.color).withAlpha(90) : Color(s.color);
  canvas.drawPath(s.path, paint);
}

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

  // ---------------- ponteiros ----------------
  void _onDown(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.touch) {
      _touches[e.pointer] = e.localPosition;
      if (_touches.length >= 2) {
        if (_drawPointer != null && _drawIsTouch) {
          c.cancelStroke();
          _drawPointer = null;
          _holdTimer?.cancel();
        }
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
    _holdTimer = Timer(const Duration(milliseconds: 500), () {
      if (_drawPointer == null) return;
      if (c.holdDetected()) HapticFeedback.selectionClick();
    });
  }

  void _onMove(PointerMoveEvent e) {
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
    return LayoutBuilder(builder: (context, constraints) {
      _viewSize = constraints.biggest;
      if (!_fitted) {
        _fitted = true;
        _fit();
      }
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: (e) => _onUp(e, cancel: true),
        onPointerSignal: _onSignal,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
              RepaintBoundary(
                child: CustomPaint(
                  painter: _PagePainter(c, _scale, _offset, c.version, c.pageIndex),
                  size: Size.infinite,
                ),
              ),
              CustomPaint(
                painter: _LivePainter(c, _scale, _offset),
                size: Size.infinite,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PagePainter extends CustomPainter {
  _PagePainter(this.c, this.scale, this.offset, this.version, this.pageIndex)
      : super(repaint: c.committed);

  final CanvasController c;
  final double scale;
  final Offset offset;
  final int version;
  final int pageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final pageRect = Offset.zero & kPageSize;
    canvas.drawShadow(Path()..addRect(pageRect), Colors.black, 3, false);
    canvas.drawRect(pageRect, Paint()..color = Colors.white);
    _paintBackground(canvas, c.page.background);

    canvas.clipRect(pageRect);
    final visible = Rect.fromLTWH(
        -offset.dx / scale, -offset.dy / scale, size.width / scale, size.height / scale);
    for (final s in c.page.strokes) {
      if (s.bounds.overlaps(visible)) paintStroke(canvas, s);
    }
    canvas.restore();
  }

  void _paintBackground(Canvas canvas, PageBackground bg) {
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
  bool shouldRepaint(_PagePainter old) =>
      old.scale != scale ||
      old.offset != offset ||
      old.version != version ||
      old.pageIndex != pageIndex;
}

class _LivePainter extends CustomPainter {
  _LivePainter(this.c, this.scale, this.offset) : super(repaint: c.live);

  final CanvasController c;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final s = c.current;
    if (s == null) return;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.clipRect(Offset.zero & kPageSize);
    paintStroke(canvas, s);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LivePainter old) => old.scale != scale || old.offset != offset;
}
