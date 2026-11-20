import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'dialogs.dart';
import 'models.dart';
import 'settings.dart';
import 'shape_bar.dart';

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
    required this.onPages,
    required this.pagesOpen,
  });

  final CanvasController controller;
  final VoidCallback onBack;
  final VoidCallback onRename;
  final VoidCallback onSettings;
  final VoidCallback onPages;
  final bool pagesOpen;

  static IconData _penIcon(Tool t) => switch (t) {
        Tool.fountain => Icons.draw,
        Tool.smart => Icons.auto_fix_high,
        _ => Icons.edit,
      };

  static String _penName(Tool t) => switch (t) {
        Tool.fountain => 'Caneta tinteiro',
        Tool.smart => 'Caneta de formas',
        _ => 'Caneta',
      };

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
              // Um único botão de caneta: o ícone mostra a caneta em uso e o toque
              // abre a subaba para trocar de tipo (o marca-texto fica de fora).
              _ToolButton(
                icon: _penIcon(c.isPenTool ? c.tool : c.lastPen),
                tooltip: '${_penName(c.isPenTool ? c.tool : c.lastPen)} (P / F) — '
                    'toque para trocar de caneta',
                selected: c.isPenTool,
                badge: true,
                onTap: c.selectPen,
              ),
              _ToolButton(
                icon: Icons.border_color,
                tooltip: 'Marca-texto (H)',
                selected: c.tool == Tool.highlighter,
                badge: true,
                onTap: () => c.selectTool(Tool.highlighter),
              ),
              _ToolButton(
                icon: ShapeBar.iconFor(c.shapeKind),
                tooltip: 'Formas (L) — ${ShapeBar.nameFor(c.shapeKind)}',
                selected: c.tool == Tool.shape,
                badge: true,
                onTap: () => c.selectTool(Tool.shape),
              ),
              _ToolButton(
                icon: Icons.pan_tool_alt_outlined,
                tooltip: 'Mover página (segure ${keyLabelPt(c.settings.panKeyId)})',
                selected: c.tool == Tool.pan,
                onTap: () => c.selectTool(Tool.pan),
              ),
              _ToolButton(
                icon: Icons.circle, // substituído pelo desenho da borracha
                custom: const _EraserIcon(),
                tooltip: 'Borracha (E)',
                selected: c.tool == Tool.eraser,
                badge: true,
                onTap: () => c.selectTool(Tool.eraser),
              ),
              if (c.usesColor)
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
                  if (!c.notebook.infinite) ...const [
                    PopupMenuItem(value: 'new', child: Text('Nova página')),
                    PopupMenuItem(value: 'del', child: Text('Excluir página')),
                  ],
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
                        if (!c.notebook.infinite)
                        IconButton(
                          tooltip: 'Páginas',
                          icon: Icon(
                            pagesOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                            color: pagesOpen ? scheme.primary : null,
                          ),
                          onPressed: onPages,
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
                  child: c.showOptions
                      ? (c.tool == Tool.eraser
                          ? _EraserOptions(controller: c)
                          : _OptionsRow(controller: c))
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
    this.badge = false,
    this.custom,
  });

  /// Desenho próprio no lugar do ícone (a cor vem do IconTheme).
  final Widget? custom;
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onTap;

  /// Mostra uma setinha no canto: avisa que o botão abre uma subaba.
  final bool badge;

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
            child: Stack(
              alignment: Alignment.center,
              children: [
                custom == null
                    ? Icon(icon, size: 22, color: color)
                    : IconTheme(
                        data: IconThemeData(color: color),
                        child: custom!,
                      ),
                if (badge)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.arrow_drop_down, size: 16, color: color),
                  ),
              ],
            ),
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
          // Subaba do botão de caneta: escolher o tipo (só aparece nas canetas).
          if (c.isPenTool) ...[
            ChoiceChip(
              avatar: const Icon(Icons.edit, size: 18),
              label: const Text('Caneta'),
              selected: c.tool == Tool.pen,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => c.setPenType(Tool.pen),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              avatar: const Icon(Icons.draw, size: 18),
              label: const Text('Tinteiro'),
              selected: c.tool == Tool.fountain,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => c.setPenType(Tool.fountain),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              avatar: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Formas'),
              selected: c.tool == Tool.smart,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => c.setPenType(Tool.smart),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 28,
              child: VerticalDivider(width: 1, thickness: 1, color: scheme.outlineVariant),
            ),
            const SizedBox(width: 12),
          ],
          for (var i = 0; i < c.palette.length; i++)
            _PaletteDot(
              argb: c.palette[i],
              selected: c.color == c.palette[i],
              onTap: () => c.setColor(c.palette[i]),
              onDrop: (v) => c.replacePaletteColor(i, v),
            ),
          // Mais cores: abre o painel com círculo cromático.
          Tooltip(
            message: 'Mais cores',
            child: GestureDetector(
              onTap: c.toggleColors,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(colors: [
                    Color(0xFFFF3B30),
                    Color(0xFFFFCC00),
                    Color(0xFF34C759),
                    Color(0xFF00C7FF),
                    Color(0xFF5856D6),
                    Color(0xFFFF2D92),
                    Color(0xFFFF3B30),
                  ]),
                  border: Border.all(
                    color: c.showColors ? scheme.primary : scheme.outlineVariant,
                    width: c.showColors ? 3 : 1,
                  ),
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

/// Opções da borracha: modo (apagar o traço inteiro ou só por onde passa) e tamanho.
class _EraserOptions extends StatelessWidget {
  const _EraserOptions({required this.controller});
  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = controller;
    final r = c.eraserRadius.clamp(3.0, 40.0).toDouble();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Traço'),
                icon: Icon(Icons.timeline, size: 18),
                tooltip: 'Apaga o traço inteiro que a borracha tocar',
              ),
              ButtonSegment(
                value: true,
                label: Text('Normal'),
                icon: Icon(Icons.circle_outlined, size: 18),
                tooltip: 'Apaga só por onde a borracha passa',
              ),
            ],
            selected: {c.eraserPixel},
            onSelectionChanged: (v) => c.setEraserPixel(v.first),
          ),
          const SizedBox(width: 16),
          Icon(Icons.circle, size: 8, color: scheme.onSurfaceVariant),
          SizedBox(
            width: 160,
            child: Slider(
              min: 3,
              max: 40,
              value: r,
              onChanged: c.setEraserSize,
            ),
          ),
          Icon(Icons.circle, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          // Pré-visualização do tamanho (proporcional ao raio).
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Container(
                width: (r * 1.0).clamp(6.0, 38.0).toDouble(),
                height: (r * 1.0).clamp(6.0, 38.0).toDouble(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.onSurfaceVariant, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Ícone de borracha: bloco inclinado com a faixa da ponta.
class _EraserIcon extends StatelessWidget {
  const _EraserIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.grey;
    return CustomPaint(size: const Size(22, 22), painter: _EraserPainter(color));
  }
}

class _EraserPainter extends CustomPainter {
  _EraserPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.7);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-9, -5, 18, 10),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(body, p);
    canvas.drawLine(const Offset(-2.5, -5), const Offset(-2.5, 5), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -5, 6.5, 10),
        const Radius.circular(2.5),
      ),
      Paint()..color = color.withAlpha(90),
    );
    canvas.restore();
    canvas.drawLine(
      Offset(size.width * 0.3, size.height - 1.5),
      Offset(size.width - 1.5, size.height - 1.5),
      p,
    );
  }

  @override
  bool shouldRepaint(_EraserPainter old) => old.color != color;
}


/// Bolinha da barra principal: aceita uma cor arrastada do painel (troca a dela)
/// com realce ao passar por cima e um "pulso" curto ao soltar.
class _PaletteDot extends StatefulWidget {
  const _PaletteDot({
    required this.argb,
    required this.selected,
    required this.onTap,
    required this.onDrop,
  });

  final int argb;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<int> onDrop;

  @override
  State<_PaletteDot> createState() => _PaletteDotState();
}

class _PaletteDotState extends State<_PaletteDot> {
  bool _pulse = false;

  void _drop(int v) {
    widget.onDrop(v);
    setState(() => _pulse = true);
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _pulse = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<int>(
      onAcceptWithDetails: (d) => _drop(d.data),
      builder: (context, candidates, _) {
        final hover = candidates.isNotEmpty;
        final incoming = hover ? candidates.first : null;
        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: hover ? 1.3 : (_pulse ? 1.18 : 1.0),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(incoming ?? widget.argb),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hover
                      ? scheme.primary
                      : (widget.selected ? scheme.primary : scheme.outlineVariant),
                  width: (hover || widget.selected) ? 3 : 1,
                ),
                boxShadow: hover
                    ? [BoxShadow(color: scheme.primary.withAlpha(90), blurRadius: 10)]
                    : const [],
              ),
            ),
          ),
        );
      },
    );
  }
}
