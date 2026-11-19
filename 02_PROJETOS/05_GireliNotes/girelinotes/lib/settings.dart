import 'package:flutter/foundation.dart';

enum ThemePref { system, light, dark }

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

  // ---- palm rejection ----
  bool palmRejection = true;

  /// Por quanto tempo (ms) o toque é ignorado depois que a caneta encosta
  /// ou paira sobre a tela.
  int palmGuardMs = 600;

  /// Contato maior que isto (raio, em pixels lógicos) é tratado como palma.
  double palmRadius = 30;

  // ---- formas e gestos ----
  bool autoShape = true;
  int holdMs = 500;
  bool scribbleErase = true;
  bool fingerDraws = false;

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
        'palmRejection': palmRejection,
        'palmGuardMs': palmGuardMs,
        'palmRadius': palmRadius,
        'autoShape': autoShape,
        'holdMs': holdMs,
        'scribbleErase': scribbleErase,
        'fingerDraws': fingerDraws,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final s = AppSettings();
    final t = j['theme'];
    if (t is int && t >= 0 && t < ThemePref.values.length) {
      s.theme = ThemePref.values[t];
    }
    final a = j['accent'];
    if (a is int) s.accent = a;
    if (j['palmRejection'] is bool) s.palmRejection = j['palmRejection'] as bool;
    final g = j['palmGuardMs'];
    if (g is num) s.palmGuardMs = g.toInt().clamp(100, 3000).toInt();
    final r = j['palmRadius'];
    if (r is num) s.palmRadius = r.toDouble().clamp(10.0, 80.0).toDouble();
    if (j['autoShape'] is bool) s.autoShape = j['autoShape'] as bool;
    final h = j['holdMs'];
    if (h is num) s.holdMs = h.toInt().clamp(200, 1500).toInt();
    if (j['scribbleErase'] is bool) s.scribbleErase = j['scribbleErase'] as bool;
    if (j['fingerDraws'] is bool) s.fingerDraws = j['fingerDraws'] as bool;
    return s;
  }
}
