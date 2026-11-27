import 'dart:math' as math;

typedef MathFn = double Function(double x);

const Map<String, double Function(double)> _funcs = {
  'sin': math.sin,
  'cos': math.cos,
  'tan': math.tan,
  'asin': math.asin,
  'acos': math.acos,
  'atan': math.atan,
  'sqrt': math.sqrt,
  'abs': _abs,
  'ln': math.log,
  'log': _log10,
  'exp': math.exp,
  'floor': _floor,
  'ceil': _ceil,
  'cbrt': _cbrt,
  'sinh': _sinh,
  'cosh': _cosh,
  'tanh': _tanh,
};

double _abs(double v) => v.abs();
double _log10(double v) => math.log(v) / math.ln10;
double _floor(double v) => v.floorToDouble();
double _ceil(double v) => v.ceilToDouble();
double _cbrt(double v) => v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();
double _sinh(double v) => (math.exp(v) - math.exp(-v)) / 2;
double _cosh(double v) => (math.exp(v) + math.exp(-v)) / 2;
double _tanh(double v) {
  if (v > 20) return 1;
  if (v < -20) return -1;
  final a = math.exp(v), b = math.exp(-v);
  return (a - b) / (a + b);
}

const Map<String, double> _consts = {'pi': math.pi, 'e': math.e};

class _Tok {
  _Tok(this.kind, this.text, [this.num = 0]);
  final String kind; // n número, i nome, o operador
  final String text;
  final double num;
}

/// Quebra um nome colado ("xsin", "pix") em nomes conhecidos, do maior para o menor.
List<String>? _splitName(String s) {
  final names = ['x', ..._funcs.keys, ..._consts.keys]..sort((a, b) => b.length.compareTo(a.length));
  if (s.isEmpty) return [];
  for (final n in names) {
    if (s.startsWith(n)) {
      final rest = _splitName(s.substring(n.length));
      if (rest != null) return [n, ...rest];
    }
  }
  return null;
}

List<_Tok> _tokenize(String src) {
  final out = <_Tok>[];
  var i = 0;
  while (i < src.length) {
    final ch = src[i];
    if (ch.trim().isEmpty) {
      i++;
    } else if (RegExp(r'[0-9.]').hasMatch(ch)) {
      var j = i;
      while (j < src.length && RegExp(r'[0-9.]').hasMatch(src[j])) {
        j++;
      }
      final v = double.tryParse(src.substring(i, j));
      if (v == null) throw FormatException('Número inválido: "${src.substring(i, j)}".');
      out.add(_Tok('n', src.substring(i, j), v));
      i = j;
    } else if (RegExp(r'[a-z]').hasMatch(ch)) {
      var j = i;
      while (j < src.length && RegExp(r'[a-z]').hasMatch(src[j])) {
        j++;
      }
      final word = src.substring(i, j);
      final parts = _splitName(word);
      if (parts == null) throw FormatException('Não entendi "$word".');
      for (final p in parts) {
        out.add(_Tok('i', p));
      }
      i = j;
    } else if ('+-*/^()'.contains(ch)) {
      out.add(_Tok('o', ch));
      i++;
    } else {
      throw FormatException('Símbolo não aceito: "$ch".');
    }
  }
  return out;
}

class _Parser {
  _Parser(this.t);
  final List<_Tok> t;
  int p = 0;

  _Tok? get cur => p < t.length ? t[p] : null;
  bool isOp(String o) => cur != null && cur!.kind == 'o' && cur!.text == o;

  MathFn parse() {
    if (t.isEmpty) throw const FormatException('Digite uma função.');
    final f = expr();
    if (cur != null) throw FormatException('Sobrou "${cur!.text}" na expressão.');
    return f;
  }

  MathFn expr() {
    var l = term();
    while (isOp('+') || isOp('-')) {
      final plus = cur!.text == '+';
      p++;
      final a = l, b = term();
      l = plus ? (x) => a(x) + b(x) : (x) => a(x) - b(x);
    }
    return l;
  }

  bool get startsFactor {
    final c = cur;
    if (c == null) return false;
    return c.kind == 'n' || c.kind == 'i' || (c.kind == 'o' && c.text == '(');
  }

  MathFn term() {
    var l = unary();
    while (true) {
      if (isOp('*') || isOp('/')) {
        final mul = cur!.text == '*';
        p++;
        final a = l, b = unary();
        l = mul ? (x) => a(x) * b(x) : (x) => a(x) / b(x);
      } else if (startsFactor) {
        final a = l, b = unary(); // multiplicação implícita: 2x, 3(x+1), x sin(x)
        l = (x) => a(x) * b(x);
      } else {
        return l;
      }
    }
  }

  MathFn unary() {
    if (isOp('-')) {
      p++;
      final a = unary();
      return (x) => -a(x);
    }
    if (isOp('+')) {
      p++;
      return unary();
    }
    return power();
  }

  MathFn power() {
    final base = atom();
    if (isOp('^')) {
      p++;
      final e = unary(); // associa à direita e aceita 2^-x
      return (x) => math.pow(base(x), e(x)).toDouble();
    }
    return base;
  }

  MathFn atom() {
    final c = cur;
    if (c == null) throw const FormatException('A expressão terminou antes da hora.');
    if (c.kind == 'n') {
      p++;
      final v = c.num;
      return (_) => v;
    }
    if (c.kind == 'i') {
      p++;
      if (c.text == 'x') return (x) => x;
      final k = _consts[c.text];
      if (k != null) return (_) => k;
      final fn = _funcs[c.text]!;
      // sin(x) ou sin x
      final MathFn arg = isOp('(') ? atom() : power();
      return (x) => fn(arg(x));
    }
    if (c.text == '(') {
      p++;
      final e = expr();
      if (!isOp(')')) throw const FormatException('Falta fechar um parêntese.');
      p++;
      return e;
    }
    throw FormatException('Não esperava "${c.text}" aqui.');
  }
}

/// Lê uma função de x, como `x^2 - 3x + 2`, `sin(x)/x` ou `y = 2^x`.
/// Aceita multiplicação implícita (2x), potências (^, ², ³), pi, e e funções
/// como sin, cos, tan, sqrt, abs, ln, log, exp. Lança [FormatException].
MathFn parseFunction(String input) {
  var s = input.toLowerCase().trim();
  s = s.replaceFirst(RegExp(r'^\s*(y|f\(x\))\s*='), '');
  s = s
      .replaceAll('²', '^2')
      .replaceAll('³', '^3')
      .replaceAll('−', '-')
      .replaceAll('×', '*')
      .replaceAll('·', '*')
      .replaceAll('÷', '/')
      .replaceAll('√', 'sqrt')
      .replaceAll('π', 'pi')
      .replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}');
  return _Parser(_tokenize(s)).parse();
}
