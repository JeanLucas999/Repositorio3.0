import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

import 'models.dart';
import 'page_image.dart';

/// Lado maior (px) de cada página renderizada: equilíbrio entre nitidez e
/// tamanho do arquivo do caderno.
const int kPdfRenderSide = 1800;

/// Retângulo (coordenadas da página) onde um PDF de [w]x[h] cabe inteiro,
/// centralizado e sem distorcer.
ui.Rect fitPdfRect(double w, double h, ui.Size page) {
  if (w <= 0 || h <= 0) return ui.Offset.zero & page;
  final k = math.min(page.width / w, page.height / h);
  final fw = w * k, fh = h * k;
  return ui.Rect.fromLTWH((page.width - fw) / 2, (page.height - fh) / 2, fw, fh);
}

/// Formato do caderno para o PDF: horizontal se a primeira página for mais larga.
NotebookFormat formatForPdf(double w, double h) =>
    w > h ? NotebookFormat.landscape : NotebookFormat.portrait;

/// Importa um PDF como caderno: cada página vira o fundo fixo de uma página.
/// [onProgress] recebe (feitas, total). Retorna null se o PDF não abrir.
Future<Notebook?> importPdf(
  Uint8List bytes, {
  required String id,
  required String name,
  void Function(int done, int total)? onProgress,
}) async {
  PdfDocument? doc;
  try {
    doc = await PdfDocument.openData(bytes);
    if (doc.pages.isEmpty) return null;
    final first = doc.pages.first;
    final fmt = formatForPdf(first.width, first.height);
    final nb = Notebook(id: id, name: name, pages: [], format: fmt);
    final ps = nb.pageSize;
    final total = doc.pages.length;
    for (var i = 0; i < total; i++) {
      final pg = doc.pages[i];
      final rect = fitPdfRect(pg.width, pg.height, ps);
      final k = kPdfRenderSide / math.max(rect.width, rect.height);
      final pw = math.max(1, (rect.width * k).round());
      final ph = math.max(1, (rect.height * k).round());
      final raster = await pg.render(fullWidth: pw.toDouble(), fullHeight: ph.toDouble());
      if (raster == null) {
        nb.pages.add(NotePage());
        continue;
      }
      try {
        final img = await raster.createImage();
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        nb.pages.add(NotePage(
          pdfBg: data == null
              ? null
              : PageImage(
                  id: 'pdf-$i',
                  bytes: data.buffer.asUint8List(),
                  rect: rect,
                  front: false,
                ),
        ));
      } finally {
        raster.dispose();
      }
      onProgress?.call(i + 1, total);
    }
    return nb;
  } catch (_) {
    return null;
  } finally {
    await doc?.dispose();
  }
}
