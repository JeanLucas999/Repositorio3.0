import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Um resultado de busca de imagem.
class ImageHit {
  ImageHit({
    required this.title,
    required this.thumbUrl,
    required this.fullUrl,
    required this.source,
    this.license,
    this.author,
    this.pageUrl,
  });

  final String title;
  final String thumbUrl;
  final String fullUrl;
  final String source; // Openverse, Wikimedia...
  final String? license;
  final String? author;
  final String? pageUrl;

  /// "Autor · licença · fonte", para mostrar de onde veio.
  String get credit => [
        if (author != null && author!.isNotEmpty) author!,
        if (license != null && license!.isNotEmpty) license!,
        source,
      ].join(' · ');
}

const Map<String, String> kSearchHeaders = {
  'User-Agent': 'NotasApp/1.0 (personal notes app)', // só ASCII: o HTTP recusa acentos
  'Accept': 'application/json, image/*',
};

String _stripHtml(String s) =>
    s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&amp;', '&').trim();

/// Openverse: imagens livres, sem chave (uso leve).
Future<List<ImageHit>> searchOpenverse(String q, int page) async {
  final r = await http
      .get(
        Uri.https('api.openverse.org', '/v1/images/', {
          'q': q,
          'page': '${page + 1}',
          'page_size': '20',
        }),
        headers: kSearchHeaders,
      )
      .timeout(const Duration(seconds: 15));
  if (r.statusCode != 200) throw Exception('Openverse ${r.statusCode}');
  final list = (jsonDecode(utf8.decode(r.bodyBytes))['results'] as List?) ?? const [];
  return [
    for (final j in list)
      if (j is Map && j['url'] is String && (j['thumbnail'] ?? j['url']) is String)
        ImageHit(
          title: (j['title'] as String?) ?? '',
          thumbUrl: (j['thumbnail'] ?? j['url']) as String,
          fullUrl: j['url'] as String,
          source: 'Openverse',
          license: j['license'] == null
              ? null
              : 'CC ${'${j['license']}'.toUpperCase()} ${j['license_version'] ?? ''}'.trim(),
          author: j['creator'] as String?,
          pageUrl: j['foreign_landing_url'] as String?,
        ),
  ];
}

/// Wikimedia Commons: muitos PNGs e ícones, sem chave.
Future<List<ImageHit>> searchCommons(String q, int page) async {
  final r = await http
      .get(
        Uri.https('commons.wikimedia.org', '/w/api.php', {
          'action': 'query',
          'format': 'json',
          'generator': 'search',
          'gsrsearch': '$q filetype:bitmap',
          'gsrnamespace': '6',
          'gsrlimit': '20',
          'gsroffset': '${page * 20}',
          'prop': 'imageinfo',
          'iiprop': 'url|mime|extmetadata',
          'iiurlwidth': '320',
        }),
        headers: kSearchHeaders,
      )
      .timeout(const Duration(seconds: 15));
  if (r.statusCode != 200) throw Exception('Commons ${r.statusCode}');
  final pages = (jsonDecode(utf8.decode(r.bodyBytes))['query']?['pages'] as Map?)?.values.toList() ??
      const [];
  pages.sort((a, b) => ((a['index'] ?? 0) as num).compareTo((b['index'] ?? 0) as num));
  final out = <ImageHit>[];
  for (final p in pages) {
    final infoList = p['imageinfo'];
    if (infoList is! List || infoList.isEmpty) continue;
    final info = infoList.first as Map;
    final mime = info['mime'] as String? ?? '';
    if (!mime.startsWith('image/') || mime.contains('svg')) continue;
    final meta = (info['extmetadata'] as Map?) ?? const {};
    String? m(String k) => (meta[k] is Map ? meta[k]['value'] : null)?.toString();
    final full = info['url'] as String?;
    if (full == null) continue;
    out.add(ImageHit(
      title: ('${p['title'] ?? ''}').replaceFirst(RegExp(r'^File:'), ''),
      thumbUrl: (info['thumburl'] as String?) ?? full,
      fullUrl: full,
      source: 'Wikimedia Commons',
      license: m('LicenseShortName'),
      author: m('Artist') == null ? null : _stripHtml(m('Artist')!),
      pageUrl: info['descriptionurl'] as String?,
    ));
  }
  return out;
}

/// Busca nas duas fontes e intercala os resultados. Só falha se as duas falharem.
Future<List<ImageHit>> searchImages(String q, int page) async {
  final errors = <String>[];
  Future<List<ImageHit>> safe(String name, Future<List<ImageHit>> f) =>
      f.catchError((Object e) {
        errors.add('$name: ${e.toString().replaceFirst('Exception: ', '')}');
        return <ImageHit>[];
      });
  final both = await Future.wait([
    safe('Openverse', searchOpenverse(q, page)),
    safe('Commons', searchCommons(q, page)),
  ]);
  final out = <ImageHit>[];
  final n = both.fold<int>(0, (m, l) => l.length > m ? l.length : m);
  for (var i = 0; i < n; i++) {
    for (final l in both) {
      if (i < l.length) out.add(l[i]);
    }
  }
  if (out.isEmpty && errors.length == both.length) {
    // as duas fontes falharam: mostra o motivo de cada uma
    throw Exception('Não consegui buscar. ${errors.join(' | ')}');
  }
  return out;
}

/// Parece um formato que o Flutter abre? (confere os primeiros bytes)
bool looksLikeImage(Uint8List b) {
  if (b.length < 12) return false;
  bool starts(List<int> m) {
    for (var i = 0; i < m.length; i++) {
      if (b[i] != m[i]) return false;
    }
    return true;
  }

  return starts([0x89, 0x50, 0x4E, 0x47]) || // PNG
      starts([0xFF, 0xD8, 0xFF]) || // JPEG
      starts([0x47, 0x49, 0x46]) || // GIF
      starts([0x42, 0x4D]) || // BMP
      (starts([0x52, 0x49, 0x46, 0x46]) && b[8] == 0x57 && b[9] == 0x45); // WebP
}

/// Endereços a tentar, do melhor para o mais garantido: original, versão média
/// (Commons) e a miniatura.
List<String> downloadCandidates(ImageHit h) {
  final mid = h.thumbUrl.replaceFirstMapped(
      RegExp(r'/(\d+)px-'), (m) => '/1280px-');
  return {h.fullUrl, if (mid != h.thumbUrl) mid, h.thumbUrl}.toList();
}

/// Baixa a imagem de [h]; se o original falhar (site fora, bloqueio, formato
/// estranho), tenta as alternativas.
Future<Uint8List> downloadHit(ImageHit h) async {
  Object? last;
  for (final url in downloadCandidates(h)) {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final r = await http
            .get(Uri.parse(url), headers: {
              ...kSearchHeaders,
              'Accept': 'image/png,image/jpeg,image/webp,image/*;q=0.8',
              if (h.pageUrl != null) 'Referer': h.pageUrl!,
            })
            .timeout(const Duration(seconds: 25));
        if (r.statusCode == 200 && looksLikeImage(r.bodyBytes)) return r.bodyBytes;
        last = r.statusCode == 200 ? 'formato não suportado' : 'erro ${r.statusCode}';
        if (r.statusCode == 404 || r.statusCode == 403) break; // não adianta repetir
      } catch (e) {
        last = e;
      }
    }
  }
  throw Exception('Não consegui baixar essa imagem ($last).');
}
