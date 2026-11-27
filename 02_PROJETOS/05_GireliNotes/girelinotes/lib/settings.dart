import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import 'app_style.dart';
import 'models.dart' show StrokeStyle;

enum ThemePref { system, light, dark }

/// Onde fica a barra de ferramentas.
enum ToolbarPos { top, bottom, left, right }

/// Preferências do app. Qualquer mudança passa por [update], que avisa a
/// interface e dispara o salvamento (configurado em [onChanged]).
class AppSettings extends ChangeNotifier {
  AppSettings();

  static const int defaultAccent = 0xFF2979FF;

  /// Cores de destaque disponíveis (a primeira, azul, é a padrão).
  static const List<int> accents = [
    0xFF2979FF, // azul
    0xFF00ACC1, // ciano
    0xFF00897B, // verde-azulado
    0xFF7C4DFF, // violeta
    0xFFE91E63, // rosa
    0xFFFF6D00, // laranja
  ];

  // ---- aparência ----
  ThemePref theme = ThemePref.system;
  int accent = defaultAccent;
  AppStyle style = AppStyle.padrao;

  // ---- palm rejection ----
  bool palmRejection = true;

  /// Por quanto tempo (ms) o toque é ignorado depois que a caneta encosta
  /// ou paira sobre a tela.
  int palmGuardMs = 600;

  /// Contato maior que isto (raio, em pixels lógicos) é tratado como palma.
  double palmRadius = 30;

  ToolbarPos toolbarPos = ToolbarPos.top;

  /// Estilo do traço das canetas (contínuo, tracejado, pontilhado).
  StrokeStyle strokeStyle = StrokeStyle.solid;

  // ---- papel ----
  /// Distância entre as linhas do pautado/quadriculado (unidades da página).
  double lineSpacing = 40;

  // ---- formas e gestos ----
  /// Formas fechadas (retângulo, elipse, triângulo) saem com fundo claro e translúcido.
  bool shapeFill = false;
  /// Estabilização do traço por caneta (0 = segue a caneta, 1 = bem suave).
  double stabPen = 0.4, stabFountain = 0.4, stabBrush = 0.4;
  /// Sensibilidade à pressão (0.5 = padrão) e ponta fina do tinteiro.
  double pressFountain = 0.5, pressBrush = 0.5, sharpFountain = 0.5;
  bool autoShape = true;
  int holdMs = 500;
  bool scribbleErase = true;
  bool fingerDraws = false;

  // ---- mover com a caneta (mãozinha) ----
  /// Tecla que, enquanto segurada, faz a caneta arrastar a página em vez de
  /// desenhar. Guarda o keyId da tecla (padrão: Espaço).
  static const int defaultPanKey = 0x20;
  int panKeyId = defaultPanKey;

  /// Fundo da primeira página de cada caderno novo.
  /// Índice de PageBackground: 0 liso, 1 pautado, 2 quadriculado.
  int newNotebookBackground = 0;

  // ---- cores ----
  static const List<int> defaultPenPalette = [
    0xFF1A1A1A,
    0xFF2979FF,
    0xFFC62828,
    0xFF2E7D32,
    0xFFEF6C00,
    0xFF6A1B9A,
  ];
  static const List<int> defaultHlPalette = [
    0xFFFFEB3B, // amarelo
    0xFF76FF03, // verde
    0xFFFF80AB, // rosa
    0xFF40C4FF, // azul
    0xFFFFAB40, // laranja
  ];

  /// Cores da barra principal (você pode trocar arrastando cores do painel).
  List<int> penPalette = List<int>.of(defaultPenPalette);
  List<int> hlPalette = List<int>.of(defaultHlPalette);

  /// A dica do Shift na mãozinha já foi usada/vista.
  bool shiftHintSeen = false;

  /// Últimas cores escolhidas no painel de cores (a mais recente primeiro).
  List<int> recentColors = [];

  // ---- borracha ----
  /// false: "Traço" (apaga o traço inteiro que a borracha toca);
  /// true: "Normal" (apaga só por onde a borracha passa).
  bool eraserPixel = false;

  /// Raio da borracha, em unidades da página.
  double eraserSize = 10;

  /// Chamado depois de cada mudança (usado para gravar em disco).
  VoidCallback? onChanged;

  void update(VoidCallback change) {
    change();
    notifyListeners();
    onChanged?.call();
  }

  Map<String, dynamic> toJson() => {
        'theme': theme.index,
        'accent': accent,
        'style': style.index,
        'palmRejection': palmRejection,
        'palmGuardMs': palmGuardMs,
        'palmRadius': palmRadius,
        'stabPen': stabPen,
        'stabFountain': stabFountain,
        'stabBrush': stabBrush,
        'pressFountain': pressFountain,
        'pressBrush': pressBrush,
        'sharpFountain': sharpFountain,
        'lineSpacing': lineSpacing,
        'strokeStyle': strokeStyle.index,
        'toolbarPos': toolbarPos.index,
        'shapeFill': shapeFill,
        'autoShape': autoShape,
        'holdMs': holdMs,
        'scribbleErase': scribbleErase,
        'fingerDraws': fingerDraws,
        'eraserPixel': eraserPixel,
        'eraserSize': eraserSize,
        'panKeyId': panKeyId,
        'penPalette': penPalette,
        'hlPalette': hlPalette,
        'shiftHintSeen': shiftHintSeen,
        'newNotebookBg': newNotebookBackground,
        'recentColors': recentColors,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final s = AppSettings();
    final t = j['theme'];
    if (t is int && t >= 0 && t < ThemePref.values.length) {
      s.theme = ThemePref.values[t];
    }
    final a = j['accent'];
    if (a is int) s.accent = a;
    final st = j['style'];
    if (st is int && st >= 0 && st < AppStyle.values.length) s.style = AppStyle.values[st];
    if (j['palmRejection'] is bool) s.palmRejection = j['palmRejection'] as bool;
    final g = j['palmGuardMs'];
    if (g is num) s.palmGuardMs = g.toInt().clamp(100, 3000).toInt();
    final r = j['palmRadius'];
    if (r is num) s.palmRadius = r.toDouble().clamp(10.0, 80.0).toDouble();
    final tp = j['toolbarPos'];
    if (tp is int && tp >= 0 && tp < ToolbarPos.values.length) {
      s.toolbarPos = ToolbarPos.values[tp];
    } else if (j['toolbarBottom'] == true) {
      s.toolbarPos = ToolbarPos.bottom; // versão anterior
    }
    final ss = j['strokeStyle'];
    if (ss is int && ss >= 0 && ss < StrokeStyle.values.length) {
      s.strokeStyle = StrokeStyle.values[ss];
    }
    final ls = j['lineSpacing'];
    if (ls is num) s.lineSpacing = ls.toDouble().clamp(20.0, 80.0).toDouble();
    if (j['shapeFill'] is bool) s.shapeFill = j['shapeFill'] as bool;
    double unit(Object? v, double d) => v is num ? v.toDouble().clamp(0.0, 1.0).toDouble() : d;
    final legacy = unit(j['stabilization'], 0.4); // versão antiga: uma só para todas
    s.stabPen = unit(j['stabPen'], legacy);
    s.stabFountain = unit(j['stabFountain'], legacy);
    s.stabBrush = unit(j['stabBrush'], legacy);
    s.pressFountain = unit(j['pressFountain'], 0.5);
    s.pressBrush = unit(j['pressBrush'], 0.5);
    s.sharpFountain = unit(j['sharpFountain'], 0.5);
    if (j['autoShape'] is bool) s.autoShape = j['autoShape'] as bool;
    final h = j['holdMs'];
    if (h is num) s.holdMs = h.toInt().clamp(200, 1500).toInt();
    if (j['scribbleErase'] is bool) s.scribbleErase = j['scribbleErase'] as bool;
    if (j['fingerDraws'] is bool) s.fingerDraws = j['fingerDraws'] as bool;
    if (j['eraserPixel'] is bool) s.eraserPixel = j['eraserPixel'] as bool;
    final es = j['eraserSize'];
    if (es is num) s.eraserSize = es.toDouble().clamp(3.0, 60.0).toDouble();
    final db = j['newNotebookBg'];
    if (db is int && db >= 0 && db <= 2) s.newNotebookBackground = db;
    final pp = j['penPalette'];
    if (pp is List && pp.length == defaultPenPalette.length && pp.every((e) => e is int)) {
      s.penPalette = pp.cast<int>().toList();
    }
    final hp = j['hlPalette'];
    if (hp is List && hp.length == defaultHlPalette.length && hp.every((e) => e is int)) {
      s.hlPalette = hp.cast<int>().toList();
    }
    if (j['shiftHintSeen'] is bool) s.shiftHintSeen = j['shiftHintSeen'] as bool;
    final pk = j['panKeyId'];
    if (pk is int && pk > 0) s.panKeyId = pk;
    final rc = j['recentColors'];
    if (rc is List) {
      s.recentColors = [for (final c in rc) if (c is int) c].take(10).toList();
    }
    return s;
  }
}

/// Nome da tecla para mostrar na interface.
String keyLabelPt(int keyId) {
  if (keyId == AppSettings.defaultPanKey) return 'Espaço';
  final k = LogicalKeyboardKey.findKeyByKeyId(keyId);
  final label = k?.keyLabel ?? '';
  if (label.trim().isNotEmpty) return label.toUpperCase();
  return k?.debugName ?? 'Tecla';
}
