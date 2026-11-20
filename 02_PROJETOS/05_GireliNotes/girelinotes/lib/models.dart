import 'dart:math' as math;
import 'dart:ui';

enum PageBackground { blank, ruled, grid }

/// Um traço é sempre vetorial: lista de pontos + estilo.
/// Formas reconhecidas (linha, círculo, retângulo...) também viram traços,
/// só que com [smooth] = false (cantos vivos).
///
/// A caneta tinteiro ([fountain]) guarda também a largura em cada ponto
/// ([widths]), calculada na hora de escrever (pressão e velocidade).
class Stroke {
  Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.width,
    this.highlighter = false,
    this.smooth = true,
    this.pressure = 0.5,
    this.fountain = false,
    this.widths,
    this.fill,
  });

  final String id;
  List<Offset> points;
  final int color; // ARGB
  final double width;
  final bool highlighter;
  final bool fountain;
  bool smooth;

  /// Preenchimento claro e translúcido (ARGB com alpha) de formas fechadas, ou null.
  int? fill;

  /// Pressão média normalizada (0..1). 0.5 = largura nominal.
  double pressure;

  /// Largura em cada ponto (só caneta tinteiro). Vira null quando o traço é
  /// encaixado numa forma; aí ele é desenhado com largura uniforme.
  List<double>? widths;

  Path? _path;
  int _pathLen = -1;
  Path? _ribbon;
  Path? _caps;
  int _ribbonLen = -1;
  Rect? _bounds;
  int _boundsLen = -1;

  /// Chame depois de trocar [points] ou [widths] (ex.: encaixar forma, afinar a ponta).
  void invalidate() {
    _path = null;
    _ribbon = null;
    _caps = null;
    _bounds = null;
    _pathLen = -1;
    _ribbonLen = -1;
    _boundsLen = -1;
  }

  /// Tem largura variável para desenhar?
  bool get variable =>
      fountain &&
      widths != null &&
      widths!.length == points.length &&
      points.length >= 2;

  double get effectiveWidth {
    if (highlighter) return width * 4;
    if (fountain) return width * 2.3; // maior largura possível
    return width * (0.6 + pressure * 0.8);
  }

  /// Largura usada quando o traço é desenhado com linha de espessura única.
  double get paintWidth => fountain ? width * 1.1 : effectiveWidth;

  Path get path {
    if (_path == null || _pathLen != points.length) {
      _path = _buildPath(points, smooth);
      _pathLen = points.length;
    }
    return _path!;
  }

  /// Contorno preenchido do traço de largura variável.
  Path get ribbonPath {
    _ensureRibbon();
    return _ribbon!;
  }

  /// Pontas redondas e "juntas" nas curvas fechadas do traço variável.
  Path get capsPath {
    _ensureRibbon();
    return _caps!;
  }

  void _ensureRibbon() {
    if (_ribbon != null && _caps != null && _ribbonLen == points.length) return;
    final r = _buildRibbon(points, widths!);
    _ribbon = r.$1;
    _caps = r.$2;
    _ribbonLen = points.length;
  }

  Rect get bounds {
    if (_bounds == null || _boundsLen != points.length) {
      _bounds = _computeBounds();
      _boundsLen = points.length;
    }
    return _bounds!;
  }

  Rect _computeBounds() {
    if (points.isEmpty) return Rect.zero;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(effectiveWidth / 2 + 1);
  }

  static Path _buildPath(List<Offset> pts, bool smooth) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) {
      // ponto isolado: segmento mínimo com ponta redonda vira uma bolinha
      path.lineTo(pts.first.dx + 0.01, pts.first.dy);
      return path;
    }
    if (!smooth || pts.length == 2) {
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      return path;
    }
    // Suavização: curvas quadráticas passando pelos pontos médios.
    for (var i = 1; i < pts.length - 1; i++) {
      final mx = (pts[i].dx + pts[i + 1].dx) / 2;
      final my = (pts[i].dy + pts[i + 1].dy) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mx, my);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  /// Monta o contorno de um traço com largura variável: um lado indo, o outro
  /// voltando (fita), mais círculos nas pontas e nas curvas fechadas.
  /// Os círculos ficam num caminho separado para não "anular" a fita por
  /// causa do sentido de rotação.
  static (Path, Path) _buildRibbon(List<Offset> pts, List<double> ws) {
    final n = pts.length;
    final ribbon = Path();
    final caps = Path();
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < n; i++) {
      // tangente numa janela de ±2 pontos: borda mais lisa que a de vizinhos colados
      final a = pts[math.max(0, i - 2)];
      final b = pts[math.min(n - 1, i + 2)];
      var t = b - a;
      final len = t.distance;
      t = len < 1e-6 ? const Offset(1, 0) : t / len;
      final nrm = Offset(-t.dy, t.dx);
      final h = math.max(ws[i], 0.2) / 2;
      left.add(pts[i] + nrm * h);
      right.add(pts[i] - nrm * h);
    }

    ribbon.moveTo(right[0].dx, right[0].dy);
    for (var i = 1; i < n - 1; i++) {
      final m = Offset.lerp(right[i], right[i + 1], 0.5)!;
      ribbon.quadraticBezierTo(right[i].dx, right[i].dy, m.dx, m.dy);
    }
    ribbon.lineTo(right[n - 1].dx, right[n - 1].dy);
    ribbon.lineTo(left[n - 1].dx, left[n - 1].dy);
    for (var i = n - 2; i >= 1; i--) {
      final m = Offset.lerp(left[i], left[i - 1], 0.5)!;
      ribbon.quadraticBezierTo(left[i].dx, left[i].dy, m.dx, m.dy);
    }
    ribbon.lineTo(left[0].dx, left[0].dy);
    ribbon.close();

    caps.addOval(Rect.fromCircle(center: pts.first, radius: math.max(ws.first, 0.2) / 2));
    caps.addOval(Rect.fromCircle(center: pts.last, radius: math.max(ws.last, 0.2) / 2));
    for (var i = 1; i < n - 1; i++) {
      final v1 = pts[i] - pts[i - 1];
      final v2 = pts[i + 1] - pts[i];
      final l = v1.distance * v2.distance;
      if (l < 1e-9) continue;
      final cos = (v1.dx * v2.dx + v1.dy * v2.dy) / l;
      if (cos < 0.866) {
        // virada de mais de ~30°
        caps.addOval(Rect.fromCircle(center: pts[i], radius: math.max(ws[i], 0.2) / 2));
      }
    }
    return (ribbon, caps);
  }

  static double _r(double v) => (v * 100).roundToDouble() / 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'c': color,
        'w': width,
        'h': highlighter,
        's': smooth,
        'p': _r(pressure),
        if (fountain) 'f': true,
        if (fill != null) 'fl': fill,
        if (fountain && widths != null) 'ws': [for (final w in widths!) _r(w)],
        'pts': [
          for (final p in points) ...[_r(p.dx), _r(p.dy)],
        ],
      };

  factory Stroke.fromJson(Map<String, dynamic> j) {
    final raw = (j['pts'] as List).cast<num>();
    final pts = [
      for (var i = 0; i + 1 < raw.length; i += 2)
        Offset(raw[i].toDouble(), raw[i + 1].toDouble()),
    ];
    final fountain = j['f'] as bool? ?? false;
    List<double>? ws;
    final rawWs = j['ws'];
    if (fountain && rawWs is List) {
      ws = [for (final w in rawWs) (w as num).toDouble()];
      if (ws.length != pts.length) ws = null; // arquivo inconsistente: largura uniforme
    }
    return Stroke(
      id: j['id'] as String,
      color: j['c'] as int,
      width: (j['w'] as num).toDouble(),
      highlighter: j['h'] as bool? ?? false,
      smooth: j['s'] as bool? ?? true,
      pressure: (j['p'] as num?)?.toDouble() ?? 0.5,
      fountain: fountain,
      widths: ws,
      points: pts,
      fill: j['fl'] is int ? j['fl'] as int : null,
    );
  }
}

class NotePage {
  NotePage({List<Stroke>? strokes, this.background = PageBackground.blank})
      : strokes = strokes ?? [];

  final List<Stroke> strokes;
  PageBackground background;

  Map<String, dynamic> toJson() => {
        'bg': background.index,
        'strokes': [for (final s in strokes) s.toJson()],
      };

  factory NotePage.fromJson(Map<String, dynamic> j) {
    final bg = (j['bg'] as int?) ?? 0;
    return NotePage(
      background:
          PageBackground.values[bg.clamp(0, PageBackground.values.length - 1).toInt()],
      strokes: [
        for (final s in (j['strokes'] as List? ?? const []))
          Stroke.fromJson(s as Map<String, dynamic>),
      ],
    );
  }
}

/// Formato do caderno: página vertical, horizontal ou quadro infinito (sem páginas).
enum NotebookFormat { portrait, landscape, board }

class Notebook {
  Notebook({
    required this.id,
    required this.name,
    required this.pages,
    DateTime? modified,
    this.format = NotebookFormat.portrait,
  }) : modified = modified ?? DateTime.now();

  final String id;
  String name;
  final List<NotePage> pages;
  DateTime modified;
  final NotebookFormat format;

  bool get infinite => format == NotebookFormat.board;

  /// Tamanho de cada página (no quadro infinito é só a referência da miniatura).
  Size get pageSize => format == NotebookFormat.landscape
      ? const Size(1414, 1000)
      : const Size(1000, 1414);

  /// Fundo das próximas páginas deste caderno (null: copia a página atual).
  PageBackground? nextBackground;

  factory Notebook.empty(String id, String name,
          [NotebookFormat format = NotebookFormat.portrait]) =>
      Notebook(id: id, name: name, pages: [NotePage()], format: format);

  Map<String, dynamic> toJson() => {
        'v': 1,
        'id': id,
        'name': name,
        'modified': modified.toIso8601String(),
        'fmt': format.index,
        'pages': [for (final p in pages) p.toJson()],
        if (nextBackground != null) 'nbg': nextBackground!.index,
      };

  factory Notebook.fromJson(Map<String, dynamic> j) {
    final pages = [
      for (final p in (j['pages'] as List? ?? const []))
        NotePage.fromJson(p as Map<String, dynamic>),
    ];
    final f = j['fmt'];
    final fmt = (f is int && f >= 0 && f < NotebookFormat.values.length)
        ? NotebookFormat.values[f]
        : NotebookFormat.portrait;
    final nb = Notebook(
      format: fmt,
      id: j['id'] as String,
      name: j['name'] as String? ?? 'Caderno',
      pages: pages.isEmpty ? [NotePage()] : (fmt == NotebookFormat.board ? [pages.first] : pages),
      modified: DateTime.tryParse(j['modified'] as String? ?? ''),
    );
    final nbg = j['nbg'];
    if (nbg is int && nbg >= 0 && nbg < PageBackground.values.length) {
      nb.nextBackground = PageBackground.values[nbg];
    }
    return nb;
  }
}
