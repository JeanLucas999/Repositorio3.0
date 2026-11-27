import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'function_parser.dart';
import 'graph.dart';

/// Abre o editor de gráfico. Devolve a especificação, ou null se cancelou.
Future<GraphSpec?> showGraphDialog(BuildContext context, {GraphSpec? initial}) =>
    showDialog<GraphSpec>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GraphDialog(initial: initial),
    );

class _GraphDialog extends StatefulWidget {
  const _GraphDialog({this.initial});
  final GraphSpec? initial;

  @override
  State<_GraphDialog> createState() => _GraphDialogState();
}

class _GraphDialogState extends State<_GraphDialog> {
  final List<TextEditingController> _exprs = [];
  final List<int> _colors = [];
  late final TextEditingController _x0, _x1, _y0, _y1;
  bool _autoY = true, _grid = true;
  Uint8List? _preview;
  Timer? _debounce;
  int _gen = 0;

  String _n(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s != null && s.fns.isNotEmpty) {
      for (final f in s.fns) {
        _exprs.add(TextEditingController(text: f.expr));
        _colors.add(f.color);
      }
    } else {
      _exprs.add(TextEditingController(text: 'x^2 - 3x + 2'));
      _colors.add(kGraphColors[0]);
    }
    _x0 = TextEditingController(text: _n(s?.xMin ?? -10));
    _x1 = TextEditingController(text: _n(s?.xMax ?? 10));
    _y0 = TextEditingController(text: _n(s?.yMin ?? -10));
    _y1 = TextEditingController(text: _n(s?.yMax ?? 10));
    _autoY = s?.autoY ?? true;
    _grid = s?.grid ?? true;
    _refresh();
  }

  @override
  void dispose() {
    _gen++;
    _debounce?.cancel();
    for (final c in [..._exprs, _x0, _x1, _y0, _y1]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  /// Erro de cada função (null = ok).
  String? _fnError(int i) {
    final t = _exprs[i].text.trim();
    if (t.isEmpty) return null;
    try {
      parseFunction(t);
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  String? get _rangeError {
    final a = _num(_x0), b = _num(_x1);
    if (a == null || b == null) return 'Escreva números em x.';
    if (a >= b) return 'Em x, o mínimo tem de ser menor que o máximo.';
    if (!_autoY) {
      final c = _num(_y0), d = _num(_y1);
      if (c == null || d == null) return 'Escreva números em y.';
      if (c >= d) return 'Em y, o mínimo tem de ser menor que o máximo.';
    }
    return null;
  }

  bool get _valid =>
      _rangeError == null &&
      List.generate(_exprs.length, _fnError).every((e) => e == null) &&
      _exprs.any((c) => c.text.trim().isNotEmpty);

  GraphSpec _spec() => GraphSpec(
        fns: [
          for (var i = 0; i < _exprs.length; i++)
            if (_exprs[i].text.trim().isNotEmpty) GraphFn(_exprs[i].text.trim(), _colors[i]),
        ],
        xMin: _num(_x0) ?? -10,
        xMax: _num(_x1) ?? 10,
        yMin: _num(_y0) ?? -10,
        yMax: _num(_y1) ?? 10,
        autoY: _autoY,
        grid: _grid,
      );

  void _changed() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _refresh);
  }

  Future<void> _refresh() async {
    if (_rangeError != null) return;
    final gen = ++_gen;
    final png = await renderGraphPng(_spec());
    if (gen != _gen || !mounted) return;
    setState(() => _preview = png);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.initial != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            children: [
              Row(children: [
                const Expanded(
                  child: Text('Gráfico de função',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: _preview == null
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : Image.memory(_preview!, fit: BoxFit.contain, gaplessPlayback: true),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _exprs.length; i++) _fnRow(i, scheme),
                    if (_exprs.length < kGraphColors.length)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            _exprs.add(TextEditingController());
                            _colors.add(kGraphColors[_exprs.length - 1]);
                          }),
                          icon: const Icon(Icons.add),
                          label: const Text('Outra função'),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: _numField('x mínimo', _x0)),
                      const SizedBox(width: 8),
                      Expanded(child: _numField('x máximo', _x1)),
                    ]),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ajustar y automaticamente'),
                      value: _autoY,
                      onChanged: (v) {
                        _autoY = v;
                        _changed();
                      },
                    ),
                    if (!_autoY)
                      Row(children: [
                        Expanded(child: _numField('y mínimo', _y0)),
                        const SizedBox(width: 8),
                        Expanded(child: _numField('y máximo', _y1)),
                      ]),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Grade'),
                      value: _grid,
                      onChanged: (v) {
                        _grid = v;
                        _changed();
                      },
                    ),
                    if (_rangeError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(_rangeError!, style: TextStyle(color: scheme.error)),
                      ),
                    Text(
                      'Exemplos: x^2 - 3x + 2 · sin(x) · 1/x · sqrt(x) · 2^x · abs(x) · ln(x)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _valid ? () => Navigator.of(context).pop(_spec()) : null,
                    child: Text(editing ? 'Salvar' : 'Inserir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fnRow(int i, ColorScheme scheme) {
    final err = _fnError(i);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, right: 10),
            child: GestureDetector(
              onTap: () => setState(() {
                final k = kGraphColors.indexOf(_colors[i]);
                _colors[i] = kGraphColors[(k + 1) % kGraphColors.length];
                _changed();
              }),
              child: CircleAvatar(radius: 10, backgroundColor: Color(_colors[i])),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _exprs[i],
              onChanged: (_) => _changed(),
              decoration: InputDecoration(
                labelText: 'y =',
                isDense: true,
                errorText: err,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_exprs.length > 1)
            IconButton(
              tooltip: 'Tirar',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() {
                _exprs.removeAt(i).dispose();
                _colors.removeAt(i);
                _changed();
              }),
            ),
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController c) => TextField(
        controller: c,
        onChanged: (_) => _changed(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      );
}
