import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'bg_remove.dart';

/// Abre a varinha mágica sobre [bytes]; devolve o PNG sem o fundo, ou null.
Future<Uint8List?> showBgRemover(BuildContext context, Uint8List bytes) =>
    showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BgDialog(bytes: bytes),
    );

Uint8List _wandJob(List<Object> a) {
  final rgba = a[0] as Uint8List;
  final w = a[1] as int, h = a[2] as int;
  final mask = wandMask(rgba, w, h, a[3] as List<WandTap>, a[4] as double,
      contiguous: a[5] as bool);
  return applyMask(rgba, w, h, mask, feather: a[6] as int);
}

/// Roda a varinha fora da tela; se o isolate falhar, roda aqui mesmo.
/// (Função solta, para o isolate não carregar a tela junto.)
Future<Uint8List> _runWand(Uint8List rgba, int w, int h, List<WandTap> taps,
    double tol, bool contiguous, int feather) async {
  final args = <Object>[rgba, w, h, taps, tol, contiguous, feather];
  try {
    return await Isolate.run(() => _wandJob(args)).timeout(const Duration(seconds: 60));
  } catch (_) {
    return _wandJob(args);
  }
}

class _BgDialog extends StatefulWidget {
  const _BgDialog({required this.bytes});
  final Uint8List bytes;

  @override
  State<_BgDialog> createState() => _BgDialogState();
}

class _BgDialogState extends State<_BgDialog> {
  Uint8List? _rgba;
  int _w = 0, _h = 0;
  ui.Image? _preview;
  final List<WandTap> _taps = [];
  double _tol = 18;
  bool _contiguous = true;
  double _feather = 1;
  bool _busy = true;
  bool _failed = false;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _gen++;
    _preview?.dispose();
    super.dispose();
  }

  static const _maxSide = 1600;

  Future<void> _load() async {
    try {
      var codec = await ui.instantiateImageCodec(widget.bytes);
      var img = (await codec.getNextFrame()).image;
      if (img.width > _maxSide || img.height > _maxSide) {
        // trabalha numa versão menor: a varinha fica rápida e o resultado, leve
        final wide = img.width >= img.height;
        img.dispose();
        codec = await ui.instantiateImageCodec(widget.bytes,
            targetWidth: wide ? _maxSide : null, targetHeight: wide ? null : _maxSide);
        img = (await codec.getNextFrame()).image;
      }
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw Exception('sem pixels');
      if (!mounted) return;
      _w = img.width;
      _h = img.height;
      _rgba = data.buffer.asUint8List();
      _preview = img;
      setState(() => _busy = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _busy = false;
        });
      }
    }
  }

  Future<ui.Image> _toImage(Uint8List px) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(px, _w, _h, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  /// Refaz a prévia com os toques e a tolerância atuais.
  Future<void> _refresh() async {
    final rgba = _rgba;
    if (rgba == null) return;
    final gen = ++_gen;
    setState(() => _busy = true);
    try {
      final px = await _runWand(rgba, _w, _h, List<WandTap>.of(_taps), _tol, _contiguous, 0);
      final img = await _toImage(px);
      if (gen != _gen || !mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _preview?.dispose();
        _preview = img;
        _busy = false;
      });
    } catch (_) {
      if (gen == _gen && mounted) setState(() => _busy = false);
    }
  }

  void _tap(Offset local, Size shown) {
    if (_rgba == null || _busy) return;
    final x = (local.dx / shown.width * _w).floor().clamp(0, _w - 1);
    final y = (local.dy / shown.height * _h).floor().clamp(0, _h - 1);
    _taps.add(WandTap(x, y));
    _refresh();
  }

  Future<void> _apply() async {
    final rgba = _rgba;
    if (rgba == null || _taps.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busy = true);
    try {
      final px = await _runWand(
          rgba, _w, _h, List<WandTap>.of(_taps), _tol, _contiguous, _feather.round());
      final img = await _toImage(px);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (!mounted) return;
      Navigator.of(context).pop(png?.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Remover fundo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  if (_busy)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _failed
                      ? 'Não consegui abrir essa imagem.'
                      : 'Toque no fundo para apagá-lo. Toque de novo em outras partes, se precisar.',
                  style: TextStyle(color: scheme.outline),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: _preview == null
                        ? const SizedBox.expand()
                        : LayoutBuilder(builder: (context, box) {
                            final k = (box.maxWidth / _w < box.maxHeight / _h)
                                ? box.maxWidth / _w
                                : box.maxHeight / _h;
                            final shown = Size(_w * k, _h * k);
                            return Center(
                              child: InteractiveViewer(
                                maxScale: 8,
                                child: GestureDetector(
                                  onTapUp: (d) => _tap(d.localPosition, shown),
                                  child: SizedBox(
                                    width: shown.width,
                                    height: shown.height,
                                    child: CustomPaint(
                                      painter: _PreviewPainter(
                                        _preview!,
                                        scheme.outlineVariant.withAlpha(110),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _slider('Tolerância', _tol, 0, 100, (v) => setState(() => _tol = v),
                  onEnd: (_) {
                if (_taps.isNotEmpty) _refresh();
              }, label: '${_tol.round()}'),
              _slider('Suavizar borda', _feather, 0, 4, (v) => setState(() => _feather = v),
                  divisions: 4, label: '${_feather.round()} px'),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Só a região ligada ao ponto tocado'),
                subtitle: const Text('Desligado: apaga essa cor em toda a imagem'),
                value: _contiguous,
                onChanged: (v) {
                  setState(() => _contiguous = v);
                  if (_taps.isNotEmpty) _refresh();
                },
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _taps.isEmpty || _busy
                        ? null
                        : () {
                            _taps.removeLast();
                            _refresh();
                          },
                    icon: const Icon(Icons.undo),
                    label: const Text('Desfazer toque'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_taps.isEmpty || _busy) ? null : _apply,
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(String name, double v, double min, double max, ValueChanged<double> on,
      {ValueChanged<double>? onEnd, int? divisions, required String label}) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(name)),
        Expanded(
          child: Slider(
            value: v,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: on,
            onChangeEnd: onEnd,
          ),
        ),
      ],
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.image, this.checker);
  final ui.Image image;
  final Color checker;

  @override
  void paint(Canvas canvas, Size size) {
    const s = 10.0;
    final p = Paint()..color = checker;
    for (var y = 0.0; y < size.height; y += s) {
      for (var x = 0.0; x < size.width; x += s) {
        if (((x / s).floor() + (y / s).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, s, s), p);
        }
      }
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.image != image || old.checker != checker;
}
