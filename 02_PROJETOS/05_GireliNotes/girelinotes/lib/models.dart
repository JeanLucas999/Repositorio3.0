import 'dart:ui';

enum PageBackground { blank, ruled, grid }

/// Um traço é sempre vetorial: lista de pontos + estilo.
/// Formas reconhecidas (linha, círculo, retângulo...) também viram traços,
/// só que com [smooth] = false (cantos vivos).
class Stroke {
  Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.width,
    this.highlighter = false,
    this.smooth = true,
    this.pressure = 0.5,
  });

  final String id;
  List<Offset> points;
  final int color; // ARGB
  final double width;
  final bool highlighter;
  bool smooth;

  /// Pressão média normalizada (0..1). 0.5 = largura nominal.
  double pressure;

  Path? _path;
  int _pathLen = -1;
  Rect? _bounds;
  int _boundsLen = -1;

  /// Chame depois de trocar [points] por outra lista (ex.: ao encaixar forma).
  void invalidate() {
    _path = null;
    _bounds = null;
    _pathLen = -1;
    _boundsLen = -1;
  }

  double get effectiveWidth =>
      highlighter ? width * 4 : width * (0.6 + pressure * 0.8);

  Path get path {
    if (_path == null || _pathLen != points.length) {
      _path = _buildPath(points, smooth);
      _pathLen = points.length;
    }
    return _path!;
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

  static double _r(double v) => (v * 100).roundToDouble() / 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'c': color,
        'w': width,
        'h': highlighter,
        's': smooth,
        'p': _r(pressure),
        'pts': [
          for (final p in points) ...[_r(p.dx), _r(p.dy)],
        ],
      };

  factory Stroke.fromJson(Map<String, dynamic> j) {
    final raw = (j['pts'] as List).cast<num>();
    return Stroke(
      id: j['id'] as String,
      color: j['c'] as int,
      width: (j['w'] as num).toDouble(),
      highlighter: j['h'] as bool? ?? false,
      smooth: j['s'] as bool? ?? true,
      pressure: (j['p'] as num?)?.toDouble() ?? 0.5,
      points: [
        for (var i = 0; i + 1 < raw.length; i += 2)
          Offset(raw[i].toDouble(), raw[i + 1].toDouble()),
      ],
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
      background: PageBackground.values[bg.clamp(0, PageBackground.values.length - 1)],
      strokes: [
        for (final s in (j['strokes'] as List? ?? const []))
          Stroke.fromJson(s as Map<String, dynamic>),
      ],
    );
  }
}

class Notebook {
  Notebook({
    required this.id,
    required this.name,
    required this.pages,
    DateTime? modified,
  }) : modified = modified ?? DateTime.now();

  final String id;
  String name;
  final List<NotePage> pages;
  DateTime modified;

  factory Notebook.empty(String id, String name) =>
      Notebook(id: id, name: name, pages: [NotePage()]);

  Map<String, dynamic> toJson() => {
        'v': 1,
        'id': id,
        'name': name,
        'modified': modified.toIso8601String(),
        'pages': [for (final p in pages) p.toJson()],
      };

  factory Notebook.fromJson(Map<String, dynamic> j) {
    final pages = [
      for (final p in (j['pages'] as List? ?? const []))
        NotePage.fromJson(p as Map<String, dynamic>),
    ];
    return Notebook(
      id: j['id'] as String,
      name: j['name'] as String? ?? 'Caderno',
      pages: pages.isEmpty ? [NotePage()] : pages,
      modified: DateTime.tryParse(j['modified'] as String? ?? ''),
    );
  }
}
