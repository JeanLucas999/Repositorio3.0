import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'color_utils.dart';

/// Painel flutuante de cores: círculo cromático + brilho, paleta extra e
/// as últimas cores usadas. Flutua sobre a página (não empurra o desenho)
/// e fecha sozinho quando você começa a desenhar.
class ColorPanel extends StatelessWidget {
  const ColorPanel({super.key, required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final recents = c.settings.recentColors;
        return Material(
          elevation: 8,
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 18,
              runSpacing: 14,
              children: [
                ColorWheel(
                  size: 132,
                  argb: c.color,
                  onChanged: (v) => c.pickColor(v, remember: false),
                  onEnd: () => c.pickColor(c.color),
                ),
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final argb in c.morePalette)
                            _Dot(
                              argb: argb,
                              selected: c.color == argb,
                              onTap: () => c.pickColor(argb),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Arraste uma cor para a barra para trocá-la',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant.withAlpha(170),
                            ),
                      ),
                      if (recents.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: scheme.outlineVariant),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final argb in recents)
                              _Dot(
                                argb: argb,
                                selected: c.color == argb,
                                onTap: () => c.pickColor(argb),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.argb, required this.selected, required this.onTap});

  final int argb;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget dot() => Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Color(argb),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
        );
    // Arraste para a barra principal para trocar uma das cores dela.
    return Draggable<int>(
      data: argb,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.translate(
          offset: const Offset(-17, -17),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Color(argb),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: dot()),
      child: GestureDetector(onTap: onTap, child: dot()),
    );
  }
}

/// Círculo cromático: o ângulo escolhe o matiz, a distância do centro a
/// saturação; o controle abaixo ajusta o brilho.
class ColorWheel extends StatefulWidget {
  const ColorWheel({
    super.key,
    required this.argb,
    required this.onChanged,
    this.onEnd,
    this.size = 132,
  });

  final int argb;
  final ValueChanged<int> onChanged;

  /// Chamado quando o dedo/caneta solta (para guardar a cor nas recentes).
  final VoidCallback? onEnd;
  final double size;

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  late double _h, _s, _v;
  late int _lastEmitted;

  @override
  void initState() {
    super.initState();
    _load(widget.argb);
  }

  @override
  void didUpdateWidget(ColorWheel old) {
    super.didUpdateWidget(old);
    // Cor trocada de fora (paleta, recentes): reposiciona o marcador.
    if (widget.argb != _lastEmitted) _load(widget.argb);
  }

  void _load(int argb) {
    final hsv = argbToHsv(argb);
    _h = hsv[0];
    _s = hsv[1];
    _v = hsv[2];
    _lastEmitted = argb;
  }

  void _emit() {
    _lastEmitted = hsvToArgb(_h, _s, _v);
    widget.onChanged(_lastEmitted);
  }

  void _pick(Offset local) {
    final r = widget.size / 2;
    final d = local - Offset(r, r);
    setState(() {
      _s = (d.distance / r).clamp(0.0, 1.0).toDouble();
      _h = (math.atan2(d.dy, d.dx) * 180 / math.pi + 360) % 360;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size;
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: (d) => _pick(d.localPosition),
            onTapUp: (_) => widget.onEnd?.call(),
            onPanStart: (d) => _pick(d.localPosition),
            onPanUpdate: (d) => _pick(d.localPosition),
            onPanEnd: (_) => widget.onEnd?.call(),
            child: CustomPaint(
              size: Size(size, size),
              painter: _WheelPainter(
                h: _h,
                s: _s,
                v: _v,
                thumbColor: hsvToArgb(_h, _s, _v),
                ring: scheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 28,
            child: Slider(
              value: _v,
              onChanged: (x) {
                setState(() => _v = x);
                _emit();
              },
              onChangeEnd: (_) => widget.onEnd?.call(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.h,
    required this.s,
    required this.v,
    required this.thumbColor,
    required this.ring,
  });

  final double h, s, v;
  final int thumbColor;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final rect = Rect.fromCircle(center: center, radius: r);

    // matiz (varredura 0°..360°, começando em 3 horas, no sentido horário)
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [for (var i = 0; i <= 6; i++) Color(hsvToArgb(i * 60.0, 1, 1))],
        ).createShader(rect),
    );
    // saturação: branco no centro, some até a borda
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );
    // brilho: escurece o disco todo
    canvas.drawCircle(
      center,
      r,
      Paint()..color = Color.fromARGB(((1 - v) * 255).round(), 0, 0, 0),
    );
    canvas.drawCircle(
      center,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ring,
    );

    // marcador
    final a = h * math.pi / 180;
    final tp = center + Offset(math.cos(a), math.sin(a)) * (s * r);
    canvas.drawCircle(tp, 9, Paint()..color = Color(thumbColor));
    canvas.drawCircle(
      tp,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
    canvas.drawCircle(
      tp,
      10.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black26,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.h != h || old.s != s || old.v != v || old.ring != ring;
}
