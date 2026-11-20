import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'geometry.dart';
import 'models.dart';
import 'scribble.dart';
import 'settings.dart';
import 'shape_recognizer.dart';
import 'shapes.dart';

/// pen/fountain = canetas; shape = formas básicas (reta, seta, retângulo...);
/// pan = mãozinha (a caneta arrasta a página em vez de desenhar).
enum Tool { pen, fountain, smart, highlighter, shape, eraser, pan }

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
  static const List<int> penColors = AppSettings.defaultPenPalette;
  static const List<int> hlColors = AppSettings.defaultHlPalette;

  /// Cores extras do painel (caneta, tinteiro e formas): neutros, vermelhos/rosas,
  /// laranjas/amarelos, verdes e azuis/roxos.
  static const List<int> moreColors = [
    0xFF000000, 0xFF37474F, 0xFF607D8B, 0xFF9E9E9E, 0xFF795548, 0xFF3E2723, //
    0xFFB71C1C, 0xFFE53935, 0xFFFF5252, 0xFFD81B60, 0xFFF06292, 0xFF880E4F,
    0xFFE65100, 0xFFFF9800, 0xFFFFB300, 0xFFFBC02D, 0xFFFFEB3B, 0xFF827717,
    0xFF1B5E20, 0xFF43A047, 0xFF76FF03, 0xFF00C853, 0xFF009688, 0xFF004D40,
    0xFF01579B, 0xFF03A9F4, 0xFF00BCD4, 0xFF304FFE, 0xFF5E35B1, 0xFFAA00FF,
  ];

  /// Cores extras do marca-texto (tons vivos que funcionam com transparência).
  static const List<int> moreHlColors = [
    0xFFFFEB3B, 0xFFFFD54F, 0xFFFFAB40, 0xFFFF8A80, 0xFFFF80AB, 0xFFEA80FC,
    0xFFB388FF, 0xFF82B1FF, 0xFF40C4FF, 0xFF84FFFF, 0xFFA7FFEB, 0xFFB9F6CA,
    0xFF76FF03, 0xFFCCFF90, 0xFFBDBDBD,
  ];

  int pageIndex = 0;
  Tool tool = Tool.pen;
  int penColor = 0xFF1A1A1A;
  int hlColor = 0xFFFFEB3B;
  double penWidth = 2.5;
  double fountainWidth = 3.0;
  double hlWidth = 6;
  bool showOptions = false; // linha de opções (cor/espessura ou borracha) aberta
  bool showColors = false; // painel de cores (paleta extra + círculo cromático) aberto

  /// Forma escolhida na mini barra (usada quando a ferramenta é [Tool.shape]).
  ShapeKind shapeKind = ShapeKind.line;


  /// Forma recém-criada que ainda pode ser redimensionada pelas alças.
  Stroke? editing;
  String _editKind = ''; // 'line' | 'arrow' | 'box'
  int _rsHandle = -1;
  List<Offset> _rsOrig = const [];
  Rect _rsBox = Rect.zero;

  /// Mãozinha segurada pela tecla de atalho (o editor liga/desliga).
  bool panHeld = false;
  Tool _beforePan = Tool.pen;
  Offset? _shapeStart;

  /// Posição da borracha enquanto apaga (para desenhar o círculo-guia).
  Offset? eraserPos;

  /// Tamanho de 1 pixel da tela em unidades da página (a tela de desenho
  /// atualiza isto conforme o zoom). Usado para filtrar tremido da entrada.
  double pixelSize = 1.0;

  int version = 0;
  int fitTick = 0;

  // Pedido de rolagem para a vista (página em coluna): a vista observa [scrollTick].
  int scrollTick = 0;

  // Comandos de teclado para a vista: zoom (fator) e rolagem (pixels da tela).
  int viewTick = 0;
  double viewZoom = 1;
  double viewScroll = 0;
  void zoomBy(double f) {
    viewZoom = f;
    viewScroll = 0;
    viewTick++;
    notifyListeners();
  }

  void scrollByPx(double dy) {
    viewZoom = 1;
    viewScroll = dy;
    viewTick++;
    notifyListeners();
  }
  int scrollTarget = 0;
  bool scrollForce = true; // false: só rola se a página não estiver à vista

  Stroke? current;
  Tool _active = Tool.pen;
  String? _snap; // null | 'line' | outra forma (congelada)
  double _pSum = 0;
  int _pN = 0;
  Offset _lastDir = Offset.zero; // direção do último passo (detecta cantos)
  Offset? _lastRaw; // última posição real da caneta (antes do filtro)

  // caneta tinteiro: estado da largura enquanto escreve
  Offset? _lastAcc; // última posição real aceita
  int? _lastT; // e o instante dela (ms)
  double _pSm = 0.5; // pressão suavizada
  double _wPrev = 1; // largura anterior (suavizada)

  // borracha: instantâneo da página para desfazer a sessão inteira de uma vez
  List<Stroke>? _eraseBefore;
  NotePage? _eraseSessionPage;
  bool _eraseChanged = false;
  Offset? _lastErasePos;

  final List<_Action> _undo = [];
  final List<_Action> _redo = [];
  int _idCounter = 0;

  NotePage get page => notebook.pages[pageIndex];
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  bool get isHighlighter => tool == Tool.highlighter;

  /// A ferramenta tem cor? (a borracha não tem)
  bool get usesColor => tool != Tool.eraser && tool != Tool.pan;

  /// A caneta/mouse deve arrastar a página (mãozinha) em vez de desenhar?
  bool get panActive => tool == Tool.pan || panHeld;

  int get color => switch (tool) {
        Tool.highlighter => hlColor,
        _ => penColor,
      };
  double get width => switch (tool) {
        Tool.highlighter => hlWidth,
        Tool.fountain => fountainWidth,
        _ => penWidth,
      };
  double get minWidth => switch (tool) {
        Tool.highlighter => 3.0,
        Tool.fountain => 1.5,
        _ => 1.0,
      };
  double get maxWidth => 12.0;
  List<int> get palette => switch (tool) {
        Tool.highlighter => settings.hlPalette,
        _ => settings.penPalette,
      };

  /// Troca a cor [index] da barra principal por [argb] (arrastada do painel) e a seleciona.
  void replacePaletteColor(int index, int argb) {
    final list = isHighlighter ? settings.hlPalette : settings.penPalette;
    if (index < 0 || index >= list.length) return;
    settings.update(() => list[index] = argb);
    setColor(argb);
  }

  /// O usuário usou o Shift na mãozinha: a dica não precisa mais aparecer.
  void markShiftUsed() {
    if (!settings.shiftHintSeen) settings.update(() => settings.shiftHintSeen = true);
  }

  /// Paleta extra do painel de cores.
  List<int> get morePalette => isHighlighter ? moreHlColors : moreColors;

  bool get autoShape => settings.autoShape;

  bool get _fixed => _active == Tool.shape;

  /// Caneta inteligente: à mão livre; ao soltar (ou parar) vira a forma reconhecida.
  bool get _smart => _active == Tool.smart;

  bool get smartActive => tool == Tool.smart;
  bool get scribbleErase => settings.scribbleErase;
  bool get fingerDraws => settings.fingerDraws;

  /// Borracha "Normal" (apaga só por onde passa) em vez de "Traço".
  bool get eraserPixel => settings.eraserPixel;
  double get eraserRadius => settings.eraserSize;

  @override
  void dispose() {
    settings.removeListener(notifyListeners);
    super.dispose();
  }

  // ---------------- configurações da ferramenta ----------------
  /// Última caneta usada (comum ou tinteiro): é a que o botão de caneta
  /// mostra e escolhe quando você volta de outra ferramenta.
  Tool lastPen = Tool.pen;

  /// A ferramenta atual é uma caneta (comum ou tinteiro)? O marca-texto não conta.
  bool get isPenTool => tool == Tool.pen || tool == Tool.fountain || tool == Tool.smart;

  /// Troca a ferramenta (atalhos de teclado).
  void setTool(Tool t) {
    editing = null;
    tool = t;
    if (t == Tool.pen || t == Tool.fountain || t == Tool.smart) lastPen = t;
    notifyListeners();
  }

  /// Toque numa ferramenta da barra; tocar de novo na que já está ativa
  /// abre/fecha a linha de opções (cor e espessura, ou a borracha).
  void selectTool(Tool t) {
    editing = null;
    if (t == Tool.pan) {
      // mãozinha: liga e desliga, voltando para a ferramenta anterior
      if (tool == Tool.pan) {
        tool = _beforePan;
      } else {
        _beforePan = tool;
        tool = Tool.pan;
        _setOptions(false);
      }
    } else if (t == tool) {
      _setOptions(!showOptions);
    } else {
      tool = t;
      if (t == Tool.pen || t == Tool.fountain || t == Tool.smart) lastPen = t;
    }
    notifyListeners();
  }

  /// Abre/fecha a linha de opções; fechar leva junto o painel de cores.
  void _setOptions(bool open) {
    showOptions = open;
    if (!open) showColors = false;
  }

  /// Escolhe uma forma da mini barra e passa para a ferramenta de formas.
  void setShape(ShapeKind k) {
    editing = null;
    shapeKind = k;
    tool = Tool.shape;
    notifyListeners();
  }

  /// A tecla da mãozinha foi apertada/solta (segurar = mover temporariamente).
  void setPanHeld(bool held) {
    if (panHeld == held) return;
    panHeld = held;
    notifyListeners();
  }

  void toggleColors() {
    showColors = !showColors;
    notifyListeners();
  }

  /// Escolhe uma cor no painel e guarda nas recentes.
  void pickColor(int argb, {bool remember = true}) {
    setColor(argb);
    if (!remember) return;
    settings.update(() {
      final list = settings.recentColors;
      list.remove(argb);
      list.insert(0, argb);
      if (list.length > 10) list.removeRange(10, list.length);
    });
  }

  /// Toque no botão único de caneta. Se não estava numa caneta, o primeiro
  /// toque só volta para a última usada (e fecha qualquer subaba aberta);
  /// a subaba para escolher o tipo abre no segundo toque, e o terceiro fecha.
  void selectPen() {
    if (isPenTool) {
      _setOptions(!showOptions);
    } else {
      tool = lastPen;
      _setOptions(false);
    }
    notifyListeners();
  }

  /// Escolhe o tipo de caneta na subaba (comum, tinteiro ou inteligente).
  void setPenType(Tool t) {
    if (t != Tool.pen && t != Tool.fountain && t != Tool.smart) return;
    tool = t;
    lastPen = t;
    notifyListeners();
  }

  void toggleOptions() {
    _setOptions(!showOptions);
    notifyListeners();
  }

  void setColor(int c) {
    if (tool == Tool.eraser) tool = Tool.pen;
    switch (tool) {
      case Tool.highlighter:
        hlColor = c;
      default:
        penColor = c;
    }
    notifyListeners();
  }

  void setWidth(double w) {
    switch (tool) {
      case Tool.highlighter:
        hlWidth = w;
      case Tool.fountain:
        fountainWidth = w;
      default:
        penWidth = w;
    }
    notifyListeners();
  }

  void setEraserPixel(bool pixel) => settings.update(() => settings.eraserPixel = pixel);

  void setEraserSize(double r) => settings.update(() => settings.eraserSize = r);

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

  void beginStroke(Offset p, double pressure, {bool asEraser = false, int? timeMs}) {
    _active = asEraser ? Tool.eraser : tool;
    editing = null;
    if (showColors) {
      // desenhar fecha o painel de cores (ele flutua sobre a página)
      showColors = false;
      notifyListeners();
    }
    _snap = null;
    _shapeStart = p;
    _pSum = pressure;
    _pN = 1;
    _lastRaw = p;
    _lastAcc = p;
    _lastT = timeMs;
    if (_active == Tool.eraser) {
      _eraseBefore = List<Stroke>.of(page.strokes);
      _eraseSessionPage = page;
      _eraseChanged = false;
      _lastErasePos = p;
      eraserPos = p;
      _eraseAtPoint(p);
      _live.ping();
      return;
    }
    final hl = _active == Tool.highlighter;
    final ft = _active == Tool.fountain;
    _pSm = pressure;
    _lastDir = Offset.zero;
    _wPrev = fountainWidth * (0.28 + 1.55 * pressure);
    current = Stroke(
      id: _newId(),
      points: [p],
      color: hl ? hlColor : penColor, // caneta e tinteiro dividem a cor
      width: hl ? hlWidth : (ft ? fountainWidth : penWidth),
      highlighter: hl,
      smooth: !_fixed,
      pressure: _fixed ? 0.5 : pressure, // formas fixas: espessura uniforme
      fountain: ft,
      widths: ft ? [_wPrev * 0.5] : null, // começa fino
      fill: (_fixed && settings.shapeFill && _closedShape(shapeKind))
          ? ((penColor & 0x00FFFFFF) | (kShapeFillAlpha << 24))
          : null,
    );
    _pingLive();
  }

  static const int kShapeFillAlpha = 46; // ~18%: claro, sem esconder o que está atrás

  static bool _closedShape(ShapeKind k) =>
      k == ShapeKind.rectangle || k == ShapeKind.ellipse || k == ShapeKind.triangle;

  void extendStroke(Offset p, double pressure, {int? timeMs}) {
    if (_active == Tool.eraser) {
      _eraseSegment(_lastErasePos ?? p, p);
      _lastErasePos = p;
      eraserPos = p;
      _live.ping();
      return;
    }
    final s = current;
    if (s == null) return;

    // Formas fixas: a forma acompanha a caneta, do ponto onde encostou até aqui.
    if (_fixed) {
      final start = _shapeStart ?? s.points.first;
      final straight = shapeKind == ShapeKind.line || shapeKind == ShapeKind.arrow;
      final end = straight ? _softAngleSnap(start, p) : p;
      s.points = shapePoints(shapeKind, start, end, headLen: math.max(14.0, s.width * 5));
      s.smooth = false;
      s.invalidate();
      _pingLive();
      return;
    }

    // Traço da caneta já encaixado como reta: acompanha a caneta.
    if (_snap == 'line') {
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
    // Estabilização (config.): devagar suaviza mais o tremor; rápido segue a caneta.
    // Mudança brusca de direção (canto) não é suavizada, para não arredondar letras.
    final minA = 0.6 - 0.4 * settings.stabilization; // 0.6 (leve) .. 0.2 (forte)
    var alpha = (minA + d / (12 * pixelSize)).clamp(minA, 1.0).toDouble();
    final dir = (p - last) / d;
    if (_lastDir != Offset.zero && d > 2.5 * pixelSize) {
      final cosA = dir.dx * _lastDir.dx + dir.dy * _lastDir.dy;
      if (cosA < 0.3) alpha = math.max(alpha, 0.85);
    }
    if (d > 1.5 * pixelSize) _lastDir = dir;
    s.points.add(Offset.lerp(last, p, alpha)!);
    if (s.fountain && s.widths != null) {
      s.widths!.add(_fountainWidth(s, d, p, timeMs, pressure));
    }
    _lastAcc = p;
    _lastT = timeMs;
    _pSum += pressure;
    _pN++;
    s.pressure = (_pSum / _pN).clamp(0.0, 1.0).toDouble();
    _pingLive();
  }

  /// Largura do próximo ponto da caneta tinteiro: mais pressão = mais grosso,
  /// mais rápido = mais fino (devagar a tinta "acumula"). Suavizada para não
  /// dar degraus, e com os primeiros pontos afinando (entrada do traço).
  double _fountainWidth(Stroke s, double stepDist, Offset p, int? timeMs, double pressure) {
    _pSm = _pSm * 0.6 + pressure * 0.4;

    final lastT = _lastT, lastAcc = _lastAcc;
    double sp; // velocidade normalizada 0..1
    if (timeMs != null && lastT != null && lastAcc != null && timeMs > lastT) {
      final pxPerMs = (dist(lastAcc, p) / pixelSize) / (timeMs - lastT);
      sp = (pxPerMs / 2.0).clamp(0.0, 1.0).toDouble();
    } else {
      sp = ((stepDist / pixelSize) / 16.0).clamp(0.0, 1.0).toDouble();
    }

    var w = s.width * (0.28 + 1.55 * _pSm) * (1.15 - 0.55 * sp);
    w = _wPrev * 0.7 + w * 0.3;
    // variação limitada por ponto: nada de degraus nem "pulsos" na largura
    final slew = 0.05 * s.width;
    w = w.clamp(_wPrev - slew, _wPrev + slew).toDouble();
    _wPrev = w;

    final n = s.widths!.length;
    final ramp = n < 4 ? 0.5 + 0.125 * n : 1.0;
    return w * ramp;
  }

  void endStroke() {
    if (_active == Tool.eraser) {
      _finishErase();
      return;
    }
    final s = current;
    if (s == null) return;
    current = null;

    // Forma sem arrastar (só um toque): descarta em vez de deixar uma pintinha.
    if (_fixed && diagonalOf(boundsOf(s.points)) < 4 * pixelSize) {
      _pingLive(force: true);
      return;
    }

    // O filtro deixa a ponta um pouco atrás da caneta: fecha o traço no ponto real.
    final raw = _lastRaw;
    if (_snap == null && !_fixed && raw != null) {
      if (dist(s.points.last, raw) > 0.5 * pixelSize) {
        s.points.add(raw);
        s.widths?.add(s.widths!.last);
      }
    }

    // Formas inteligentes: ao soltar, o traço vira a forma reconhecida.
    if (_smart && _snap == null) {
      final r = recognizeShape(s.points);
      if (r != null) _applyRecognized(s, r);
    }

    // Caneta tinteiro: a ponta final afina.
    final ws = s.widths;
    if (s.fountain && ws != null && ws.length >= 2) {
      final n = ws.length;
      for (var k = 0; k < 3 && k < n; k++) {
        ws[n - 1 - k] *= 0.4 + 0.2 * k; // 0,4 / 0,6 / 0,8
      }
      s.invalidate();
    }

    // Riscar por cima de algo existente = apagar.
    if ((_active == Tool.pen || _active == Tool.fountain) &&
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

    final shapeDone = _snap != null || _fixed;
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
    if (shapeDone) _startEditing(s); // logo após criar, dá para redimensionar
    _pingLive(force: true);
  }

  /// Troca o traço pela forma reconhecida (fica uniforme e, se pedido, preenchida).
  void _applyRecognized(Stroke s, RecognizedShape r) {
    s.points = r.points;
    s.widths = null;
    s.smooth = false;
    if (settings.shapeFill &&
        (r.kind == 'rectangle' || r.kind == 'ellipse' || r.kind == 'circle' ||
            r.kind == 'triangle' || r.kind == 'polygon')) {
      s.fill = (s.color & 0x00FFFFFF) | (kShapeFillAlpha << 24);
    }
    s.invalidate();
    _snap = r.kind;
  }

  // ---------------- redimensionar a forma recém-criada ----------------
  void _startEditing(Stroke s) {
    editing = s;
    if (_fixed && shapeKind == ShapeKind.arrow) {
      _editKind = 'arrow';
    } else if (s.points.length == 2 || (_fixed && shapeKind == ShapeKind.line)) {
      _editKind = 'line';
    } else {
      _editKind = 'box';
    }
    notifyListeners();
  }

  /// Posições das alças (coordenadas da página). Retas/setas: as duas pontas;
  /// as demais: 4 cantos + 4 meios de lado (ordem: TL, T, TR, R, BR, B, BL, L).
  List<Offset> editHandles() {
    final s = editing;
    if (s == null || s.points.isEmpty) return const [];
    if (_editKind == 'line' || _editKind == 'arrow') {
      return [s.points.first, s.points[1 < s.points.length ? 1 : 0]];
    }
    final b = boundsOf(s.points);
    return [
      b.topLeft, b.topCenter, b.topRight, b.centerRight,
      b.bottomRight, b.bottomCenter, b.bottomLeft, b.centerLeft,
    ];
  }

  /// Retorna o número da alça sob [p] (tolerância [tol], em unidades da página).
  int? hitHandle(Offset p, double tol) {
    final hs = editHandles();
    int? best;
    var bestD = tol;
    for (var i = 0; i < hs.length; i++) {
      final d = dist(hs[i], p);
      if (d <= bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  void beginResize(int handle) {
    final s = editing;
    if (s == null) return;
    _rsHandle = handle;
    _rsOrig = List<Offset>.of(s.points);
    _rsBox = boundsOf(s.points);
  }

  void resizeTo(Offset p) {
    final s = editing;
    if (s == null || _rsHandle < 0) return;
    if (_editKind == 'line' || _editKind == 'arrow') {
      final fixedEnd = _rsHandle == 0 ? _rsOrig[1] : _rsOrig.first;
      final moved = _softAngleSnap(fixedEnd, p);
      final a = _rsHandle == 0 ? moved : fixedEnd;
      final b = _rsHandle == 0 ? fixedEnd : moved;
      s.points = _editKind == 'arrow'
          ? shapePoints(ShapeKind.arrow, a, b, headLen: math.max(14.0, s.width * 5))
          : [a, b];
    } else {
      final o = _rsBox;
      var l = o.left, t = o.top, r = o.right, bt = o.bottom;
      switch (_rsHandle) {
        case 0:
          l = p.dx;
          t = p.dy;
        case 1:
          t = p.dy;
        case 2:
          r = p.dx;
          t = p.dy;
        case 3:
          r = p.dx;
        case 4:
          r = p.dx;
          bt = p.dy;
        case 5:
          bt = p.dy;
        case 6:
          l = p.dx;
          bt = p.dy;
        case 7:
          l = p.dx;
      }
      var nl = math.min(l, r), nr = math.max(l, r);
      var nt = math.min(t, bt), nb = math.max(t, bt);
      if (nr - nl < 6) nr = nl + 6;
      if (nb - nt < 6) nb = nt + 6;
      final sx = o.width < 1e-6 ? 1.0 : (nr - nl) / o.width;
      final sy = o.height < 1e-6 ? 1.0 : (nb - nt) / o.height;
      s.points = [
        for (final q in _rsOrig)
          Offset(nl + (q.dx - o.left) * sx, nt + (q.dy - o.top) * sy),
      ];
    }
    s.invalidate();
    _committed.ping();
    _live.ping();
  }

  void endResize() {
    if (_rsHandle < 0) return;
    _rsHandle = -1;
    notebook.modified = DateTime.now();
    onDocumentChanged?.call();
    version++;
    _committed.ping();
    notifyListeners();
  }

  /// Chamado quando a caneta ficou parada por um instante.
  /// Retorna true se encaixou uma reta ou forma (para dar um "tec" tátil).
  bool holdDetected() {
    final s = current;
    if (s == null || _snap != null) return false;
    // A caneta inteligente encaixa ao parar mesmo com o encaixe da caneta desligado.
    if (!_smart && !autoShape) return false;
    if (_active != Tool.pen &&
        _active != Tool.fountain &&
        _active != Tool.highlighter &&
        !_smart) {
      return false;
    }
    final r = recognizeShape(s.points);
    if (r == null) return false;
    _applyRecognized(s, r);
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
  /// Apaga ao longo do caminho de [a] até [b], sem deixar buracos quando a
  /// caneta anda rápido entre duas amostras.
  void _eraseSegment(Offset a, Offset b) {
    final step = math.max(1.0, eraserRadius * 0.6);
    final n = math.max(1, (dist(a, b) / step).ceil());
    for (var k = 1; k <= n; k++) {
      _eraseAtPoint(Offset.lerp(a, b, k / n)!);
    }
  }

  void _eraseAtPoint(Offset p) {
    final strokes = page.strokes;
    final r = eraserRadius;
    var changed = false;
    for (var i = strokes.length - 1; i >= 0; i--) {
      final s = strokes[i];
      if (!s.bounds.inflate(r).contains(p)) continue;
      if (!_strokeNear(s, p, r)) continue;
      if (!eraserPixel) {
        // modo "Traço": some o traço inteiro
        strokes.removeAt(i);
        changed = true;
      } else {
        // modo "Normal": tira só o pedaço debaixo da borracha
        final pieces = _erasePieces(s, p, r);
        if (pieces == null) continue;
        strokes.removeAt(i);
        strokes.insertAll(i, pieces);
        changed = true;
      }
    }
    if (changed) {
      _eraseChanged = true;
      version++;
      _committed.ping();
    }
  }

  bool _strokeNear(Stroke s, Offset p, double r) {
    final pts = s.points;
    // só conta o que está dentro do círculo desenhado (eixo do traço)
    final reach = r;
    if (pts.length == 1) return dist(pts[0], p) <= reach;
    for (var i = 1; i < pts.length; i++) {
      if (distToSegment(p, pts[i - 1], pts[i]) <= reach) return true;
    }
    return false;
  }

  /// Divide [s] tirando os pontos que a borracha em [p] alcança.
  /// Retorna null se nada foi removido; senão os pedaços que sobraram
  /// (lista vazia = o traço inteiro sumiu). O traço original não é alterado,
  /// por isso o desfazer só precisa guardar a lista de traços da página.
  List<Stroke>? _erasePieces(Stroke s, Offset p, double r) {
    // Pontos a menos de (raio + meia espessura) do centro da borracha somem;
    // a ponta redonda do que sobra deixa o vão exatamente do tamanho do círculo.
    final thr = r + s.effectiveWidth / 2;
    final step = math.max(0.5, r / 10);

    // Densifica o traço para a borracha poder cortar entre dois pontos.
    final src = s.points;
    final srcW = s.variable ? s.widths! : null;
    final pts = <Offset>[];
    final ws = srcW == null ? null : <double>[];
    for (var i = 0; i < src.length; i++) {
      pts.add(src[i]);
      if (ws != null && srcW != null) ws.add(srcW[i]);
      if (i + 1 < src.length) {
        final a = src[i], b = src[i + 1];
        final n = (dist(a, b) / step).ceil();
        for (var k = 1; k < n; k++) {
          final t = k / n;
          pts.add(Offset.lerp(a, b, t)!);
          if (ws != null && srcW != null) {
            ws.add(srcW[i] + (srcW[i + 1] - srcW[i]) * t);
          }
        }
      }
    }

    final keep = [for (final q in pts) dist(q, p) > thr];
    if (!keep.contains(false)) return null;

    final pieces = <Stroke>[];
    var i = 0;
    while (i < pts.length) {
      if (!keep[i]) {
        i++;
        continue;
      }
      var j = i;
      while (j < pts.length && keep[j]) {
        j++;
      }
      if (j - i >= 2) {
        // sobras de 1 ponto virariam uma "pintinha": descarta
        pieces.add(Stroke(
          id: _newId(),
          points: pts.sublist(i, j),
          color: s.color,
          width: s.width,
          highlighter: s.highlighter,
          smooth: s.smooth,
          pressure: s.pressure,
          fountain: s.fountain,
          widths: ws?.sublist(i, j),
        ));
      }
      i = j;
    }
    return pieces;
  }

  void _finishErase() {
    final before = _eraseBefore;
    final pg = _eraseSessionPage;
    final changed = _eraseChanged;
    _eraseBefore = null;
    _eraseSessionPage = null;
    _eraseChanged = false;
    _lastErasePos = null;
    eraserPos = null;
    _live.ping();
    if (!changed || before == null || pg == null) return;

    final after = List<Stroke>.of(pg.strokes);
    _push(_Action(
      () {
        pg.strokes
          ..clear()
          ..addAll(before);
        _show(pg);
      },
      () {
        pg.strokes
          ..clear()
          ..addAll(after);
        _show(pg);
      },
    ));
    _bump();
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
    if (i >= 0) {
      pageIndex = i;
      _requestScroll(i, force: false);
    }
  }

  void _requestScroll(int i, {bool force = true}) {
    scrollTarget = i;
    scrollForce = force;
    scrollTick++;
  }

  void _bump() {
    editing = null;
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
  /// Vai para a página [i] e rola a vista até ela.
  void goToPage(int i) {
    if (i < 0 || i >= notebook.pages.length) return;
    if (i != pageIndex) {
      current = null;
      pageIndex = i;
    }
    _requestScroll(i);
    _bump();
    _pingLive(force: true);
  }

  /// A página [i] virou a ativa (você tocou nela ou rolou até ela), sem rolar.
  void activatePage(int i) {
    if (i < 0 || i >= notebook.pages.length || i == pageIndex) return;
    editing = null;
    pageIndex = i;
    notifyListeners();
  }

  void addPage() {
    notebook.pages.add(NotePage(background: notebook.nextBackground ?? page.background));
    goToPage(notebook.pages.length - 1);
  }

  void deletePage() => deletePageAt(pageIndex);

  /// Exclui a página [i] (se for a única, só esvazia).
  void deletePageAt(int i) {
    if (i < 0 || i >= notebook.pages.length) return;
    current = null;
    if (notebook.pages.length <= 1) {
      notebook.pages[i].strokes.clear();
    } else {
      notebook.pages.removeAt(i);
      if (i < pageIndex) pageIndex--;
      if (pageIndex >= notebook.pages.length) pageIndex = notebook.pages.length - 1;
    }
    _requestScroll(pageIndex);
    _undo.clear();
    _redo.clear();
    _bump();
    _pingLive(force: true);
  }

  void cycleBackground() {
    final values = PageBackground.values;
    page.background = values[(page.background.index + 1) % values.length];
    notebook.nextBackground = page.background; // vale para as próximas páginas
    _bump();
  }
}
