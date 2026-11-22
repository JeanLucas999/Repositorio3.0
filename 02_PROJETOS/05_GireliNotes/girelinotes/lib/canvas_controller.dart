import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'geometry.dart';
import 'models.dart';
import 'pen_tune.dart';
import 'page_image.dart';
import 'scribble.dart';
import 'settings.dart';
import 'shape_recognizer.dart';
import 'shapes.dart';

/// pen/fountain = canetas; shape = formas básicas (reta, seta, retângulo...);
/// pan = mãozinha (a caneta arrasta a página em vez de desenhar).
enum Tool { pen, fountain, brush, smart, select, highlighter, shape, eraser, pan }

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
  double brushWidth = 4.0;
  double hlWidth = 6;
  bool showOptions = false; // linha de opções (cor/espessura ou borracha) aberta
  bool showShapeLib = false; // biblioteca de formas aberta
  bool showTune = false; // painel de ajustes da caneta aberto
  bool showColors = false; // painel de cores (paleta extra + círculo cromático) aberto

  /// Forma escolhida na mini barra (usada quando a ferramenta é [Tool.shape]).
  ShapeKind shapeKind = ShapeKind.line;


  /// Forma recém-criada que ainda pode ser redimensionada pelas alças.
  Stroke? editing;
  Offset _fixedEnd = Offset.zero; // fim da forma fixa que está sendo desenhada
  ShapeKind _editShape = ShapeKind.arrow; // forma de seta em edição
  List<Offset> _editEnds = const []; // pontas (a, b) da seta em edição
  List<Offset> _rsEnds = const [];
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

  // Forma recém-reconhecida "presa" à caneta: mexer a caneta redimensiona a forma.
  List<Offset> _snapOrig = const [];
  Offset _snapAnchor = Offset.zero; // canto fixo (o mais longe da caneta)
  Offset _snapPen = Offset.zero; // onde a caneta estava quando a forma encaixou
  bool _snapRound = false; // círculo/quadrado: mantém a proporção

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
  bool get usesColor => tool != Tool.eraser && tool != Tool.pan && tool != Tool.select;

  /// A caneta/mouse deve arrastar a página (mãozinha) em vez de desenhar?
  bool get panActive => tool == Tool.pan || panHeld;

  int get color => switch (tool) {
        Tool.highlighter => hlColor,
        _ => penColor,
      };
  double get width => switch (tool) {
        Tool.highlighter => hlWidth,
        Tool.fountain => fountainWidth,
        Tool.brush => brushWidth,
        _ => penWidth,
      };
  double get minWidth => switch (tool) {
        Tool.highlighter => 3.0,
        Tool.fountain => 1.5,
        Tool.brush => 2.0,
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
  bool get isPenTool => tool == Tool.pen || tool == Tool.fountain || tool == Tool.brush || tool == Tool.smart;

  /// Troca a ferramenta (atalhos de teclado).
  void setTool(Tool t) {
    editing = null;
    if (t != Tool.select) _dropSel();
    tool = t;
    if (t == Tool.pen || t == Tool.fountain || t == Tool.brush || t == Tool.smart) lastPen = t;
    notifyListeners();
  }

  /// Toque numa ferramenta da barra; tocar de novo na que já está ativa
  /// abre/fecha a linha de opções (cor e espessura, ou a borracha).
  void selectTool(Tool t) {
    editing = null;
    if (t != Tool.select) _dropSel();
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
      if (t != Tool.select) _setOptions(!showOptions);
    } else {
      tool = t;
      if (t == Tool.pen || t == Tool.fountain || t == Tool.brush || t == Tool.smart) lastPen = t;
    }
    notifyListeners();
  }

  /// Abre/fecha a linha de opções; fechar leva junto o painel de cores.
  void _setOptions(bool open) {
    showOptions = open;
    if (!open) {
      showColors = false;
      showTune = false;
    }
  }

  /// Escolhe uma forma da mini barra e passa para a ferramenta de formas.
  /// Atalho L: ativa as formas; com elas já ativas, abre/fecha a biblioteca.
  void openShapes() {
    if (tool == Tool.shape) {
      showShapeLib = !showShapeLib;
      notifyListeners();
    } else {
      setShape(shapeKind);
    }
  }

  void toggleShapeLib() {
    showShapeLib = !showShapeLib;
    notifyListeners();
  }

  void setShape(ShapeKind k) {
    showShapeLib = false;
    editing = null;
    _dropSel();
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

  /// Estabilização da caneta [t] (a de formas usa a da caneta comum).
  double stabOf(Tool t) => switch (t) {
        Tool.fountain => settings.stabFountain,
        Tool.brush => settings.stabBrush,
        _ => settings.stabPen,
      };

  void toggleTune() {
    showTune = !showTune;
    if (showTune) showColors = false;
    notifyListeners();
  }

  void toggleColors() {
    showColors = !showColors;
    if (showColors) showTune = false;
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
    _dropSel();
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
    if (t != Tool.pen && t != Tool.fountain && t != Tool.brush && t != Tool.smart) return;
    _dropSel();
    tool = t;
    lastPen = t;
    notifyListeners();
  }

  void setStrokeStyle(StrokeStyle st) => settings.update(() => settings.strokeStyle = st);

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
      case Tool.brush:
        brushWidth = w;
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
    if (showColors || showTune || showShapeLib) {
      // desenhar fecha os painéis flutuantes (cores, ajustes e formas)
      showColors = false;
      showTune = false;
      showShapeLib = false;
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
    final br = _active == Tool.brush;
    final ft = _active == Tool.fountain || br;
    _pSm = pressure;
    _lastDir = Offset.zero;
    _wPrev = (br ? brushWidth : fountainWidth) *
        pressureFactor(_active, pressure, br ? settings.pressBrush : settings.pressFountain);
    current = Stroke(
      id: _newId(),
      points: [p],
      color: hl ? hlColor : penColor, // caneta e tinteiro dividem a cor
      width: hl ? hlWidth : (br ? brushWidth : (ft ? fountainWidth : penWidth)),
      highlighter: hl,
      smooth: !_fixed,
      pressure: _fixed ? 0.5 : pressure, // formas fixas: espessura uniforme
      fountain: ft,
      style: (_active == Tool.pen || ft || _smart) ? settings.strokeStyle : StrokeStyle.solid,
      widths: ft ? [_wPrev * 0.5] : null, // começa fino
      fill: (_fixed && settings.shapeFill && _closedShape(shapeKind))
          ? ((penColor & 0x00FFFFFF) | (kShapeFillAlpha << 24))
          : null,
    );
    _pingLive();
  }

  static const int kShapeFillAlpha = 46; // ~18%: claro, sem esconder o que está atrás

  static bool _closedShape(ShapeKind k) => isClosedShape(k);

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
      final straight = shapeKind == ShapeKind.line ||
          shapeKind == ShapeKind.arrow ||
          shapeKind == ShapeKind.doubleArrow;
      final end = straight ? _softAngleSnap(start, p) : p;
      _fixedEnd = end;
      s.points = shapePoints(shapeKind, start, end, headLen: math.max(14.0, s.width * 5));
      final outline = shapeFillOutline(shapeKind, start, end);
      if (outline != null) {
        final bb = boundsOf(s.points);
        final w = math.max(bb.width, 1e-9), h = math.max(bb.height, 1e-9);
        s.fillNorm = [for (final q in outline) Offset((q.dx - bb.left) / w, (q.dy - bb.top) / h)];
      }
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
    if (_snap != null) {
      _resizeWithPen(s, p); // a forma continua presa à caneta
      return;
    }

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
    final minA = 0.6 - 0.4 * stabOf(_active); // 0.6 (leve) .. 0.2 (forte)
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

    final br = _active == Tool.brush;
    // Pincel: largura bem mais sensível à pressão, entrada e saída longas.
    var w = s.width *
        pressureFactor(_active, _pSm, br ? settings.pressBrush : settings.pressFountain) *
        (br ? 1.1 - 0.5 * sp : 1.15 - 0.55 * sp);
    w = _wPrev * (br ? 0.8 : 0.7) + w * (br ? 0.2 : 0.3);
    // variação limitada por ponto: nada de degraus nem "pulsos" na largura
    final slew = (br ? 0.09 : 0.05) * s.width;
    w = w.clamp(_wPrev - slew, _wPrev + slew).toDouble();
    _wPrev = w;

    final n = s.widths!.length;
    final ramp = br
        ? (n < 8 ? 0.2 + 0.1 * n : 1.0)
        : (n < 4 ? _tip + (1 - _tip) * n / 4 : 1.0);
    return w * ramp;
  }

  double get _tip => tipMin(settings.sharpFountain);

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

    // Toque sem arrastar: vira um ponto de tamanho normal (sem a rampa de
    // entrada/saída que deixaria a bolinha minúscula).
    final isDot = !_fixed && _snap == null && diagonalOf(boundsOf(s.points)) < 3 * pixelSize;
    if (isDot) {
      s.points = [s.points.first];
      if (s.fountain && s.widths != null) {
        final br = _active == Tool.brush;
        final avg = _pN > 0 ? _pSum / _pN : 0.5;
        final w = s.width *
            pressureFactor(_active, avg, br ? settings.pressBrush : settings.pressFountain);
        s.widths = [math.max(w, s.width * 0.8)];
      }
      s.invalidate();
    }

    // Formas inteligentes: ao soltar, o traço vira a forma reconhecida.
    if (_smart && _snap == null && !isDot) {
      final r = recognizeShape(s.points);
      if (r != null) _applyRecognized(s, r);
    }

    // Caneta tinteiro: a ponta final afina.
    final ws = s.widths;
    if (s.fountain && ws != null && ws.length >= 2) {
      final n = ws.length;
      if (_active == Tool.brush) {
        // saída longa e fina, como a ponta de um pincel
        for (var k = 0; k < 8 && k < n; k++) {
          ws[n - 1 - k] *= 0.12 + 0.11 * k; // 0,12 ... 0,89
        }
      } else {
        for (var k = 0; k < 3 && k < n; k++) {
          ws[n - 1 - k] *= _tip + (1 - _tip) * k / 3; // ponta fina (config.)
        }
      }
      s.invalidate();
    }

    // Riscar por cima de algo existente = apagar.
    if ((_active == Tool.pen || _active == Tool.fountain || _active == Tool.brush) &&
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
    _captureSnap(s);
  }

  void _captureSnap(Stroke s) {
    final pen = _lastRaw ?? s.points.last;
    final b = boundsOf(s.points);
    final corners = [b.topLeft, b.topRight, b.bottomLeft, b.bottomRight];
    corners.sort((a, z) => dist(z, pen).compareTo(dist(a, pen)));
    _snapOrig = List<Offset>.of(s.points);
    _snapAnchor = corners.first;
    _snapPen = pen;
    final w = b.width, h = b.height;
    _snapRound = math.max(w, h) > 0 && (w - h).abs() / math.max(w, h) < 0.1;
  }

  /// Depois de encaixar, o movimento da caneta escala a forma a partir do canto oposto.
  void _resizeWithPen(Stroke s, Offset p) {
    if (_snapOrig.isEmpty) return;
    final a = _snapAnchor;
    if (dist(p, _snapPen) < 6 * pixelSize) return; // tremor da mão: ignora
    final dx0 = _snapPen.dx - a.dx, dy0 = _snapPen.dy - a.dy;
    var sx = dx0.abs() < 8 ? 1.0 : (p.dx - a.dx) / dx0;
    var sy = dy0.abs() < 8 ? 1.0 : (p.dy - a.dy) / dy0;
    sx = sx.clamp(0.1, 30.0).toDouble();
    sy = sy.clamp(0.1, 30.0).toDouble();
    if (_snapRound && dx0.abs() >= 8 && dy0.abs() >= 8) {
      final u = (sx + sy) / 2;
      sx = u;
      sy = u;
    }
    s.points = [
      for (final q in _snapOrig) Offset(a.dx + (q.dx - a.dx) * sx, a.dy + (q.dy - a.dy) * sy),
    ];
    s.invalidate();
    _pingLive();
  }


  // ---------------- imagens e seleção (laço) ----------------
  final List<Stroke> selStrokes = [];
  final List<PageImage> selImages = [];
  List<Offset>? lasso; // laço sendo desenhado (página ativa)
  Offset Function()? centerOnPage; // centro da área visível, na página ativa (a tela define)

  List<Stroke> _clipS = [];
  List<PageImage> _clipI = [];
  bool get canPaste => _clipS.isNotEmpty || _clipI.isNotEmpty;

  bool get hasSel => tool == Tool.select && (selStrokes.isNotEmpty || selImages.isNotEmpty);

  /// Caixa que envolve tudo que está selecionado.
  Rect? get selBounds {
    Rect? r;
    for (final s in selStrokes) {
      r = r == null ? s.bounds : r.expandToInclude(s.bounds);
    }
    for (final im in selImages) {
      r = r == null ? im.rect : r.expandToInclude(im.rect);
    }
    return r;
  }

  Rect? get activeSelBounds => hasSel ? selBounds : null;

  /// Chamado quando uma imagem terminou de decodificar: repinta as páginas.
  void imageReady() {
    _committed.ping();
    _live.ping();
  }

  void _dropSel() {
    showSelColors = false;
    _rcBase = null;
    selStrokes.clear();
    selImages.clear();
    lasso = null;
  }

  void clearSelection() {
    if (selStrokes.isEmpty && selImages.isEmpty && lasso == null) return;
    _dropSel();
    _live.ping();
    notifyListeners();
  }

  /// Insere uma imagem (PNG, JPEG, WebP...) na página ativa, centrada em [at]
  /// (ou no centro da área visível). Passa para a ferramenta de seleção.
  /// Retorna false se os bytes não forem uma imagem.
  Future<bool> insertImageBytes(Uint8List raw, {Offset? at, int? pageNo}) async {
    final prep = await prepareImage(raw);
    if (prep == null) return false;
    if (pageNo != null) activatePage(pageNo);
    final ps = notebook.pageSize;
    var w = prep.$2.width, h = prep.$2.height;
    final maxW = notebook.infinite ? 600.0 : ps.width * 0.6;
    final maxH = notebook.infinite ? 600.0 : ps.height * 0.5;
    final k = math.min(1.0, math.min(maxW / w, maxH / h));
    w *= k;
    h *= k;
    final center = at ?? centerOnPage?.call() ?? Offset(ps.width / 2, ps.height / 2);
    var left = center.dx - w / 2, top = center.dy - h / 2;
    if (!notebook.infinite) {
      left = left.clamp(0.0, math.max(0.0, ps.width - w)).toDouble();
      top = top.clamp(0.0, math.max(0.0, ps.height - h)).toDouble();
    }
    _adoptNew(PageImage(id: _newId(), bytes: prep.$1, rect: Rect.fromLTWH(left, top, w, h)));
    return true;
  }

  /// Põe um item novo na página ativa (desfazível), seleciona e passa para Selecionar.
  void _adoptNew(PageImage img) {
    final pg = page;
    pg.images.add(img);
    _push(_Action(
      () {
        pg.images.remove(img);
        _show(pg);
      },
      () {
        pg.images.add(img);
        _show(pg);
      },
    ));
    editing = null;
    tool = Tool.select;
    _setOptions(false);
    _bump();
    selImages.add(img); // _bump limpa a seleção; seleciona o novo
    _live.ping();
    notifyListeners();
  }

  /// Cria um post-it no centro da área visível (ou em [at]).
  void insertNote(String text, int color, double fontSize, {Offset? at}) {
    const w = 240.0, h = 190.0;
    final ps = notebook.pageSize;
    final center = at ?? centerOnPage?.call() ?? Offset(ps.width / 2, ps.height / 2);
    var left = center.dx - w / 2, top = center.dy - h / 2;
    if (!notebook.infinite) {
      left = left.clamp(0.0, math.max(0.0, ps.width - w)).toDouble();
      top = top.clamp(0.0, math.max(0.0, ps.height - h)).toDouble();
    }
    _adoptNew(PageImage(
      id: _newId(),
      bytes: Uint8List(0),
      rect: Rect.fromLTWH(left, top, w, h),
      text: text,
      noteColor: color,
      fontSize: fontSize,
    ));
  }

  /// Muda texto, cor e/ou tamanho da letra de um post-it (desfazível).
  void updateNote(PageImage n, {String? text, int? color, double? fontSize}) {
    if (!n.isNote) return;
    final before = (n.text, n.noteColor, n.fontSize);
    final after = (text ?? n.text, color ?? n.noteColor, fontSize ?? n.fontSize);
    if (before == after) return;
    void set((String?, int, double) v) {
      n.text = v.$1;
      n.noteColor = v.$2;
      n.fontSize = v.$3;
    }

    final pg = page;
    set(after);
    _push(_Action(
      () {
        set(before);
        _show(pg);
      },
      () {
        set(after);
        _show(pg);
      },
    ));
    notebook.modified = DateTime.now();
    onDocumentChanged?.call();
    version++;
    _committed.ping();
    _live.ping();
    notifyListeners();
  }

  // --- laço ---
  void beginLasso(Offset p) {
    _dropSel();
    lasso = [p];
    _live.ping();
    notifyListeners();
  }

  void extendLasso(Offset p) {
    final l = lasso;
    if (l == null) return;
    if (dist(l.last, p) < 1.5) return;
    l.add(p);
    _live.ping();
  }

  /// Solta o laço. Laço minúsculo = toque: seleciona o item sob o dedo/caneta.
  void endLasso(double tol) {
    final l = lasso;
    lasso = null;
    if (l == null) return;
    if (l.length < 3 || diagonalOf(boundsOf(l)) < tol) {
      _pickAt(l.first, tol);
    } else {
      _selectInside(l);
    }
    _live.ping();
    notifyListeners();
  }

  bool _hitStroke(Stroke s, Offset p, double tol) {
    final reach = tol + s.width;
    if (!s.bounds.inflate(reach).contains(p)) return false;
    if (s.fill != null && s.points.length >= 3 && pointInPolygon(p, s.fillPolygon)) return true;
    if (s.points.length == 1) return dist(s.points.first, p) <= reach;
    for (var i = 1; i < s.points.length; i++) {
      if (distToSegment(p, s.points[i - 1], s.points[i]) <= reach) return true;
    }
    return false;
  }

  void _pickAt(Offset p, double tol) {
    final pg = page;
    for (var i = pg.strokes.length - 1; i >= 0; i--) {
      if (_hitStroke(pg.strokes[i], p, tol)) {
        selStrokes.add(pg.strokes[i]);
        return;
      }
    }
    for (var i = pg.images.length - 1; i >= 0; i--) {
      if (pg.images[i].rect.inflate(2).contains(p)) {
        selImages.add(pg.images[i]);
        return;
      }
    }
  }

  void _selectInside(List<Offset> poly) {
    final pg = page;
    final box = boundsOf(poly);
    for (final s in pg.strokes) {
      if (s.points.isEmpty || !s.bounds.overlaps(box.inflate(1))) continue;
      var n = 0;
      for (final q in s.points) {
        if (pointInPolygon(q, poly)) n++;
      }
      if (n * 2 >= s.points.length) selStrokes.add(s);
    }
    for (final im in pg.images) {
      if (pointInPolygon(im.rect.center, poly)) selImages.add(im);
    }
  }

  // --- mover / redimensionar a seleção ---
  Map<Stroke, List<Offset>> _origPts = {};
  Map<PageImage, Rect> _origRects = {};
  Rect _selBox = Rect.zero;
  Offset _selGrab = Offset.zero;
  int _selHandle = -2; // -2 nada, -1 mover, 0..3 cantos (TL, TR, BR, BL), 4..7 lados (T, R, B, L)
  bool _selMoved = false;

  List<Offset> selHandles() {
    final r = selBounds;
    if (r == null) return const [];
    return [
      r.topLeft, r.topRight, r.bottomRight, r.bottomLeft,
      // lados: só quando a seleção é de imagens/post-its (esticam sem manter a proporção)
      if (stretchable) ...[r.topCenter, r.centerRight, r.bottomCenter, r.centerLeft],
    ];
  }

  /// Seleção só de imagens e post-its: aceita esticar por um lado.
  bool get stretchable => selStrokes.isEmpty && selImages.isNotEmpty;

  int? hitSelHandle(Offset p, double tol) {
    final hs = selHandles();
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

  bool selContains(Offset p) => selBounds?.inflate(6).contains(p) ?? false;

  void _snapSel() {
    _selBox = selBounds ?? Rect.zero;
    _origPts = {for (final s in selStrokes) s: List<Offset>.of(s.points)};
    _origRects = {for (final im in selImages) im: im.rect};
    _selMoved = false;
  }

  void beginSelMove(Offset p) {
    if (!hasSel) return;
    _snapSel();
    _selHandle = -1;
    _selGrab = p;
  }

  void beginSelResize(int handle) {
    if (!hasSel) return;
    _snapSel();
    _selHandle = handle;
  }

  void _applySel(Offset Function(Offset) f) {
    for (final s in selStrokes) {
      final o = _origPts[s];
      if (o == null) continue;
      s.points = [for (final q in o) f(q)];
      s.invalidate();
    }
    for (final im in selImages) {
      final o = _origRects[im];
      if (o == null) continue;
      im.rect = Rect.fromPoints(f(o.topLeft), f(o.bottomRight));
    }
    _selMoved = true;
    _committed.ping();
    _live.ping();
  }

  /// Move ou redimensiona (proporcional, a partir do canto oposto) a seleção.
  void selDragTo(Offset p) {
    if (_selHandle == -2) return;
    if (_selHandle == -1) {
      final d = p - _selGrab;
      _applySel((q) => q + d);
      return;
    }
    final o = _selBox;
    if (_selHandle >= 4) {
      const minK = 0.05;
      final w = math.max(o.width, 1.0), h = math.max(o.height, 1.0);
      switch (_selHandle) {
        case 4: // topo: ancora na base
          final k = math.max((o.bottom - p.dy) / h, minK);
          _applySel((q) => Offset(q.dx, o.bottom + (q.dy - o.bottom) * k));
        case 5: // direita: ancora na esquerda
          final k = math.max((p.dx - o.left) / w, minK);
          _applySel((q) => Offset(o.left + (q.dx - o.left) * k, q.dy));
        case 6: // base: ancora no topo
          final k = math.max((p.dy - o.top) / h, minK);
          _applySel((q) => Offset(q.dx, o.top + (q.dy - o.top) * k));
        default: // esquerda: ancora na direita
          final k = math.max((o.right - p.dx) / w, minK);
          _applySel((q) => Offset(o.right + (q.dx - o.right) * k, q.dy));
      }
      return;
    }
    final anchor = switch (_selHandle) {
      0 => o.bottomRight,
      1 => o.bottomLeft,
      2 => o.topLeft,
      _ => o.topRight,
    };
    final sx = (_selHandle == 1 || _selHandle == 2) ? 1.0 : -1.0;
    final sy = (_selHandle == 2 || _selHandle == 3) ? 1.0 : -1.0;
    final w = math.max(o.width, 1.0), h = math.max(o.height, 1.0);
    final k = math.max(math.max((p.dx - anchor.dx) * sx / w, (p.dy - anchor.dy) * sy / h), 0.05);
    _applySel((q) => anchor + (q - anchor) * k);
  }

  void _restoreSel(Map<Stroke, List<Offset>> pts, Map<PageImage, Rect> rects) {
    pts.forEach((s, o) {
      s.points = List<Offset>.of(o);
      s.invalidate();
    });
    rects.forEach((im, r) => im.rect = r);
  }

  void endSelDrag() {
    if (_selHandle == -2) return;
    _selHandle = -2;
    if (!_selMoved) return;
    final bp = _origPts, br = _origRects;
    final ap = {for (final s in selStrokes) s: List<Offset>.of(s.points)};
    final ar = {for (final im in selImages) im: im.rect};
    final pg = page;
    _push(_Action(
      () {
        _restoreSel(bp, br);
        _show(pg);
      },
      () {
        _restoreSel(ap, ar);
        _show(pg);
      },
    ));
    notebook.modified = DateTime.now();
    onDocumentChanged?.call();
    version++;
    _committed.ping();
    notifyListeners();
  }

  // --- camada das imagens (frente/atrás) ---
  /// Posição do botãozinho de camada (perto do canto superior direito), ou null
  /// quando não há imagem selecionada.
  Offset? layerButtonPos(double scale) {
    if (!hasSel || selImages.isEmpty) return null;
    final r = selBounds;
    if (r == null) return null;
    return r.topRight + Offset(24 / scale, -24 / scale);
  }

  bool hitLayerButton(Offset p, double scale) {
    final b = layerButtonPos(scale);
    return b != null && dist(b, p) <= 16 / scale;
  }

  /// Manda as imagens selecionadas para trás da tinta, ou de volta para a frente.
  void toggleImageLayer() {
    if (!hasSel || selImages.isEmpty) return;
    final ims = List<PageImage>.of(selImages);
    final target = !ims.first.front;
    final before = {for (final im in ims) im: (im.front, im.z)};
    final pg = page;
    final now = DateTime.now().microsecondsSinceEpoch;
    for (final im in ims) {
      im.front = target;
      if (target) im.z = now; // vai para a frente do que já existe
    }
    _push(_Action(
      () {
        before.forEach((im, v) {
          im.front = v.$1;
          im.z = v.$2;
        });
        _show(pg);
      },
      () {
        for (final im in ims) {
          im.front = target;
          if (target) im.z = now;
        }
        _show(pg);
      },
    ));
    notebook.modified = DateTime.now();
    onDocumentChanged?.call();
    version++;
    _committed.ping();
    _live.ping();
    notifyListeners();
  }

  // --- ações sobre a seleção ---
  void deleteSelection() {
    if (!hasSel) return;
    final pg = page;
    final sPairs = <(int, Stroke)>[
      for (final s in selStrokes)
        if (pg.strokes.indexOf(s) case final i when i >= 0) (i, s),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final iPairs = <(int, PageImage)>[
      for (final im in selImages)
        if (pg.images.indexOf(im) case final i when i >= 0) (i, im),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    void remove() {
      for (final e in sPairs) {
        pg.strokes.remove(e.$2);
      }
      for (final e in iPairs) {
        pg.images.remove(e.$2);
      }
    }

    remove();
    _push(_Action(
      () {
        for (final e in sPairs) {
          pg.strokes.insert(math.min(e.$1, pg.strokes.length), e.$2);
        }
        for (final e in iPairs) {
          pg.images.insert(math.min(e.$1, pg.images.length), e.$2);
        }
        _show(pg);
      },
      () {
        remove();
        _show(pg);
      },
    ));
    _bump();
    _live.ping();
  }

  PageImage _cloneImage(PageImage im, Offset shift) =>
      PageImage(id: _newId(), bytes: im.bytes, rect: im.rect.shift(shift),
          front: im.front, text: im.text, noteColor: im.noteColor, fontSize: im.fontSize)
        ..image = im.image;

  /// Adiciona cópias à página ativa (desfazível) e as seleciona.
  void _addCopies(List<Stroke> ss, List<PageImage> ims) {
    final pg = page;
    pg.strokes.addAll(ss);
    pg.images.addAll(ims);
    _push(_Action(
      () {
        for (final s in ss) {
          pg.strokes.remove(s);
        }
        for (final im in ims) {
          pg.images.remove(im);
        }
        _show(pg);
      },
      () {
        pg.strokes.addAll(ss);
        pg.images.addAll(ims);
        _show(pg);
      },
    ));
    tool = Tool.select;
    _setOptions(false);
    _bump();
    selStrokes.addAll(ss);
    selImages.addAll(ims);
    _live.ping();
    notifyListeners();
  }

  void duplicateSelection() {
    if (!hasSel) return;
    const d = Offset(24, 24);
    _addCopies(
      [for (final s in selStrokes) s.clone(id: _newId(), shift: d)],
      [for (final im in selImages) _cloneImage(im, d)],
    );
  }

  void copySelection() {
    if (!hasSel) return;
    _clipS = [for (final s in selStrokes) s.clone()];
    _clipI = [for (final im in selImages) _cloneImage(im, Offset.zero)];
    notifyListeners();
  }

  void cutSelection() {
    copySelection();
    deleteSelection();
  }

  /// Cola o que foi copiado, centrado na área visível.
  void pasteSelection() {
    if (!canPaste) return;
    var box = Rect.zero;
    var first = true;
    for (final s in _clipS) {
      box = first ? s.bounds : box.expandToInclude(s.bounds);
      first = false;
    }
    for (final im in _clipI) {
      box = first ? im.rect : box.expandToInclude(im.rect);
      first = false;
    }
    final ps = notebook.pageSize;
    final target = centerOnPage?.call() ?? Offset(ps.width / 2, ps.height / 2);
    final d = target - box.center;
    _addCopies(
      [for (final s in _clipS) s.clone(id: _newId(), shift: d)],
      [for (final im in _clipI) _cloneImage(im, d)],
    );
  }

  bool showSelColors = false; // painel de cores da seleção aberto
  List<(int, Stroke)>? _rcBase; // traços originais (índice, objeto) durante o ajuste

  /// Cor do primeiro traço selecionado (para marcar no painel).
  int? get selectionColor => selStrokes.isEmpty ? null : selStrokes.first.color;

  void toggleSelColors() {
    showSelColors = !showSelColors;
    notifyListeners();
  }

  /// Guarda a cor entre as recentes do painel de cores.
  void rememberColor(int argb) {
    settings.update(() {
      final list = settings.recentColors;
      list.remove(argb);
      list.insert(0, argb);
      if (list.length > 10) list.removeRange(10, list.length);
    });
  }

  /// Mostra a cor [argb] nos traços selecionados sem registrar no desfazer
  /// (usado enquanto se arrasta o círculo cromático). Termine com [endRecolor].
  void previewRecolor(int argb) {
    if (!hasSel || selStrokes.isEmpty) return;
    final pg = page;
    _rcBase ??= [
      for (final s in selStrokes)
        if (pg.strokes.indexOf(s) case final i when i >= 0) (i, s),
    ];
    final newSel = <Stroke>[];
    for (final e in _rcBase!) {
      final n = e.$2.clone(color: (e.$2.color & 0xFF000000) | (argb & 0x00FFFFFF));
      pg.strokes[e.$1] = n;
      newSel.add(n);
    }
    selStrokes
      ..clear()
      ..addAll(newSel);
    _committed.ping();
    _live.ping();
    notifyListeners();
  }

  /// Fecha o ajuste de cor: um único passo no desfazer, mantendo a seleção.
  void endRecolor() {
    final base = _rcBase;
    _rcBase = null;
    if (base == null) return;
    final pg = page;
    final after = <(int, Stroke)>[for (final e in base) (e.$1, pg.strokes[e.$1])];
    _push(_Action(
      () {
        for (final e in base) {
          pg.strokes[e.$1] = e.$2;
        }
        _show(pg);
      },
      () {
        for (final e in after) {
          pg.strokes[e.$1] = e.$2;
        }
        _show(pg);
      },
    ));
    notebook.modified = DateTime.now();
    onDocumentChanged?.call();
    version++;
    _committed.ping();
    notifyListeners();
  }

  /// Troca a cor dos traços selecionados (mantém a transparência do marca-texto).
  void recolorSelection(int argb) {
    previewRecolor(argb);
    endRecolor();
  }

  // ---------------- redimensionar a forma recém-criada ----------------
  void _startEditing(Stroke s) {
    editing = s;
    if (_fixed && isArrowLike(shapeKind)) {
      _editKind = 'arrow';
      _editShape = shapeKind;
      _editEnds = [_shapeStart ?? s.points.first, _fixedEnd];
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
    if (_editKind == 'arrow') return List<Offset>.of(_editEnds);
    if (_editKind == 'line') {
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
    _rsEnds = List<Offset>.of(_editEnds);
    _rsBox = boundsOf(s.points);
  }

  void resizeTo(Offset p) {
    final s = editing;
    if (s == null || _rsHandle < 0) return;
    if (_editKind == 'arrow') {
      final fixedEnd = _rsHandle == 0 ? _rsEnds[1] : _rsEnds[0];
      final moved = _editShape == ShapeKind.curvedArrow ? p : _softAngleSnap(fixedEnd, p);
      final a = _rsHandle == 0 ? moved : fixedEnd;
      final b = _rsHandle == 0 ? fixedEnd : moved;
      _editEnds = [a, b];
      s.points = shapePoints(_editShape, a, b, headLen: math.max(14.0, s.width * 5));
    } else if (_editKind == 'line') {
      final fixedEnd = _rsHandle == 0 ? _rsOrig[1] : _rsOrig.first;
      final moved = _softAngleSnap(fixedEnd, p);
      final a = _rsHandle == 0 ? moved : fixedEnd;
      final b = _rsHandle == 0 ? fixedEnd : moved;
      s.points = [a, b];
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
        _active != Tool.brush &&
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
          id: '${s.t}-${_idCounter++}', // mantém a ordem em relação às imagens
          points: pts.sublist(i, j),
          color: s.color,
          width: s.width,
          highlighter: s.highlighter,
          smooth: s.smooth,
          pressure: s.pressure,
          fountain: s.fountain,
          style: s.style,
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
    _dropSel();
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
