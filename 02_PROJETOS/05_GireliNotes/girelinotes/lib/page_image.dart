import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

/// Cores pastel dos post-its.
const List<int> kNoteColors = [
  0xFFFFF59D, 0xFFF8BBD0, 0xFFBBDEFB, 0xFFC8E6C9, 0xFFFFE0B2, 0xFFE1BEE7,
];

/// Tamanhos de texto do post-it (unidades da página): pequeno, médio, grande.
const List<double> kNoteSizes = [18, 26, 38];

/// Imagem ou post-it colocado numa página (coordenadas da página). Os dois
/// compartilham seleção, mover, redimensionar, camada, cópia e desfazer.
/// É post-it quando [text] não é nulo.
class PageImage {
  PageImage({
    required this.id,
    required this.bytes,
    required this.rect,
    this.front = true,
    int? z,
    this.text,
    this.noteColor = 0xFFFFF59D,
    this.fontSize = 26,
  }) : z = z ?? DateTime.now().microsecondsSinceEpoch;

  /// Post-it: texto digitado, cor do papel e tamanho da letra.
  String? text;
  int noteColor;
  double fontSize;
  bool get isNote => text != null;

  TextPainter? _tp;
  String _tpKey = '';

  /// Texto já medido para a largura atual (guardado até algo mudar).
  TextPainter notePainter() {
    final pad = fontSize * 0.6;
    final w = math.max(10.0, rect.width - 2 * pad);
    final key = '${text ?? ''}|$fontSize|${w.round()}';
    if (_tp == null || key != _tpKey) {
      _tp = TextPainter(
        text: TextSpan(
          text: text ?? '',
          style: TextStyle(color: const ui.Color(0xFF3A3A3A), fontSize: fontSize, height: 1.25),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: w);
      _tpKey = key;
    }
    return _tp!;
  }

  final String id;
  final Uint8List bytes; // PNG ou JPEG
  ui.Rect rect;

  /// Camada: true = na frente de tudo (padrão); false = atrás da tinta.
  bool front;

  /// Instante (µs) em que foi para a frente: só o que foi desenhado ANTES
  /// fica abaixo dela; o que vier depois sempre fica por cima.
  int z;

  ui.Image? image;
  bool _loading = false;
  String? _b64;

  /// Decodifica uma vez; [onReady] é chamado quando a imagem puder ser desenhada.
  void ensureDecoded(ui.VoidCallback onReady) {
    if (image != null || _loading) return;
    _loading = true;
    () async {
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        image = frame.image;
        onReady();
      } catch (_) {
        // imagem ilegível: fica sem desenhar
      }
    }();
  }

  static double _r(double v) => (v * 100).roundToDouble() / 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': _r(rect.left),
        'y': _r(rect.top),
        'w': _r(rect.width),
        'h': _r(rect.height),
        if (!front) 'back': true,
        'z': z,
        if (isNote) ...{
          'tx': text,
          'nc': noteColor,
          'fs': fontSize,
        } else
          'd': _b64 ??= base64Encode(bytes),
      };

  static PageImage? fromJson(Map<String, dynamic> j) {
    try {
      final note = j['tx'] is String;
      final d = note ? '' : j['d'] as String;
      final w = (j['w'] as num).toDouble(), h = (j['h'] as num).toDouble();
      if (w <= 0 || h <= 0) return null;
      final im = PageImage(
        id: j['id'] as String? ?? 'img',
        bytes: note ? Uint8List(0) : base64Decode(d),
        text: note ? j['tx'] as String : null,
        noteColor: (j['nc'] as num?)?.toInt() ?? 0xFFFFF59D,
        fontSize: (j['fs'] as num?)?.toDouble() ?? 26,
        front: j['back'] != true,
        z: (j['z'] as num?)?.toInt() ?? 0,
        rect: ui.Rect.fromLTWH((j['x'] as num).toDouble(), (j['y'] as num).toDouble(), w, h),
      );
      im._b64 = d;
      return im;
    } catch (_) {
      return null;
    }
  }
}

/// Desenha as imagens da página (já com o canvas na origem dela).
void paintImages(ui.Canvas canvas, Iterable<PageImage> images, ui.VoidCallback onReady,
    {ui.Rect? visible}) {
  for (final im in images) {
    if (visible != null && !im.rect.overlaps(visible)) continue;
    if (im.isNote) {
      paintNote(canvas, im);
      continue;
    }
    final img = im.image;
    if (img == null) {
      im.ensureDecoded(onReady);
      continue;
    }
    canvas.drawImageRect(
      img,
      ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      im.rect,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..isAntiAlias = true,
    );
  }
}

/// Fundo de PDF da página (sempre abaixo de tudo).
void paintPdfBg(ui.Canvas canvas, PageImage? bg, ui.VoidCallback onReady) {
  if (bg != null) paintImages(canvas, [bg], onReady);
}

/// Desenha o post-it: papel arredondado com sombra e o texto por dentro.
void paintNote(ui.Canvas canvas, PageImage n, {bool shadow = true}) {
  final rr = ui.RRect.fromRectAndRadius(n.rect, const ui.Radius.circular(8));
  if (shadow) {
    canvas.drawShadow(ui.Path()..addRRect(rr), const ui.Color(0xFF000000), 3, false);
  }
  canvas.drawRRect(rr, ui.Paint()..color = ui.Color(n.noteColor));
  final pad = n.fontSize * 0.6;
  canvas.save();
  canvas.clipRRect(rr);
  n.notePainter().paint(canvas, ui.Offset(n.rect.left + pad, n.rect.top + pad));
  canvas.restore();
}

/// Post-it como PNG transparente (para o PDF), em [scale] pixels por unidade.
Future<Uint8List?> renderNotePng(PageImage n, {double scale = 2}) async {
  try {
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    canvas.scale(scale);
    canvas.translate(-n.rect.left, -n.rect.top);
    paintNote(canvas, n, shadow: false);
    final img = await rec.endRecording().toImage(
          math.max(1, (n.rect.width * scale).round()),
          math.max(1, (n.rect.height * scale).round()),
        );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

bool _isPngOrJpeg(Uint8List b) =>
    b.length > 4 &&
    ((b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) ||
        (b[0] == 0xFF && b[1] == 0xD8));

/// Valida a imagem, reduz se passar de [maxSide] px e converte para PNG quando
/// não for PNG/JPEG (para o PDF e o arquivo ficarem leves e compatíveis).
/// Retorna os bytes finais e o tamanho em pixels, ou null se não for imagem.
Future<(Uint8List, ui.Size)?> prepareImage(Uint8List raw, {int maxSide = 1600}) async {
  try {
    final codec = await ui.instantiateImageCodec(raw);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final w = img.width, h = img.height;
    if (w <= 0 || h <= 0) return null;
    final m = math.max(w, h);
    if (m <= maxSide && _isPngOrJpeg(raw)) {
      return (raw, ui.Size(w.toDouble(), h.toDouble()));
    }
    final k = m > maxSide ? maxSide / m : 1.0;
    final tw = math.max(1, (w * k).round()), th = math.max(1, (h * k).round());
    final rec = ui.PictureRecorder();
    ui.Canvas(rec).drawImageRect(
      img,
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Rect.fromLTWH(0, 0, tw.toDouble(), th.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final small = await rec.endRecording().toImage(tw, th);
    final data = await small.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return (data.buffer.asUint8List(), ui.Size(tw.toDouble(), th.toDouble()));
  } catch (_) {
    return null;
  }
}
