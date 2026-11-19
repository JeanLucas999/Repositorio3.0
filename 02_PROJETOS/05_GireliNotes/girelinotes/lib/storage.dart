import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Guarda o caderno como JSON na pasta de documentos do app.
/// A sincronização com o Google Drive entra aqui depois (mesmo formato).
class NotebookStorage {
  static const _defaultId = 'caderno-principal';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}notas_app');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _file(Directory d, String id) =>
      File('${d.path}${Platform.pathSeparator}$id.json');

  Future<Notebook> loadOrCreate() async {
    final dir = await _dir();
    final f = _file(dir, _defaultId);
    if (await f.exists()) {
      try {
        final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        return Notebook.fromJson(map);
      } catch (_) {
        // Arquivo ilegível: guarda uma cópia e começa um caderno novo.
        await f.rename('${f.path}.corrompido');
      }
    }
    return Notebook.empty(_defaultId, 'Meu caderno');
  }

  /// Escreve num arquivo temporário e troca, para não corromper se fechar no meio.
  Future<void> save(Notebook nb) async {
    final dir = await _dir();
    final target = _file(dir, nb.id);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(jsonEncode(nb.toJson()), flush: true);
    await tmp.rename(target.path);
  }
}
