import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';
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
  Future<void> save(Notebook nb) async {
    final dir = await _dir();
    final target = _file(dir, nb.id);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(jsonEncode(nb.toJson()), flush: true);
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
