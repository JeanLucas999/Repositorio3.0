import 'package:flutter/material.dart';

import 'drive_api.dart';
import 'drive_auth.dart';

/// Seção "Google Drive" das configurações: credenciais, login e teste.
class DriveSection extends StatefulWidget {
  const DriveSection({super.key, required this.auth});
  final DriveAuth auth;

  @override
  State<DriveSection> createState() => _DriveSectionState();
}

class _DriveSectionState extends State<DriveSection> {
  final _id = TextEditingController();
  final _secret = TextEditingController();
  bool _ready = false;
  bool _busy = false;
  String? _msg;

  DriveAuth get a => widget.auth;

  @override
  void initState() {
    super.initState();
    a.load().then((_) {
      if (!mounted) return;
      setState(() {
        _id.text = a.clientId;
        _secret.text = a.clientSecret;
        _ready = true;
      });
    });
  }

  @override
  void dispose() {
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function() job) async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final m = await job();
      if (mounted) setState(() => _msg = m);
    } catch (e) {
      if (mounted) setState(() => _msg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _signIn() async {
    a.clientId = _id.text;
    a.clientSecret = _secret.text;
    await a.save();
    await a.signIn();
    return 'Conectado ao Google.';
  }

  Future<String> _test() async {
    final id = await DriveApi(a).ensureFolder('Notas');
    final n = (await DriveApi(a).list(id)).length;
    return 'Tudo certo: pasta "Notas" no seu Drive ($n arquivos).';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox(height: 48);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _id,
            enabled: !a.signedIn && !_busy,
            decoration: const InputDecoration(labelText: 'ID do cliente'),
          ),
          TextField(
            controller: _secret,
            enabled: !a.signedIn && !_busy,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Segredo do cliente'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!a.signedIn)
                FilledButton.icon(
                  onPressed: _busy ? null : () => _run(_signIn),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar com Google'),
                )
              else ...[
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _run(_test),
                  icon: const Icon(Icons.cloud_done_outlined),
                  label: const Text('Testar conexão'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await a.signOut();
                            return 'Desconectado.';
                          }),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
              ],
            ],
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_msg!, style: TextStyle(color: scheme.primary)),
            ),
        ],
      ),
    );
  }
}
