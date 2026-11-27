import 'package:flutter/material.dart';

/// Estilos visuais do app. Cada um muda fundos, superfícies, formato dos
/// botões, bordas e fonte; a COR DE DESTAQUE continua vindo das configurações
/// (botões, seleção, realces), então os dois combinam em qualquer escolha.
/// A folha do caderno não depende do estilo.
enum AppStyle { padrao, papel, grafite, meiaNoite, pastel, contraste }

extension AppStyleInfo on AppStyle {
  String get label => switch (this) {
        AppStyle.padrao => 'Padrão',
        AppStyle.papel => 'Papel',
        AppStyle.grafite => 'Grafite',
        AppStyle.meiaNoite => 'Meia-noite',
        AppStyle.pastel => 'Pastel',
        AppStyle.contraste => 'Contraste',
      };

  String get description => switch (this) {
        AppStyle.padrao => 'Material, limpo e neutro.',
        AppStyle.papel => 'Tons de papel, fonte com serifa, cantos suaves.',
        AppStyle.grafite => 'Cinza sóbrio, cantos retos, sem enfeite.',
        AppStyle.meiaNoite => 'Preto puro (sempre escuro), ideal para telas OLED.',
        AppStyle.pastel => 'Cores suaves tingidas pelo destaque, bem arredondado.',
        AppStyle.contraste => 'Bordas marcadas e preto/branco, para leitura fácil.',
      };

  /// Raio dos cantos de botões e componentes.
  double get radius => switch (this) {
        AppStyle.padrao => 20,
        AppStyle.papel => 8,
        AppStyle.grafite => 3,
        AppStyle.meiaNoite => 14,
        AppStyle.pastel => 28,
        AppStyle.contraste => 6,
      };

  bool get forceDark => this == AppStyle.meiaNoite;
}

/// Cores de fundo/superfície de um estilo.
class StyleSurfaces {
  const StyleSurfaces({
    required this.bg,
    required this.low,
    required this.high,
    required this.text,
    this.outline,
  });
  final Color bg, low, high, text;
  final Color? outline;
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Superfícies do [style] (null no estilo padrão, que usa as do Material).
StyleSurfaces? styleSurfaces(AppStyle style, Brightness br, Color accent) {
  final dark = br == Brightness.dark || style.forceDark;
  switch (style) {
    case AppStyle.padrao:
      return null;
    case AppStyle.papel:
      return dark
          ? const StyleSurfaces(
              bg: Color(0xFF241C14), low: Color(0xFF2B2218), high: Color(0xFF362B1F), text: Color(0xFFEADFCB))
          : const StyleSurfaces(
              bg: Color(0xFFF3EBDD), low: Color(0xFFEFE5D1), high: Color(0xFFFBF6EA), text: Color(0xFF3B2F23));
    case AppStyle.grafite:
      return dark
          ? const StyleSurfaces(
              bg: Color(0xFF1B1F23), low: Color(0xFF22272C), high: Color(0xFF2B3238), text: Color(0xFFDDE2E6))
          : const StyleSurfaces(
              bg: Color(0xFFEEF0F2), low: Color(0xFFE4E7EA), high: Color(0xFFF8F9FA), text: Color(0xFF22282D));
    case AppStyle.meiaNoite:
      return const StyleSurfaces(
          bg: Color(0xFF000000), low: Color(0xFF0A0A0C), high: Color(0xFF151518), text: Color(0xFFF2F2F2));
    case AppStyle.pastel:
      return dark
          ? StyleSurfaces(
              bg: _mix(const Color(0xFF1A1A20), accent, 0.10),
              low: _mix(const Color(0xFF1F1F26), accent, 0.14),
              high: _mix(const Color(0xFF26262E), accent, 0.20),
              text: const Color(0xFFEDEDF4))
          : StyleSurfaces(
              bg: _mix(Colors.white, accent, 0.09),
              low: _mix(Colors.white, accent, 0.06),
              high: _mix(Colors.white, accent, 0.16),
              text: const Color(0xFF2B2B33));
    case AppStyle.contraste:
      return dark
          ? const StyleSurfaces(
              bg: Color(0xFF000000),
              low: Color(0xFF0B0B0B),
              high: Color(0xFF1A1A1A),
              text: Color(0xFFFFFFFF),
              outline: Color(0xFFFFFFFF))
          : const StyleSurfaces(
              bg: Color(0xFFFFFFFF),
              low: Color(0xFFF2F2F2),
              high: Color(0xFFE6E6E6),
              text: Color(0xFF000000),
              outline: Color(0xFF000000));
  }
}

ThemeData buildStyledTheme(Brightness brightness, int accent, AppStyle style) {
  final br = style.forceDark ? Brightness.dark : brightness;
  var scheme = ColorScheme.fromSeed(
    seedColor: Color(accent),
    brightness: br,
    contrastLevel: style == AppStyle.contraste ? 1.0 : 0.0,
  );
  final sf = styleSurfaces(style, br, Color(accent));
  if (sf != null) {
    scheme = scheme.copyWith(
      surface: sf.bg,
      onSurface: sf.text,
      onSurfaceVariant: _mix(sf.text, sf.bg, 0.25),
      surfaceContainerLowest: _mix(sf.bg, sf.low, 0.5),
      surfaceContainerLow: sf.low,
      surfaceContainer: _mix(sf.low, sf.high, 0.5),
      surfaceContainerHigh: sf.high,
      surfaceContainerHighest: _mix(sf.high, sf.text, 0.06),
      outline: sf.outline ?? _mix(sf.text, sf.bg, 0.55),
      outlineVariant: sf.outline != null ? sf.outline!.withAlpha(150) : _mix(sf.text, sf.bg, 0.8),
    );
  }

  final r = style.radius;
  final stadium = style == AppStyle.pastel || style == AppStyle.padrao;
  OutlinedBorder shape() => stadium
      ? const StadiumBorder()
      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
  final border = style == AppStyle.contraste ? BorderSide(color: scheme.outline, width: 2) : null;

  final (String? family, List<String>? fallback) = switch (style) {
    AppStyle.papel => ('Georgia', ['Cambria', 'Times New Roman', 'serif']),
    AppStyle.pastel => ('Trebuchet MS', ['Segoe UI', 'Roboto', 'sans-serif']),
    AppStyle.grafite => ('Segoe UI', ['Roboto', 'sans-serif']),
    _ => (null, null),
  };

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: family,
    fontFamilyFallback: fallback,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: shape(), side: border)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: shape(), side: border)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: shape())),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: shape())),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: stadium
          ? const StadiumBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(r + 4)),
    ),
    chipTheme: ChipThemeData(shape: shape(), side: border),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(stadium ? 18 : r),
          side: border ?? BorderSide.none),
    ),
  );
}
