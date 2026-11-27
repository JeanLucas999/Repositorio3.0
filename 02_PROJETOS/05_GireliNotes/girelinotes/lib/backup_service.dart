import 'dart:typed_data';

import 'export_service.dart';
import 'folders.dart';
import 'models.dart';
import 'storage.dart';
import 'zip_io.dart';

String _clean(String s, String fallback) {
  final t = s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return t.isEmpty ? fallback : t;
}

/// Backup completo em um .zip: um arquivo por caderno (`.notas` ou PDF), nas
/// mesmas pastas da biblioteca.
Future<Uint8List> buildBackup(
  List<Notebook> books,
  List<Folder> folders, {
  required bool pdf,
  required double lineSpacing,
  void Function(int done, int total)? onProgress,
}) async {
  final entries = <ZipEntry>[];
  final used = <String>{};
  final ext = pdf ? 'pdf' : kNotasExtension;
  for (var i = 0; i < books.length; i++) {
    final nb = books[i];
    final dir = [for (final f in folderPath(folders, nb.folderId)) _clean(f.name, 'Pasta')];
    final base = [...dir, _clean(nb.name, 'Caderno')].join('/');
    var path = '$base.$ext';
    for (var n = 2; !used.add(path.toLowerCase()); n++) {
      path = '$base ($n).$ext';
    }
    final bytes = pdf ? await buildPdf(nb, lineSpacing: lineSpacing) : encodeNotas(nb);
    entries.add(ZipEntry(path, bytes));
    onProgress?.call(i + 1, books.length);
    await Future<void>.delayed(Duration.zero); // deixa a tela respirar
  }
  return writeZip(entries);
}

class RestoreResult {
  int added = 0, updated = 0, skipped = 0, failed = 0;

  String get summary {
    final p = <String>[
      if (added > 0) '$added novo${added > 1 ? 's' : ''}',
      if (updated > 0) '$updated atualizado${updated > 1 ? 's' : ''}',
      if (skipped > 0) '$skipped já em dia',
      if (failed > 0) '$failed ilegível${failed > 1 ? 'eis' : ''}',
    ];
    return p.isEmpty ? 'O backup não tinha cadernos .notas.' : 'Restaurado: ${p.join(', ')}.';
  }
}

/// Restaura os `.notas` de um backup (.zip). Cadernos que já existem (mesmo id)
/// só são trocados se o do backup for mais novo. As pastas são recriadas.
Future<RestoreResult> restoreBackup(
  Uint8List zip,
  List<Notebook> books,
  List<Folder> folders,
  NotebookStorage storage,
) async {
  final res = RestoreResult();
  final foldersBefore = folders.length;
  for (final e in readZip(zip)) {
    if (!e.name.toLowerCase().endsWith('.$kNotasExtension')) continue;
    try {
      final nb = decodeNotas(e.data, '', keepId: true);
      final parts = e.name.split('/').where((s) => s.isNotEmpty).toList();
      nb.folderId = ensureFolderPath(folders, parts.sublist(0, parts.length - 1));
      final i = books.indexWhere((b) => b.id == nb.id);
      if (i < 0) {
        books.add(nb);
        await storage.save(nb);
        res.added++;
      } else if (nb.modified.isAfter(books[i].modified)) {
        books[i] = nb;
        await storage.save(nb);
        res.updated++;
      } else {
        res.skipped++;
      }
    } catch (_) {
      res.failed++;
    }
  }
  if (folders.length != foldersBefore) await storage.saveFolders(folders);
  return res;
}
