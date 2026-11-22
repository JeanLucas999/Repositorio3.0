import 'package:flutter/material.dart';

import 'page_image.dart';

/// Resultado do editor de post-it.
typedef NoteEdit = ({String text, int color, double size});

/// Editor simples: texto, cor do papel e tamanho da letra.
Future<NoteEdit?> showNoteDialog(
  BuildContext context, {
  String text = '',
  int color = 0xFFFFF59D,
  double size = 26,
  bool isNew = true,
}) {
  return showDialog<NoteEdit>(
    context: context,
    builder: (_) => _NoteDialog(text: text, color: color, size: size, isNew: isNew),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.text,
    required this.color,
    required this.size,
    required this.isNew,
  });
  final String text;
  final int color;
  final double size;
  final bool isNew;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _ctl = TextEditingController(text: widget.text);
  late int _color = widget.color;
  late double _size = kNoteSizes.contains(widget.size) ? widget.size : kNoteSizes[1];

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop((text: _ctl.text.trim(), color: _color, size: _size));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.isNew ? 'Novo post-it' : 'Editar post-it'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(_color),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _ctl,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                style: const TextStyle(color: Color(0xFF3A3A3A)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Escreva a nota…',
                  hintStyle: TextStyle(color: Color(0x803A3A3A)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final c in kNoteColors)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c == _color ? scheme.primary : scheme.outlineVariant,
                            width: c == _color ? 2.5 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<double>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(value: 18.0, label: Text('Pequena')),
                ButtonSegment(value: 26.0, label: Text('Média')),
                ButtonSegment(value: 38.0, label: Text('Grande')),
              ],
              selected: {_size},
              onSelectionChanged: (v) => setState(() => _size = v.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
