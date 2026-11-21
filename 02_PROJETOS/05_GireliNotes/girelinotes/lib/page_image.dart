import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Imagem colocada numa página (coordenadas da página). Fica atrás da tinta.
class PageImage {
  PageImage({required this.id, required this.bytes, required this.rect});

  final String id;
  final Uint8List bytes; // PNG ou JPEG
  ui.Rect rect;

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
        'd': _b64 ??= base64Encode(bytes),
      };

  static PageImage? fromJson(Map<String, dynamic> j) {
    try {
      final d = j['d'] as String;
      final w = (j['w'] as num).toDouble(), h = (j['h'] as num).toDouble();
      if (w <= 0 || h <= 0) return null;
      final im = PageImage(
        id: j['id'] as String? ?? 'img',
        bytes: base64Decode(d),
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
