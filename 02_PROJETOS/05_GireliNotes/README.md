# Notas — caderno digital pessoal (Android + Windows)

Fase 1: núcleo do app. Caneta fluida, marca-texto, linha reta, reconhecimento de
formas, apagar riscando, borracha, desfazer/refazer, páginas, zoom e salvamento
automático local. A sincronização com o Google Drive é a Fase 3 (o formato de
arquivo já é um JSON por caderno, pensado para isso).

> Este código foi escrito sem poder compilar nem rodar o Flutter no ambiente em
> que foi gerado. A lógica de reconhecimento foi validada num port em Python, mas
> o app em si nunca foi executado: é normal aparecer algum erro de compilação
> na primeira vez. Mande a mensagem de erro que eu corrijo.

## Como rodar

1. Instale o [Flutter](https://docs.flutter.dev/get-started/install) e, para o
   Windows, o Visual Studio com a carga **"Desenvolvimento para desktop com C++"**.
2. Crie um projeto novo (isso gera as pastas `android/` e `windows/`):

   ```
   flutter create --platforms=android,windows --project-name notas notas
   ```

3. Copie por cima do projeto novo, desta pasta: `lib/`, `test/` e `pubspec.yaml`.
4. Dentro do projeto:

   ```
   flutter pub get
   flutter test            # roda os testes de formas, gesto e desfazer
   flutter run -d windows  # PC
   flutter run             # tablet Android (depuração USB ligada)
   ```

   Para instalar de vez no tablet: `flutter build apk --release`.

## Como usar

| Ação | Como |
|---|---|
| Desenhar | caneta / mesa digitalizadora |
| Encaixar reta ou forma | desenhe e **segure a caneta parada** meio segundo (vibra no tablet) |
| Ajustar a reta encaixada | continue arrastando; ela gruda em múltiplos de 15° |
| Reta direto | ferramenta "Linha reta" (tecla L) |
| Apagar riscando | faça um zigue-zague por cima do que quer apagar |
| Borracha | ferramenta borracha (E) ou a ponta invertida da caneta |
| Rolar / zoom | dois dedos (tablet); roda do mouse, **Ctrl + roda** para zoom (PC) |
| Desfazer / refazer | Ctrl+Z / Ctrl+Y |
| Dedo desenha | botão "mão" na barra (por padrão o dedo só rola e dá zoom) |

Formas reconhecidas: reta, círculo, elipse, retângulo, triângulo e quadrilátero.

## Arquivos

- `canvas_controller.dart`: regras do caderno (traços, borracha, histórico, páginas)
- `canvas_view.dart`: desenho na tela, gestos de caneta/dedo/zoom
- `shape_recognizer.dart`, `scribble.dart`, `geometry.dart`: reconhecimento e gesto
- `models.dart`, `storage.dart`: dados e salvamento (pasta de documentos do app)

## Limitações atuais

- Elipses são reconhecidas só alinhadas aos eixos (elipse inclinada vira polígono ou nada).
- Um caderno só; sem biblioteca de cadernos ainda.
- A latência da caneta no Flutter é boa, mas não igual à do GoodNotes no iPad.
  Se incomodar no Android, a camada de tinta pode ser trocada por uma nativa depois.

## Próximas fases

2. Biblioteca de cadernos, laço de seleção, mover/redimensionar traços.
3. Sincronização com o Google Drive (login Google, pasta privada do app, conflito por data).
4. Importar e anotar PDF, exportar PDF, texto, busca.
