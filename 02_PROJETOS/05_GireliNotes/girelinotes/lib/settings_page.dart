import 'package:flutter/material.dart';

import 'settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final s = settings;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const _Section('Aparência'),
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
                    ],
                  ),
                ),
              ),
              const _Section('Caneta e palma (tablet)'),
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
              const _Section('Formas e gestos'),
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
            ],
          );
        },
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
