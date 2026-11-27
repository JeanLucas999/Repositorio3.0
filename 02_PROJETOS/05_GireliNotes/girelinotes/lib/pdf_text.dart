import 'dart:ui' show Rect;

import 'models.dart';

/// Uma palavra do texto de uma página de PDF importado, com a posição
/// normalizada (0..1, origem no canto superior esquerdo da página do PDF).
class PdfWord {
  const PdfWord(this.text, this.box);
  final String text;
  final Rect box;

  static double _r(double v) => (v * 10000).roundToDouble() / 10000;

  List<Object> toJson() => [text, _r(box.left), _r(box.top), _r(box.right), _r(box.bottom)];

  static PdfWord? fromJson(Object? j) {
    if (j is! List || j.length != 5 || j[0] is! String) return null;
    final n = [for (final v in j.skip(1)) if (v is num) v.toDouble()];
    if (n.length != 4) return null;
    return PdfWord(j[0] as String, Rect.fromLTRB(n[0], n[1], n[2], n[3]));
  }
}

/// Junta os caracteres de [fullText] em palavras (separadas por espaço/quebra
/// de linha). [charRects] traz a caixa de cada caractere, na mesma ordem.
List<PdfWord> wordsFromChars(String fullText, List<Rect> charRects) {
  final out = <PdfWord>[];
  final n = fullText.length < charRects.length ? fullText.length : charRects.length;
  var start = -1;
  Rect? box;
  void flush(int end) {
    if (start >= 0 && box != null) {
      out.add(PdfWord(fullText.substring(start, end), box!));
    }
    start = -1;
    box = null;
  }

  for (var i = 0; i < n; i++) {
    final ch = fullText[i];
    if (ch.trim().isEmpty) {
      flush(i);
      continue;
    }
    final r = charRects[i];
    if (r.isEmpty && r.width == 0 && r.height == 0) continue;
    if (start < 0) start = i;
    box = box == null ? r : box!.expandToInclude(r);
  }
  flush(n);
  return out;
}

const _from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _to = 'aaaaaeeeeiiiiooooouuuucn';

/// Minúsculas, sem acentos e sem pontuação: para comparar buscas.
String normalizeForSearch(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = _from.indexOf(ch);
    b.write(i >= 0 ? _to[i] : ch);
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
}

/// Um resultado da busca: a página, onde marcar e um trecho para mostrar.
class SearchHit {
  SearchHit(this.pageIndex, this.rects, this.before, this.match, this.after);
  final int pageIndex;
  final List<Rect> rects; // em coordenadas da página do caderno
  final String before, match, after;
}

/// Procura [query] no texto dos PDFs importados. Várias palavras: têm de
/// aparecer em sequência. Não diferencia maiúsculas nem acentos.
List<SearchHit> searchNotebook(Notebook nb, String query, {int limit = 300}) {
  final tokens = normalizeForSearch(query).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return const [];
  final out = <SearchHit>[];
  for (var pi = 0; pi < nb.pages.length; pi++) {
    final page = nb.pages[pi];
    final words = page.words;
    final area = page.pdfBg?.rect;
    if (words == null || area == null) continue;
    final norm = [
      for (final w in words) normalizeForSearch(w.text).replaceAll(RegExp(r'\s'), ''),
    ];
    for (var i = 0; i + tokens.length <= words.length; i++) {
      var ok = true;
      for (var k = 0; k < tokens.length && ok; k++) {
        ok = norm[i + k].contains(tokens[k]);
      }
      if (!ok) continue;
      final last = i + tokens.length;
      out.add(SearchHit(
        pi,
        [
          for (var k = i; k < last; k++)
            Rect.fromLTRB(
              area.left + words[k].box.left * area.width,
              area.top + words[k].box.top * area.height,
              area.left + words[k].box.right * area.width,
              area.top + words[k].box.bottom * area.height,
            ),
        ],
        words.sublist(i < 4 ? 0 : i - 4, i).map((w) => w.text).join(' '),
        words.sublist(i, last).map((w) => w.text).join(' '),
        words.sublist(last, last + 7 > words.length ? words.length : last + 7).map((w) => w.text).join(' '),
      ));
      if (out.length >= limit) return out;
    }
  }
  return out;
}

/// O caderno tem algum texto pesquisável?
bool hasSearchableText(Notebook nb) => nb.pages.any((p) => p.words != null && p.words!.isNotEmpty);

/// O caderno veio de um PDF importado?
bool isPdfNotebook(Notebook nb) => nb.pages.any((p) => p.pdfBg != null);
