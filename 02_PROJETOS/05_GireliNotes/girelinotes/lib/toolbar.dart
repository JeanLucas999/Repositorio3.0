import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'dialogs.dart';
import 'models.dart';

/// Barra minimalista: voltar, nome do caderno, 4 ferramentas, bolinha de cor,
/// desfazer/refazer e um menu "mais". Tocar na ferramenta ativa (ou na bolinha)
/// abre a linha de cor e espessura.
class NotasToolbar extends StatelessWidget {
  const NotasToolbar({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onRename,
    required this.onSettings,
  });

  final CanvasController controller;
  final VoidCallback onBack;
  final VoidCallback onRename;
  final VoidCallback onSettings;

  static String _bgName(PageBackground b) {
    switch (b) {
      case PageBackground.blank:
        return 'liso';
      case PageBackground.ruled:
        return 'pautado';
      case PageBackground.grid:
        return 'quadriculado';
    }
  }

  Future<void> _onMenu(BuildContext context, String v) async {
    final c = controller;
    switch (v) {
      case 'bg':
        c.cycleBackground();
      case 'fit':
        c.requestFit();
      case 'new':
        c.addPage();
      case 'del':
        final ok = await confirmDialog(
          context,
          title: 'Excluir página?',
          message: 'Essa ação não pode ser desfeita.',
        );
        if (ok) c.deletePage();
      case 'settings':
        onSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final c = controller;

          final tools = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolButton(
                icon: Icons.edit,
                tooltip: 'Caneta (P)',
                selected: c.tool == Tool.pen,
                onTap: () => c.selectTool(Tool.pen),
              ),
              _ToolButton(
                icon: Icons.border_color,
                tooltip: 'Marca-texto (H)',
                selected: c.tool == Tool.highlighter,
                onTap: () => c.selectTool(Tool.highlighter),
              ),
              _ToolButton(
                icon: Icons.horizontal_rule,
                tooltip: 'Linha reta (L)',
                selected: c.tool == Tool.line,
                onTap: () => c.selectTool(Tool.line),
              ),
              _ToolButton(
                icon: Icons.auto_fix_normal,
                tooltip: 'Borracha (E)',
                selected: c.tool == Tool.eraser,
                onTap: () => c.selectTool(Tool.eraser),
              ),
              if (c.hasOptions)
                Tooltip(
                  message: 'Cor e espessura',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: c.toggleOptions,
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Color(c.color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.showOptions ? scheme.primary : scheme.outlineVariant,
                            width: c.showOptions ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              _ToolButton(
                icon: Icons.undo,
                tooltip: 'Desfazer (Ctrl+Z)',
                selected: false,
                onTap: c.canUndo ? c.undo : null,
              ),
              _ToolButton(
                icon: Icons.redo,
                tooltip: 'Refazer (Ctrl+Y)',
                selected: false,
                onTap: c.canRedo ? c.redo : null,
              ),
              PopupMenuButton<String>(
                tooltip: 'Mais',
                icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
                onSelected: (v) => _onMenu(context, v),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'bg',
                    child: Text('Fundo: ${_bgName(c.page.background)}'),
                  ),
                  const PopupMenuItem(value: 'fit', child: Text('Ajustar à tela')),
                  const PopupMenuItem(value: 'new', child: Text('Nova página')),
                  const PopupMenuItem(value: 'del', child: Text('Excluir página')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'settings', child: Text('Configurações')),
                ],
              ),
            ],
          );

          return LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth >= 720;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Biblioteca',
                          icon: const Icon(Icons.arrow_back),
                          onPressed: onBack,
                        ),
                        if (wide)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: onRename,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Text(
                                    c.notebook.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (wide)
                          tools
                        else
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: tools,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.topCenter,
                  child: (c.showOptions && c.hasOptions)
                      ? _OptionsRow(controller: c)
                      : const SizedBox(width: double.infinity),
                ),
                Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              ],
            );
          });
        },
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final color = selected
        ? scheme.primary
        : (enabled ? scheme.onSurfaceVariant : scheme.onSurface.withAlpha(70));
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? scheme.primary.withAlpha(36) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}

class _OptionsRow extends StatelessWidget {
  const _OptionsRow({required this.controller});
  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = controller;
    final w = c.width.clamp(c.minWidth, c.maxWidth).toDouble();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final argb in c.palette)
            GestureDetector(
              onTap: () => c.setColor(argb),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Color(argb),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.color == argb ? scheme.primary : scheme.outlineVariant,
                    width: c.color == argb ? 3 : 1,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: Slider(
              min: c.minWidth,
              max: c.maxWidth,
              value: w,
              onChanged: c.setWidth,
            ),
          ),
          // Pré-visualização da espessura.
          SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Container(
                width: (w * (c.isHighlighter ? 2.0 : 2.4)).clamp(3.0, 34.0).toDouble(),
                height: (w * (c.isHighlighter ? 2.0 : 2.4)).clamp(3.0, 34.0).toDouble(),
                decoration: BoxDecoration(
                  color: Color(c.color).withAlpha(c.isHighlighter ? 140 : 255),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
