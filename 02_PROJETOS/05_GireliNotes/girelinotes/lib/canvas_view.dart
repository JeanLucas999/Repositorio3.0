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

/// Espaço entre páginas na coluna e distância de topo a topo.
const double kPageGap = 24;

/// Opacidade do realce (0..255): fixa, para o amarelo ficar igual em todo lugar.
const int kHighlightAlpha = 120;

/// Pinta todos os marca-textos juntos numa camada só: onde um traço cruza
/// outro (ou ele mesmo) o realce NÃO escurece; fica uniforme. Pontas redondas.
void paintHighlighters(Canvas canvas, Iterable<Stroke> strokes, Rect bounds) {
  var any = false;
  for (final s in strokes) {
    any = true;
    break;
  }
  if (!any) return;
  canvas.saveLayer(bounds, Paint()..color = const Color.fromARGB(kHighlightAlpha, 0, 0, 0));
  for (final s in strokes) {
    paintStroke(canvas, s, opaque: true);
  }
  canvas.restore();
}

/// Fundo claro e translúcido de formas fechadas (fica atrás da tinta).
void paintFill(Canvas canvas, Stroke s) {
  final f = s.fill;
  if (f == null || s.points.length < 3) return;
  canvas.drawPath(
    Path()..addPolygon(s.points, true),
    Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = Color(f),
  );
}

void paintStroke(Canvas canvas, Stroke s, {bool opaque = false}) {
  if (s.variable) {
    // Caneta tinteiro: contorno preenchido de largura variável.
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = Color(s.color);
    canvas.drawPath(s.ribbonPath, fill);
    canvas.drawPath(s.capsPath, fill);
    return;
  }
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = s.paintWidth
    ..isAntiAlias = true
    ..color = s.highlighter && !opaque
        ? Color(s.color).withAlpha(kHighlightAlpha)
        : Color(s.color).withAlpha(255);
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
  double _fitScale = 1;
  Offset _fitOffset = Offset.zero;
  int _lastFitTick = 0;
  int _lastScrollTick = 0;
  int _lastViewTick = 0;
  double _drawTop = 0; // topo (no documento) da página em que o traço começou

  final Map<int, Offset> _touches = {};
  int _panAxis = 0; // 0 livre, 1 horizontal, 2 vertical (com Shift)
  Offset _panAccum = Offset.zero;
  int? _panPointer; // caneta/mouse arrastando a página (mãozinha)
  Offset _panLast = Offset.zero;
  int? _drawPointer;
  int? _resizePointer; // arrastando uma alça de redimensionar
  bool _drawIsTouch = false;
  Timer? _holdTimer;
  Offset _holdAnchor = Offset.zero;

  late final PalmGuard _guard = PalmGuard(c.settings);

  CanvasController get c => widget.controller;
  Size get _ps => c.notebook.pageSize;
  bool get _inf => c.notebook.infinite;
  double get _stride => _ps.height + kPageGap;

  @override
  void initState() {
    super.initState();
    _lastFitTick = c.fitTick;
    _lastScrollTick = c.scrollTick;
    _lastViewTick = c.viewTick;
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
      if (c.viewTick != _lastViewTick) {
        _lastViewTick = c.viewTick;
        if (c.viewZoom != 1) {
          final mid = _viewSize.center(Offset.zero);
          final pagePt = (mid - _offset) / _scale;
          _scale = (_scale * c.viewZoom).clamp(_minScale, 8.0).toDouble();
          _offset = mid - pagePt * _scale;
        } else {
          _offset += Offset(0, c.viewScroll);
        }
        _moved();
      }
      if (c.scrollTick != _lastScrollTick) {
        _lastScrollTick = c.scrollTick;
        _reveal(c.scrollTarget, force: c.scrollForce);
      }
    });
  }

  /// Margem lateral confortável: ~12% da largura (entre 16 e 160 px).
  double get _fitScaleNow {
    final w = _viewSize.width;
    final margin = (w * 0.12).clamp(16.0, 160.0).toDouble();
    return ((w - 2 * margin) / _ps.width).clamp(0.1, 4.0).toDouble();
  }

  /// Não deixa afastar além de metade do enquadramento (conteúdo minúsculo).
  double get _minScale => _inf ? 0.05 : math.max(0.1, _fitScaleNow * 0.5);

  void _fit() {
    final w = _viewSize.width;
    if (w <= 0) return;
    if (_inf) {
      _fitBoard();
      return;
    }
    _scale = _fitScaleNow;
    _offset = Offset(
      (w - _ps.width * _scale) / 2,
      16 - c.pageIndex * _stride * _scale,
    );
    _limit();
    _fitScale = _scale;
    _fitOffset = _offset;
  }

  /// Quadro infinito: enquadra tudo o que foi desenhado (ou centraliza a origem).
  void _fitBoard() {
    final h = _viewSize.height;
    Rect? b;
    for (final s in c.page.strokes) {
      b = b == null ? s.bounds : b.expandToInclude(s.bounds);
    }
    if (b == null || b.isEmpty) {
      _scale = 1;
      _offset = _viewSize.center(Offset.zero);
    } else {
      final w = _viewSize.width;
      _scale = math
          .min((w * 0.88) / math.max(b.width, 1), (h * 0.88) / math.max(b.height, 1))
          .clamp(_minScale, 1.5)
          .toDouble();
      _offset = _viewSize.center(Offset.zero) - b.center * _scale;
    }
    _fitScale = _scale;
    _fitOffset = _offset;
  }

  /// Janela mudou de tamanho: se você não mexeu no zoom/posição, reajusta a
  /// página ao centro; senão mantém onde você está, só recentralizando na horizontal.
  void _onResize(Size old, Size now) {
    final untouched = _scale == _fitScale && _offset == _fitOffset;
    if (untouched) {
      _fit();
    } else if (_inf) {
      _offset += Offset((now.width - old.width) / 2, (now.height - old.height) / 2);
    } else {
      _offset += Offset((now.width - old.width) / 2, 0);
      _limit();
    }
  }

  /// Rola até a página [i]: com [force] ela vai para o topo; senão só se
  /// estiver quase toda fora da tela.
  void _reveal(int i, {required bool force}) {
    if (_inf) return;
    final top = i * _stride * _scale;
    final bottom = top + _ps.height * _scale;
    final viewTop = -_offset.dy, viewBottom = viewTop + _viewSize.height;
    if (!force) {
      final visible = math.min(bottom, viewBottom) - math.max(top, viewTop);
      if (visible > math.min(_ps.height * _scale, _viewSize.height) * 0.4) return;
    }
    _offset = Offset(_offset.dx, 16 - top);
    _limit();
  }

  /// Mantém a coluna de páginas dentro de limites razoáveis.
  void _limit() {
    if (_inf) return;
    final n = c.notebook.pages.length;
    final docH = (n * _stride - kPageGap) * _scale;
    final minDy = math.min(16.0, _viewSize.height - docH - 16);
    final pw = _ps.width * _scale;
    final loX = math.min(80 - pw, _viewSize.width - 80);
    final hiX = math.max(80 - pw, _viewSize.width - 80);
    _offset = Offset(
      _offset.dx.clamp(loX, hiX).toDouble(),
      _offset.dy.clamp(minDy, 16.0).toDouble(),
    );
  }

  /// Depois de o usuário rolar/dar zoom: limita e marca como ativa a página
  /// mais visível (a menos que haja um traço em andamento).
  void _moved() {
    _limit();
    if (_inf) return;
    if (_drawPointer != null) return;
    final n = c.notebook.pages.length;
    final viewTop = -_offset.dy / _scale;
    final viewBottom = viewTop + _viewSize.height / _scale;
    var best = c.pageIndex;
    var bestVis = -1.0;
    for (var i = 0; i < n; i++) {
      final top = i * _stride;
      final vis = math.min(top + _ps.height, viewBottom) - math.max(top, viewTop);
      if (vis > bestVis) {
        bestVis = vis;
        best = i;
      }
    }
    c.activatePage(best);
  }

  /// Ponto da tela -> ponto do documento (todas as páginas empilhadas).
  Offset _toDoc(Offset screen) => (screen - _offset) / _scale;

  int _pageAt(double docY) =>
      (docY / _stride).floor().clamp(0, c.notebook.pages.length - 1).toInt();

  /// Ponto da tela -> coordenadas da página onde o traço começou.
  Offset _toPage(Offset screen) => _toDoc(screen) - Offset(0, _drawTop);

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

    // Se a tecla da mãozinha foi solta fora do app, o "segurando" não pode ficar preso.
    if (c.panHeld &&
        !HardwareKeyboard.instance.logicalKeysPressed
            .any((k) => k.keyId == c.settings.panKeyId)) {
      c.setPanHeld(false);
    }

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

    if (_tryStartResize(e)) return;

    if (e.kind == PointerDeviceKind.touch) {
      if (_guard.rejectTouchDown(e.pointer, now, e.radiusMajor)) return;
      _touches[e.pointer] = e.localPosition;
      if (_touches.length >= 2) {
        _cancelTouchDrawing();
        return;
      }
      if (!c.fingerDraws || c.panActive) return; // com a mãozinha, o dedo só move
      _startDraw(e, touch: true);
      return;
    }
    if (_drawPointer != null) return;
    if (c.panActive) {
      // Mãozinha: a caneta/mouse arrasta a página em vez de desenhar.
      setState(() {
        _panPointer = e.pointer;
        _panLast = e.localPosition;
        _panAxis = 0;
        _panAccum = Offset.zero;
      });
      return;
    }
    _startDraw(e, touch: false);
  }

  /// Encostou numa alça da forma recém-criada? Então redimensiona em vez de desenhar.
  bool _tryStartResize(PointerDownEvent e) {
    if (c.editing == null || _resizePointer != null || c.panActive) return false;
    if (e.kind == PointerDeviceKind.touch && !c.fingerDraws) return false;
    final local = _toDoc(e.localPosition) - Offset(0, c.pageIndex * _stride);
    final h = c.hitHandle(local, 18 / _scale);
    if (h == null) return false;
    _resizePointer = e.pointer;
    c.beginResize(h);
    return true;
  }

  Offset _toActivePage(Offset screen) => _toDoc(screen) - Offset(0, c.pageIndex * _stride);

  void _startDraw(PointerDownEvent e, {required bool touch}) {
    _drawPointer = e.pointer;
    _drawIsTouch = touch;
    final pageNo = _pageAt(_toDoc(e.localPosition).dy);
    c.activatePage(pageNo);
    _drawTop = pageNo * _stride;
    c.beginStroke(
      _toPage(e.localPosition),
      _norm(e),
      asEraser: e.kind == PointerDeviceKind.invertedStylus,
      timeMs: e.timeStamp.inMilliseconds,
    );
    _holdAnchor = e.localPosition;
    _restartHold();
  }

  void _restartHold() {
    _holdTimer?.cancel();
    // Formas inteligentes encaixam mais rápido ao parar a caneta.
    final ms = c.smartActive ? math.min(c.settings.holdMs, 280) : c.settings.holdMs;
    _holdTimer = Timer(Duration(milliseconds: ms), () {
      if (_drawPointer == null) return;
      if (c.holdDetected()) HapticFeedback.selectionClick();
    });
  }

  void _onMove(PointerMoveEvent e) {
    if (_isPen(e.kind)) _guard.onPenMove(e.timeStamp.inMilliseconds);

    if (e.pointer == _resizePointer) {
      c.resizeTo(_toActivePage(e.localPosition));
      return;
    }

    if (e.pointer == _panPointer) {
      var d = e.localPosition - _panLast;
      _panLast = e.localPosition;
      if (HardwareKeyboard.instance.isShiftPressed) {
        // Shift: trava o movimento no eixo dominante (horizontal ou vertical).
        _panAccum += d;
        if (_panAxis == 0 && _panAccum.distance > 8) {
          _panAxis = _panAccum.dx.abs() >= _panAccum.dy.abs() ? 1 : 2;
          c.markShiftUsed();
          d = _panAxis == 1 ? Offset(_panAccum.dx, 0) : Offset(0, _panAccum.dy);
        } else if (_panAxis == 1) {
          d = Offset(d.dx, 0);
        } else if (_panAxis == 2) {
          d = Offset(0, d.dy);
        } else {
          d = Offset.zero;
        }
      } else {
        _panAxis = 0;
        _panAccum = Offset.zero;
      }
      setState(() => _offset += d);
      _moved();
      return;
    }

    if (e.kind == PointerDeviceKind.touch &&
        _guard.rejectTouchMove(e.pointer, e.radiusMajor)) {
      // O toque virou palma (ou já era): sai da conta e, se desenhava, cancela.
      _touches.remove(e.pointer);
      if (e.pointer == _drawPointer) _cancelTouchDrawing();
      return;
    }

    if (e.pointer == _drawPointer) {
      c.extendStroke(
        _toPage(e.localPosition),
        _norm(e),
        timeMs: e.timeStamp.inMilliseconds,
      );
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
      setState(() {
        _offset += e.localPosition - old;
      });
      _moved();
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
    final ns = (_scale * newDist / oldDist).clamp(_minScale, 8.0).toDouble();
    setState(() {
      _scale = ns;
      _offset = newC - pagePt * ns;
    });
    _moved();
  }

  void _onUp(PointerEvent e, {bool cancel = false}) {
    if (_isPen(e.kind)) _guard.onPenUp(e.timeStamp.inMilliseconds);
    _guard.touchEnded(e.pointer);
    _touches.remove(e.pointer);
    if (e.pointer == _resizePointer) {
      _resizePointer = null;
      c.endResize();
      return;
    }
    if (e.pointer == _panPointer) {
      setState(() => _panPointer = null);
      return;
    }
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
      final ns = (_scale * f).clamp(_minScale, 8.0).toDouble();
      setState(() {
        _scale = ns;
        _offset = e.localPosition - pagePt * ns;
      });
      _moved();
    } else {
      final shift = kb.isShiftPressed;
      setState(() {
        _offset -= Offset(shift ? e.scrollDelta.dy : e.scrollDelta.dx,
            shift ? 0 : e.scrollDelta.dy);
      });
      _moved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final prev = _viewSize;
      _viewSize = constraints.biggest;
      if (!_fitted) {
        _fitted = true;
        _fit();
      } else if (prev != _viewSize && prev != Size.zero) {
        _onResize(prev, _viewSize);
      }
      c.pixelSize = 1 / _scale;
      return MouseRegion(
        cursor: c.panActive
            ? (_panPointer != null ? SystemMouseCursors.grabbing : SystemMouseCursors.grab)
            : MouseCursor.defer,
        child: Listener(
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

/// Percorre as páginas visíveis; para cada uma o canvas já está na origem dela.
void _forVisiblePages(
  Canvas canvas,
  Size size,
  Offset offset,
  double scale,
  int count,
  double pageH,
  void Function(int index, Rect visible) paint,
) {
  final kPageStride = pageH + kPageGap;
  final viewTop = -offset.dy / scale;
  final viewBottom = viewTop + size.height / scale;
  final first = (viewTop / kPageStride).floor().clamp(0, count - 1).toInt();
  final last = (viewBottom / kPageStride).floor().clamp(0, count - 1).toInt();
  for (var i = first; i <= last; i++) {
    final o = Offset(offset.dx, offset.dy + i * kPageStride * scale);
    _beginPage(canvas, o, scale);
    paint(i, _visibleRect(size, o, scale));
    canvas.restore();
  }
}

/// Linhas do fundo da página (pautado / quadriculado).
void paintPageLines(Canvas canvas, PageBackground bg, Size pageSize,
    {double strokeWidth = 1, double step = 40}) {
  if (bg == PageBackground.blank) return;
  final p = Paint()
    ..color = const Color(0xFFD5DCE8)
    ..strokeWidth = strokeWidth;
  if (bg == PageBackground.ruled) {
    for (var y = step * 2.5; y < pageSize.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(pageSize.width, y), p);
    }
  } else {
    for (var y = step; y < pageSize.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(pageSize.width, y), p);
    }
    for (var x = step; x < pageSize.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, pageSize.height), p);
    }
  }
}

/// Linhas do fundo do quadro infinito, só na parte visível.
void paintInfiniteLines(Canvas canvas, PageBackground bg, Rect v, double step) {
  if (bg == PageBackground.blank) return;
  if (v.width / step > 300 || v.height / step > 300) return; // muito afastado
  final p = Paint()
    ..color = const Color(0xFFD5DCE8)
    ..strokeWidth = 1;
  final y0 = (v.top / step).floor() * step, x0 = (v.left / step).floor() * step;
  for (var y = y0; y <= v.bottom; y += step) {
    canvas.drawLine(Offset(v.left, y), Offset(v.right, y), p);
  }
  if (bg == PageBackground.grid) {
    for (var x = x0; x <= v.right; x += step) {
      canvas.drawLine(Offset(x, v.top), Offset(x, v.bottom), p);
    }
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.c, this.scale, this.offset)
      : _spacing = c.settings.lineSpacing,
        super(repaint: c.committed);

  final double _spacing;

  final CanvasController c;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final pages = c.notebook.pages;
    final ps = c.notebook.pageSize;
    final inf = c.notebook.infinite;
    if (inf) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      final o = offset;
      _beginPage(canvas, o, scale);
      paintInfiniteLines(canvas, pages[0].background, _visibleRect(size, o, scale), c.settings.lineSpacing);
      canvas.restore();
      return;
    }
    _forVisiblePages(canvas, size, offset, scale, pages.length, ps.height, (i, visible) {
      final pageRect = Offset.zero & ps;
      canvas.drawShadow(Path()..addRect(pageRect), Colors.black, 3, false);
      canvas.drawRect(pageRect, Paint()..color = Colors.white);
      paintPageLines(canvas, pages[i].background, ps, step: c.settings.lineSpacing);
    });
  }


  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.scale != scale || old.offset != offset || old._spacing != _spacing;
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.c, this.scale, this.offset)
      : super(repaint: c.committed);

  final CanvasController c;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final pages = c.notebook.pages;
    final ps = c.notebook.pageSize;
    final inf = c.notebook.infinite;
    _forVisiblePages(canvas, size, offset, scale, pages.length, ps.height, (i, visible) {
      if (!inf) canvas.clipRect(Offset.zero & ps);
      for (final s in pages[i].strokes) {
        if (s.fill != null && s.bounds.overlaps(visible)) paintFill(canvas, s);
      }
      final hl = <Stroke>[
        for (final s in pages[i].strokes)
          if (s.highlighter && s.bounds.overlaps(visible)) s,
      ];
      paintHighlighters(canvas, hl, inf ? visible : Offset.zero & ps);
    });
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
    final pages = c.notebook.pages;
    final ps = c.notebook.pageSize;
    final inf = c.notebook.infinite;
    _forVisiblePages(canvas, size, offset, scale, pages.length, ps.height, (i, visible) {
      if (!inf) canvas.clipRect(Offset.zero & ps);
      for (final s in pages[i].strokes) {
        if (!s.highlighter && s.bounds.overlaps(visible)) paintStroke(canvas, s);
      }
    });
  }

  @override
  bool shouldRepaint(_InkPainter old) => old.scale != scale || old.offset != offset;
}

class _LiveInkPainter extends CustomPainter {
  _LiveInkPainter(this.c, this.scale, this.offset)
      : edit = c.editing,
        super(repaint: c.live);

  final Object? edit; // forma em edição (para repintar as alças quando muda)

  final CanvasController c;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final s = c.current;
    // Enquanto o gesto dura, o marca-texto fica POR CIMA (tingindo a escrita);
    // ao soltar ele passa para trás, na camada do realce.
    final ink = s;
    final eraser = c.eraserPos;
    if (ink == null && eraser == null && c.editing == null) return;
    // O traço ao vivo pertence à página ativa.
    final ps = c.notebook.pageSize;
    final inf = c.notebook.infinite;
    _beginPage(canvas, offset + Offset(0, c.pageIndex * (ps.height + kPageGap) * scale), scale);
    if (!inf) canvas.clipRect(Offset.zero & ps);
    if (ink != null) {
      paintFill(canvas, ink);
      paintStroke(canvas, ink);
    }
    final edit = c.editing;
    if (edit != null && s == null) _paintHandles(canvas, scale);
    if (eraser != null) {
      // círculo-guia da borracha, com o tamanho real da área apagada
      canvas.drawCircle(
        eraser,
        c.eraserRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 / scale
          ..color = const Color(0xAA607D8B),
      );
    }
    canvas.restore();
  }

  /// Caixa tracejada leve e alças para redimensionar a forma recém-criada.
  void _paintHandles(Canvas canvas, double scale) {
    final hs = c.editHandles();
    if (hs.isEmpty) return;
    final line = hs.length == 2;
    final accent = const Color(0xFF2979FF);
    if (!line) {
      canvas.drawRect(
        Rect.fromPoints(hs[0], hs[4]),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 / scale
          ..color = accent.withAlpha(150),
      );
    }
    for (final p in hs) {
      canvas.drawCircle(p, 7 / scale, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        7 / scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / scale
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_LiveInkPainter old) =>
      old.scale != scale || old.offset != offset || old.edit != edit;
}
