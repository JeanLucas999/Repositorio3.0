import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'folders.dart';
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
