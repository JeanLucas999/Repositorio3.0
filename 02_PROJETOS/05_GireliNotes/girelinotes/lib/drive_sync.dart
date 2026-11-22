import 'dart:typed_data';

import 'drive_api.dart';
import 'drive_auth.dart';
import 'export_service.dart';
import 'folders.dart';
import 'models.dart';
import 'storage.dart';

/// O que fazer com um caderno que existe aqui e no Drive.
enum SyncAction { none, upload, download, conflict }

/// Decide pela data de edição (ms): [lastSynced] é a versão da última
/// sincronização (null = nunca sincronizou este caderno).
SyncAction decideSync({required int local, required int remote, int? lastSynced}) {
  if (lastSynced == null) return local == remote ? SyncAction.none : SyncAction.conflict;
  final localChanged = local > lastSynced;
  final remoteChanged = remote != lastSynced;
  if (localChanged && remoteChanged) return SyncAction.conflict;
  if (localChanged) return SyncAction.upload;
  if (remoteChanged) return SyncAction.download;
  return SyncAction.none;
}

/// Nome de arquivo seguro para o Drive.
String driveFileName(String name) {
  final s = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return '${s.isEmpty ? 'Caderno' : s}.$kNotasExtension';
}

class SyncResult {
  int up = 0, down = 0, conflicts = 0;
  String get summary {
    final p = <String>[
      if (up > 0) '$up enviado${up > 1 ? 's' : ''}',
      if (down > 0) '$down baixado${down > 1 ? 's' : ''}',
      if (conflicts > 0) '$conflicts conflito${conflicts > 1 ? 's' : ''} (cópia guardada)',
    ];
    return p.isEmpty ? 'Tudo em dia.' : 'Sincronizado: ${p.join(', ')}.';
  }
}

class _Remote {
  _Remote(this.fileId, this.parentId, this.path, this.mod);
  final String fileId;
  final String parentId;
  final List<String> path;
  final int mod;
}

/// Sincroniza a biblioteca com a pasta "Notas" do Drive: um arquivo `.notas`
/// por caderno, pastas da biblioteca como subpastas. Nada é apagado por
/// conflito: as duas versões ficam.
class DriveSync {
  DriveSync(this.auth, this.storage) : api = DriveApi(auth);

  final DriveAuth auth;
  final NotebookStorage storage;
  final DriveApi api;

  static String _key(List<String> path) => path.join('/');

  /// Sincroniza [books] e [folders] (alterados no lugar).
  Future<SyncResult> run(List<Notebook> books, List<Folder> folders) async {
    final res = SyncResult();
    final state = await storage.loadSyncState();
    final root = await api.ensureFolder('Notas');

    // ---- o que existe no Drive
    final remote = <String, _Remote>{};
    final dirIds = <String, String>{'': root};
    Future<void> walk(String dir, List<String> path) async {
      for (final f in await api.list(dir)) {
        if (f.isFolder) {
          final p = [...path, f.name];
          dirIds.putIfAbsent(_key(p), () => f.id);
          await walk(f.id, p);
        } else if (f.props['nb'] != null) {
          final mod = int.tryParse(f.props['mod'] ?? '') ?? f.modified.millisecondsSinceEpoch;
          final old = remote[f.props['nb']!];
          if (old == null || mod > old.mod) {
            remote[f.props['nb']!] = _Remote(f.id, dir, path, mod);
          }
        }
      }
    }

    await walk(root, const []);

    Future<String> dirFor(List<String> path) async {
      var cur = '';
      var curId = root;
      for (final name in path) {
        final next = cur.isEmpty ? name : '$cur/$name';
        curId = dirIds[next] ??= await api.ensureFolder(name, parent: curId);
        cur = next;
      }
      return curId;
    }

    List<String> localPath(Notebook nb) =>
        [for (final f in folderPath(folders, nb.folderId)) f.name];

    String? ensureLocalFolders(List<String> path) {
      String? cur;
      for (final name in path) {
        final hit = folders.where((f) => f.parentId == cur && f.name == name).firstOrNull;
        if (hit != null) {
          cur = hit.id;
        } else {
          final f = Folder(
              id: 'fd-${DateTime.now().microsecondsSinceEpoch}-${folders.length}',
              name: name,
              parentId: cur);
          folders.add(f);
          cur = f.id;
        }
      }
      return cur;
    }

    Future<void> upload(Notebook nb, _Remote? r) async {
      final path = localPath(nb);
      final parent = await dirFor(path);
      final mod = nb.modified.millisecondsSinceEpoch;
      final id = await api.upload(
        driveFileName(nb.name),
        encodeNotas(nb),
        parent: parent,
        id: r?.fileId,
        moveFrom: r?.parentId,
        props: {'nb': nb.id, 'mod': '$mod'},
      );
      state[nb.id] = {'f': id, 'm': mod, 'p': _key(path)};
      res.up++;
    }

    Future<Notebook> fetch(_Remote r, String id) async {
      final Uint8List bytes = await api.download(r.fileId);
      return decodeNotas(bytes, id);
    }

    final foldersBefore = folders.length;
    final byId = {for (final b in books) b.id: b};

    // ---- cadernos daqui
    for (final nb in List<Notebook>.of(books)) {
      final r = remote[nb.id];
      final st = state[nb.id] as Map<String, dynamic>?;
      if (r == null) {
        await upload(nb, null); // novo (ou apagado no Drive: volta para lá)
        continue;
      }
      final action = decideSync(
        local: nb.modified.millisecondsSinceEpoch,
        remote: r.mod,
        lastSynced: (st?['m'] as num?)?.toInt(),
      );
      switch (action) {
        case SyncAction.upload:
          await upload(nb, r);
        case SyncAction.download:
          final got = await fetch(r, nb.id);
          got.folderId = ensureLocalFolders(r.path);
          await storage.save(got);
          books[books.indexOf(nb)] = got;
          state[nb.id] = {'f': r.fileId, 'm': r.mod, 'p': _key(r.path)};
          res.down++;
        case SyncAction.conflict:
          // guarda a versão do Drive como cópia e manda a daqui para o Drive
          final copy = await fetch(r, storage.newId());
          final dup = Notebook(
            id: copy.id,
            name: '${copy.name} (conflito)',
            pages: copy.pages,
            format: copy.format,
          )..folderId = nb.folderId;
          await storage.save(dup);
          books.add(dup);
          byId[dup.id] = dup;
          await upload(nb, r);
          await upload(dup, null);
          res.conflicts++;
        case SyncAction.none:
          final here = _key(localPath(nb)), there = _key(r.path);
          final was = st?['p'] as String?;
          if (here != there) {
            if (was != null && here != was) {
              await upload(nb, r); // movido aqui: acompanha no Drive
            } else if (was != null && there != was) {
              nb.folderId = ensureLocalFolders(r.path); // movido no Drive
              await storage.save(nb);
              state[nb.id] = {'f': r.fileId, 'm': r.mod, 'p': there};
            }
          } else {
            state[nb.id] = {'f': r.fileId, 'm': r.mod, 'p': here};
          }
      }
    }

    // ---- cadernos só do Drive
    for (final e in remote.entries) {
      if (byId.containsKey(e.key)) continue;
      try {
        final got = await fetch(e.value, e.key);
        got.folderId = ensureLocalFolders(e.value.path);
        await storage.save(got);
        books.add(got);
        state[e.key] = {'f': e.value.fileId, 'm': e.value.mod, 'p': _key(e.value.path)};
        res.down++;
      } catch (_) {
        // arquivo ilegível: segue com os outros
      }
    }

    if (folders.length != foldersBefore) await storage.saveFolders(folders);
    await storage.saveSyncState(state);
    return res;
  }

  /// Manda para a lixeira do Drive os cadernos apagados aqui (sem erro se falhar).
  Future<void> trash(Iterable<String> ids) async {
    try {
      final state = await storage.loadSyncState();
      for (final id in ids) {
        final f = (state[id] as Map<String, dynamic>?)?['f'] as String?;
        if (f == null) continue;
        await api.trash(f);
        state.remove(id);
      }
      await storage.saveSyncState(state);
    } catch (_) {}
  }
}
