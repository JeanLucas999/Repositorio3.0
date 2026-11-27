import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'color_panel.dart';
import 'color_utils.dart';
import 'drive_auth.dart';
import 'drive_tile.dart';
import 'settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings, this.onBackup, this.onRestore});

  final AppSettings settings;

  /// Backup completo e restauração (só a biblioteca oferece).
  final VoidCallback? onBackup;
  final VoidCallback? onRestore;

  Future<void> _captureKey(BuildContext context) async {
    final id = await showDialog<int>(
      context: context,
      builder: (_) => const _KeyCaptureDialog(),
    );
    if (id != null) settings.update(() => settings.panKeyId = id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Aparência'),
              Tab(text: 'Caneta'),
              Tab(text: 'Cadernos'),
              Tab(text: 'Formas e gestos'),
              Tab(text: 'Backup e Drive'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            final s = settings;
            return TabBarView(
              children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SegmentedButton<ThemePref>(
                  segments: const [
                    ButtonSegment(
                      value: ThemePref.system,
                      label: Text('Sistema'),
                      icon: Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: ThemePref.light,
                      label: Text('Claro'),
                      icon: Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemePref.dark,
                      label: Text('Escuro'),
                      icon: Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {s.theme},
                  onSelectionChanged: (v) => s.update(() => s.theme = v.first),
                ),
              ),
              ListTile(
                title: const Text('Estilo do app'),
                subtitle: Text('${s.style.label} — ${s.style.description}'),
                leading: _StylePreview(style: s.style, accent: Color(s.accent)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final st = await _pickStyle(context, s.style, Color(s.accent));
                  if (st != null) s.update(() => s.style = st);
                },
              ),
              ListTile(
                title: const Text('Cor de destaque'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final a in AppSettings.accents)
                        GestureDetector(
                          onTap: () => s.update(() => s.accent = a),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color(a),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: s.accent == a ? scheme.onSurface : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: s.accent == a
                                ? const Icon(Icons.check, size: 18, color: Colors.white)
                                : null,
                          ),
                        ),
                      // qualquer outra cor: círculo cromático
                      Builder(builder: (context) {
                        final custom = !AppSettings.accents.contains(s.accent);
                        return Tooltip(
                          message: 'Outra cor…',
                          child: GestureDetector(
                            onTap: () async {
                              final c = await _pickAccent(context, s.accent);
                              if (c != null) s.update(() => s.accent = c);
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: custom ? Color(s.accent) : null,
                                gradient: custom
                                    ? null
                                    : SweepGradient(colors: [
                                        for (var i = 0; i <= 6; i++)
                                          Color(hsvToArgb(i * 60.0, 0.85, 1)),
                                      ]),
                                border: Border.all(
                                  color: custom ? scheme.onSurface : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Icon(custom ? Icons.check : Icons.colorize,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
              SwitchListTile(
                title: const Text('Rejeição de palma'),
                subtitle: const Text(
                    'Ignora toques enquanto a caneta está encostando ou perto da tela, '
                    'e contatos grandes demais para um dedo.'),
                value: s.palmRejection,
                onChanged: (v) => s.update(() => s.palmRejection = v),
              ),
              _SliderTile(
                title: 'Proteção depois da caneta',
                valueText: '${s.palmGuardMs} ms',
                min: 200,
                max: 1500,
                divisions: 13,
                value: s.palmGuardMs.toDouble(),
                onChanged: s.palmRejection
                    ? (v) => s.update(() => s.palmGuardMs = v.round())
                    : null,
              ),
              _SliderTile(
                title: 'Tamanho de toque considerado palma',
                valueText: s.palmRadius.round().toString(),
                min: 15,
                max: 60,
                divisions: 45,
                value: s.palmRadius,
                onChanged: s.palmRejection
                    ? (v) => s.update(() => s.palmRadius = v.roundToDouble())
                    : null,
              ),
              SwitchListTile(
                title: const Text('Desenhar com o dedo'),
                subtitle: const Text('Desligado: o dedo só rola e dá zoom.'),
                value: s.fingerDraws,
                onChanged: (v) => s.update(() => s.fingerDraws = v),
              ),
              ListTile(
                title: const Text('Posição da barra'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<ToolbarPos>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: ToolbarPos.top, label: Text('Cima')),
                      ButtonSegment(value: ToolbarPos.bottom, label: Text('Baixo')),
                      ButtonSegment(value: ToolbarPos.left, label: Text('Esquerda')),
                      ButtonSegment(value: ToolbarPos.right, label: Text('Direita')),
                    ],
                    selected: {s.toolbarPos},
                    onSelectionChanged: (v) => s.update(() => s.toolbarPos = v.first),
                  ),
                ),
              ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
              _SliderTile(
                title: 'Espaçamento de linhas e quadriculado',
                valueText: '${s.lineSpacing.round()}',
                min: 20,
                max: 80,
                divisions: 12,
                value: s.lineSpacing,
                onChanged: (v) => s.update(() => s.lineSpacing = v.roundToDouble()),
              ),
              ListTile(
                title: const Text('Fundo dos cadernos novos'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Liso')),
                      ButtonSegment(value: 1, label: Text('Pautado')),
                      ButtonSegment(value: 2, label: Text('Quadriculado')),
                    ],
                    selected: {s.newNotebookBackground},
                    onSelectionChanged: (v) =>
                        s.update(() => s.newNotebookBackground = v.first),
                  ),
                ),
              ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
              SwitchListTile(
                title: const Text('Segurar a caneta encaixa reta/forma'),
                value: s.autoShape,
                onChanged: (v) => s.update(() => s.autoShape = v),
              ),
              _SliderTile(
                title: 'Tempo parado para encaixar',
                valueText: '${s.holdMs} ms',
                min: 300,
                max: 1000,
                divisions: 14,
                value: s.holdMs.toDouble().clamp(300.0, 1000.0).toDouble(),
                onChanged: s.autoShape ? (v) => s.update(() => s.holdMs = v.round()) : null,
              ),
              SwitchListTile(
                title: const Text('Riscar por cima apaga'),
                subtitle: const Text('Zigue-zague de 6 passadas ou mais sobre o objeto.'),
                value: s.scribbleErase,
                onChanged: (v) => s.update(() => s.scribbleErase = v),
              ),
              ListTile(
                title: const Text('Tecla da mãozinha'),
                subtitle: const Text('Segure para mover a página com a caneta.'),
                trailing: Text(
                  keyLabelPt(s.panKeyId),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: scheme.primary),
                ),
                onTap: () => _captureKey(context),
              ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
              if (onBackup != null || onRestore != null) ...[
                const _Section('Backup'),
                if (onBackup != null)
                  ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: const Text('Fazer backup completo'),
                    subtitle: const Text('Todos os cadernos e pastas, em .notas ou PDF'),
                    onTap: onBackup,
                  ),
                if (onRestore != null)
                  ListTile(
                    leading: const Icon(Icons.unarchive_outlined),
                    title: const Text('Restaurar backup'),
                    subtitle: const Text('Lê um backup em .notas (.zip)'),
                    onTap: onRestore,
                  ),
              ],
              const _Section('Google Drive'),
              DriveSection(auth: driveAuth),
                ],
              ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.valueText,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.divisions,
  });

  final String title;
  final String valueText;
  final double min;
  final double max;
  final double value;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(title)),
          Text(valueText, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
      subtitle: Slider(
        min: min,
        max: max,
        divisions: divisions,
        value: value.clamp(min, max).toDouble(),
        onChanged: onChanged,
      ),
    );
  }
}


/// Espera o usuário apertar a tecla que será a da mãozinha.
class _KeyCaptureDialog extends StatefulWidget {
  const _KeyCaptureDialog();

  @override
  State<_KeyCaptureDialog> createState() => _KeyCaptureDialogState();
}

class _KeyCaptureDialogState extends State<_KeyCaptureDialog> {
  bool _handler(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    if (e.logicalKey == LogicalKeyboardKey.escape) return false;
    Navigator.of(context).pop(e.logicalKey.keyId);
    return true;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aperte a tecla'),
      content: const Text('Qualquer tecla do teclado vira a mãozinha.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(AppSettings.defaultPanKey),
          child: const Text('Espaço (padrão)'),
        ),
      ],
    );
  }
}


/// Janela com o círculo cromático para escolher qualquer cor de destaque.
Future<int?> _pickAccent(BuildContext context, int current) {
  var c = current | 0xFF000000;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Cor de destaque'),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorWheel(argb: c, size: 220, onChanged: (v) => setS(() => c = v)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text('#${(c & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c), child: const Text('Usar')),
        ],
      ),
    ),
  );
}


/// Miniatura de um estilo: fundo, "cartão" e uma pílula na cor de destaque.
class _StylePreview extends StatelessWidget {
  const _StylePreview({required this.style, required this.accent});

  final AppStyle style;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final br = Theme.of(context).brightness;
    final sf = styleSurfaces(style, br, accent);
    final r = style.radius.clamp(3.0, 12.0).toDouble();
    return Container(
      width: 54,
      height: 40,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: sf?.bg ?? scheme.surface,
        borderRadius: BorderRadius.circular(r + 2),
        border: Border.all(color: sf?.outline ?? scheme.outlineVariant),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sf?.high ?? scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(r),
        ),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 20,
          height: 6,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(style == AppStyle.grafite ? 2 : 4),
          ),
        ),
      ),
    );
  }
}

/// Lista de estilos para escolher.
Future<AppStyle?> _pickStyle(BuildContext context, AppStyle current, Color accent) {
  return showDialog<AppStyle>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Estilo do app'),
      children: [
        for (final st in AppStyle.values)
          ListTile(
            leading: _StylePreview(style: st, accent: accent),
            title: Text(st.label),
            subtitle: Text(st.description),
            trailing: st == current ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(ctx, st),
          ),
      ],
    ),
  );
}
