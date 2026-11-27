import 'package:flutter/material.dart';

import 'canvas_controller.dart';

/// Ações da seleção (flutua sobre a página): copiar, duplicar, cor, apagar.
/// Sem seleção, mostra "Colar" se houver algo copiado.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.controller,
    required this.onEditNote,
    required this.onRemoveBg,
    required this.onEditGraph,
  });
  final CanvasController controller;
  final VoidCallback onEditNote;
  final VoidCallback onRemoveBg;
  final VoidCallback onEditGraph;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        if (c.tool != Tool.select) return const SizedBox.shrink();
        final List<Widget> items;
        if (c.hasSel) {
          items = [
            if (c.selStrokes.isEmpty && c.selImages.length == 1 && c.selImages.first.isNote)
              _Btn(Icons.edit_outlined, 'Editar post-it', onEditNote),
            if (c.selStrokes.isEmpty && c.selImages.length == 1 && c.selImages.first.isGraph)
              _Btn(Icons.edit_outlined, 'Editar gráfico', onEditGraph),
            if (c.selStrokes.isEmpty &&
                c.selImages.length == 1 &&
                !c.selImages.first.isNote &&
                !c.selImages.first.isGraph)
              _Btn(Icons.auto_fix_high_outlined, 'Remover fundo', onRemoveBg),
            _Btn(Icons.copy_outlined, 'Copiar (Ctrl+C)', c.copySelection),
            _Btn(Icons.content_cut, 'Recortar (Ctrl+X)', c.cutSelection),
            _Btn(Icons.control_point_duplicate, 'Duplicar (Ctrl+D)', c.duplicateSelection),
            if (c.selStrokes.isNotEmpty)
              IconButton(
                tooltip: 'Trocar cor',
                icon: Icon(Icons.palette_outlined, color: c.showSelColors ? scheme.primary : null),
                onPressed: c.toggleSelColors,
              ),
            _Btn(Icons.delete_outline, 'Apagar (Delete)', c.deleteSelection),
          ];
        } else if (c.canPaste) {
          items = [_Btn(Icons.content_paste, 'Colar (Ctrl+V)', c.pasteSelection)];
        } else {
          return const SizedBox.shrink();
        }
        return Material(
          elevation: 6,
          color: scheme.surfaceContainerHigh,
          shape: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: items),
          ),
        );
      },
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(this.icon, this.tip, this.onTap);
  final IconData icon;
  final String tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      IconButton(tooltip: tip, icon: Icon(icon), onPressed: onTap);
}
