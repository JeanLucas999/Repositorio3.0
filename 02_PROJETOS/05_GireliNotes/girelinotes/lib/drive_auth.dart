import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Login único do app (settings e biblioteca usam o mesmo).
final DriveAuth driveAuth = DriveAuth();

/// Login no Google por navegador (OAuth com PKCE e retorno em localhost).
/// Escopo `drive.file`: o app só enxerga o que ele mesmo criou no Drive.
class DriveAuth {
  static const scope = 'https://www.googleapis.com/auth/drive.file';

  String clientId = '';
  String clientSecret = '';
  String? _refresh;
  String? _access;
  DateTime _expires = DateTime.fromMillisecondsSinceEpoch(0);

  bool get hasClient => clientId.trim().isNotEmpty && clientSecret.trim().isNotEmpty;
  bool get signedIn => _refresh != null;

  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}notas_app');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}drive.dat');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      clientId = j['id'] as String? ?? '';
      clientSecret = j['secret'] as String? ?? '';
      _refresh = j['refresh'] as String?;
    } catch (_) {}
  }

  Future<void> save() async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode({'id': clientId.trim(), 'secret': clientSecret.trim(), 'refresh': _refresh}),
      flush: true,
    );
  }

  static String _rand(int n) {
    final r = math.Random.secure();
    const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(n, (_) => abc[r.nextInt(abc.length)]).join();
  }

  /// Abre o navegador, espera o retorno e troca o código pelos tokens.
  /// Lança [Exception] com mensagem em português se algo falhar.
  Future<void> signIn() async {
    if (!hasClient) throw Exception('Preencha o ID e o segredo do cliente.');
    final verifier = _rand(64);
    final challenge = base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    final state = _rand(24);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final redirect = 'http://127.0.0.1:${server.port}';
      final url = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId.trim(),
        'redirect_uri': redirect,
        'response_type': 'code',
        'scope': scope,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
        'state': state,
      });
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Não consegui abrir o navegador.');
      }
      final req = await server.first.timeout(const Duration(minutes: 5));
      final q = req.uri.queryParameters;
      final ok = q['code'] != null && q['state'] == state;
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('<html><meta charset="utf-8"><body style="font-family:sans-serif;'
            'text-align:center;margin-top:20vh"><h2>'
            '${ok ? 'Pronto! Pode fechar esta aba e voltar ao app.' : 'Não deu certo. Volte ao app e tente de novo.'}'
            '</h2></body></html>');
      await req.response.close();
      if (!ok) throw Exception(q['error'] ?? 'Login cancelado.');
      await _token({
        'code': q['code']!,
        'code_verifier': verifier,
        'redirect_uri': redirect,
        'grant_type': 'authorization_code',
      });
      await save();
    } on TimeoutException {
      throw Exception('Tempo esgotado esperando o login.');
    } finally {
      await server.close(force: true);
    }
  }

  Future<void> _token(Map<String, String> body) async {
    final r = await http.post(
      Uri.https('oauth2.googleapis.com', '/token'),
      body: {'client_id': clientId.trim(), 'client_secret': clientSecret.trim(), ...body},
    );
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200) {
      if (j['error'] == 'invalid_grant') _refresh = null;
      throw Exception('Google recusou o login (${j['error'] ?? r.statusCode}).');
    }
    _access = j['access_token'] as String;
    _expires = DateTime.now().add(Duration(seconds: (j['expires_in'] as num).toInt() - 60));
    _refresh = (j['refresh_token'] as String?) ?? _refresh;
  }

  /// Token de acesso válido (renova sozinho). Null se não houver login.
  Future<String?> accessToken() async {
    if (_refresh == null) return null;
    if (_access == null || DateTime.now().isAfter(_expires)) {
      await _token({'refresh_token': _refresh!, 'grant_type': 'refresh_token'});
      await save();
    }
    return _access;
  }

  Future<void> signOut() async {
    _refresh = null;
    _access = null;
    await save();
  }
}
