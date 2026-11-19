import 'package:flutter/material.dart';

import 'canvas_controller.dart';

class NotasToolbar extends StatelessWidget {
  const NotasToolbar({super.key, required this.controller});

  final CanvasController controller;

  static const _palette = [
    0xFF1A1A1A,
    0xFF1565C0,
    0xFFC62828,
    0xFF2E7D32,
    0xFFEF6C00,
    0xFF6A1B9A,
  ];

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir página?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) controller.deletePage();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      color: scheme.surface,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final c = controller;

          Widget toolBtn(IconData icon, String tip, Tool t) => IconButton(
                tooltip: tip,
                icon: Icon(icon),
                style: IconButton.styleFrom(
                  backgroundColor: c.tool == t ? scheme.primaryContainer : null,
                ),
                onPressed: () => c.setTool(t),
              );

          Widget toggleBtn(IconData icon, String tip, bool on, VoidCallback f) =>
              IconButton(
                tooltip: tip,
                icon: Icon(icon),
                style: IconButton.styleFrom(
                  backgroundColor: on ? scheme.primaryContainer : null,
                ),
                onPressed: f,
              );

          Widget colorDot(int argb) {
            final sel = c.color == argb;
            return GestureDetector(
              onTap: () => c.setColor(argb),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Color(argb),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sel ? scheme.primary : Colors.black12,
                    width: sel ? 3 : 1,
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                toolBtn(Icons.edit, 'Caneta (P)', Tool.pen),
                toolBtn(Icons.border_color, 'Marca-texto (H)', Tool.highlighter),
                toolBtn(Icons.horizontal_rule, 'Linha reta (L)', Tool.line),
                toolBtn(Icons.auto_fix_normal, 'Borracha (E)', Tool.eraser),
                const SizedBox(width: 8),
                for (final col in _palette) colorDot(col),
                SizedBox(
                  width: 110,
                  child: Slider(
                    min: 1,
                    max: 12,
                    value: c.penWidth,
                    onChanged: c.setWidth,
                  ),
                ),
                toggleBtn(Icons.auto_awesome, 'Segurar a caneta encaixa reta/forma',
                    c.autoShape, c.toggleAutoShape),
                toggleBtn(Icons.gesture, 'Riscar por cima apaga', c.scribbleErase,
                    c.toggleScribbleErase),
                toggleBtn(Icons.touch_app, 'Desenhar com o dedo', c.fingerDraws,
                    c.toggleFingerDraws),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Desfazer (Ctrl+Z)',
                  icon: const Icon(Icons.undo),
                  onPressed: c.canUndo ? c.undo : null,
                ),
                IconButton(
                  tooltip: 'Refazer (Ctrl+Y)',
                  icon: const Icon(Icons.redo),
                  onPressed: c.canRedo ? c.redo : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Fundo da página',
                  icon: const Icon(Icons.grid_on),
                  onPressed: c.cycleBackground,
                ),
                IconButton(
                  tooltip: 'Ajustar à tela',
                  icon: const Icon(Icons.fit_screen),
                  onPressed: c.requestFit,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Página anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: c.pageIndex > 0 ? () => c.goToPage(c.pageIndex - 1) : null,
                ),
                Text('${c.pageIndex + 1}/${c.notebook.pages.length}'),
                IconButton(
                  tooltip: 'Próxima página',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: c.pageIndex < c.notebook.pages.length - 1
                      ? () => c.goToPage(c.pageIndex + 1)
                      : null,
                ),
                IconButton(
                  tooltip: 'Nova página',
                  icon: const Icon(Icons.note_add),
                  onPressed: c.addPage,
                ),
                IconButton(
                  tooltip: 'Excluir página',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
