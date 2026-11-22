/// Pasta da biblioteca. Pastas podem ficar dentro de outras ([parentId]);
/// null = raiz. Os cadernos guardam a pasta em `Notebook.folderId`.
class Folder {
  Folder({required this.id, required this.name, this.parentId});

  final String id;
  String name;
  String? parentId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (parentId != null) 'parent': parentId,
      };

  static Folder? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], name = j['name'];
    if (id is! String || name is! String) return null;
    final p = j['parent'];
    return Folder(id: id, name: name, parentId: p is String ? p : null);
  }
}

/// Ids de todas as pastas dentro de [id] (filhas, netas...).
Set<String> descendantIds(List<Folder> all, String id) {
  final out = <String>{};
  var frontier = <String>{id};
  while (frontier.isNotEmpty) {
    final next = <String>{};
    for (final f in all) {
      if (f.parentId != null && frontier.contains(f.parentId) && out.add(f.id)) {
        next.add(f.id);
      }
    }
    frontier = next;
  }
  return out;
}

/// Caminho da raiz até a pasta [id] (inclusive). Vazio para a raiz (null).
List<Folder> folderPath(List<Folder> all, String? id) {
  final byId = {for (final f in all) f.id: f};
  final out = <Folder>[];
  var cur = id;
  var guard = 0;
  while (cur != null && byId[cur] != null && guard++ < 64) {
    out.insert(0, byId[cur]!);
    cur = byId[cur]!.parentId;
  }
  return out;
}

/// Itens entre [a] e [b] (inclusive), na ordem da lista: seleção com Shift.
List<T> rangeBetween<T>(List<T> items, T a, T b) {
  final i = items.indexOf(a), j = items.indexOf(b);
  if (i < 0 || j < 0) return [b];
  return items.sublist(i < j ? i : j, (i < j ? j : i) + 1);
}
