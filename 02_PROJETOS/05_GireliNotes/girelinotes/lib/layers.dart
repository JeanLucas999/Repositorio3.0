import 'models.dart';
import 'page_image.dart';

/// Instante (µs) em que o traço foi criado, lido do id (`"<µs>-<n>"`).
/// Traços sem esse formato valem 0 (ficam abaixo de qualquer imagem).
int strokeTime(Stroke s) => s.t;

/// Imagens "da frente" da página, da mais antiga para a mais nova.
List<PageImage> frontImages(NotePage pg) =>
    pg.images.where((m) => m.front).toList()..sort((a, b) => a.z.compareTo(b.z));

/// Camada do traço: quantas imagens da frente foram colocadas antes dele.
/// Camada 0 = abaixo de todas; o que se escreve depois da imagem fica acima dela.
int strokeLayer(Stroke s, List<PageImage> front) {
  var k = 0;
  for (final im in front) {
    if (im.z < s.t) k++;
  }
  return k;
}
