import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'image_search.dart';

/// Imagem escolhida na busca.
class SearchPick {
  SearchPick(this.bytes, this.credit);
  final Uint8List bytes;
  final String credit;
}

/// Abre a busca de imagens; devolve a imagem escolhida (ou null).
Future<SearchPick?> showImageSearch(BuildContext context) => showDialog<SearchPick>(
      context: context,
      builder: (_) => const _ImageSearchDialog(),
    );

class _ImageSearchDialog extends StatefulWidget {
  const _ImageSearchDialog();

  @override
  State<_ImageSearchDialog> createState() => _ImageSearchDialogState();
}

class _ImageSearchDialogState extends State<_ImageSearchDialog> {
  final _q = TextEditingController();
  final List<ImageHit> _hits = [];
  final Set<String> _seen = {};
  bool _loading = false;
  bool _picking = false;
  bool _searched = false;
  String? _error;
  String _query = '';
  int _page = 0;
  int _gen = 0; // descarta respostas de buscas antigas

  @override
  void dispose() {
    _gen++;
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    _gen++;
    setState(() {
      _query = q;
      _page = 0;
      _hits.clear();
      _seen.clear();
      _error = null;
      _searched = true;
    });
    await _more();
  }

  /// Carrega a próxima página de resultados.
  Future<void> _more() async {
    if (_loading || _query.isEmpty) return;
    final gen = ++_gen;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final found = await searchImages(_query, _page++);
      if (gen != _gen || !mounted) return;
      final fresh = [for (final h in found) if (_seen.add(h.fullUrl)) h];
      setState(() => _hits.addAll(fresh));
    } catch (e) {
      if (gen == _gen && mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
    if (gen == _gen && mounted) setState(() => _loading = false);
  }

  Future<void> _pick(ImageHit h) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final bytes = await downloadHit(h);
      if (!mounted) return;
      Navigator.of(context).pop(SearchPick(bytes, h.credit));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _q,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: 'Buscar imagens na internet',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _search, child: const Text('Buscar')),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: _body(scheme)),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Resultados do Openverse e do Wikimedia Commons. Respeite a licença de cada imagem.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ColorScheme scheme) {
    if (_picking) return const Center(child: CircularProgressIndicator());
    if (!_searched) {
      return Center(
        child: Text('Digite o que procura e toque em Buscar.',
            style: TextStyle(color: scheme.outline)),
      );
    }
    if (_hits.isEmpty && !_loading) {
      return Center(
        child: Text(_error ?? 'Nada encontrado. Tente outra palavra (em inglês acha mais).',
            textAlign: TextAlign.center, style: TextStyle(color: scheme.outline)),
      );
    }
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(_error!, style: TextStyle(color: scheme.error)),
          ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _hits.length + 1,
            itemBuilder: (context, i) {
              if (i == _hits.length) {
                return Center(
                  child: _loading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : TextButton(onPressed: _more, child: const Text('Mais')),
                );
              }
              return _Tile(hit: _hits[i], onTap: () => _pick(_hits[i]));
            },
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.hit, required this.onTap});
  final ImageHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '${hit.title}\n${hit.credit}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: scheme.surfaceContainerHighest,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _Checker(scheme.outlineVariant.withAlpha(90))),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.network(
                    hit.thumbUrl,
                    fit: BoxFit.contain,
                    headers: kSearchHeaders,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Xadrez cinza: mostra onde a imagem é transparente.
class _Checker extends CustomPainter {
  _Checker(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const s = 10.0;
    final p = Paint()..color = color;
    for (var y = 0.0; y < size.height; y += s) {
      for (var x = 0.0; x < size.width; x += s) {
        if (((x / s).floor() + (y / s).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, s, s), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Checker old) => old.color != color;
}
