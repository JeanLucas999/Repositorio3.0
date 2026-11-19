import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'geometry.dart';
import 'models.dart';
import 'scribble.dart';
import 'settings.dart';
import 'shape_recognizer.dart';

enum Tool { pen, highlighter, line, eraser }

class _Ping extends ChangeNotifier {
  void ping() => notifyListeners();
}

class _Removed {
  _Removed(this.index, this.stroke);
  final int index;
  final Stroke stroke;
}

class _Action {
  _Action(this.undo, this.redo);
  final VoidCallback undo;
  final VoidCallback redo;
}

/// Estado e regras do caderno. Toda coordenada aqui está no espaço da PÁGINA
/// (não da tela), então zoom e rolagem não interferem.
class CanvasController extends ChangeNotifier {
  CanvasController(this.notebook, [AppSettings? settings])
      : settings = settings ?? AppSettings() {
    this.settings.addListener(notifyListeners);
  }

  final Notebook notebook;
  final AppSettings settings;

  /// Avisa as camadas de traços já prontos (repinta só quando algo é confirmado).
  final _Ping _committed = _Ping();
  Listenable get committed => _committed;

  /// Avisa a camada do traço de tinta que está sendo desenhado agora.
  final _Ping _live = _Ping();
  Listenable get live => _live;

  /// Avisa a camada do marca-texto (que fica ATRÁS da tinta) quando o traço
  /// ao vivo é um marca-texto.
  final _Ping _liveHl = _Ping();
  Listenable get liveHighlight => _liveHl;

  /// Chamado a cada mudança no documento (usado para salvar automático).
  VoidCallback? onDocumentChanged;

  // ---- ferramenta atual ----
  static const List<int> penColors = [
    0xFF1A1A1A,
    0xFF2979FF,
    0xFFC62828,
    0xFF2E7D32,
    0xFFEF6C00,
    0xFF6A1B9A,
  ];
  static const List<int> hlColors = [
    0xFFFFEB3B, // amarelo
    0xFF76FF03, // verde
    0xFFFF80AB, // rosa
    0xFF40C4FF, // azul
    0xFFFFAB40, // laranja
  ];

  int pageIndex = 0;
  Tool tool = Tool.pen;
  int penColor = 0xFF1A1A1A;
  int hlColor = 0xFFFFEB3B;
  double penWidth = 2.5;
  double hlWidth = 6;
  bool showOptions = false; // linha de cores/espessura aberta
  double eraserRadius = 10;

  /// Tamanho de 1 pixel da tela em unidades da página (a tela de desenho
  /// atualiza isto conforme o zoom). Usado para filtrar tremido da entrada.
  double pixelSize = 1.0;

  int version = 0;
  int fitTick = 0;

  Stroke? current;
  Tool _active = Tool.pen;
  String? _snap; // null | 'line' | outra forma (congelada)
  double _pSum = 0;
  int _pN = 0;
  Offset? _lastRaw; // última posição real da caneta (antes do filtro)
  List<_Removed>? _eraseSession;
  NotePage? _eraseSessionPage;
  final List<_Action> _undo = [];
  final List<_Action> _redo = [];
  int _idCounter = 0;

  NotePage get page => notebook.pages[pageIndex];
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  bool get isHighlighter => tool == Tool.highlighter;
  bool get hasOptions => tool != Tool.eraser;
  int get color => isHighlighter ? hlColor : penColor;
  double get width => isHighlighter ? hlWidth : penWidth;
  double get minWidth => isHighlighter ? 3.0 : 1.0;
  double get maxWidth => 12.0;
  List<int> get palette => isHighlighter ? hlColors : penColors;

  bool get autoShape => settings.autoShape;
  bool get scribbleErase => settings.scribbleErase;
  bool get fingerDraws => settings.fingerDraws;

  @override
  void dispose() {
    settings.removeListener(notifyListeners);
    super.dispose();
  }

  // ---------------- configurações da ferramenta ----------------
  /// Troca a ferramenta (atalhos de teclado).
  void setTool(Tool t) {
    tool = t;
    if (t == Tool.eraser) showOptions = false;
    notifyListeners();
  }

  /// Toque na barra: escolher uma ferramenta; tocar de novo na que já está
  /// ativa abre/fecha a linha de cor e espessura.
  void selectTool(Tool t) {
    if (t == tool) {
      if (t != Tool.eraser) showOptions = !showOptions;
    } else {
      tool = t;
      if (t == Tool.eraser) showOptions = false;
    }
    notifyListeners();
  }

  void toggleOptions() {
    if (!hasOptions) return;
    showOptions = !showOptions;
    notifyListeners();
  }

  void setColor(int c) {
    if (tool == Tool.eraser) tool = Tool.pen;
    if (isHighlighter) {
      hlColor = c;
    } else {
      penColor = c;
    }
    notifyListeners();
  }

  void setWidth(double w) {
    if (isHighlighter) {
      hlWidth = w;
    } else {
      penWidth = w;
    }
    notifyListeners();
  }

  void requestFit() {
    fitTick++;
    notifyListeners();
  }

  void renameNotebook(String name) {
    final n = name.trim();
    if (n.isEmpty || n == notebook.name) return;
    notebook.name = n;
    _bump();
  }

  // ---------------- desenho ----------------
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  /// Avisa a camada do traço ao vivo. A camada do marca-texto só precisa
  /// repintar quando o traço ao vivo é um marca-texto (ou [force]).
  void _pingLive({bool force = false}) {
    _live.ping();
    if (force || current?.highlighter == true) _liveHl.ping();
  }

  void beginStroke(Offset p, double pressure, {bool asEraser = false}) {
    _active = asEraser ? Tool.eraser : tool;
    _snap = null;
    _pSum = pressure;
    _pN = 1;
    _lastRaw = p;
    if (_active == Tool.eraser) {
      _eraseSession = [];
      _eraseSessionPage = page;
      _eraseAt(p);
      return;
    }
    final hl = _active == Tool.highlighter;
    current = Stroke(
      id: _newId(),
      points: [p],
      color: hl ? hlColor : penColor,
      width: hl ? hlWidth : penWidth,
      highlighter: hl,
      smooth: _active != Tool.line,
      pressure: pressure,
    );
    _pingLive();
  }

  void extendStroke(Offset p, double pressure) {
    if (_active == Tool.eraser) {
      _eraseAt(p);
      return;
    }
    final s = current;
    if (s == null) return;

    // Ferramenta reta, ou traço já encaixado como reta: acompanha a caneta.
    if (_active == Tool.line || _snap == 'line') {
      final start = s.points.first;
      s.points = [start, _softAngleSnap(start, p)];
      s.smooth = false;
      s.invalidate();
      _pingLive();
      return;
    }
    if (_snap != null) return; // outra forma: congelada

    // Filtro de entrada (tira o serrilhado de mesas que mandam coordenadas
    // "quebradas" em pixels inteiros e o tremido da mão):
    // 1) ignora movimento menor que ~1 pixel da tela;
    // 2) suaviza com média exponencial: devagar suaviza mais, rápido segue a caneta.
    _lastRaw = p;
    final last = s.points.last;
    final d = dist(last, p);
    if (d < 0.8 * pixelSize) return;
    final alpha = (0.35 + d / (12 * pixelSize)).clamp(0.35, 1.0).toDouble();
    s.points.add(Offset.lerp(last, p, alpha)!);
    _pSum += pressure;
    _pN++;
    s.pressure = (_pSum / _pN).clamp(0.0, 1.0).toDouble();
    _pingLive();
  }

  void endStroke() {
    if (_active == Tool.eraser) {
      _finishErase();
      return;
    }
    final s = current;
    if (s == null) return;
    current = null;

    // O filtro deixa a ponta um pouco atrás da caneta: fecha o traço no ponto real.
    final raw = _lastRaw;
    if (_snap == null && _active != Tool.line && raw != null) {
      if (dist(s.points.last, raw) > 0.5 * pixelSize) s.points.add(raw);
    }

    // Riscar por cima de algo existente = apagar.
    if (_active == Tool.pen &&
        scribbleErase &&
        _snap == null &&
        looksLikeScribble(s.points)) {
      final hits = strokesCoveredBy(page.strokes, s.points);
      if (hits.isNotEmpty) {
        _removeStrokes(page, hits);
        _pingLive(force: true);
        return;
      }
    }

    final pg = page;
    _push(_Action(
      () {
        pg.strokes.remove(s);
        _show(pg);
      },
      () {
        pg.strokes.add(s);
        _show(pg);
      },
    ));
    pg.strokes.add(s);
    _bump();
    _pingLive(force: true);
  }

  /// Chamado quando a caneta ficou parada por um instante.
  /// Retorna true se encaixou uma reta ou forma (para dar um "tec" tátil).
  bool holdDetected() {
    final s = current;
    if (s == null || !autoShape || _snap != null) return false;
    if (_active != Tool.pen && _active != Tool.highlighter) return false;
    final r = recognizeShape(s.points);
    if (r == null) return false;
    s.points = r.points;
    s.smooth = false;
    s.invalidate();
    _snap = r.kind;
    _pingLive();
    return true;
  }

  void cancelStroke() {
    if (_active == Tool.eraser) {
      _finishErase();
    }
    current = null;
    _snap = null;
    _pingLive(force: true);
  }

  /// Gruda em múltiplos de 15° quando está a menos de 4° de distância.
  Offset _softAngleSnap(Offset a, Offset b) {
    final d = b - a;
    final len = d.distance;
    if (len < 1) return b;
    final ang = math.atan2(d.dy, d.dx);
    const step = math.pi / 12;
    final nearest = (ang / step).roundToDouble() * step;
    if ((ang - nearest).abs() < 4 * math.pi / 180) {
      return Offset(a.dx + math.cos(nearest) * len, a.dy + math.sin(nearest) * len);
    }
    return b;
  }

  // ---------------- borracha ----------------
  void _eraseAt(Offset p) {
    final strokes = page.strokes;
    var changed = false;
    for (var i = strokes.length - 1; i >= 0; i--) {
      final s = strokes[i];
      if (!s.bounds.inflate(eraserRadius).contains(p)) continue;
      if (_strokeNear(s, p, eraserRadius)) {
        _eraseSession?.add(_Removed(i, s));
        strokes.removeAt(i);
        changed = true;
      }
    }
    if (changed) {
      version++;
      _committed.ping();
    }
  }

  bool _strokeNear(Stroke s, Offset p, double r) {
    final pts = s.points;
    final reach = r + s.effectiveWidth / 2;
    if (pts.length == 1) return dist(pts[0], p) <= reach;
    for (var i = 1; i < pts.length; i++) {
      if (distToSegment(p, pts[i - 1], pts[i]) <= reach) return true;
    }
    return false;
  }

  void _finishErase() {
    final List<_Removed> removed = _eraseSession ?? <_Removed>[];
    final pg = _eraseSessionPage;
    _eraseSession = null;
    _eraseSessionPage = null;
    if (removed.isNotEmpty && pg != null) _recordRemoval(pg, removed);
  }

  void _removeStrokes(NotePage pg, List<Stroke> hits) {
    final set = hits.toSet();
    final removed = <_Removed>[];
    for (var i = pg.strokes.length - 1; i >= 0; i--) {
      if (set.contains(pg.strokes[i])) {
        removed.add(_Removed(i, pg.strokes[i]));
        pg.strokes.removeAt(i);
      }
    }
    if (removed.isNotEmpty) _recordRemoval(pg, removed);
  }

  void _recordRemoval(NotePage pg, List<_Removed> removed) {
    _push(_Action(
      () {
        for (final r in removed.reversed) {
          pg.strokes.insert(r.index, r.stroke);
        }
        _show(pg);
      },
      () {
        for (final r in removed) {
          pg.strokes.removeAt(r.index);
        }
        _show(pg);
      },
    ));
    _bump();
  }

  // ---------------- histórico ----------------
  void _push(_Action a) {
    _undo.add(a);
    if (_undo.length > 300) _undo.removeAt(0);
    _redo.clear();
  }

  void _show(NotePage pg) {
    final i = notebook.pages.indexOf(pg);
    if (i >= 0) pageIndex = i;
  }

  void _bump() {
    version++;
    notebook.modified = DateTime.now();
    _committed.ping();
    notifyListeners();
    onDocumentChanged?.call();
  }

  void undo() {
    if (_undo.isEmpty) return;
    final a = _undo.removeLast();
    a.undo();
    _redo.add(a);
    _bump();
  }

  void redo() {
    if (_redo.isEmpty) return;
    final a = _redo.removeLast();
    a.redo();
    _undo.add(a);
    _bump();
  }

  // ---------------- páginas ----------------
  void goToPage(int i) {
    if (i < 0 || i >= notebook.pages.length || i == pageIndex) return;
    current = null;
    pageIndex = i;
    _bump();
    _pingLive(force: true);
  }

  void addPage() {
    notebook.pages.add(NotePage(background: page.background));
    goToPage(notebook.pages.length - 1);
  }

  void deletePage() {
    current = null;
    if (notebook.pages.length <= 1) {
      page.strokes.clear();
    } else {
      notebook.pages.removeAt(pageIndex);
      if (pageIndex >= notebook.pages.length) pageIndex = notebook.pages.length - 1;
    }
    _undo.clear();
    _redo.clear();
    _bump();
    _pingLive(force: true);
  }

  void cycleBackground() {
    final values = PageBackground.values;
    page.background = values[(page.background.index + 1) % values.length];
    _bump();
  }
}
