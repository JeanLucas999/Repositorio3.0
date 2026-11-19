import 'settings.dart';

/// Decide quais toques devem ser ignorados porque provavelmente são a palma
/// da mão. Não depende de widgets: recebe só números, então dá para testar.
///
/// Três sinais:
///  1. a caneta está encostada, ou encostou/pairou há pouco ([AppSettings.palmGuardMs]);
///  2. o contato é grande demais para um dedo ([AppSettings.palmRadius]);
///  3. a palma pousou ANTES da caneta (a view chama [ignore] nos toques já ativos).
class PalmGuard {
  PalmGuard(this.settings);

  final AppSettings settings;

  bool _penDown = false;
  bool _seenPen = false;
  int _lastPenMs = -100000000;
  final Set<int> _ignored = {};

  bool get penDown => _penDown;

  void onPenDown(int nowMs) {
    _seenPen = true;
    _penDown = true;
    _lastPenMs = nowMs;
  }

  void onPenMove(int nowMs) => _lastPenMs = nowMs;

  void onPenHover(int nowMs) {
    _seenPen = true;
    _lastPenMs = nowMs;
  }

  void onPenUp(int nowMs) {
    _penDown = false;
    _lastPenMs = nowMs;
  }

  bool _penNear(int nowMs) =>
      _penDown || (_seenPen && nowMs - _lastPenMs < settings.palmGuardMs);

  /// Um dedo/palma encostou. Retorna true se deve ser ignorado.
  bool rejectTouchDown(int pointer, int nowMs, double radiusMajor) {
    if (!settings.palmRejection) return false;
    if (_penNear(nowMs) || radiusMajor > settings.palmRadius) {
      _ignored.add(pointer);
      return true;
    }
    return false;
  }

  /// O toque se mexeu. Retorna true se deve ser ignorado (inclusive se
  /// ele cresceu e virou uma palma no meio do caminho).
  bool rejectTouchMove(int pointer, double radiusMajor) {
    if (!settings.palmRejection) return false;
    if (_ignored.contains(pointer)) return true;
    if (radiusMajor > settings.palmRadius) {
      _ignored.add(pointer);
      return true;
    }
    return false;
  }

  void ignore(int pointer) => _ignored.add(pointer);

  bool isIgnored(int pointer) => _ignored.contains(pointer);

  void touchEnded(int pointer) => _ignored.remove(pointer);

  void reset() {
    _penDown = false;
    _ignored.clear();
  }
}
