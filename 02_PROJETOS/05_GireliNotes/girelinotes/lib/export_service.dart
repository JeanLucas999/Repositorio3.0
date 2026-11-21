import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Path, PathMetric, Rect;

import 'package:pdf/pdf.dart';

import 'models.dart';

/// Formato próprio (.notas): JSON do caderno comprimido com gzip. Guarda cada
/// traço, forma, preenchimento e fundo como objeto separado; reabre editável.
const String kNotasExtension = 'notas';
const int kNotasVersion = 1;

Uint8List encodeNotas(Notebook nb) {
  final json = jsonEncode({
    'format': 'notas',
    'version': kNotasVersion,
    'notebook': nb.toJson(),
  });
  return Uint8List.fromList(gzip.encode(utf8.encode(json)));
}

/// Lê um arquivo .notas (ou o JSON puro). Dá ao caderno o [newId] para não
/// sobrescrever um caderno existente. Lança [FormatException] se não for válido.
Notebook decodeNotas(Uint8List bytes, String newId) {
  final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
  final text = utf8.decode(isGzip ? gzip.decode(bytes) : bytes);
  final map = jsonDecode(text);
  if (map is! Map<String, dynamic> || map['format'] != 'notas') {
    throw const FormatException('Arquivo não é um caderno do Notas.');
  }
  final v = map['version'];
  if (v is! int || v > kNotasVersion) {
    throw const FormatException('Versão do arquivo mais nova que este app.');
  }
  final nbJson = Map<String, dynamic>.from(map['notebook'] as Map);
  nbJson['id'] = newId;
  return Notebook.fromJson(nbJson);
}

// ------------------------------------------------------------------ PDF

const double _kA4Scale = 595.28 / 1000; // pontos do PDF por unidade da página

/// Exporta o caderno em PDF vetorial. Cadernos com páginas viram uma página de
/// PDF por página; o quadro infinito vira uma única página do tamanho do conteúdo.
Future<Uint8List> buildPdf(Notebook nb, {double lineSpacing = 40}) async {
  final doc = PdfDocument(compress: true);
  if (nb.infinite) {
    final page = nb.pages.first;
    var b = Rect.zero;
    var any = false;
    for (final s in page.strokes) {
      b = any ? b.expandToInclude(s.bounds) : s.bounds;
      any = true;
    }
    for (final im in page.images) {
      b = any ? b.expandToInclude(im.rect) : im.rect;
      any = true;
    }
    final area = any ? b.inflate(40) : const Rect.fromLTWH(0, 0, 1000, 1414);
    var k = _kA4Scale;
    final maxDim = math.max(area.width, area.height);
    if (maxDim * k > 14000) k = 14000 / maxDim; // limite do formato PDF
    _drawPage(doc, page, area, k, lineSpacing);
  } else {
    final ps = nb.pageSize;
    for (final page in nb.pages) {
      _drawPage(doc, page, Rect.fromLTWH(0, 0, ps.width, ps.height), _kA4Scale, lineSpacing);
    }
  }
  return doc.save();
}

void _drawPage(PdfDocument doc, NotePage page, Rect area, double k, double spacing) {
  final w = area.width * k, h = area.height * k;
  final pdfPage = PdfPage(doc, pageFormat: PdfPageFormat(w, h));
  final g = pdfPage.getGraphics();

  Offset map(Offset p) => Offset((p.dx - area.left) * k, h - (p.dy - area.top) * k);

  // fundo (linhas do pautado/quadriculado)
  if (page.background != PageBackground.blank) {
    g
      ..setStrokeColor(const PdfColor.fromInt(0xFFD5DCE8))
      ..setLineWidth(math.max(0.3, 1 * k));
    final first = (area.top / spacing).floor() * spacing;
    final startY = page.background == PageBackground.ruled
        ? math.max(first, spacing * 2.5)
        : math.max(first, spacing);
    for (var y = startY; y < area.bottom; y += spacing) {
      final a = map(Offset(area.left, y)), b = map(Offset(area.right, y));
      g
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..strokePath();
    }
    if (page.background == PageBackground.grid) {
      for (var x = math.max((area.left / spacing).floor() * spacing, spacing);
          x < area.right;
          x += spacing) {
        final a = map(Offset(x, area.top)), b = map(Offset(x, area.bottom));
        g
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..strokePath();
      }
    }
  }

  // imagens ficam atrás de tudo (menos do papel)
  for (final im in page.images) {
    try {
      final img = PdfImage.file(doc, bytes: im.bytes);
      final tl = map(im.rect.bottomLeft);
      g.drawImage(img, tl.dx, tl.dy, im.rect.width * k, im.rect.height * k);
    } catch (_) {
      // imagem que o PDF não consegue ler: segue sem ela
    }
  }

  // mesma ordem da tela: fundos de forma, marca-texto, tinta
  for (final s in page.strokes) {
    if (s.fill != null && s.points.length >= 3) _fillPolygon(g, s, map, k);
  }
  for (final s in page.strokes) {
    if (s.highlighter) _drawStroke(g, s, map, k);
  }
  for (final s in page.strokes) {
    if (!s.highlighter) _drawStroke(g, s, map, k);
  }
}

void _fillPolygon(PdfGraphics g, Stroke s, Offset Function(Offset) map, double k) {
  final f = s.fill!;
  g
    ..saveContext()
    ..setGraphicState(PdfGraphicState(opacity: ((f >> 24) & 0xFF) / 255))
    ..setFillColor(PdfColor.fromInt(0xFF000000 | (f & 0x00FFFFFF)));
  final first = map(s.points.first);
  g.moveTo(first.dx, first.dy);
  for (final p in s.points.skip(1)) {
    final q = map(p);
    g.lineTo(q.dx, q.dy);
  }
  g
    ..closePath()
    ..fillPath()
    ..restoreContext();
}

void _drawStroke(PdfGraphics g, Stroke s, Offset Function(Offset) map, double k) {
  if (s.points.isEmpty) return;
  final color = PdfColor.fromInt(0xFF000000 | (s.color & 0x00FFFFFF));
  g.saveContext();
  if (s.highlighter) {
    g.setGraphicState(PdfGraphicState(opacity: 120 / 255));
  }
  if (s.variable) {
    // tinteiro: contorno preenchido (corpo e pontas)
    g.setFillColor(color);
    _tracePath(g, s.ribbonPath, map, closeAll: true);
    g.fillPath();
    _tracePath(g, s.capsPath, map, closeAll: true);
    g.fillPath();
  } else {
    final width = s.paintWidth * k;
    final src = s.style == StrokeStyle.solid ? s.path : s.dashedPath;
    g
      ..setStrokeColor(color)
      ..setFillColor(color)
      ..setLineWidth(width)
      ..setLineCap(PdfLineCap.round)
      ..setLineJoin(PdfLineJoin.round);
    for (final m in src.computeMetrics()) {
      final pts = _sample(m);
      if (pts.isEmpty) continue;
      if (m.length < 0.05 || pts.length == 1) {
        // ponto isolado / bolinha do pontilhado
        final c = map(pts.first);
        g
          ..drawEllipse(c.dx, c.dy, width / 2, width / 2)
          ..fillPath();
        continue;
      }
      final a = map(pts.first);
      g.moveTo(a.dx, a.dy);
      for (final p in pts.skip(1)) {
        final q = map(p);
        g.lineTo(q.dx, q.dy);
      }
      g.strokePath(close: m.isClosed);
    }
  }
  g.restoreContext();
}

/// Contornos do [path] como polígonos finos (≈1 unidade de página por segmento).
void _tracePath(PdfGraphics g, Path path, Offset Function(Offset) map,
    {bool closeAll = false}) {
  for (final m in path.computeMetrics()) {
    final pts = _sample(m);
    if (pts.length < 2) continue;
    final a = map(pts.first);
    g.moveTo(a.dx, a.dy);
    for (final p in pts.skip(1)) {
      final q = map(p);
      g.lineTo(q.dx, q.dy);
    }
    if (closeAll || m.isClosed) g.closePath();
  }
}

List<Offset> _sample(PathMetric metric) {
  final len = metric.length;
  final n = math.max(1, (len / 1.2).ceil());
  final pts = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final t = metric.getTangentForOffset(math.min(len, i * len / n));
    if (t != null) pts.add(t.position);
  }
  return pts;
}
