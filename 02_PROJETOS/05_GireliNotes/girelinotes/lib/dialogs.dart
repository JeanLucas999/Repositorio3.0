import 'package:flutter/material.dart';

import 'models.dart';

/// Pede um texto (ex.: nome do caderno). Retorna null se cancelar.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String initial = '',
  String confirm = 'OK',
}) {
  final ctrl = TextEditingController(text: initial);
  ctrl.selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        onSubmitted: (v) => Navigator.pop(ctx, v),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(confirm),
        ),
      ],
    ),
  );
}

/// Pergunta sim/não. Retorna true só se confirmar.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Excluir',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok == true;
}


/// Diálogo de novo caderno: nome + formato. Retorna null se cancelar.
Future<({String name, NotebookFormat format})?> newNotebookDialog(BuildContext context) {
  final ctrl = TextEditingController(text: 'Novo caderno');
  ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
  var format = NotebookFormat.portrait;
  return showDialog<({String name, NotebookFormat format})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Novo caderno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SegmentedButton<NotebookFormat>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: NotebookFormat.portrait,
                  icon: Icon(Icons.crop_portrait),
                  label: Text('Vertical'),
                ),
                ButtonSegment(
                  value: NotebookFormat.landscape,
                  icon: Icon(Icons.crop_landscape),
                  label: Text('Horizontal'),
                ),
                ButtonSegment(
                  value: NotebookFormat.board,
                  icon: Icon(Icons.all_inclusive),
                  label: Text('Infinito'),
                ),
              ],
              selected: {format},
              onSelectionChanged: (v) => setState(() => format = v.first),
            ),
            const SizedBox(height: 8),
            Text(
              format == NotebookFormat.board
                  ? 'Um quadro sem páginas e sem bordas.'
                  : 'Páginas A4 em coluna.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, (name: ctrl.text, format: format)),
            child: const Text('Criar'),
          ),
        ],
      ),
    ),
  );
}
