import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'drive_auth.dart';

class DriveFile {
  DriveFile(this.id, this.name, this.modified, this.isFolder, [this.props = const {}]);
  final String id;
  final String name;
  final DateTime modified;
  final bool isFolder;

  /// Propriedades do app gravadas no arquivo (id do caderno e data de edição).
  final Map<String, String> props;
}

/// Chamadas mínimas à API REST do Google Drive (v3).
class DriveApi {
  DriveApi(this.auth);
  final DriveAuth auth;

  static const _folderMime = 'application/vnd.google-apps.folder';

  Future<Map<String, String>> _headers() async {
    final t = await auth.accessToken();
    if (t == null) throw Exception('Entre na conta Google primeiro.');
    return {'Authorization': 'Bearer $t'};
  }

  Never _fail(http.Response r) {
    String msg = '${r.statusCode}';
    try {
      msg = (jsonDecode(r.body)['error']['message'] as String?) ?? msg;
    } catch (_) {}
    throw Exception('Drive: $msg');
  }

  /// Arquivos e pastas dentro de [parent] ('root' = raiz do Drive).
  Future<List<DriveFile>> list(String parent) async {
    final out = <DriveFile>[];
    String? page;
    do {
      final r = await http.get(
        Uri.https('www.googleapis.com', '/drive/v3/files', {
          'q': "'$parent' in parents and trashed = false",
          'fields': 'nextPageToken, files(id,name,modifiedTime,mimeType,appProperties)',
          'pageSize': '200',
          if (page != null) 'pageToken': page,
        }),
        headers: await _headers(),
      );
      if (r.statusCode != 200) _fail(r);
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      for (final f in (j['files'] as List)) {
        out.add(DriveFile(
          f['id'] as String,
          f['name'] as String,
          DateTime.parse(f['modifiedTime'] as String),
          f['mimeType'] == _folderMime,
          {
            for (final e in ((f['appProperties'] as Map?) ?? const {}).entries)
              '${e.key}': '${e.value}',
          },
        ));
      }
      page = j['nextPageToken'] as String?;
    } while (page != null);
    return out;
  }

  /// Id da pasta [name] dentro de [parent]; cria se não existir.
  Future<String> ensureFolder(String name, {String parent = 'root'}) async {
    for (final f in await list(parent)) {
      if (f.isFolder && f.name == name) return f.id;
    }
    final r = await http.post(
      Uri.https('www.googleapis.com', '/drive/v3/files', {'fields': 'id'}),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'mimeType': _folderMime, 'parents': [parent]}),
    );
    if (r.statusCode != 200) _fail(r);
    return jsonDecode(r.body)['id'] as String;
  }

  /// Cria (ou, com [id], substitui o conteúdo de) um arquivo. Devolve o id.
  /// [props] vira `appProperties`. Com [id] e [moveFrom], também move o arquivo
  /// da pasta [moveFrom] para [parent].
  Future<String> upload(String name, Uint8List bytes,
      {required String parent,
      String? id,
      Map<String, String>? props,
      String? moveFrom}) async {
    const boundary = 'notas_boundary_7f3a';
    final meta = jsonEncode({
      'name': name,
      if (id == null) 'parents': [parent],
      if (props != null) 'appProperties': props,
    });
    final body = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
          '$meta\r\n--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--'));
    final uri = Uri.https(
      'www.googleapis.com',
      id == null ? '/upload/drive/v3/files' : '/upload/drive/v3/files/$id',
      {
        'uploadType': 'multipart',
        'fields': 'id',
        if (id != null && moveFrom != null && moveFrom != parent) ...{
          'addParents': parent,
          'removeParents': moveFrom,
        },
      },
    );
    final h = {...await _headers(), 'Content-Type': 'multipart/related; boundary=$boundary'};
    final r = id == null
        ? await http.post(uri, headers: h, body: body.toBytes())
        : await http.patch(uri, headers: h, body: body.toBytes());
    if (r.statusCode != 200) _fail(r);
    return jsonDecode(r.body)['id'] as String;
  }

  Future<Uint8List> download(String id) async {
    final r = await http.get(
      Uri.https('www.googleapis.com', '/drive/v3/files/$id', {'alt': 'media'}),
      headers: await _headers(),
    );
    if (r.statusCode != 200) _fail(r);
    return r.bodyBytes;
  }

  Future<void> trash(String id) async {
    final r = await http.patch(
      Uri.https('www.googleapis.com', '/drive/v3/files/$id'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'trashed': true}),
    );
    if (r.statusCode != 200) _fail(r);
  }
}
