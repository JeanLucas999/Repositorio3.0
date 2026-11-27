# Notas — caderno digital pessoal (Android + Windows)

Entrega A: biblioteca de cadernos, menu minimalista, tema claro/escuro com cor
de destaque configurável, marca-texto que fica atrás da tinta, palm rejection e
tela de configurações. Depois: caneta tinteiro e borracha com dois modos. A sincronização com o Google Drive é uma fase futura (o
formato de arquivo já é um JSON por caderno, pensado para isso).

> Este código foi escrito sem poder compilar nem rodar o Flutter no ambiente em
> que foi gerado. A lógica de reconhecimento de formas foi validada num port em
> Python, mas o app em si nunca foi executado: é normal aparecer algum erro de
> compilação na primeira vez. Mande a mensagem de erro que eu corrijo.

## Como rodar

1. Instale o [Flutter](https://docs.flutter.dev/get-started/install) e, para o
   Windows, o Visual Studio com a carga **"Desenvolvimento para desktop com C++"**.
   No Windows, ligue também o **Modo de Desenvolvedor** (`start ms-settings:developers`),
   senão o Flutter recusa compilar com plugins.
2. Crie um projeto novo (isso gera as pastas `android/` e `windows/`):

   ```
   flutter create --platforms=android,windows --project-name notas notas
   ```

3. Copie por cima do projeto novo, desta pasta: `lib/`, `test/` e `pubspec.yaml`.
   Se já tinha copiado a versão anterior, **apague a `lib/` antiga antes** (tem
   arquivos novos e o `main.dart` mudou).
4. Dentro do projeto:

   ```
   flutter pub get
   flutter test            # roda os testes
   flutter run -d windows  # PC
   flutter run             # tablet Android (depuração USB ligada)
   ```

   Para instalar de vez no tablet: `flutter build apk --release`.

## Telas

- **Biblioteca (tela inicial):** seus cadernos com miniatura, número de páginas e
  data. "Novo caderno", e no menu ⋮ de cada um: renomear ou excluir. O caderno
  que já existia aparece como "Meu caderno".
- **Caderno:** barra fina com voltar, nome (toque para renomear), botão de caneta,
  marca-texto, linha reta, borracha, bolinha de cor, desfazer, refazer e "⋯"
  (fundo da página, ajustar à tela, nova/excluir página, configurações).
  Tocar de novo na ferramenta ativa (ou na bolinha) abre a linha de opções:
  **cor e espessura**, ou, na borracha, **modo e tamanho**. Embaixo, a pílula flutuante de páginas (‹ 2 / 5 › +).
- **Configurações:** tema (sistema/claro/escuro), cor de destaque (azul por
  padrão), palm rejection, tempo de segurar para encaixar forma, etc.

## Como usar

| Ação | Como |
|---|---|
| Desenhar | caneta / mesa digitalizadora |
| Trocar de caneta | o botão de caneta (com uma setinha) tem uma **subaba**: com a caneta ativa, toque nele para abrir e escolha *Caneta* ou *Tinteiro*. Vindo de outra ferramenta, o primeiro toque só seleciona a última caneta usada e a subaba abre no segundo toque. O ícone do botão passa a ser o da caneta em uso. O marca-texto tem botão próprio |
| Caneta tinteiro | escolha *Tinteiro* na subaba (ou tecla F): o traço fica **mais grosso com mais pressão e quando você escreve devagar**, mais fino quando escreve rápido. Começa e termina fino. Sem pressão (mouse), só a velocidade conta. Encaixar forma e riscar para apagar funcionam como na caneta |
| Marca-texto | ferramenta marca-texto: o texto escrito continua 100% da cor dele, o amarelo fica **atrás** (mesmo se você passou o marca-texto depois) |
| Encaixar reta ou forma | desenhe e **segure a caneta parada** (0,5 s por padrão; vibra no tablet) |
| Ajustar a reta encaixada | continue arrastando; ela gruda em múltiplos de 15° |
| Formas | botão de formas (tecla L) abre uma mini barra: reta, seta, retângulo, elipse, triângulo. Arraste na página; Shift não é preciso, ângulos e quadrados "encaixam" sozinhos |
| Mais cores | bolinha arco-íris na linha de cor: círculo cromático + brilho, 30 cores extras e as 10 últimas usadas |
| Mãozinha | botão de mão (ou segure **Espaço**) e arraste com a caneta para mover a página; a tecla muda em Configurações > Formas e gestos |
| Apagar riscando | zigue-zague de **6 passadas ou mais**, cobrindo o objeto. Só some o que estiver coberto em pelo menos 60%. Se riscar sobre nada, vira tinta normal |
| Borracha | ferramenta borracha (E) ou a ponta invertida da caneta. Toque de novo na borracha para escolher o modo e o tamanho: **Traço** apaga o traço inteiro que a borracha tocar; **Normal** apaga só por onde ela passa (um traço pode ser cortado em dois). Um círculo mostra a área apagada. A varrida inteira é um único desfazer |
| Rolar / zoom | dois dedos (tablet); roda do mouse, **Ctrl + roda** para zoom (PC) |
| Desfazer / refazer | Ctrl+Z / Ctrl+Y |
| Atalhos de ferramenta | P caneta, F tinteiro, H marca-texto, L linha, E borracha |

Formas reconhecidas: reta, círculo, elipse (inclusive inclinada), retângulo,
triângulo e quadrilátero.

## Palm rejection (tablet)

Três sinais combinados, todos ajustáveis em Configurações:

1. **Caneta por perto:** enquanto a caneta está encostada, e por 600 ms depois de
   encostar ou pairar sobre a tela, os toques são ignorados (não rolam nem dão zoom).
2. **Contato grande:** toque com raio maior que 30 (pixels lógicos) é tratado
   como palma. Se um toque cresce no meio do gesto, ele é descartado.
3. **Palma antes da caneta:** se a palma já estava na tela quando a caneta
   encostou, esses toques são descartados na hora.

Limites: o Flutter não dá acesso ao filtro de palma do próprio Android, então a
precisão depende do que o seu tablet informa (tamanho do contato e se detecta a
caneta pairando). Se ainda rolar sem querer, aumente o tempo de proteção; se o
dedo for rejeitado quando não deveria, aumente o "tamanho de toque considerado
palma". Isso só dá para calibrar de verdade no seu aparelho.

## Arquivos

- `main.dart`: tema e início do app
- `library_page.dart`, `editor_page.dart`, `settings_page.dart`, `toolbar.dart`, `dialogs.dart`: telas
- `canvas_controller.dart`: regras do caderno (traços, borracha, histórico, páginas)
- `canvas_view.dart`: desenho em camadas (papel, marca-texto, tinta, traço ao vivo) e gestos
- `palm_guard.dart`: decisão de quais toques ignorar
- `shape_recognizer.dart`, `scribble.dart`, `geometry.dart`: reconhecimento e gesto
- `settings.dart`, `models.dart`, `storage.dart`: dados, preferências e salvamento

## Onde ficam os arquivos

Na pasta de documentos do usuário: `notas_app/<id>.json` (um por caderno) e
`notas_config.json` (preferências).

## Limitações atuais

- A caneta tinteiro varia a largura por pressão e velocidade, mas não tem ponta
  chata (caligráfica) que muda a espessura pela direção do traço. A
  sensibilidade à pressão vai ganhar ajuste fino na Entrega B (configuração de pressão).
- Borracha Normal: cada passada divide os traços em pedaços com mais pontos;
  em páginas muito cheias de traços longos pode ficar mais pesado que o modo Traço.

- A página fica branca também no tema escuro (só o resto da interface escurece).
- Miniaturas e lista carregam todos os cadernos de uma vez; com muitos cadernos
  grandes pode ficar lento (cache de miniaturas vem depois).
- A latência da caneta no Flutter é boa, mas não igual à do GoodNotes no iPad.
  Se incomodar no Android, a camada de tinta pode ser trocada por uma nativa depois.

## Próximas entregas

- **B:** configuração de pressão da caneta, laço de seleção, mais formas
  geométricas, post-its.
- **C:** importar/anotar PDF, pastas na biblioteca, modelos de página.
- Depois: sincronização com o Google Drive, gravação de áudio, flashcards, etc.

## Nome e ícone (Gireli Notes)
1. `flutter pub get`
2. `dart run tools/aplicar_marca.dart`  (nome no Android/Windows; o .exe passa a ser `GireliNotes.exe`; garante a permissão de internet)
3. `dart run flutter_launcher_icons`  (gera os ícones do Android e do Windows a partir de `assets/icon/`)
4. `flutter clean` e compile de novo.
