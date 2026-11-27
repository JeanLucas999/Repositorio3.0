import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'folders.dart';
import 'models.dart';
import 'page_image.dart';
import 'settings.dart';

/// Guarda cada caderno como um arquivo JSON na pasta de documentos do app.
/// A sincronização com o Google Drive entra aqui depois (mesmo formato, um
/// arquivo por caderno).
class NotebookStorage {
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}notas_app');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _file(Directory d, String id) =>
      File('${d.path}${Platform.pathSeparator}$id.json');

  String newId() => 'nb-${DateTime.now().microsecondsSinceEpoch}';

  /// Todos os cadernos, do mais recente para o mais antigo.
  Future<List<Notebook>> listNotebooks() async {
    final dir = await _dir();
    final out = <Notebook>[];
    await for (final ent in dir.list()) {
      if (ent is! File || !ent.path.endsWith('.json')) continue;
      try {
        final map = jsonDecode(await ent.readAsString()) as Map<String, dynamic>;
        out.add(Notebook.fromJson(map));
      } catch (_) {
        // Arquivo ilegível: guarda uma cópia e segue.
        try {
          await ent.rename('${ent.path}.corrompido');
        } catch (_) {}
      }
    }
    out.sort((a, b) => b.modified.compareTo(a.modified));
    return out;
  }

  /// Escreve num arquivo temporário e troca, para não corromper se fechar no meio.
  Future<void> save(Notebook nb) {
    // um salvamento de cada vez por caderno (não se atropelam no arquivo temporário)
    final prev = _saving[nb.id] ?? Future<void>.value();
    final next = prev.catchError((_) {}).then((_) => _saveNow(nb));
    _saving[nb.id] = next;
    return next.whenComplete(() {
      if (identical(_saving[nb.id], next)) _saving.remove(nb.id);
    });
  }

  final Map<String, Future<void>> _saving = {};

  /// JSON já codificado (em bytes) de cada página, por caderno. Só as páginas
  /// que mudaram desde o último salvamento são codificadas de novo.
  final Map<String, Map<NotePage, _PageBytes>> _pageCache = {};

  Future<void> _saveNow(Notebook nb) async {
    final dir = await _dir();
    final target = _file(dir, nb.id);
    final tmp = File('${target.path}.tmp');

    final old = _pageCache[nb.id] ?? {};
    final fresh = <NotePage, _PageBytes>{};
    final head = utf8.encode(_headOf(nb));
    final pages = List.of(nb.pages);
    final raf = await tmp.open(mode: FileMode.write);
    try {
      await raf.writeFrom(head);
      for (var i = 0; i < pages.length; i++) {
        final p = pages[i];
        final fp = pageFingerprint(p);
        var e = old[p];
        if (e == null || e.fp != fp) {
          e = _PageBytes(fp, await encodePage(p));
        }
        fresh[p] = e;
        if (i > 0) await raf.writeFrom(_comma);
        await raf.writeFrom(e.bytes); // bytes prontos: nada de texto -> UTF-8 aqui
      }
      await raf.writeFrom(_tail);
      await raf.flush();
    } finally {
      await raf.close();
    }
    _pageCache[nb.id] = fresh; // descarta o que saiu do caderno
    await tmp.rename(target.path);
  }

  static final _comma = utf8.encode(',');
  static final _tail = utf8.encode(']}');

  static String _headOf(Notebook nb) {
    final head = jsonEncode(nb.headerJson());
    return '${head.substring(0, head.length - 1)},"pages":[';
  }

  /// Pastas da biblioteca (um arquivo só; fora do filtro `.json` dos cadernos).
  Future<List<Folder>> loadFolders() async {
    try {
      final f = File('${(await _dir()).path}${Platform.pathSeparator}pastas.dat');
      if (!await f.exists()) return [];
      final raw = jsonDecode(await f.readAsString());
      final list = raw is Map ? raw['folders'] : null;
      if (list is! List) return [];
      return [for (final j in list) if (Folder.fromJson(j) case final fd?) fd];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFolders(List<Folder> folders) async {
    final target = File('${(await _dir()).path}${Platform.pathSeparator}pastas.dat');
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(jsonEncode({'folders': [for (final f in folders) f.toJson()]}), flush: true);
    await tmp.rename(target.path);
  }

  /// Estado da sincronização com o Drive (id do caderno -> arquivo e versão).
  Future<Map<String, dynamic>> loadSyncState() async {
    try {
      final f = File('${(await _dir()).path}${Platform.pathSeparator}sync.dat');
      if (!await f.exists()) return {};
      final raw = jsonDecode(await f.readAsString());
      return raw is Map<String, dynamic> ? raw : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSyncState(Map<String, dynamic> state) async {
    final target = File('${(await _dir()).path}${Platform.pathSeparator}sync.dat');
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(jsonEncode(state), flush: true);
    await tmp.rename(target.path);
  }

  Future<void> delete(String id) async {
    final dir = await _dir();
    final f = _file(dir, id);
    if (await f.exists()) await f.delete();
  }
}

/// Guarda as preferências do app (tema, palm rejection, gestos...).
class SettingsStorage {
  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}${Platform.pathSeparator}notas_config.json');
  }

  Future<AppSettings> load() async {
    var s = AppSettings();
    try {
      final f = await _file();
      if (await f.exists()) {
        s = AppSettings.fromJson(
            jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      }
    } catch (_) {
      s = AppSettings();
    }

    Timer? timer;
    s.onChanged = () {
      timer?.cancel();
      timer = Timer(const Duration(milliseconds: 400), () async {
        try {
          final f = await _file();
          await f.writeAsString(jsonEncode(s.toJson()), flush: true);
        } catch (_) {}
      });
    };
    return s;
  }
}

class _PageBytes {
  _PageBytes(this.fp, this.bytes);
  final Object fp;
  final List<int> bytes;
}

/// "Impressão digital" barata de uma página: muda quando qualquer coisa nela muda
/// (traços, pontos, imagens, fundo, título...). Só percorre números, sem criar
/// JSON, então custa uma fração do salvamento.
Object pageFingerprint(NotePage p) {
  var h = Object.hash(p.background.index, p.mark, p.strokes.length, p.images.length,
      p.words?.length ?? -1, p.words == null ? 0 : identityHashCode(p.words));
  var sx = 0.0, sy = 0.0, sw = 0.0;
  for (final s in p.strokes) {
    h = Object.hash(h, s.id, s.color, s.width, s.highlighter, s.smooth, s.fountain, s.fill,
        s.style.index, s.points.length, s.widths?.length, s.fillNorm?.length, s.pressure);
    var i = 1;
    for (final q in s.points) {
      sx += q.dx * i;
      sy += q.dy * i;
      i++;
    }
    final ws = s.widths;
    if (ws != null) {
      for (final w in ws) {
        sw += w;
      }
    }
    final fn = s.fillNorm;
    if (fn != null) {
      for (final q in fn) {
        sw += q.dx + q.dy * 3;
      }
    }
  }
  for (final m in [...p.images, if (p.pdfBg != null) p.pdfBg!]) {
    h = Object.hash(h, m.id, m.rect, m.front, m.z, m.text, m.noteColor, m.fontSize, m.angle,
        m.graph, m.bytes.length, identityHashCode(m.bytes));
  }
  return (h, sx, sy, sw);
}

/// JSON de uma página em bytes, codificado em pedaços (devolve o controle ao app a
/// cada [batch] traços). Mesmo conteúdo de `jsonEncode(page.toJson())`.
Future<List<int>> encodePage(NotePage p, {int batch = 250}) async {
  final out = BytesBuilder(copy: false);
  final meta = jsonEncode(p.metaJson());
  out.add(utf8.encode(meta.substring(0, meta.length - 1)));
  out.add(utf8.encode(meta.length > 2 ? ',"strokes":[' : '"strokes":['));
  final strokes = List.of(p.strokes);
  var buf = StringBuffer();
  for (var k = 0; k < strokes.length; k++) {
    if (k > 0) buf.write(',');
    buf.write(jsonEncode(strokes[k].toJson()));
    if ((k + 1) % batch == 0) {
      out.add(utf8.encode(buf.toString()));
      buf = StringBuffer();
      await Future<void>.delayed(Duration.zero);
    }
  }
  buf.write(']}');
  out.add(utf8.encode(buf.toString()));
  await Future<void>.delayed(Duration.zero);
  return out.takeBytes();
}

/// Converte o caderno em JSON em pedaços, devolvendo o controle ao app entre eles
/// (por página e a cada [batch] traços). Assim a tela continua fluida mesmo em
/// cadernos grandes, em vez de travar durante o salvamento. O resultado é o mesmo
/// de `jsonEncode(nb.toJson())`.
Future<String> encodeNotebook(Notebook nb, {int batch = 250}) async {
  Future<void> breathe() => Future<void>.delayed(Duration.zero);
  final out = StringBuffer();
  final head = jsonEncode(nb.headerJson());
  out
    ..write(head.substring(0, head.length - 1))
    ..write(',"pages":[');
  final pages = List.of(nb.pages);
  for (var i = 0; i < pages.length; i++) {
    final p = pages[i];
    if (i > 0) out.write(',');
    final meta = jsonEncode(p.metaJson());
    out
      ..write(meta.substring(0, meta.length - 1))
      ..write(meta.length > 2 ? ',"strokes":[' : '"strokes":[');
    final strokes = List.of(p.strokes);
    for (var k = 0; k < strokes.length; k++) {
      if (k > 0) out.write(',');
      out.write(jsonEncode(strokes[k].toJson()));
      if ((k + 1) % batch == 0) await breathe();
    }
    out.write(']}');
    await breathe();
  }
  out.write(']}');
  return out.toString();
}
