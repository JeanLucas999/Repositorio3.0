import 'dart:ui' show Rect, Size, Offset;

import 'models.dart';

/// Um trecho marcado com marca-texto, para revisar.
class ReviewClip {
  ReviewClip(this.pageIndex, this.rect, this.color);
  final int pageIndex;
  final Rect rect; // em coordenadas da página, já com margem
  final int color; // cor do marca-texto (ARGB)
}

/// Agrupa os marca-textos de uma página em trechos: traços que se tocam (ou
/// ficam bem próximos) viram um recorte só. Ordem: de cima para baixo.
List<Rect> highlightRegions(NotePage page, {double gap = 14}) {
  final boxes = <Rect>[];
  for (final s in page.strokes) {
    if (!s.highlighter || s.points.isEmpty) continue;
    final b = s.bounds.inflate(s.width / 2);
    if (b.width * b.height < 16) continue; // pontinho solto
    boxes.add(b);
  }
  // une por proximidade até não sobrar nada se tocando
  var merged = true;
  while (merged) {
    merged = false;
    for (var i = 0; i < boxes.length && !merged; i++) {
      for (var j = i + 1; j < boxes.length; j++) {
        if (boxes[i].inflate(gap).overlaps(boxes[j].inflate(gap))) {
          boxes[i] = boxes[i].expandToInclude(boxes[j]);
          boxes.removeAt(j);
          merged = true;
          break;
        }
      }
    }
  }
  boxes.sort((a, b) {
    final c = a.top.compareTo(b.top);
    return c != 0 ? c : a.left.compareTo(b.left);
  });
  return boxes;
}

/// Cor mais usada entre os marca-textos dentro de [r] (ignora o alfa).
int _dominantColor(NotePage page, Rect r) {
  final count = <int, int>{};
  for (final s in page.strokes) {
    if (s.highlighter && s.bounds.overlaps(r)) {
      final c = s.color | 0xFF000000;
      count[c] = (count[c] ?? 0) + 1;
    }
  }
  if (count.isEmpty) return 0xFFFFEB3B;
  return count.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// Todos os trechos marcados do caderno, página por página.
List<ReviewClip> reviewClips(Notebook nb, {double marginX = 28, double marginY = 18}) {
  final out = <ReviewClip>[];
  final bounds = Offset.zero & nb.pageSize;
  for (var i = 0; i < nb.pages.length; i++) {
    final page = nb.pages[i];
    for (final r in highlightRegions(page)) {
      var box = r.inflate(0).deflate(0);
      box = Rect.fromLTRB(box.left - marginX, box.top - marginY, box.right + marginX, box.bottom + marginY);
      if (!nb.infinite) box = box.intersect(bounds);
      if (box.width <= 0 || box.height <= 0) continue;
      out.add(ReviewClip(i, box, _dominantColor(page, r)));
    }
  }
  return out;
}

/// Tamanho exibido de um recorte de largura [rect] para caber em [width].
Size clipDisplaySize(Rect rect, double width) =>
    Size(width, rect.height * (width / rect.width));
